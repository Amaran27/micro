import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Simplified adapter for ZhipuAI GLM models
/// Uses LangChain's ChatOpenAI with custom baseUrl (coding endpoint)
/// ZhipuAI API is OpenAI-compatible, no need for custom implementation
class ZhipuAIAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  ChatOpenAI? _chatModel;
  String _currentModel = 'glm-4.5-flash';
  bool _isInitialized = false;

  // ZhipuAI coding endpoint (OpenAI-compatible, optimized for code tasks)
  static const String _codingBaseUrl = 'https://api.z.ai/api/coding/paas/v4';
  // General endpoint (for non-coding tasks)
  static const String _generalBaseUrl = 'https://api.z.ai/api/paas/v4';

  @override
  String get providerId => 'zhipu-ai';

  @override
  String get currentModel => _currentModel;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get supportsStreaming => true;

  @override
  Future<void> initialize(ProviderConfig config) async {
    try {
      if (config is! ZhipuAIConfig) {
        throw ArgumentError(
            'Expected ZhipuAIConfig, got ${config.runtimeType}');
      }

      _currentModel = config.model;
      final apiKey = config.apiKey;

      if (apiKey.isEmpty) {
        throw Exception('ZhipuAI API key not provided in config');
      }

      // Choose endpoint based on config
      final baseUrl =
          config.useCodingEndpoint ? _codingBaseUrl : _generalBaseUrl;
      final endpointType = config.useCodingEndpoint ? 'coding' : 'general';

      // Use ChatOpenAI with custom baseUrl (ZhipuAI is OpenAI-compatible)
      _chatModel = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: baseUrl,
        defaultOptions: ChatOpenAIOptions(
          model: _currentModel,
          temperature: 0.7,
        ),
      );

      _isInitialized = true;
      _logger.info(
          'ZhipuAI adapter initialized with model: $_currentModel ($endpointType endpoint)');
    } catch (e) {
      _logger.error('Failed to initialize ZhipuAI adapter', error: e);
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<micro.ChatMessage> sendMessage({
    required String text,
    required List<micro.ChatMessage> history,
  }) async {
    if (!_isInitialized || _chatModel == null) {
      throw Exception('ZhipuAI adapter not initialized');
    }

    _logger.info('ZhipuAI adapter sending message with model: $_currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final response = await _chatModel!.invoke(prompt);

      return _convertResponseToMicro(response.output.content);
    } catch (e) {
      _logger.error('Error sending message to ZhipuAI', error: e);
      return _buildErrorMessage(e);
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  }) async* {
    if (!_isInitialized || _chatModel == null) {
      throw Exception('ZhipuAI adapter not initialized');
    }

    _logger
        .info('ZhipuAI adapter streaming message with model: $_currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final stream = _chatModel!.stream(prompt);

      await for (final chunk in stream) {
        final content = chunk.output.content;
        if (content.isNotEmpty) {
          yield content;
        }
      }
    } catch (e) {
      _logger.error('Error streaming message from ZhipuAI', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
  }

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized) return false;

    try {
      _currentModel = newModel;
      _logger.info('ZhipuAI model switched to: $newModel');
      return true;
    } catch (e) {
      _logger.error('Failed to switch ZhipuAI model', error: e);
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    return [
      'glm-4-plus',
      'glm-4.5-flash',
      'glm-4.6',
      'glm-4.5',
      'glm-4.5-air',
      'glm-4-flash',
      'glm-4-air',
      'glm-4-long',
      'glm-3-turbo',
    ];
  }

  @override
  BaseChatModel? getLangChainModel() {
    return _chatModel;
  }

  @override
  void dispose() {
    _chatModel?.close();
    _chatModel = null;
    _isInitialized = false;
  }

  List<ChatMessage> _convertHistoryToLangchain(
    List<micro.ChatMessage> history,
  ) {
    final messages = <ChatMessage>[];
    for (final msg in history) {
      if (msg.isFromUser) {
        messages.add(ChatMessage.humanText(msg.content));
      } else if (msg.isFromAssistant) {
        messages.add(ChatMessage.ai(msg.content));
      } else {
        messages.add(ChatMessage.system(msg.content));
      }
    }
    return messages;
  }

  micro.ChatMessage _convertResponseToMicro(String responseContent) {
    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: responseContent,
    );
  }

  micro.ChatMessage _buildErrorMessage(Object error) {
    String errorMessage;

    if (error.toString().contains('1113')) {
      errorMessage =
          'Your ZhipuAI account has insufficient balance. Please recharge your account to continue using this provider.';
    } else if (error.toString().contains('code: 1000') ||
        error.toString().toLowerCase().contains('authorization failure')) {
      errorMessage =
          'ZhipuAI Authorization Failure (code 1000). Please verify that your API key is valid and that the selected model is enabled for your account.';
    } else if (error.toString().contains('401') ||
        error.toString().contains('authentication')) {
      errorMessage =
          'ZhipuAI authentication failed. Please update your API key in settings.';
    } else if (error.toString().contains('RateLimitException') ||
        error.toString().contains('429')) {
      errorMessage =
          'ZhipuAI rate limit exceeded. Please wait a moment and try again.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      errorMessage =
          'Network connection issue. Please check your internet connection and try again.';
    } else {
      errorMessage =
          'Sorry, I encountered an error while processing your message. Please try again.';
    }

    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: errorMessage,
    );
  }
}

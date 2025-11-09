import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Adapter for OpenAI ChatGPT models
/// Uses LangChain's ChatOpenAI integration directly
class ChatOpenAIAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  late ChatOpenAI _chatModel;
  OpenAIConfig? _config;
  bool _isInitialized = false;

  @override
  String get providerId => 'openai';

  @override
  String get currentModel => _config?.model ?? 'gpt-4o';

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get supportsStreaming => true;

  @override
  Future<void> initialize(ProviderConfig config) async {
    try {
      if (config is! OpenAIConfig) {
        throw ArgumentError('Expected OpenAIConfig, got ${config.runtimeType}');
      }
      _config = config;

      _chatModel = ChatOpenAI(
        apiKey: config.apiKey,
        defaultOptions: ChatOpenAIOptions(
          model: config.model,
          temperature: 0.7,
        ),
      );

      _isInitialized = true;
      _logger.info('OpenAI adapter initialized with model: ${config.model}');
    } catch (e) {
      _logger.error('Failed to initialize OpenAI adapter', error: e);
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<micro.ChatMessage> sendMessage({
    required String text,
    required List<micro.ChatMessage> history,
  }) async {
    if (!_isInitialized) {
      throw Exception('OpenAI adapter not initialized');
    }

    try {
      _logger.info('OpenAI adapter sending message with model: $currentModel');

      // Convert micro messages to LangChain ChatMessages
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final response = await _chatModel.invoke(
        prompt,
        options: ChatOpenAIOptions(
          model: _config!.model,
          temperature: 0.7,
        ),
      );

      return _convertResponseToMicro(response.output);
    } catch (e) {
      _logger.error('Error sending message to OpenAI', error: e);
      return _buildErrorMessage(e, 'OpenAI');
    }
  }

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized || _config == null) return false;

    try {
      final newConfig = OpenAIConfig(
        model: newModel,
        apiKey: _config!.apiKey,
        organizationId: _config!.organizationId,
      );
      await initialize(newConfig);
      return true;
    } catch (e) {
      _logger.error('Failed to switch OpenAI model', error: e);
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    return [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4',
      'gpt-4-turbo',
      'gpt-3.5-turbo',
    ];
  }

  @override
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  }) async* {
    if (!_isInitialized) {
      throw Exception('OpenAI adapter not initialized');
    }

    _logger.info('OpenAI adapter streaming message with model: $currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);

      // Use LangChain's stream method for token-by-token streaming
      final stream = _chatModel.stream(
        prompt,
        options: ChatOpenAIOptions(
          model: _config!.model,
          temperature: 0.7,
        ),
      );

      await for (final chunk in stream) {
        final content = chunk.output.toString();
        if (content.isNotEmpty) {
          yield content;
        }
      }
    } catch (e) {
      _logger.error('Error streaming message from OpenAI', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _chatModel = null as dynamic;
    _config = null;
    _isInitialized = false;
  }

  /// Convert micro ChatMessages to LangChain ChatMessages
  List<ChatMessage> _convertHistoryToLangchain(
    List<micro.ChatMessage> history,
  ) {
    return history.map((msg) {
      if (msg.isFromUser) {
        return ChatMessage.humanText(msg.content);
      } else if (msg.isFromAssistant) {
        return ChatMessage.ai(msg.content);
      } else {
        return ChatMessage.system(msg.content);
      }
    }).toList();
  }

  /// Convert LangChain ChatMessage response to micro ChatMessage
  micro.ChatMessage _convertResponseToMicro(ChatMessage lcMessage) {
    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: lcMessage.toString(),
    );
  }

  /// Build user-friendly error message from exception
  micro.ChatMessage _buildErrorMessage(Object error, String provider) {
    String errorMessage;
    if (error.toString().contains('RateLimitException') ||
        error.toString().contains('429')) {
      errorMessage =
          'I\'ve reached my usage limit for now. Please try again later or switch to a different AI provider in settings.';
    } else if (error.toString().contains('quota') ||
        error.toString().contains('billing')) {
      errorMessage =
          'The $provider quota has been exceeded. Please check your billing details or try a different provider.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      errorMessage =
          'Network connection issue. Please check your internet connection and try again.';
    } else if (error.toString().contains('401') ||
        error.toString().contains('authentication')) {
      errorMessage =
          'Authentication failed. Please check your $provider API key in settings.';
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

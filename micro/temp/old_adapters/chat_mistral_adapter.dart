import 'package:langchain/langchain.dart';
import 'package:langchain_mistralai/langchain_mistralai.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Adapter for Mistral AI models
/// Uses LangChain's ChatMistralAI integration
class ChatMistralAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  late ChatMistralAI _chatModel;
  OpenAIConfig? _config; // Mistral API is compatible with OpenAI config
  bool _isInitialized = false;

  @override
  String get providerId => 'mistral-ai';

  @override
  String get currentModel => _config?.model ?? 'mistral-small';

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

      _chatModel = ChatMistralAI(
        apiKey: config.apiKey,
        defaultOptions: ChatMistralAIOptions(
          model: config.model,
          temperature: 0.7,
        ),
      );

      _isInitialized = true;
      _logger.info('Mistral adapter initialized with model: ${config.model}');
    } catch (e) {
      _logger.error('Failed to initialize Mistral adapter', error: e);
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
      throw Exception('Mistral adapter not initialized');
    }

    try {
      _logger.info('Mistral adapter sending message with model: $currentModel');

      // Convert micro messages to LangChain ChatMessages
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final response = await _chatModel.invoke(prompt);

      return _convertResponseToMicro(response.output);
    } catch (e) {
      _logger.error('Error sending message to Mistral', error: e);
      return _buildErrorMessage(e, 'Mistral');
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  }) async* {
    if (!_isInitialized) {
      throw Exception('Mistral adapter not initialized');
    }

    final startTime = DateTime.now();
    _logger.info('Mistral adapter streaming message with model: $currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);

      final stream = _chatModel.stream(prompt);

      await for (final chunk in stream) {
        final content = chunk.output.toString();
        if (content.isNotEmpty) {
          yield content;
        }
      }
      
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      _logger.info('Mistral streaming completed: ${totalTime}ms total');
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      _logger.error('Error streaming message from Mistral (${totalTime}ms elapsed)', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
  }

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized || _config == null) return false;

    try {
      final newConfig = OpenAIConfig(
        model: newModel,
        apiKey: _config!.apiKey,
      );
      await initialize(newConfig);
      return true;
    } catch (e) {
      _logger.error('Failed to switch Mistral model', error: e);
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    return [
      'mistral-large',
      'mistral-medium',
      'mistral-small',
    ];
  }

  @override
  BaseChatModel? getLangChainModel() {
    return _chatModel as BaseChatModel?;
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

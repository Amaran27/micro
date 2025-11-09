import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Unified adapter for all OpenAI-compatible providers
/// Uses LangChain's ChatOpenAI with custom baseUrl for different providers
///
/// Supported providers:
/// - OpenAI (https://api.openai.com/v1)
/// - ZhipuAI General (https://open.bigmodel.cn/api/paas/v4)
/// - ZhipuAI Coding (https://open.bigmodel.cn/api/coding/paas/v4)
/// - Mistral AI (https://api.mistral.ai/v1)
/// - DeepSeek (https://api.deepseek.com/v1)
/// - Any other OpenAI-compatible API
class UnifiedOpenAIAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  ChatOpenAI? _chatModel;
  ProviderConfig? _config;
  String? _providerId;
  String? _currentModel;
  bool _isInitialized = false;

  // Base URLs for different providers
  static const Map<String, String> _baseUrls = {
    'openai': 'https://api.openai.com/v1',
    // Prefer international endpoints by default
    'zhipu-ai': 'https://api.z.ai/api/paas/v4',
    'zhipu-ai-coding': 'https://api.z.ai/api/coding/paas/v4',
    'mistral': 'https://api.mistral.ai/v1',
    'deepseek': 'https://api.deepseek.com/v1',
  };

  @override
  String get providerId => _providerId ?? 'unknown';

  @override
  String get currentModel => _currentModel ?? 'unknown';

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get supportsStreaming => true;

  @override
  Future<void> initialize(ProviderConfig config) async {
    try {
      _config = config;
      _providerId = config.providerId;
      _currentModel = config.model; // All ProviderConfig have model field

      // Get base URL for provider
      final baseUrl = _getBaseUrl(config);
      final apiKey = _getApiKey(config);

      if (apiKey.isEmpty) {
        throw Exception('API key not provided for $_providerId');
      }

      _chatModel = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: baseUrl,
        defaultOptions: ChatOpenAIOptions(
          model: _currentModel!,
          temperature: 0.7,
        ),
      );

      _isInitialized = true;
      _logger.info(
          '$_providerId adapter initialized with model: $_currentModel (baseUrl: $baseUrl)');
    } catch (e) {
      _logger.error('Failed to initialize $_providerId adapter', error: e);
      _isInitialized = false;
      rethrow;
    }
  }

  String _getBaseUrl(ProviderConfig config) {
    // Check if config specifies a custom base URL
    if (config is ZhipuAIConfig && config.useCodingEndpoint == true) {
      return _baseUrls['zhipu-ai-coding']!;
    }

    return _baseUrls[config.providerId] ?? _baseUrls['openai']!;
  }

  String _getApiKey(ProviderConfig config) {
    // All ProviderConfig have apiKey field
    return config.apiKey;
  }

  @override
  Future<micro.ChatMessage> sendMessage({
    required String text,
    required List<micro.ChatMessage> history,
  }) async {
    if (!_isInitialized || _chatModel == null) {
      throw Exception('$_providerId adapter not initialized');
    }

    try {
      _logger.info(
          '$_providerId adapter sending message with model: $currentModel');

      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final response = await _chatModel!.invoke(prompt);

      return _convertResponseToMicro(response.output);
    } catch (e) {
      _logger.error('Error sending message to $_providerId', error: e);
      return _buildErrorMessage(e, _providerId ?? 'provider');
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  }) async* {
    if (!_isInitialized || _chatModel == null) {
      throw Exception('$_providerId adapter not initialized');
    }

    _logger.info(
        '$_providerId adapter streaming message with model: $currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final stream = _chatModel!.stream(prompt);

      await for (final chunk in stream) {
        final content = chunk.output.toString();
        if (content.isNotEmpty) {
          yield content;
        }
      }
    } catch (e) {
      _logger.error('Error streaming message from $_providerId', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
  }

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized || _config == null) return false;

    try {
      _currentModel = newModel;
      final baseUrl = _getBaseUrl(_config!);
      final apiKey = _getApiKey(_config!);

      _chatModel = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: baseUrl,
        defaultOptions: ChatOpenAIOptions(
          model: newModel,
          temperature: 0.7,
        ),
      );

      _logger.info('Switched $_providerId model to: $newModel');
      return true;
    } catch (e) {
      _logger.error('Failed to switch $_providerId model', error: e);
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    // Return provider-specific default models
    switch (_providerId) {
      case 'openai':
        return [
          'gpt-4o',
          'gpt-4o-mini',
          'gpt-4',
          'gpt-4-turbo',
          'gpt-3.5-turbo'
        ];
      case 'zhipu-ai':
        return [
          'glm-4-plus',
          'glm-4.5-flash',
          'glm-4.6',
          'glm-4.5',
          'glm-4.5-air'
        ];
      case 'mistral':
        return [
          'mistral-large-latest',
          'mistral-small-latest',
          'mistral-medium-latest'
        ];
      default:
        return [];
    }
  }

  @override
  BaseChatModel? getLangChainModel() {
    return _chatModel;
  }

  @override
  void dispose() {
    _chatModel = null;
    _config = null;
    _isInitialized = false;
  }

  List<ChatMessage> _convertHistoryToLangchain(
      List<micro.ChatMessage> history) {
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

  micro.ChatMessage _convertResponseToMicro(ChatMessage lcMessage) {
    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: lcMessage.toString(),
    );
  }

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

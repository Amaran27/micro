import 'package:langchain/langchain.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../providers/chat_zhipuai.dart';
import '../providers/zhipuai_provider.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Adapter for ZhipuAI GLM models
/// Uses LangChain's SimpleChatModel-based ChatZhipuAI implementation
class ZhipuAIAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  ChatZhipuAI? _chatModel;
  ZhipuAIProvider? _zhipuaiProvider;
  String _currentModel = 'glm-4.6';
  bool _isInitialized = false;
  String? _apiKey;

  @override
  String get providerId => 'zhipu-ai';

  @override
  String get currentModel => _currentModel;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize(ProviderConfig config) async {
    try {
      // Type-safe configuration with validation in constructor
      if (config is! ZhipuAIConfig) {
        throw ArgumentError(
            'Expected ZhipuAIConfig, got ${config.runtimeType}');
      }

      _currentModel = config.model;

      // Get API key directly from config (new storage system)
      // Use API key provided via config (already persisted in secure storage
      // by ProviderStorageService). Avoid re-reading legacy stores here to
      // prevent mismatches with the Test Connection flow.
      _apiKey = config.apiKey;
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('ZhipuAI API key not provided in config');
      }

      // Log masked key details for diagnostics
      final masked = _apiKey!.length > 8
          ? '${_apiKey!.substring(0, 4)}...${_apiKey!.substring(_apiKey!.length - 4)}'
          : '****';
      _logger.info(
          'Using ZhipuAI API key from config (len=${_apiKey!.length}): $masked');

      // Create LangChain ChatZhipuAI model
      _chatModel = ChatZhipuAI(
        apiKey: _apiKey!,
        model: _currentModel,
        defaultOptions: const ChatZhipuAIOptions(
          temperature: 0.7,
        ),
      );

      _zhipuaiProvider = ZhipuAIProvider();

      _isInitialized = true;
      _logger.info(
          'ZhipuAI adapter initialized successfully with model: $_currentModel');
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
      // Convert micro messages to LangChain ChatMessages
      // Note: history already contains all messages including the current user message
      final messages = _convertHistoryToLangchain(history);

      // Create prompt and invoke model
      final prompt = PromptValue.chat(messages);
      final response = await _chatModel!.invoke(prompt);

      return _convertResponseToMicro(response.output);
    } catch (e) {
      _logger.error('Error sending message to ZhipuAI', error: e);

      // Log detailed error information for debugging
      _logger.error('Full error toString: ${e.toString()}');
      if (e is Exception) {
        _logger.error('Exception type: ${e.runtimeType}');
      }

      // Convert common ZhipuAI errors to user-friendly messages
      String errorMessage;

      // Check for ZhipuAI API error codes in response body
      if (e is Exception && e.toString().contains('1113')) {
        errorMessage =
            'Your ZhipuAI account has insufficient balance. Please recharge your account to continue using this provider.';
      } else if (e.toString().contains('code: 1000') ||
          e.toString().toLowerCase().contains('authorization failure')) {
        errorMessage =
            'ZhipuAI Authorization Failure (code 1000). Please verify that your API key is valid for api.z.ai (PaaS) and that the selected model is enabled for your account. Try regenerating the key or testing the connection in Settings.';
      } else if (e is ZhipuAIAuthenticationException ||
          e.toString().contains('401') ||
          e.toString().contains('令牌已过期') ||
          e.toString().contains('token') ||
          e.toString().contains('API key format')) {
        errorMessage =
            'ZhipuAI authentication failed. Please update your API key in settings. '
            'ZhipuAI keys should be 49+ characters with a dot (.) separator.';
      } else if (e.toString().contains('RateLimitException')) {
        errorMessage =
            'ZhipuAI rate limit exceeded. Please wait a moment and try again.';
      } else if (e.toString().contains('429')) {
        // 429 could be rate limit or billing issue, check response body
        if (e.toString().contains('Insufficient balance') ||
            e.toString().contains('no resource package')) {
          errorMessage =
              'Your ZhipuAI account has insufficient balance. Please recharge your account to continue using this provider.';
        } else {
          errorMessage =
              'ZhipuAI service temporarily unavailable. Please try again later.';
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
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

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized || _chatModel == null) return false;

    try {
      _currentModel = newModel;
      // Recreate the chat model with the new model ID
      _chatModel = ChatZhipuAI(
        apiKey: _apiKey!,
        model: newModel,
        defaultOptions: const ChatZhipuAIOptions(
          temperature: 0.7,
        ),
      );
      _logger.info('ZhipuAI model switched to: $newModel');
      return true;
    } catch (e) {
      _logger.error('Failed to switch ZhipuAI model', error: e);
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    try {
      if (_zhipuaiProvider != null) {
        final models = await _zhipuaiProvider!.getAvailableModels();
        return models.map((model) => model.modelId).toList();
      }
    } catch (e) {
      _logger.error('Error getting ZhipuAI models', error: e);
    }

    // Return current ZhipuAI models as fallback
    return [
      'glm-4.6',
      'glm-4.5-flash',
      'glm-4.5v',
      'glm-4-flash',
      'glm-4-air',
      'glm-4-long',
      'glm-3-turbo',
    ];
  }

  @override
  void dispose() {
    _chatModel?.close();
    _chatModel = null;
    _zhipuaiProvider = null;
    _apiKey = null;
    _isInitialized = false;
  }

  /// Convert micro ChatMessages to LangChain ChatMessages
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

  /// Convert ZhipuAI response to micro ChatMessage
  micro.ChatMessage _convertResponseToMicro(String responseContent) {
    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: responseContent,
    );
  }
}

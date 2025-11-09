import 'package:langchain/langchain.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../providers/chat_zhipuai.dart';
import '../providers/zhipuai_provider.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Adapter for ZhipuAI GLM models - General Chat Endpoint
/// Optimized for natural conversations and general queries
/// Uses: https://api.z.ai/api/paas/v4 (general endpoint)
class ZhipuAIGeneralAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  ChatZhipuAI? _chatModel;
  ZhipuAIProvider? _zhipuaiProvider;
  String _currentModel = 'glm-4.5-flash';
  bool _isInitialized = false;
  String? _apiKey;

  // Configuration for general endpoint
  static const String _generalEndpoint = 'https://api.z.ai/api/paas/v4';
  static const String _freeModel = 'glm-4.5-flash';
  static const List<String> _supportedModels = [
    'glm-4.5-flash',
    'glm-4.6',
    'glm-4.5',
    'glm-4.5-air',
  ];

  @override
  String get providerId => 'zai-general';

  @override
  String get currentModel => _currentModel;

  @override
  bool get isInitialized => _isInitialized;

  /// Human-readable provider name
  String get providerName => 'Z.AI (General)';

  /// Description of this provider variant
  String get description => 'General chat models optimized for conversations';

  /// Get the API endpoint being used
  String get endpoint => _generalEndpoint;

  /// Get list of supported models
  List<String> get supportedModels => _supportedModels;

  /// Get recommended model for free tier
  String get freeModel => _freeModel;

  @override
  Future<void> initialize(ProviderConfig config) async {
    try {
      if (config is! ZhipuAIConfig) {
        throw ArgumentError(
            'Expected ZhipuAIConfig, got ${config.runtimeType}');
      }

      _currentModel = config.model.isEmpty ? _freeModel : config.model;

      // Validate model is supported
      if (!_supportedModels.contains(_currentModel)) {
        _logger.warning(
            'Model $_currentModel not in general endpoint supported list, '
            'using $_freeModel');
        _currentModel = _freeModel;
      }

      _apiKey = config.apiKey;
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('ZhipuAI API key not provided in config');
      }

      final masked = _apiKey!.length > 8
          ? '${_apiKey!.substring(0, 4)}...${_apiKey!.substring(_apiKey!.length - 4)}'
          : '****';
      _logger
          .info('Initializing Z.AI General adapter with model: $_currentModel, '
              'key: $masked, endpoint: $_generalEndpoint');

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
          'Z.AI General adapter initialized successfully with model: $_currentModel');
    } catch (e) {
      _logger.error('Failed to initialize Z.AI General adapter', error: e);
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
      throw Exception('Z.AI General adapter not initialized');
    }

    _logger.info(
        'Z.AI General adapter sending message with model: $_currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      final prompt = PromptValue.chat(messages);
      final response = await _chatModel!.invoke(prompt);

      return _convertResponseToMicro(response.output);
    } catch (e) {
      _logger.error('Error sending message to Z.AI General', error: e);
      return _handleError(e);
    }
  }

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized || _chatModel == null) return false;

    try {
      if (!_supportedModels.contains(newModel)) {
        _logger.warning('Model $newModel not supported by general endpoint');
        return false;
      }

      _currentModel = newModel;
      _chatModel = ChatZhipuAI(
        apiKey: _apiKey!,
        model: newModel,
        defaultOptions: const ChatZhipuAIOptions(
          temperature: 0.7,
        ),
      );
      _logger.info('Z.AI General model switched to: $newModel');
      return true;
    } catch (e) {
      _logger.error('Failed to switch Z.AI General model', error: e);
      return false;
    }
  }

  @override
  BaseChatModel? getLangChainModel() {
    return _chatModel as BaseChatModel?;
  }

  @override
  void dispose() {
    _chatModel?.close();
    _chatModel = null;
    _zhipuaiProvider = null;
    _apiKey = null;
    _isInitialized = false;
  }

  /// Convert history of micro messages to LangChain messages
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

  /// Convert LangChain response to micro message
  micro.ChatMessage _convertResponseToMicro(String content) {
    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: content,
    );
  }

  /// Handle and convert errors to user-friendly messages
  micro.ChatMessage _handleError(dynamic e) {
    String errorMessage;

    if (e.toString().contains('1113')) {
      errorMessage =
          'Your Z.AI account has insufficient balance. Please recharge your account.';
    } else if (e.toString().contains('code: 1000') ||
        e.toString().toLowerCase().contains('authorization failure')) {
      errorMessage =
          'Z.AI Authorization Failed. Verify your API key is valid for api.z.ai';
    } else if (e.toString().contains('401') ||
        e.toString().contains('token') ||
        e.toString().contains('API key')) {
      errorMessage =
          'Z.AI authentication failed. Please update your API key in settings.';
    } else if (e.toString().contains('429')) {
      errorMessage = 'Z.AI rate limit exceeded. Please wait and try again.';
    } else if (e.toString().contains('network') ||
        e.toString().contains('connection')) {
      errorMessage =
          'Network connection issue. Please check your internet connection.';
    } else {
      errorMessage = 'Sorry, I encountered an error. Please try again.';
    }

    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: errorMessage,
    );
  }

  @override
  Future<List<String>> getAvailableModels() async {
    return _supportedModels;
  }
}

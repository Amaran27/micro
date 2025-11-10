import 'package:langchain/langchain.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../simple_ai_service.dart';

/// Adapter wrapper for SimpleAIService to maintain backward compatibility
/// This allows gradual migration from the adapter pattern to direct LangChain usage
class SimpleProviderAdapter implements ProviderAdapter {
  final SimpleAIService _service;
  final String _providerId;
  String _currentModel;
  bool _isInitialized = false;

  SimpleProviderAdapter(this._service, this._providerId, this._currentModel);

  @override
  String get providerId => _providerId;

  @override
  String get currentModel => _currentModel;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get supportsStreaming => true;

  @override
  Future<void> initialize(ProviderConfig config) async {
    Map<String, dynamic>? extraConfig;
    
    if (config is ZhipuAIConfig) {
      extraConfig = {'useCodingEndpoint': config.useCodingEndpoint};
      _currentModel = config.model;
    } else if (config is OpenAIConfig) {
      _currentModel = config.model;
    } else if (config is GoogleConfig) {
      _currentModel = config.model;
    }

    await _service.initializeProvider(
      providerId: _providerId,
      apiKey: config.apiKey,
      model: _currentModel,
      extraConfig: extraConfig,
    );
    
    _isInitialized = true;
  }

  @override
  Future<micro.ChatMessage> sendMessage({
    required String text,
    required List<micro.ChatMessage> history,
  }) async {
    return await _service.sendMessage(
      providerId: _providerId,
      text: text,
      history: history,
    );
  }

  @override
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  }) {
    return _service.sendMessageStream(
      providerId: _providerId,
      text: text,
      history: history,
    );
  }

  @override
  Future<bool> switchModel(String newModel) async {
    _currentModel = newModel;
    // Model switching would require re-initialization with SimpleAIService
    return true;
  }

  @override
  Future<List<String>> getAvailableModels() async {
    // Return models based on provider
    switch (_providerId.toLowerCase()) {
      case 'zhipu-ai':
      case 'zhipuai':
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
      case 'openai':
        return [
          'gpt-4-turbo',
          'gpt-4',
          'gpt-3.5-turbo',
        ];
      case 'google':
        return [
          'gemini-1.5-pro',
          'gemini-1.5-flash',
          'gemini-pro',
        ];
      default:
        return [];
    }
  }

  @override
  BaseChatModel? getLangChainModel() {
    return _service.getModel(_providerId);
  }

  @override
  void dispose() {
    // SimpleAIService handles disposal centrally
  }
}

import '../../../domain/models/chat/chat_message.dart' as micro;
import 'provider_config.dart';

/// Unified interface for all AI providers
/// This adapter pattern abstracts provider-specific implementations
/// while providing a consistent interface for chat functionality
abstract class ProviderAdapter {
  /// Provider identifier (e.g., 'openai', 'google', 'zhipuai')
  String get providerId;

  /// Currently selected model for this provider
  String get currentModel;

  /// Whether this provider is initialized and ready to use
  bool get isInitialized;

  /// Initialize the provider with typed configuration
  /// Uses ProviderConfig subclasses for type safety instead of generic Map
  Future<void> initialize(ProviderConfig config);

  /// Send a message and get response
  Future<micro.ChatMessage> sendMessage({
    required String text,
    required List<micro.ChatMessage> history,
  });

  /// Send a message and stream response tokens in real-time
  /// Returns a stream of partial content updates
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  });

  /// Check if this provider supports streaming
  bool get supportsStreaming => false;

  /// Switch to a different model
  Future<bool> switchModel(String newModel);

  /// Get available models for this provider
  Future<List<String>> getAvailableModels();

  /// Dispose of resources
  void dispose();
}

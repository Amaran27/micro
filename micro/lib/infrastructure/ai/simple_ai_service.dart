import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import '../../domain/models/chat/chat_message.dart' as micro;
import '../../core/utils/logger.dart';

/// Simple AI Provider Service - No adapters needed!
/// LangChain already provides the abstraction we need.
/// 
/// This replaces the complex adapter pattern with direct LangChain usage.
/// All providers (OpenAI, Google, ZhipuAI) implement BaseChatModel,
/// so we can use them interchangeably without custom abstractions.
class SimpleAIService {
  final AppLogger _logger = AppLogger();
  final Map<String, BaseChatModel> _models = {};
  final Map<String, String> _modelNames = {};  // Track which model is active for each provider
  
  /// Initialize a provider with its configuration
  Future<void> initializeProvider({
    required String providerId,
    required String apiKey,
    required String model,
    Map<String, dynamic>? extraConfig,
  }) async {
    try {
      BaseChatModel chatModel;
      
      switch (providerId.toLowerCase()) {
        case 'zhipu-ai':
        case 'zhipuai':
          final baseUrl = extraConfig?['useCodingEndpoint'] == true
              ? 'https://api.z.ai/api/coding/paas/v4'
              : 'https://api.z.ai/api/paas/v4';
          
          chatModel = ChatOpenAI(
            apiKey: apiKey,
            baseUrl: baseUrl,
            defaultOptions: ChatOpenAIOptions(
              model: model,
              temperature: 0.7,
            ),
          );
          break;
          
        case 'google':
          chatModel = ChatGoogleGenerativeAI(
            apiKey: apiKey,
            defaultOptions: ChatGoogleGenerativeAIOptions(
              model: model,
              temperature: 0.7,
            ),
          );
          break;
          
        case 'openai':
          chatModel = ChatOpenAI(
            apiKey: apiKey,
            defaultOptions: ChatOpenAIOptions(
              model: model,
              temperature: 0.7,
            ),
          );
          break;
          
        default:
          _logger.error('Unknown provider: $providerId');
          throw Exception('Unknown provider: $providerId');
      }
      
      _models[providerId] = chatModel;
      _modelNames[providerId] = model;
      _logger.info('Initialized $providerId with model $model');
      
    } catch (e) {
      _logger.error('Failed to initialize provider $providerId', error: e);
      rethrow;
    }
  }
  
  /// Send a message using a provider
  Future<micro.ChatMessage> sendMessage({
    required String providerId,
    required String text,
    required List<micro.ChatMessage> history,
  }) async {
    final model = _models[providerId];
    if (model == null) {
      _logger.error('Provider $providerId not initialized');
      throw Exception('Provider $providerId not initialized');
    }
    
    try {
      // 1) Inspect incoming history for safety & debugging
      try {
        _logger.info('SEND start: provider=$providerId model=${_modelNames[providerId]}');
        _logger.info('History count=${history.length}');
        for (var i = 0; i < history.length; i++) {
          final h = history[i];
          final content = h.content;
          _logger.info(
              'History[$i]: role=' +
                  (h.isFromUser
                      ? 'user'
                      : (h.isFromAssistant ? 'assistant' : 'system')) +
                  ', contentIsNull=${content == null}, contentType=${content?.runtimeType}');
        }
      } catch (_) {
        // Logging should never break the flow
      }

      // 2) Convert history to LangChain format (normalized content)
      final messages = _convertHistoryToLangChain(history);
      
      // Add current message
      messages.add(ChatMessage.humanText(_normalizeContent(text)));
      
      // Send to LangChain
      ChatResult response;
      try {
        // Log prompt preview (types + first 120 chars)
        try {
            for (var i = 0; i < messages.length; i++) {
              final m = messages[i];
              final role = m is HumanChatMessage
                  ? 'human'
                  : m is AIChatMessage
                      ? 'ai'
                      : m is SystemChatMessage
                          ? 'system'
                          : m.runtimeType.toString();
              
              // Extract content safely from each message type
              dynamic raw;
              try {
                if (m is HumanChatMessage) {
                  raw = m.content;
                } else if (m is AIChatMessage) {
                  raw = m.content;
                } else if (m is SystemChatMessage) {
                  raw = m.content;
                } else {
                  raw = null;
                }
              } catch (_) {
                raw = null;
              }
              
              final preview = _normalizeContent(raw);
              final safePreview = preview.length > 120 
                  ? '${preview.substring(0, 120)}...' 
                  : preview;
              _logger.info('PROMPT[$i] role=$role len=${preview.length} preview="$safePreview"');
            }
          } catch (_) {}        response = await model.invoke(PromptValue.chat(messages));
      } catch (e) {
        _logger.error('Invoke failed for provider $providerId', error: e);
        rethrow;
      }
      
      // LangChain pattern: extract content directly following cookbook examples
      final content = _extractContentSafely(response.output);
      
      // Convert back to Micro format
      return micro.ChatMessage.assistant(
        id: DateTime.now().toIso8601String(),
        content: content,
      );
    } catch (e) {
      _logger.error('Error sending message via $providerId', error: e);
      return _buildErrorMessage(e, providerId);
    }
  }
  
  /// Stream a message response
  Stream<String> sendMessageStream({
    required String providerId,
    required String text,
    required List<micro.ChatMessage> history,
  }) async* {
    final model = _models[providerId];
    if (model == null) {
      _logger.error('Provider $providerId not initialized');
      throw Exception('Provider $providerId not initialized');
    }
    
    try {
  // Convert history
  final messages = _convertHistoryToLangChain(history);
  messages.add(ChatMessage.humanText(_normalizeContent(text)));
      
      // Stream response
      final stream = model.stream(PromptValue.chat(messages));
      await for (final chunk in stream) {
        final content = chunk.output.content;
        if (content.isNotEmpty) {
          yield content;
        }
      }
    } catch (e) {
      _logger.error('Error streaming message via $providerId', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
  }
  
  /// Convert Micro message history to LangChain format
  List<ChatMessage> _convertHistoryToLangChain(List<micro.ChatMessage> history) {
    final messages = <ChatMessage>[];
    for (final msg in history) {
      final normalized = _normalizeContent(msg.content);
      if (msg.isFromUser) {
        messages.add(ChatMessage.humanText(normalized));
      } else if (msg.isFromAssistant) {
        messages.add(ChatMessage.ai(normalized));
      } else {
        messages.add(ChatMessage.system(normalized));
      }
    }
    return messages;
  }

  /// Normalize any dynamic content into a safe String
  String _normalizeContent(dynamic content) {
    if (content == null) return '';
    if (content is String) return content;
    // Some content types (e.g., ChatMessageContent) implement toString()
    try {
      return content.toString();
    } catch (_) {
      return '';
    }
  }
  
  /// Extract content using LangChain cookbook patterns
  /// Following examples from Microsoft docs - let the framework handle content extraction
  String _extractContentSafely(dynamic output) {
    // Check if output is null
    if (output == null) {
      _logger.error('Received null response from AI provider');
      return 'Error: Received null response from AI provider';
    }
    
    try {
      // LangChain cookbook pattern: access content directly
      // Most responses should have content as a simple string
      if (output.content != null) {
        final content = output.content;
        
        // If it's already a string, return it (most common case)
        if (content is String) {
          return content;
        }
        
        // For ChatMessageContent objects, use toString() which LangChain provides
        if (content.toString().isNotEmpty) {
          return content.toString();
        }
      }
      
      // Fallback: try the message's string representation
      final messageString = output.toString();
      if (messageString.isNotEmpty) {
        return messageString;
      }
      
      _logger.error('Unable to extract content from response: $output');
      return 'Error: Unable to extract content from AI response';
      
    } catch (e) {
      _logger.error('Error extracting content from response', error: e);
      return 'Error: Failed to extract content from AI response';
    }
  }
  
  /// Build user-friendly error message
  micro.ChatMessage _buildErrorMessage(Object error, String providerId) {
    String errorMessage;
    final errorStr = error.toString();

    if (errorStr.contains('1113')) {
      errorMessage =
          'Your $providerId account has insufficient balance. Please recharge your account.';
    } else if (errorStr.contains('401') || errorStr.contains('authentication')) {
      errorMessage =
          'Authentication failed for $providerId. Please update your API key in settings.';
    } else if (errorStr.contains('429')) {
      errorMessage =
          'Rate limit exceeded for $providerId. Please wait a moment and try again.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      errorMessage =
          'Network connection issue. Please check your internet connection.';
    } else {
      errorMessage =
          'Sorry, I encountered an error while processing your message. Please try again.';
    }

    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: errorMessage,
    );
  }
  
  /// Get the LangChain model directly for advanced use (like Swarm)
  BaseChatModel? getModel(String providerId) {
    return _models[providerId];
  }
  
  /// Get current model name for a provider
  String? getCurrentModel(String providerId) {
    return _modelNames[providerId];
  }
  
  /// Check if provider is initialized
  bool isInitialized(String providerId) {
    return _models.containsKey(providerId);
  }
  
  /// Get all initialized provider IDs
  List<String> getInitializedProviders() {
    return _models.keys.toList();
  }
  
  /// Dispose resources
  void dispose() {
    for (final model in _models.values) {
      try {
        model.close();
      } catch (e) {
        _logger.error('Error closing model', error: e);
      }
    }
    _models.clear();
    _modelNames.clear();
  }
}

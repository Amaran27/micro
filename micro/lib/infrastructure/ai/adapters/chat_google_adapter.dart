import 'package:langchain/langchain.dart';
import 'package:langchain_google/langchain_google.dart';
import '../interfaces/provider_adapter.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Adapter for Google Gemini models
/// Uses LangChain's ChatGoogleGenerativeAI integration
class ChatGoogleAdapter implements ProviderAdapter {
  final AppLogger _logger = AppLogger();
  late ChatGoogleGenerativeAI _chatModel;
  GoogleConfig? _config;
  bool _isInitialized = false;

  @override
  String get providerId => 'google';

  @override
  String get currentModel => _config?.model ?? 'gemini-1.5-flash';

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get supportsStreaming => true;

  @override
  Future<void> initialize(ProviderConfig config) async {
    try {
      if (config is! GoogleConfig) {
        throw ArgumentError('Expected GoogleConfig, got ${config.runtimeType}');
      }
      _config = config;

      final startTime = DateTime.now();
      
      _chatModel = ChatGoogleGenerativeAI(
        apiKey: config.apiKey,
        defaultOptions: ChatGoogleGenerativeAIOptions(
          model: config.model,
          temperature: 0.3, // Lower temperature for better accuracy
          topP: 0.8, // Focus on more likely tokens
          topK: 40, // Limit token diversity
          maxOutputTokens: 2048, // Reasonable limit for performance
        ),
      );

      // Optimized pre-warm with minimal overhead
      try {
        // Skip pre-warm for faster startup - let first request handle initialization
        _logger.info('Google adapter ready (lazy initialization enabled)');
      } catch (e) {
        _logger.info('Google adapter initialization note: ${e.toString()}');
      }

      _isInitialized = true;
      final initTime = DateTime.now().difference(startTime).inMilliseconds;
      _logger.info('Google adapter initialized with model: ${config.model} (${initTime}ms + pre-warm)');
    } catch (e) {
      _logger.error('Failed to initialize Google adapter', error: e);
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
      throw Exception('Google adapter not initialized');
    }

    _logger.info('Google adapter sending message with model: $currentModel');

    try {
      // Convert micro messages to LangChain ChatMessages
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final response = await _chatModel.invoke(
        prompt,
        options: ChatGoogleGenerativeAIOptions(
          model: _config!.model,
          temperature: 0.3, // Consistent with initialization
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 2048,
        ),
      );

      return _convertResponseToMicro(response.output);
    } catch (e) {
      _logger.error('Error sending message to Google', error: e);
      return _buildErrorMessage(e, 'Google');
    }
  }

  @override
  Future<bool> switchModel(String newModel) async {
    if (!_isInitialized || _config == null) return false;

    try {
      final newConfig = GoogleConfig(
        model: newModel,
        apiKey: _config!.apiKey,
      );
      await initialize(newConfig);
      return true;
    } catch (e) {
      _logger.error('Failed to switch Google model', error: e);
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    // TODO: Fetch dynamically from Google API when available
    // Current models as of November 2025 - updated to include 2.x generation
    return [
      // Latest 2.5 generation (most capable)
      'gemini-2.5-pro',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      
      // 2.0 generation (workhorse models with 1M context)
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      
      // Latest aliases (auto-update to newest versions)
      'gemini-2.5-pro-latest',
      'gemini-2.5-flash-latest',
      'gemini-flash-latest',
      
      // Legacy 1.5 generation (still supported)
      'gemini-1.5-pro',
      'gemini-1.5-flash',
      'gemini-1.5-pro-latest',
      'gemini-1.5-flash-latest',
    ];
  }

  @override
  Stream<String> sendMessageStream({
    required String text,
    required List<micro.ChatMessage> history,
  }) async* {
    if (!_isInitialized) {
      throw Exception('Google adapter not initialized');
    }

    final startTime = DateTime.now();
    _logger.info('Google adapter streaming message with model: $currentModel');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);

      // Optimized streaming with performance and accuracy settings
      final stream = _chatModel.stream(
        prompt,
        options: ChatGoogleGenerativeAIOptions(
          model: _config!.model,
          temperature: 0.3, // Better accuracy with lower temperature
          topP: 0.8, // Focus on likely responses
          topK: 40, // Controlled diversity
          maxOutputTokens: 2048, // Performance-friendly limit
        ),
      );

      await for (final chunk in stream) {
        final content = _extractContentFromChunk(chunk.output);
        if (content.isNotEmpty) {
          yield content;
        }
      }
      
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      _logger.info('Google streaming completed: ${totalTime}ms total');
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      _logger.error('Error streaming message from Google (${totalTime}ms elapsed)', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
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
  micro.ChatMessage _convertResponseToMicro(dynamic response) {
    // Handle both String content and ChatMessage objects for consistency
    String content;
    if (response is String) {
      content = response;
    } else {
      // Extract just the content from LangChain response objects
      // Check if it has a content property (like ChatMessage objects)
      try {
        if (response.runtimeType.toString().contains('ChatMessage')) {
          // For LangChain ChatMessage objects, extract the content field
          final contentField = response.content;
          if (contentField != null) {
            content = contentField.toString();
          } else {
            content = response.toString();
          }
        } else {
          // Fallback to string conversion
          content = response.toString();
        }
      } catch (e) {
        // If extraction fails, fall back to string conversion
        content = response.toString();
      }
    }
    
    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: content,
    );
  }

  /// Extract content from streaming response chunks
  String _extractContentFromChunk(dynamic chunk) {
    if (chunk is String) {
      return chunk;
    }
    
    try {
      // Check if it's a ChatMessage-like object
      if (chunk.runtimeType.toString().contains('ChatMessage')) {
        final contentField = chunk.content;
        if (contentField != null) {
          return contentField.toString();
        }
      }
      
      // Parse from string representation if it contains content
      final chunkStr = chunk.toString();
      if (chunkStr.contains('content:')) {
        final contentMatch = RegExp(r'content:\s*([^,}]+)').firstMatch(chunkStr);
        if (contentMatch != null) {
          var content = contentMatch.group(1)?.trim() ?? chunkStr;
          // Remove surrounding quotes if present
          if (content.startsWith('"') && content.endsWith('"')) {
            content = content.substring(1, content.length - 1);
          }
          return content;
        }
      }
      
      return chunkStr;
    } catch (e) {
      _logger.error('Error extracting content from chunk', error: e);
      return chunk.toString();
    }
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

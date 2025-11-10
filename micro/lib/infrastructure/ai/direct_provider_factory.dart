import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import '../interfaces/provider_config.dart';
import '../../../domain/models/chat/chat_message.dart' as micro;
import '../../../core/utils/logger.dart';

/// Direct factory for creating LangChain models without adapter layer
/// Much simpler architecture - no unnecessary abstraction
class DirectProviderFactory {
  static final AppLogger _logger = AppLogger();

  /// Create any provider model directly using LangChain
  static BaseChatModel createModel(String providerId, ProviderConfig config) {
    switch (providerId) {
      case 'zhipu-ai':
        final zhipuConfig = config as ZhipuAIConfig;
        return ChatOpenAI(
          apiKey: zhipuConfig.apiKey,
          model: zhipuConfig.model,
          baseUrl: 'https://api.z.ai/api/coding/paas/v4', // ZhipuAI is OpenAI-compatible
        );
        
      case 'google':
        final googleConfig = config as GoogleConfig;
        return ChatGoogleGenerativeAI(
          apiKey: googleConfig.apiKey,
          defaultOptions: ChatGoogleGenerativeAIOptions(
            model: googleConfig.model,
            temperature: 0.3,
            maxOutputTokens: 2048,
          ),
        );
        
      case 'openai':
        final openaiConfig = config as OpenAIConfig;
        return ChatOpenAI(
          apiKey: openaiConfig.apiKey,
          model: openaiConfig.model,
        );
        
      default:
        throw ArgumentError('Unsupported provider: $providerId');
    }
  }

  /// Send message directly using LangChain model
  static Future<micro.ChatMessage> sendMessageDirect({
    required BaseChatModel model,
    required String text,
    required List<micro.ChatMessage> history,
    required String providerId,
  }) async {
    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final response = await model.invoke(prompt);

      return _convertResponseToMicro(response.output, providerId);
    } catch (e) {
      _logger.error('Error sending message to $providerId', error: e);
      return _buildErrorMessage(e, providerId);
    }
  }

  /// Stream message directly using LangChain model
  static Stream<String> sendMessageStreamDirect({
    required BaseChatModel model,
    required String text,
    required List<micro.ChatMessage> history,
    required String providerId,
  }) async* {
    final startTime = DateTime.now();
    _logger.info('Direct streaming with $providerId');

    try {
      final messages = _convertHistoryToLangchain(history);
      messages.add(ChatMessage.humanText(text));

      final prompt = PromptValue.chat(messages);
      final stream = model.stream(prompt);

      await for (final chunk in stream) {
        final content = _extractContentFromChunk(chunk.output);
        if (content.isNotEmpty) {
          yield content;
        }
      }
      
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      _logger.info('$providerId streaming completed: ${totalTime}ms total');
    } catch (e) {
      _logger.error('Error streaming from $providerId', error: e);
      throw Exception('Streaming error: ${e.toString()}');
    }
  }

  /// Convert micro ChatMessages to LangChain ChatMessages
  static List<ChatMessage> _convertHistoryToLangchain(List<micro.ChatMessage> history) {
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

  /// Convert LangChain response to micro ChatMessage
  static micro.ChatMessage _convertResponseToMicro(dynamic response, String providerId) {
    String content;
    if (response is String) {
      content = response;
    } else if (response.runtimeType.toString().contains('ChatMessage')) {
      content = response.content?.toString() ?? response.toString();
    } else {
      content = response.toString();
    }

    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: content,
    );
  }

  /// Extract content from streaming chunks
  static String _extractContentFromChunk(dynamic chunk) {
    if (chunk is String) return chunk;
    
    try {
      if (chunk.runtimeType.toString().contains('ChatMessage')) {
        return chunk.content?.toString() ?? chunk.toString();
      }
      
      final chunkStr = chunk.toString();
      if (chunkStr.contains('content:')) {
        final contentMatch = RegExp(r'content:\s*([^,}]+)').firstMatch(chunkStr);
        if (contentMatch != null) {
          var content = contentMatch.group(1)?.trim() ?? chunkStr;
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

  /// Build user-friendly error message
  static micro.ChatMessage _buildErrorMessage(Object error, String provider) {
    String errorMessage;
    if (error.toString().contains('RateLimitException') || error.toString().contains('429')) {
      errorMessage = 'I\'ve reached my usage limit. Please try again later.';
    } else if (error.toString().contains('401') || error.toString().contains('authentication')) {
      errorMessage = 'Authentication failed. Please check your $provider API key.';
    } else {
      errorMessage = 'Sorry, I encountered an error. Please try again.';
    }

    return micro.ChatMessage.assistant(
      id: DateTime.now().toIso8601String(),
      content: errorMessage,
    );
  }
}
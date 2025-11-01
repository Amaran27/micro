import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';

/// Simple LangChain-compatible chat model for ZhipuAI
/// Provides a unified interface for LangChain integration without requiring
/// full BaseChatModel inheritance which has many abstract methods
class ChatZhipuAI {
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio();
  final String _apiKey;
  final String _model;
  final ChatZhipuAIOptions _defaultOptions;

  static const String _baseUrl = 'https://api.z.ai/api/paas/v4';

  ChatZhipuAI({
    required String apiKey,
    required String model,
    ChatZhipuAIOptions? defaultOptions,
  })  : _apiKey = apiKey,
        _model = model,
        _defaultOptions = defaultOptions ?? const ChatZhipuAIOptions();

  /// Invoke the model with messages
  Future<ChatZhipuAIResult> invoke(dynamic prompt, {dynamic options}) async {
    try {
      _logger.info(
        'ChatZhipuAI: Invoking model: $_model',
      );

      // Extract messages from prompt if it's a PromptValue
      final messages = _extractMessagesFromPrompt(prompt);

      // Convert LangChain messages to ZhipuAI API format
      final zhipuaiMessages = _convertMessagesToZhipuAIFormat(messages);

      // Build request
      final requestData = {
        'model': _model,
        'max_tokens': _defaultOptions.maxTokens ?? 1000,
        'temperature': _defaultOptions.temperature ?? 0.7,
        'messages': zhipuaiMessages,
      };

      // Make API call
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'Accept-Language': 'en-US,en',
          },
        ),
      );

      _logger.info('ZhipuAI API response status: ${response.statusCode}');
      _logger.info('ZhipuAI API response body: ${response.data}');

      if (response.statusCode == 200) {
        final choices = response.data['choices'];
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'] ?? '';
          _logger.info('ZhipuAI extracted content: length=${content.length}');
          return ChatZhipuAIResult(output: content);
        }
        throw Exception('No choices in ZhipuAI API response');
      }

      throw Exception(
        'ZhipuAI API error: ${response.statusCode} - ${response.statusMessage}',
      );
    } catch (e) {
      _logger.error('Error in ChatZhipuAI.invoke', error: e);

      // Log detailed error information and propagate rich context upstream
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final message = e.message;

        _logger.error('Dio Exception Details - Status Code: $status');
        _logger.error('Dio Exception Response Body: $data');
        _logger.error('Dio Exception Message: $message');

        // Rethrow with response body included so callers can map business codes
        throw Exception(
          'DioException status=$status message=$message body=$data',
        );
      }

      rethrow;
    }
  }

  /// Extract messages from PromptValue or list
  List<dynamic> _extractMessagesFromPrompt(dynamic prompt) {
    if (prompt == null) return [];

    // If it's a PromptValue with chat method
    if (prompt.runtimeType.toString().contains('PromptValue')) {
      try {
        return prompt.messages ?? [];
      } catch (e) {
        _logger.warning('Could not extract messages from PromptValue');
        return [];
      }
    }

    // If it's a list
    if (prompt is List) {
      return prompt;
    }

    return [];
  }

  /// Convert LangChain ChatMessages to ZhipuAI API format
  List<Map<String, String>> _convertMessagesToZhipuAIFormat(
    List<dynamic> messages,
  ) {
    final zhipuaiMessages = <Map<String, String>>[];

    for (final message in messages) {
      String role;
      String content;

      // Handle different message types
      try {
        // Try LangChain message types
        final typeName = message.runtimeType.toString();

        if (typeName.contains('HumanChatMessage')) {
          role = 'user';
        } else if (typeName.contains('AIChatMessage')) {
          role = 'assistant';
        } else if (typeName.contains('SystemChatMessage')) {
          role = 'system';
        } else {
          role = 'user';
        }

        // Extract content
        if (message is Map<String, dynamic>) {
          content = message['content'] ?? '';
        } else if (message.toString().contains('content')) {
          // Try to get content property
          try {
            content = message.content ?? '';
          } catch (_) {
            content = message.toString();
          }
        } else {
          content = message.toString();
        }
      } catch (e) {
        _logger.warning('Error converting message: $e');
        continue;
      }

      if (content.isNotEmpty) {
        zhipuaiMessages.add({
          'role': role,
          'content': content,
        });
      }
    }

    return zhipuaiMessages;
  }

  void close() {
    _dio.close();
  }
}

/// Result from ChatZhipuAI invoke
class ChatZhipuAIResult {
  final String output;

  ChatZhipuAIResult({required this.output});
}

/// Options for ChatZhipuAI
class ChatZhipuAIOptions {
  /// Maximum number of tokens to generate
  final int? maxTokens;
  final double? temperature;

  const ChatZhipuAIOptions({
    this.maxTokens,
    this.temperature,
  });
}

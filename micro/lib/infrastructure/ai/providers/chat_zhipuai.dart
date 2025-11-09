import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:langchain_core/chat_models.dart';

import '../../../core/utils/logger.dart';

/// Simple LangChain-compatible chat model for ZhipuAI
/// Provides a unified interface for LangChain integration without requiring
/// full BaseChatModel inheritance which has many abstract methods
class ChatZhipuAI {
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      // Increase receive timeout – GLM responses can exceed 30s without true streaming
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );
  final String _apiKey;
  final String _model;
  final ChatZhipuAIOptions _defaultOptions;

  // Use general chat endpoint (chat-optimized). Coding endpoint can be slower and is not required here.
  static const String _baseUrl = 'https://api.z.ai/api/paas/v4';

  ChatZhipuAI({
    required String apiKey,
    required String model,
    ChatZhipuAIOptions? defaultOptions,
  })  : _apiKey = apiKey,
        _model = model,
        _defaultOptions = defaultOptions ?? const ChatZhipuAIOptions();

  /// Stream tokens from the model in real-time
  Stream<String> stream(
    List<ChatMessage> messages, {
    ChatZhipuAIOptions? options,
  }) async* {
    final model = options?.model ?? _model;

    // Convert LangChain messages to ZhipuAI API format
    final zhipuMessages = messages.map((m) {
      final String role;
      final content = m.contentAsString;

      if (m is HumanChatMessage) {
        role = 'user';
      } else if (m is AIChatMessage) {
        role = 'assistant';
      } else if (m is SystemChatMessage) {
        role = 'system';
      } else {
        // Fallback for custom or other message types
        role = 'user';
      }
      return {'role': role, 'content': content};
    }).toList();

    final streamingOptions = {
      'model': model,
      'messages': zhipuMessages,
      'stream': true,
      'temperature': options?.temperature ?? _defaultOptions.temperature,
      'top_p': options?.topP ?? _defaultOptions.topP,
    }..removeWhere((_, v) => v == null);

    _logger.info('ChatZhipuAI: Streaming model: $model');

    try {
      final response = await _dio.post<ResponseBody>(
        '$_baseUrl/chat/completions',
        data: streamingOptions,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data?.stream;

      if (stream == null) {
        throw Exception('No stream in response');
      }

      await for (final event in stream
          .map((bytes) => utf8.decode(bytes))
          .transform(const LineSplitter())) {
        if (event.startsWith('data:')) {
          final data = event.substring(5).trim();
          if (data.isEmpty || data == '[DONE]') {
            continue;
          }
          try {
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            final content = decoded['choices']
                ?.map((c) => c['delta']?['content'])
                .whereType<String>()
                .join('');
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (e) {
            _logger.warning('SSE JSON decode failed: $e. Data: "$data"');
          }
        }
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

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

      _logger.info('ChatZhipuAI: Request Data = $requestData');

      final jsonData = json.encode(requestData);
      _logger.info('ChatZhipuAI: JSON Data length = ${jsonData.length}');
      _logger.info('ChatZhipuAI: JSON Data = $jsonData');

      // Make API call - use json.encode like the working direct test
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'Accept-Language': 'en-US,en',
          },
          validateStatus: (_) =>
              true, // Don't throw on any status, we'll check ourselves
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
        _handleDioException(e);
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

        // Extract content from LangChain ChatMessage objects
        if (message is Map<String, dynamic>) {
          content = message['content'] ?? '';
        } else {
          // Try to access content property directly (LangChain ChatMessage)
          try {
            final dynamic rawContent = message.content;
            // Handle ChatMessageContentText wrapper
            if (rawContent != null) {
              if (rawContent is String) {
                content = rawContent;
              } else if (rawContent.toString().contains('text:')) {
                // Extract text from ChatMessageContentText object
                try {
                  content = rawContent.text ?? rawContent.toString();
                } catch (_) {
                  // Fallback: parse from toString()
                  final str = rawContent.toString();
                  final textMatch =
                      RegExp(r'text:\s*(.+?)[,}]').firstMatch(str);
                  content = textMatch?.group(1)?.trim() ?? str;
                }
              } else {
                content = rawContent.toString();
              }
            } else {
              content = message.toString();
            }
          } catch (_) {
            content = message.toString();
          }
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

  void _handleDioException(DioException e) {
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
  final String? model;

  /// Maximum number of tokens to generate
  final int? maxTokens;
  final double? temperature;
  final double? topP;

  const ChatZhipuAIOptions({
    this.model,
    this.maxTokens,
    this.temperature,
    this.topP,
  });
}

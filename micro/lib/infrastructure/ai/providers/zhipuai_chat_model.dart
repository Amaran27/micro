import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:langchain/langchain.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/logger.dart';

/// ZhipuAI Chat Model extending LangChain's BaseChatModel
/// Implements JWT authentication and API communication for Zhipu AI (ChatGLM)
class ZhipuAIChatModel extends BaseChatModel {
  final String apiKey;
  final String model;
  final AppLogger _logger;

  late http.Client _client;

  ZhipuAIChatModel({
    required this.apiKey,
    required this.model,
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger() {
    _client = http.Client();
  }

  @override
  String get modelType => 'zhipuai';

  /// Validate ZhipuAI API key format
  bool _isValidApiKey(String key) {
    return key.length >= 49 && key.contains('.');
  }

  /// Generate JWT token for Zhipu AI authentication
  String _generateToken() {
    if (!_isValidApiKey(apiKey)) {
      throw Exception(
        'ZhipuAI API key format is invalid. Keys should be 49+ characters with a dot separator.',
      );
    }

    // Parse the API key to extract ID and secret
    final parts = apiKey.split('.');
    if (parts.length < 2) {
      throw Exception('Invalid ZhipuAI API key format');
    }

    final apiId = parts[0];
    final apiSecret = parts[1];

    // Create JWT header and payload
    final header = base64Url
        .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'sign_type': 'SIGN'})))
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + 3600; // Token valid for 1 hour
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'api_key': apiId,
          'exp': exp,
          'timestamp': now,
        })))
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    // Create signature
    final message = '$header.$payload';
    final signature = base64Url
        .encode(Hmac(sha256, utf8.encode(apiSecret))
            .convert(utf8.encode(message))
            .bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    return '$message.$signature';
  }

  @override
  Future<ChatResult> invoke(
    PromptValue input, {
    ChatModelOptions? options,
  }) async {
    try {
      final token = _generateToken();
      final messages = input.toChatMessages();

      // Convert LangChain messages to Zhipu AI format
      final zhipuMessages = messages.map((msg) {
        if (msg is HumanChatMessage) {
          return {'role': 'user', 'content': msg.content};
        } else if (msg is AIChatMessage) {
          return {'role': 'assistant', 'content': msg.content};
        } else {
          return {'role': 'system', 'content': msg.content};
        }
      }).toList();

      final response = await _client.post(
        Uri.parse('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': zhipuMessages,
          'temperature': 0.7,
          'top_p': 0.95,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices']?[0]?['message']?['content'] ?? 'No response';
        final aiMessage = AIChatMessage(content: content);
        return ChatResult(output: aiMessage);
      } else {
        throw Exception(
          'ZhipuAI API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _logger.error('Error invoking ZhipuAI model', error: e);
      rethrow;
    }
  }

  @override
  Stream<ChatResultChunk> stream(
    PromptValue input, {
    ChatModelOptions? options,
  }) async* {
    try {
      final token = _generateToken();
      final messages = input.toChatMessages();

      // Convert LangChain messages to Zhipu AI format
      final zhipuMessages = messages.map((msg) {
        if (msg is HumanChatMessage) {
          return {'role': 'user', 'content': msg.content};
        } else if (msg is AIChatMessage) {
          return {'role': 'assistant', 'content': msg.content};
        } else {
          return {'role': 'system', 'content': msg.content};
        }
      }).toList();

      final request = http.Request(
        'POST',
        Uri.parse('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      request.body = jsonEncode({
        'model': model,
        'messages': zhipuMessages,
        'stream': true,
        'temperature': 0.7,
        'top_p': 0.95,
      });

      final response = await _client.send(request);

      if (response.statusCode == 200) {
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .where((line) => line.isNotEmpty && line.startsWith('data:'))) {
          final jsonStr = line.replaceFirst('data:', '').trim();
          if (jsonStr == '[DONE]') break;

          try {
            final data = jsonDecode(jsonStr);
            final content = data['choices']?[0]?['delta']?['content'] ?? '';
            if (content.isNotEmpty) {
              yield ChatResultChunk(
                output: AIChatMessage(content: content),
              );
            }
          } catch (e) {
            // Skip malformed JSON lines
            continue;
          }
        }
      } else {
        throw Exception(
          'ZhipuAI API stream error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Error streaming from ZhipuAI model', error: e);
      rethrow;
    }
  }

  @override
  void close() {
    _client.close();
  }
}

class ZhipuAIAuthenticationException implements Exception {
  final String message;
  ZhipuAIAuthenticationException(this.message);

  @override
  String toString() => message;
}

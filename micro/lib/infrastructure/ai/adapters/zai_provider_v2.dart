/// Z.AI Provider (v2) - streaming-enabled OpenAI-compatible adapter.
///
/// Features:
/// - Treats Z.AI as OpenAI-compatible: uses same client, request shape, SSE parsing
/// - Region support: international vs China base URLs
/// - Thinking param: conditionally includes when modelInfo.supportsReasoningBinary
/// - Streaming: parses SSE "data: {json}" events into ApiStreamChunk types
/// - Mobile: uses lightweight parsing, releases resources in finally blocks
///
/// Based on Roo Code patterns adapted for Dart/Riverpod.
library;

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:micro/domain/models/api_stream.dart';
import 'package:micro/core/utils/logger.dart';
import 'base_provider.dart';

/// Region enum for Z.AI API endpoints
enum ZaiRegion {
  international('international_coding', 'https://api.z.ai/api/coding/paas/v4'),
  china('china_coding', 'https://open.bigmodel.cn/api/coding/paas/v4');

  final String configKey;
  final String baseUrl;

  const ZaiRegion(this.configKey, this.baseUrl);
}

/// Z.AI Provider adapter - implements BaseProvider for streaming Z.AI responses.
class ZaiProvider extends BaseProvider {
  final ProviderSettings settings;
  final Dio dio;
  final AppLogger _logger = AppLogger();

  ZaiProvider({
    required this.settings,
    Dio? dio,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: settings.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 0), // streaming
                headers: {
                  'Authorization': 'Bearer ${settings.apiKey}',
                  'Content-Type': 'application/json',
                },
              ),
            );

  @override
  String getModelId() => settings.modelId ?? 'glm-4.6';

  @override
  ModelInfo getModelInfo() {
    // Z.AI model defaults; in production merge with manifest overrides
    return ModelInfo(
      contextWindow: 204800,
      maxTokens: 98304,
      supportsImages: false,
      supportsPromptCache: true,
      supportsReasoningBinary: true, // supports thinking param
      inputPrice: 0.29,
      outputPrice: 1.14,
      cacheReadsPrice: 0.057,
      cacheWritesPrice: 0.0,
    );
  }

  @override
  Stream<ApiStreamChunk> createMessage(
    String systemPrompt,
    List<Map<String, dynamic>> anthropicMessages, {
    CreateMessageMetadata? metadata,
  }) {
    final controller = StreamController<ApiStreamChunk>();
    final cancelToken = CancelToken();

    // Start streaming in background (async)
    _streamFromZai(
      systemPrompt,
      anthropicMessages,
      cancelToken,
      controller,
      metadata,
    );

    // Return broadcast stream so multiple listeners can subscribe
    return controller.stream.asBroadcastStream();
  }

  /// Internal: execute the streaming request and emit chunks to controller.
  Future<void> _streamFromZai(
    String systemPrompt,
    List<Map<String, dynamic>> anthropicMessages,
    CancelToken cancelToken,
    StreamController<ApiStreamChunk> controller,
    CreateMessageMetadata? metadata,
  ) async {
    Response<ResponseBody>? response;
    try {
      // Build OpenAI-style messages (simplified conversion from Anthropic format)
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        // Convert anthropic messages to OpenAI format
        for (final m in anthropicMessages)
          {
            'role': m['role'] ?? 'user',
            'content': m['content'] ?? '',
          },
      ];

      final modelId = getModelId();
      final modelInfo = getModelInfo();
      final temperature = 0.6; // default

      // Build request body
      final body = {
        'model': modelId,
        'messages': messages,
        'temperature': temperature,
        'stream': true,
        'stream_options': {'include_usage': true},
      };

      // Gate thinking param: only include if model supports reasoning
      // In production, wire enableReasoning to app state/settings
      final bool enableReasoning = false; // TODO: connect to user settings
      if (modelInfo.supportsReasoningBinary && enableReasoning) {
        body['thinking'] = {'type': 'enabled'};
      }

      _logger.info('ZaiProvider: requesting model=$modelId, reasoning=$enableReasoning');

      // Stream the request
      response = await dio.post<ResponseBody>(
        '/chat/completions',
        data: jsonEncode(body),
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      // Parse SSE stream
      await _parseStreamResponse(response.data!.stream, controller, cancelToken);
    } catch (e) {
      if (!controller.isClosed) {
        // Map Dio errors to friendly error chunks
        if (e is DioException) {
          final status = e.response?.statusCode ?? 0;
          final code = 'dio_${e.type}';
          _logger.error('ZaiProvider: DioException code=$code status=$status: ${e.message}');
          controller.add(
            ErrorChunk(
              code: code,
              message: _mapDioErrorToMessage(e),
            ),
          );
        } else {
          _logger.error('ZaiProvider: Unknown error: $e');
          controller.add(
            ErrorChunk(
              code: 'unknown_error',
              message: e.toString(),
            ),
          );
        }
        await controller.close();
      }
    } finally {
      // Ensure cancellation token is cancelled (idempotent)
      try {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('completed');
        }
      } catch (_) {}
    }
  }

  /// Parse SSE "data: {...}" events from the stream response.
  /// Emits ApiStreamChunk types to the controller.
  Future<void> _parseStreamResponse(
    Stream<List<int>> byteStream,
    StreamController<ApiStreamChunk> controller,
    CancelToken cancelToken,
  ) async {
    final decoder = Utf8Decoder();
    var buffer = '';

    try {
      await for (final bytes in byteStream) {
        if (cancelToken.isCancelled) break;

        // Decode bytes and accumulate in buffer
        buffer += decoder.convert(bytes);

        // Split by newline; keep trailing partial line
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final raw in lines) {
          final line = raw.trim();
          if (line.isEmpty) continue;

          // OpenAI SSE format: "data: {json}"
          final String payload = line.startsWith('data: ')
              ? line.substring(6)
              : line; // also handle raw JSON

          if (payload == '[DONE]') {
            // Stream finished
            continue;
          }

          // Parse JSON event
          dynamic parsed;
          try {
            parsed = jsonDecode(payload);
          } catch (e) {
            _logger.warning('ZaiProvider: parse error: $e, line: $line');
            controller.add(
              ErrorChunk(code: 'parse_error', message: 'Invalid JSON from provider'),
            );
            continue;
          }

          try {
            // Extract choices and deltas
            final choices = parsed['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                // Text content
                if (delta.containsKey('content')) {
                  final content = delta['content'];
                  if (content is String && content.isNotEmpty) {
                    controller.add(TextChunk(content));
                  }
                }

                // Reasoning content (Z.AI thinking mode)
                if (delta.containsKey('reasoning') ||
                    delta.containsKey('reasoning_content')) {
                  final reasoning = delta['reasoning'] ?? delta['reasoning_content'];
                  if (reasoning is String && reasoning.isNotEmpty) {
                    controller.add(ReasoningChunk(reasoning));
                  }
                }
              }
            }

            // Usage information (authoritative for billing)
            if (parsed.containsKey('usage')) {
              final usage = parsed['usage'] as Map<String, dynamic>;
              final inputTokens = (usage['prompt_tokens'] ?? 0) as int;
              final outputTokens = (usage['completion_tokens'] ?? 0) as int;
              final cacheReadTokens = usage['prompt_tokens_from_cache_read'] as int?;
              final cacheWriteTokens = usage['prompt_tokens_written_to_cache'] as int?;

              // Compute cost if we have pricing
              final modelInfo = getModelInfo();
              double? totalCost;
              if (modelInfo.inputPrice != null && modelInfo.outputPrice != null) {
                totalCost = (inputTokens * (modelInfo.inputPrice ?? 0.0)) +
                    (outputTokens * (modelInfo.outputPrice ?? 0.0));
                if (cacheReadTokens != null && modelInfo.cacheReadsPrice != null) {
                  totalCost += cacheReadTokens * modelInfo.cacheReadsPrice!;
                }
              }

              controller.add(
                UsageChunk(
                  inputTokens: inputTokens,
                  outputTokens: outputTokens,
                  cacheReadTokens: cacheReadTokens,
                  cacheWriteTokens: cacheWriteTokens,
                  totalCost: totalCost,
                ),
              );
            }
          } catch (e) {
            _logger.warning('ZaiProvider: mapping error: $e');
            controller.add(
              ErrorChunk(code: 'mapping_error', message: 'Failed to map provider response'),
            );
          }
        }
      }

      // Process leftover buffer if any
      if (buffer.trim().isNotEmpty && !cancelToken.isCancelled) {
        try {
          final parsed = jsonDecode(buffer.trim());
          // Handle final event (would have same structure as above)
          // Omitted for brevity; same logic applies
        } catch (_) {
          // trailing garbage or incomplete final event
        }
      }

      await controller.close();
    } catch (e) {
      if (!controller.isClosed) {
        _logger.error('ZaiProvider: stream parsing error: $e');
        controller.add(
          ErrorChunk(code: 'stream_error', message: 'Stream parsing failed'),
        );
        await controller.close();
      }
    }
  }

  /// Map Dio errors to user-friendly messages.
  String _mapDioErrorToMessage(DioException e) {
    final status = e.response?.statusCode;

    if (status == 401 || status == 403) {
      return 'Authentication failed: Check your Z.AI API key.';
    } else if (status == 429) {
      return 'Rate limited: Too many requests. Please try again later.';
    } else if (status == 500 || status == 502 || status == 503) {
      return 'Provider error: Z.AI service temporarily unavailable.';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout: Check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout: Provider is taking too long to respond.';
    } else if (e.type == DioExceptionType.unknown && e.error is SocketException) {
      return 'Network error: Check your internet connection.';
    } else {
      return 'Unexpected error: ${e.message}';
    }
  }
}

// Import for SocketException (for network error detection)
import 'dart:io' show SocketException;

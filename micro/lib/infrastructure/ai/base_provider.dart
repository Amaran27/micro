/// BaseProvider abstraction - contract for all AI provider integrations.
///
/// Key principles:
/// - Single createMessage() contract -> Stream<ApiStreamChunk> for all providers.
/// - ModelInfo carries provider capabilities (pricing, feature flags) for gating params.
/// - Mobile-first: estimateTokens is lightweight fallback; prefer provider-reported usage.
///
/// Handlers extend BaseProvider and implement createMessage by:
/// 1. Building provider-specific request (with conditional thinking/reasoning params).
/// 2. Streaming raw provider events.
/// 3. Parsing provider event shapes and normalizing to ApiStreamChunk types.
/// 4. Yielding chunks so consumers can process a uniform stream.
library;

import 'dart:async';
import '../models/api_stream.dart';

/// Model capability metadata - gates provider-specific params and pricing.
/// This is the contract between provider handlers and the UI/task layer.
class ModelInfo {
  /// Model context window (tokens)
  final int contextWindow;

  /// Max tokens the model can generate
  final int maxTokens;

  /// True if model supports image inputs
  final bool supportsImages;

  /// True if model supports prompt caching
  final bool supportsPromptCache;

  /// True if model supports reasoning/thinking mode (O1-style or Z.AI thinking)
  final bool supportsReasoningBinary;

  /// Input token price (per 1M tokens or per token, depends on provider)
  /// Used to compute cost from UsageChunk
  final double? inputPrice;

  /// Output token price
  final double? outputPrice;

  /// Cache read price (if supportsPromptCache)
  final double? cacheReadsPrice;

  /// Cache write price (if supportsPromptCache)
  final double? cacheWritesPrice;

  ModelInfo({
    required this.contextWindow,
    required this.maxTokens,
    required this.supportsImages,
    required this.supportsPromptCache,
    required this.supportsReasoningBinary,
    this.inputPrice,
    this.outputPrice,
    this.cacheReadsPrice,
    this.cacheWritesPrice,
  });

  /// Immutable copy with optional overrides
  ModelInfo copyWith({
    int? contextWindow,
    int? maxTokens,
    bool? supportsImages,
    bool? supportsPromptCache,
    bool? supportsReasoningBinary,
    double? inputPrice,
    double? outputPrice,
    double? cacheReadsPrice,
    double? cacheWritesPrice,
  }) =>
      ModelInfo(
        contextWindow: contextWindow ?? this.contextWindow,
        maxTokens: maxTokens ?? this.maxTokens,
        supportsImages: supportsImages ?? this.supportsImages,
        supportsPromptCache: supportsPromptCache ?? this.supportsPromptCache,
        supportsReasoningBinary:
            supportsReasoningBinary ?? this.supportsReasoningBinary,
        inputPrice: inputPrice ?? this.inputPrice,
        outputPrice: outputPrice ?? this.outputPrice,
        cacheReadsPrice: cacheReadsPrice ?? this.cacheReadsPrice,
        cacheWritesPrice: cacheWritesPrice ?? this.cacheWritesPrice,
      );
}

/// Provider configuration per user profile.
/// Stores credentials, base URL, model selection, and provider-specific options.
class ProviderSettings {
  /// Provider name (e.g., 'zhipu-ai', 'openai', 'google', 'anthropic')
  final String providerName;

  /// API base URL (can be overridden for local/proxy endpoints)
  final String baseUrl;

  /// API key (stored in FlutterSecureStorage, passed here only when needed)
  final String apiKey;

  /// Currently selected model ID
  final String? modelId;

  /// Provider-specific region or configuration (e.g., 'international' or 'china' for Z.AI)
  final String? region;

  ProviderSettings({
    required this.providerName,
    required this.baseUrl,
    required this.apiKey,
    this.modelId,
    this.region,
  });
}

/// Optional metadata passed to createMessage.
/// Allows handlers to log/trace request context.
class CreateMessageMetadata {
  /// Task or conversation ID for tracing
  final String? taskId;

  CreateMessageMetadata({this.taskId});
}

/// BaseProvider - abstract contract for all AI provider integrations.
///
/// Implementations (ZaiProvider, OpenAiProvider, AnthropicProvider, etc.)
/// override createMessage to stream provider-specific events as ApiStreamChunk.
abstract class BaseProvider {
  /// Create a message stream.
  ///
  /// Args:
  ///   - systemPrompt: system message for the provider
  ///   - anthropicMessages: messages in Anthropic-style format (converted from UI)
  ///   - metadata: optional tracing/context
  ///
  /// Returns: broadcast Stream<ApiStreamChunk> that:
  ///   - Emits TextChunk, ReasoningChunk, UsageChunk as provider streams.
  ///   - Emits ErrorChunk if provider returns an error (stream may continue).
  ///   - Completes when provider response finishes.
  ///
  /// Mobile note: Stream is broadcast so multiple consumers can listen.
  /// Cancellation is controlled via CancelToken passed in activeRequestNotifier.
  Stream<ApiStreamChunk> createMessage(
    String systemPrompt,
    List<Map<String, dynamic>> anthropicMessages, {
    CreateMessageMetadata? metadata,
  });

  /// Current model ID for this provider instance
  String getModelId();

  /// Model capability info - used to gate features and compute costs
  ModelInfo getModelInfo();

  /// Lightweight client-side token estimator (fallback if provider doesn't report usage).
  ///
  /// Mobile: this is intentionally cheap (char-based approximation).
  /// Avoid heavy tiktoken on UI thread; use provider-reported usage when available.
  /// Advanced users can opt-in to tiktoken via a remote service (Phase 4E).
  Future<int> estimateTokens(String text) async {
    if (text.isEmpty) return 0;
    // Very conservative heuristic: ~4 chars per token (typical for English)
    final approx = (text.length / 4).ceil();
    return approx;
  }
}

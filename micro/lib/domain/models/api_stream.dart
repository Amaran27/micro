/// API Streaming chunk types - normalized across all providers.
/// Mobile-first: keep objects immutable and small.
///
/// This layer decouples UI/Task logic from provider-specific event shapes.
/// Handlers parse raw provider events and yield these canonical chunk types.
library;

abstract class ApiStreamChunk {}

/// Text content chunk from provider response.
class TextChunk extends ApiStreamChunk {
  final String text;
  TextChunk(this.text);
}

/// Token usage and cost metadata from provider.
/// Provider-reported usage is authoritative for billing.
class UsageChunk extends ApiStreamChunk {
  final int inputTokens;
  final int outputTokens;
  final int? cacheReadTokens;
  final int? cacheWriteTokens;
  final double? totalCost;

  UsageChunk({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheReadTokens,
    this.cacheWriteTokens,
    this.totalCost,
  });
}

/// Reasoning/thinking tokens from models that support reasoning.
/// Used by models with o1-style reasoning or Z.AI thinking mode.
class ReasoningChunk extends ApiStreamChunk {
  final String text;
  ReasoningChunk(this.text);
}

/// Grounding/retrieval sources from providers that support grounding.
/// Each source is {title, url, snippet?}
class GroundingChunk extends ApiStreamChunk {
  final List<Map<String, String>> sources;
  GroundingChunk(this.sources);
}

/// Error chunk: stream continues but includes error metadata.
/// Allows partial content + error to be surfaced to UI together.
class ErrorChunk extends ApiStreamChunk {
  final String code;
  final String message;

  ErrorChunk({required this.code, required this.message});
}

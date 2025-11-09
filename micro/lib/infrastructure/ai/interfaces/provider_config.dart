/// Base configuration for any AI provider
/// Provides type-safety over generic Map<String, dynamic>
abstract class ProviderConfig {
  /// Provider identifier
  String get providerId;

  /// Selected model to use
  String get model;

  /// API key or token for authentication
  String get apiKey;

  /// Convert to map for storage/serialization if needed
  Map<String, dynamic> toMap();
}

/// ZhiPu AI specific configuration
class ZhipuAIConfig implements ProviderConfig {
  @override
  final String providerId = 'zhipu-ai';

  @override
  final String model;

  @override
  final String apiKey;

  /// Whether to use the coding-optimized endpoint instead of general endpoint
  final bool useCodingEndpoint;

  ZhipuAIConfig({
    required this.model,
    required this.apiKey,
    this.useCodingEndpoint = true, // Default to coding endpoint
  }) {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    if (model.isEmpty) {
      throw ArgumentError('Model cannot be empty');
    }
  }

  @override
  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'model': model,
        'apiKey': apiKey,
        'useCodingEndpoint': useCodingEndpoint,
      };

  factory ZhipuAIConfig.fromMap(Map<String, dynamic> map) => ZhipuAIConfig(
        model: map['model'] as String,
        apiKey: map['apiKey'] as String,
        useCodingEndpoint: map['useCodingEndpoint'] as bool? ?? true,
      );
}

/// Google Gemini specific configuration
class GoogleConfig implements ProviderConfig {
  @override
  final String providerId = 'google';

  @override
  final String model;

  @override
  final String apiKey;

  GoogleConfig({
    required this.model,
    required this.apiKey,
  }) {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    if (model.isEmpty) {
      throw ArgumentError('Model cannot be empty');
    }
  }

  @override
  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'model': model,
        'apiKey': apiKey,
      };

  factory GoogleConfig.fromMap(Map<String, dynamic> map) => GoogleConfig(
        model: map['model'] as String,
        apiKey: map['apiKey'] as String,
      );
}

/// OpenAI specific configuration
class OpenAIConfig implements ProviderConfig {
  @override
  final String providerId = 'openai';

  @override
  final String model;

  @override
  final String apiKey;

  final String? organizationId;

  OpenAIConfig({
    required this.model,
    required this.apiKey,
    this.organizationId,
  }) {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    if (model.isEmpty) {
      throw ArgumentError('Model cannot be empty');
    }
  }

  @override
  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'model': model,
        'apiKey': apiKey,
        if (organizationId != null) 'organizationId': organizationId,
      };

  factory OpenAIConfig.fromMap(Map<String, dynamic> map) => OpenAIConfig(
        model: map['model'] as String,
        apiKey: map['apiKey'] as String,
        organizationId: map['organizationId'] as String?,
      );
}

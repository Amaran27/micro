import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Provider for dynamically fetching models from AI providers
class DynamicModelFetcher {
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  /// Get models dynamically from provider APIs
  Future<List<String>> fetchModelsForProvider(String providerId) async {
    try {
      switch (providerId.toLowerCase()) {
        case 'openai':
          return await _fetchOpenAIModels();
        case 'google':
          return await _fetchGoogleModels();
        case 'claude':
          return await _fetchClaudeModels();
        case 'azure-openai':
          return await _fetchAzureOpenAIModels();
        case 'cohere':
          return await _fetchCohereModels();
        case 'mistral-ai':
          return await _fetchMistralModels();
        default:
          return _getFallbackModels(providerId);
      }
    } catch (e) {
      _logger.e('Error fetching models for $providerId: $e');
      return _getFallbackModels(providerId);
    }
  }

  /// Fetch OpenAI models
  Future<List<String>> _fetchOpenAIModels() async {
    final apiKey = await _secureStorage.read(key: 'openai_api_key');
    if (apiKey == null) return _getFallbackModels('openai');

    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final models = List<String>.from(
          response.data['data']
              .where((model) => model['id'].toString().startsWith('gpt-'))
              .map((model) => model['id'].toString()),
        );
        return models.isEmpty ? _getFallbackModels('openai') : models;
      }
    } catch (e) {
      _logger.e('OpenAI API error: $e');
    }

    return _getFallbackModels('openai');
  }

  /// Fetch Google AI models
  Future<List<String>> _fetchGoogleModels() async {
    final apiKey = await _secureStorage.read(key: 'google_api_key');
    if (apiKey == null) return _getFallbackModels('google');

    try {
      // Google models are typically predefined, but we can validate API access
      await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey',
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'test'}
              ]
            }
          ]
        },
      );

      // If API works, return known models
      return ['gemini-pro', 'gemini-pro-vision'];
    } catch (e) {
      _logger.e('Google AI API error: $e');
    }

    return _getFallbackModels('google');
  }

  /// Fetch Claude models
  Future<List<String>> _fetchClaudeModels() async {
    final apiKey = await _secureStorage.read(key: 'claude_api_key');
    if (apiKey == null) return _getFallbackModels('claude');

    try {
      final response = await _dio.get(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        ),
      );

      if (response.statusCode == 200) {
        return [
          'claude-3-opus-20240229',
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307'
        ];
      }
    } catch (e) {
      _logger.e('Claude API error: $e');
    }

    return _getFallbackModels('claude');
  }

  /// Fetch Azure OpenAI models
  Future<List<String>> _fetchAzureOpenAIModels() async {
    final apiKey = await _secureStorage.read(key: 'azure_openai_api_key');
    final endpoint = await _secureStorage.read(key: 'azure_openai_endpoint');
    if (apiKey == null || endpoint == null) {
      return _getFallbackModels('azure-openai');
    }

    try {
      final response = await _dio.get(
        '$endpoint/openai/deployments?api-version=2023-12-01-preview',
        options: Options(
          headers: {'api-key': apiKey},
        ),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final models = List<String>.from(
          response.data['data']
              .map((deployment) => deployment['model'].toString()),
        );
        return models.isEmpty ? _getFallbackModels('azure-openai') : models;
      }
    } catch (e) {
      _logger.e('Azure OpenAI API error: $e');
    }

    return _getFallbackModels('azure-openai');
  }

  /// Fetch Cohere models
  Future<List<String>> _fetchCohereModels() async {
    final apiKey = await _secureStorage.read(key: 'cohere_api_key');
    if (apiKey == null) return _getFallbackModels('cohere');

    try {
      final response = await _dio.get(
        'https://api.cohere.ai/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );

      if (response.statusCode == 200 && response.data['models'] != null) {
        final models = List<String>.from(
          response.data['models'].map((model) => model['name'].toString()),
        );
        return models.isEmpty ? _getFallbackModels('cohere') : models;
      }
    } catch (e) {
      _logger.e('Cohere API error: $e');
    }

    return _getFallbackModels('cohere');
  }

  /// Fetch Mistral AI models
  Future<List<String>> _fetchMistralModels() async {
    final apiKey = await _secureStorage.read(key: 'mistral_ai_api_key');
    if (apiKey == null) return _getFallbackModels('mistral-ai');

    try {
      final response = await _dio.get(
        'https://api.mistral.ai/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final models = List<String>.from(
          response.data['data'].map((model) => model['id'].toString()),
        );
        return models.isEmpty ? _getFallbackModels('mistral-ai') : models;
      }
    } catch (e) {
      _logger.e('Mistral AI API error: $e');
    }

    return _getFallbackModels('mistral-ai');
  }

  /// Get fallback models when API calls fail
  List<String> _getFallbackModels(String providerId) {
    switch (providerId.toLowerCase()) {
      case 'openai':
        return ['gpt-4', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case 'google':
        return ['gemini-pro', 'gemini-pro-vision'];
      case 'claude':
        return [
          'claude-3-opus-20240229',
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307'
        ];
      case 'azure-openai':
        return ['gpt-4', 'gpt-4-turbo', 'gpt-35-turbo'];
      case 'cohere':
        return ['command-r-plus', 'command-r', 'command'];
      case 'mistral-ai':
        return ['mistral-large', 'mistral-medium', 'mistral-small'];
      default:
        return ['unknown'];
    }
  }
}

/// Provider instance
final dynamicModelFetcherProvider = Provider((ref) => DynamicModelFetcher());

/// State for managing cached models
class ModelsState {
  const ModelsState({
    required this.models,
    this.isLoading = false,
    this.error,
  });

  final Map<String, List<String>> models;
  final bool isLoading;
  final String? error;

  ModelsState copyWith({
    Map<String, List<String>>? models,
    bool? isLoading,
    String? error,
  }) {
    return ModelsState(
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier for managing cached models
class ModelsNotifier extends StateNotifier<ModelsState> {
  ModelsNotifier(this._fetcher) : super(const ModelsState(models: {}));

  final DynamicModelFetcher _fetcher;

  /// Fetch and cache models for a provider
  Future<void> fetchModels(String providerId) async {
    if (state.models[providerId] != null) return; // Already cached

    state = state.copyWith(isLoading: true, error: null);

    try {
      final models = await _fetcher.fetchModelsForProvider(providerId);
      final newModels = Map<String, List<String>>.from(state.models);
      newModels[providerId] = models;
      state = state.copyWith(models: newModels, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch models for $providerId: $e',
      );
    }
  }

  /// Get models for a provider (fetch if not cached)
  Future<List<String>> getModels(String providerId) async {
    if (state.models[providerId] == null) {
      await fetchModels(providerId);
    }
    return state.models[providerId] ?? [];
  }

  /// Clear cache for a provider
  void clearCache(String providerId) {
    final newModels = Map<String, List<String>>.from(state.models);
    newModels.remove(providerId);
    state = state.copyWith(models: newModels, error: null);
  }

  /// Clear all cache
  void clearAllCache() {
    state = const ModelsState(models: {});
  }
}

/// Provider for models state
final modelsProvider = StateNotifierProvider<ModelsNotifier, ModelsState>(
  (ref) => ModelsNotifier(ref.read(dynamicModelFetcherProvider)),
);

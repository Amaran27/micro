import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../../infrastructure/ai/comprehensive_llm_provider.dart';

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
        case 'stability-ai':
          return await _fetchStabilityModels();
        case 'huggingface':
          return await _fetchHuggingFaceModels();
        case 'ollama':
          return await _fetchOllamaModels();
        default:
          // Fallback to hardcoded models for unsupported providers
          return _getFallbackModels(providerId);
      }
    } catch (e) {
      _logger.e('Failed to fetch models for $providerId: $e');
      // Fallback to hardcoded models
      return _getFallbackModels(providerId);
    }
  }

  /// Fetch OpenAI models using their API
  Future<List<String>> _fetchOpenAIModels() async {
    final apiKey = await _secureStorage.read(key: 'openai_api_key');
    if (apiKey == null) return _getFallbackModels('openai');

    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .where((model) => 
                (model['id'] as String).contains('gpt') && 
                ((model['id'] as String).contains('turbo') || (model['id'] as String).contains('4')))
            .map((model) => model['id'] as String)
            .toList();
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
        data: {'contents': [{'role': 'user', 'parts': [{'text': 'test'}]}],
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
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Claude doesn't provide a models endpoint, so we return known models
        return ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'];
      }
    } catch (e) {
      _logger.e('Claude API error: $e');
    }

    return _getFallbackModels('claude');
  }

  /// Fallback models for when API calls fail
  List<String> _getFallbackModels(String providerId) {
    switch (providerId.toLowerCase()) {
      case 'openai':
        return ['gpt-4', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case 'google':
        return ['gemini-pro', 'gemini-pro-vision'];
      case 'claude':
        return ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'];
      case 'azure-openai':
        return ['gpt-4', 'gpt-4-32k', 'gpt-3.5-turbo'];
      case 'cohere':
        return ['command', 'command-nightly', 'command-light'];
      case 'mistral-ai':
        return ['mistral-7b', 'mistral-8x7b', 'mixtral-8x7b'];
      case 'stability-ai':
        return ['stable-diffusion-xl-1024-v1-0', 'stable-diffusion-2-1'];
      case 'huggingface':
        return ['gpt2', 'bert-base-uncased', 'distilbert-base-uncased'];
      case 'ollama':
        return ['llama2', 'mistral', 'codellama'];
      default:
        return [];
    }
  }

  /// Placeholder methods for other providers
  Future<List<String>> _fetchAzureOpenAIModels() async => _getFallbackModels('azure-openai');
  Future<List<String>> _fetchCohereModels() async => _getFallbackModels('cohere');
  Future<List<String>> _fetchMistralModels() async => _getFallbackModels('mistral-ai');
  Future<List<String>> _fetchStabilityModels() async => _getFallbackModels('stability-ai');
  Future<List<String>> _fetchHuggingFaceModels() async => _getFallbackModels('huggingface');
  Future<List<String>> _fetchOllamaModels() async => _getFallbackModels('ollama');
}

/// Riverpod provider for dynamic model fetching
final dynamicModelFetcherProvider = Provider((ref) => DynamicModelFetcher());

/// State provider for cached models
final cachedModelsProvider = StateNotifierProvider<CachedModelsNotifier, Map<String, List<String>>>(
  (ref) => CachedModelsNotifier(ref.read(dynamicModelFetcherProvider)),
);

/// Notifier for managing cached model data
class CachedModelsNotifier extends StateNotifier<Map<String, List<String>>> {
  CachedModelsNotifier(this._fetcher) : super({});

  final DynamicModelFetcher _fetcher;

  /// Fetch and cache models for a provider
  Future<void> fetchModels(String providerId) async {
    if (state[providerId] != null) return; // Already cached

    final models = await _fetcher.fetchModelsForProvider(providerId);
    state = {...state, providerId: models};
  }

  /// Get models for a provider (fetch if not cached)
  Future<List<String>> getModels(String providerId) async {
    if (state[providerId] == null) {
      await fetchModels(providerId);
    }
    return state[providerId] ?? [];
  }

  /// Clear cache for a provider
  void clearCache(String providerId) {
    final newState = Map<String, List<String>>.from(state);
    newState.remove(providerId);
    state = newState;
  }

  /// Clear all cache
  void clearAllCache() {
    state = {};
  }
}
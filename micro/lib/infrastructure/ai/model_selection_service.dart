import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/ai_provider_constants.dart';
import 'secure_api_storage.dart';
import '../../core/utils/logger.dart';

/// Service for managing model discovery, selection, and preferences
class ModelSelectionService {
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Available models from each provider (fetched dynamically)
  final Map<String, List<String>> _availableModels = {};

  /// User-selected favorite models (multiple per provider)
  final Map<String, List<String>> _favoriteModels = {};

  /// Currently active model for each provider
  final Map<String, String> _activeModels = {};

  /// Initialize the model selection service
  Future<void> initialize() async {
    AppLogger().info('Initializing ModelSelectionService...');
    await _loadFavoriteModels();
    await _loadActiveModels();
    AppLogger().info(
        'ModelSelectionService initialization complete. Found ${_favoriteModels.length} provider(s) with favorites');
  }

  /// Fetch available models from all configured providers
  Future<void> fetchAvailableModels() async {
    _availableModels.clear();

    for (final providerId in AIProviderConstants.providerNames.keys) {
      final isConfigured =
          await SecureApiStorage.isProviderConfigured(providerId);
      if (isConfigured) {
        await _fetchProviderModels(providerId);
      }
    }
  }

  /// Fetch models from a specific provider
  Future<void> _fetchProviderModels(String providerId) async {
    try {
      final models = await _getModelsFromProvider(providerId);
      _availableModels[providerId] = models;

      AppLogger().info('Fetched ${models.length} models from $providerId');
    } catch (e) {
      AppLogger().error('Failed to fetch models from $providerId', error: e);
      // Fall back to default models
      _availableModels[providerId] =
          AIProviderConstants.defaultModels[providerId] ?? [];
    }
  }

  /// Get models from provider API
  Future<List<String>> _getModelsFromProvider(String providerId) async {
    final apiKey = await SecureApiStorage.getApiKey(providerId);
    if (apiKey == null) return [];

    switch (providerId) {
      case 'openai':
        return await _fetchOpenAIModels(apiKey);
      case 'google':
        return await _fetchGoogleModels(apiKey);
      case 'claude':
        return await _fetchClaudeModels(apiKey);
      case 'azure':
        return await _fetchAzureModels(apiKey);
      case 'cohere':
        return await _fetchCohereModels(apiKey);
      case 'mistral':
        return await _fetchMistralModels(apiKey);
      case 'stability':
        return await _fetchStabilityModels(apiKey);
      case 'ollama':
        return await _fetchOllamaModels(apiKey);
      case 'huggingface':
        return await _fetchHuggingFaceModels(apiKey);
      default:
        return [];
    }
  }

  /// Fetch OpenAI models
  Future<List<String>> _fetchOpenAIModels(String apiKey) async {
    final dio = Dio();

    try {
      final response = await dio.get(
        'https://api.openai.com/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = data['data'] as List;

        return models
            .where((model) => (model['id'] as String).startsWith('gpt-'))
            .map((model) => model['id'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch OpenAI models', error: e);
      return [];
    }
  }

  /// Fetch Google AI models
  Future<List<String>> _fetchGoogleModels(String apiKey) async {
    final dio = Dio();

    try {
      AppLogger().info(
          'Fetching Google AI models with API key: ${apiKey.substring(0, 10)}...');

      final response = await dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {
          'key': apiKey,
        },
      );

      AppLogger()
          .info('Google AI models response status: ${response.statusCode}');
      AppLogger().info('Google AI models response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger().info('Google AI API response: $data');

        // Try different response formats
        List models = [];
        if (data.containsKey('models')) {
          // Native Google AI API format
          models = data['models'] as List;
        } else if (data.containsKey('data')) {
          // OpenAI-compatible format
          models = data['data'] as List;
        } else {
          AppLogger().warning('Unknown Google AI API response format');
          return [];
        }

        AppLogger().info('Google AI raw models count: ${models.length}');

        final filteredModels = models.where((model) {
          final modelId =
              model['name'] as String? ?? model['id'] as String? ?? '';
          return modelId.contains('gemini-');
        }).map((model) {
          final modelId =
              model['name'] as String? ?? model['id'] as String? ?? '';
          // Remove any prefix like 'models/' if present
          if (modelId.startsWith('models/')) {
            return modelId.substring(7);
          }
          return modelId;
        }).toList();

        AppLogger()
            .info('Google AI filtered models count: ${filteredModels.length}');
        if (filteredModels.isNotEmpty) {
          AppLogger().info('Google AI models: ${filteredModels.join(', ')}');
        }

        return filteredModels;
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Google AI models', error: e);
      return [];
    }
  }

  /// Fetch Claude/Anthropic models
  Future<List<String>> _fetchClaudeModels(String apiKey) async {
    try {
      final dio = Dio();

      final response = await dio.get(
        'https://api.anthropic.com/v1/models',
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = data['data'] as List;

        return models.map((model) => model['id'] as String).toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Claude models from API', error: e);

      // Fallback to known models if API call fails
      return [
        'claude-3-5-sonnet-20241022',
        'claude-3-sonnet-20240229',
        'claude-3-haiku-20240307',
        'claude-3-opus-20240229',
        'claude-2.1',
        'claude-2.0',
        'claude-instant-1.2',
      ];
    }
  }

  /// Fetch Azure OpenAI models
  Future<List<String>> _fetchAzureModels(String apiKey) async {
    try {
      // Parse apiKey to extract endpoint and key
      // Format: endpoint|key
      final parts = apiKey.split('|');
      if (parts.length != 2) {
        AppLogger().error('Invalid Azure API key format');
        return [];
      }

      final endpoint = parts[0];
      final key = parts[1];
      final dio = Dio();

      // Azure OpenAI uses the same models endpoint as OpenAI
      final response = await dio.get(
        '$endpoint/openai/models?api-version=2024-02-15-preview',
        options: Options(
          headers: {
            'api-key': key,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = data['data'] as List;

        return models.map((model) => model['id'] as String).toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Azure OpenAI models', error: e);

      // Fallback to known models if API call fails
      return [
        'gpt-4',
        'gpt-4-32k',
        'gpt-35-turbo',
        'gpt-35-turbo-16k',
      ];
    }
  }

  /// Fetch Cohere models
  Future<List<String>> _fetchCohereModels(String apiKey) async {
    try {
      final dio = Dio();

      final response = await dio.get(
        'https://api.cohere.ai/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = data['models'] as List;

        return models.map((model) => model['name'] as String).toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Cohere models', error: e);

      // Fallback to known models if API call fails
      return [
        'command-r-plus',
        'command-r',
        'command',
        'command-nightly',
        'command-light',
      ];
    }
  }

  /// Fetch Mistral AI models
  Future<List<String>> _fetchMistralModels(String apiKey) async {
    try {
      final dio = Dio();

      final response = await dio.get(
        'https://api.mistral.ai/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = data['data'] as List;

        return models.map((model) => model['id'] as String).toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Mistral AI models', error: e);

      // Fallback to known models if API call fails
      return [
        'mistral-large-latest',
        'mistral-medium-latest',
        'mistral-small-latest',
        'mistral-next',
        'codestral',
      ];
    }
  }

  /// Fetch Stability AI models
  Future<List<String>> _fetchStabilityModels(String apiKey) async {
    return [
      'stable-diffusion-xl-1024-v1-0',
      'stable-diffusion-xl-1024-v1-0',
      'stable-diffusion-2-1',
      'stable-diffusion-2-1-base',
    ];
  }

  /// Fetch Ollama models
  Future<List<String>> _fetchOllamaModels(String apiKey) async {
    try {
      final dio = Dio();
      final endpoint = apiKey; // Ollama uses endpoint as API key

      final response = await dio.get(
        '$endpoint/api/tags',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = data['models'] as List;

        return models.map((model) => model['name'] as String).toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Ollama models', error: e);
      return ['llama3.1', 'mistral', 'codellama']; // fallback
    }
  }

  /// Fetch Hugging Face models
  Future<List<String>> _fetchHuggingFaceModels(String apiKey) async {
    try {
      final dio = Dio();

      // Fetch only text generation models
      final response = await dio.get(
        'https://huggingface.co/api/models',
        queryParameters: {
          'filter': 'text-generation',
          'limit': '100',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final models = response.data as List;

        return models
            .map((model) => model['id'] as String)
            .take(50) // Limit to first 50 models
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger().error('Failed to fetch Hugging Face models', error: e);

      // Fallback to known models if API call fails
      return [
        'gpt2',
        'distilgpt2',
        't5-small',
        'bert-base-uncased',
        'meta-llama/Llama-2-7b-chat-hf',
        'microsoft/DialoGPT-medium',
      ];
    }
  }

  /// Get all available models for a provider
  List<String> getAvailableModels(String providerId) {
    return _availableModels[providerId] ?? [];
  }

  /// Set favorite models for a provider
  Future<void> setFavoriteModels(String providerId, List<String> models) async {
    _favoriteModels[providerId] = models;
    await _saveFavoriteModels();
  }

  /// Add a model to favorites
  Future<void> addFavoriteModel(String providerId, String model) async {
    final favorites = _favoriteModels[providerId] ?? [];
    if (!favorites.contains(model)) {
      favorites.add(model);
      _favoriteModels[providerId] = favorites;
      await _saveFavoriteModels();
    }
  }

  /// Remove a model from favorites
  Future<void> removeFavoriteModel(String providerId, String model) async {
    final favorites = _favoriteModels[providerId] ?? [];
    if (favorites.contains(model)) {
      favorites.remove(model);
      _favoriteModels[providerId] = favorites;
      await _saveFavoriteModels();
    }
  }

  /// Get favorite models for a provider
  List<String> getFavoriteModels(String providerId) {
    return _favoriteModels[providerId] ?? [];
  }

  /// Check if provider has any favorite models
  bool hasFavoriteModels(String providerId) {
    final favorites = _favoriteModels[providerId];
    return favorites != null && favorites.isNotEmpty;
  }

  /// Set active model for a provider
  Future<void> setActiveModel(String providerId, String model) async {
    _activeModels[providerId] = model;
    await _saveActiveModels();
  }

  /// Get active model for a provider
  String? getActiveModel(String providerId) {
    return _activeModels[providerId] ?? _favoriteModels[providerId]?.first;
  }

  /// Get all active models across providers
  Map<String, String> getAllActiveModels() {
    final activeModels = <String, String>{};

    for (final providerId in _availableModels.keys) {
      final activeModel = getActiveModel(providerId);
      if (activeModel != null) {
        activeModels[providerId] = activeModel;
      }
    }

    return activeModels;
  }

  /// Load favorite models from secure storage
  Future<void> _loadFavoriteModels() async {
    try {
      AppLogger().info('Loading favorite models from secure storage...');
      final data = await _storage.read(key: 'favorite_models');
      if (data != null) {
        AppLogger().info('Found favorite models data: $data');
        final entries = data.split('|');
        for (final entry in entries) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            final models = parts[1].split(',');
            _favoriteModels[parts[0]] = models;
            AppLogger().info(
                'Loaded ${models.length} favorite models for provider ${parts[0]}');
          }
        }
      } else {
        AppLogger().info('No favorite models found in storage');
      }
    } catch (e) {
      AppLogger().error('Failed to load favorite models', error: e);
    }
  }

  /// Save favorite models to secure storage
  Future<void> _saveFavoriteModels() async {
    try {
      final data = _favoriteModels.entries
          .map((entry) => '${entry.key}:${entry.value.join(',')}')
          .join('|');
      await _storage.write(key: 'favorite_models', value: data);
    } catch (e) {
      AppLogger().error('Failed to save favorite models', error: e);
    }
  }

  /// Load active models from secure storage
  Future<void> _loadActiveModels() async {
    try {
      AppLogger().info('Loading active models from secure storage...');
      final data = await _storage.read(key: 'active_models');
      if (data != null) {
        AppLogger().info('Found active models data: $data');
        final entries = data.split('|');
        for (final entry in entries) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            _activeModels[parts[0]] = parts[1];
            AppLogger().info(
                'Loaded active model ${parts[1]} for provider ${parts[0]}');
          }
        }
      } else {
        AppLogger().info('No active models found in storage');
      }
    } catch (e) {
      AppLogger().error('Failed to load active models', error: e);
    }
  }

  /// Save active models to secure storage
  Future<void> _saveActiveModels() async {
    try {
      final data = _activeModels.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join('|');
      await _storage.write(key: 'active_models', value: data);
    } catch (e) {
      AppLogger().error('Failed to save active models', error: e);
    }
  }

  /// Clear all model selections
  Future<void> clearSelections() async {
    _favoriteModels.clear();
    _activeModels.clear();
    await _storage.delete(key: 'favorite_models');
    await _storage.delete(key: 'active_models');
  }
}

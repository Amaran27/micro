import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';

import '../../core/utils/logger.dart';
import '../../config/ai_provider_constants.dart';
import 'secure_api_storage.dart';
import 'model_selection_service.dart';
import 'providers/anthropic_provider.dart';
import 'providers/zhipuai_provider.dart';
import 'model_selection_notifier.dart';

/// Configuration for AI providers in the autonomous agent system
class AIProviderConfig {
  final AppLogger _logger = AppLogger();
  late final ModelSelectionService _modelSelectionService;

  // Provider configurations
  final Map<String, dynamic> _providerConfigs = {};
  final Map<String, BaseChatModel> _activeProviders = {};

  bool _isInitialized = false;

  /// Initialize AI providers with API keys from secure storage
  Future<void> initialize({ModelSelectionService? modelSelectionService}) async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing AI Provider Configuration');

      // Use provided service or create a singleton instance
      _modelSelectionService = modelSelectionService ?? ModelSelectionService.instance;

      // Initialize ModelSelectionService first
      await _modelSelectionService.initialize();
      await _modelSelectionService.fetchAvailableModels(forceRefresh: false);

      // Load configurations from secure storage
      await _loadAllConfigurations();

      // Initialize providers
      await _initializeAllProviders();

      _isInitialized = true;
      _logger.info('AI Provider Configuration initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize AI providers', error: e);
      // Continue without AI capabilities
    }
  }

  /// Get the best available chat model
  BaseChatModel? getBestAvailableChatModel() {
    // Prefer OpenAI GPT-4 for better reasoning
    if (_activeProviders.containsKey('openai')) {
      return _activeProviders['openai'];
    }

    // Fall back to Google Gemini
    if (_activeProviders.containsKey('google')) {
      return _activeProviders['google'];
    }

    // Try Claude next
    if (_activeProviders.containsKey('claude')) {
      return _activeProviders['claude'];
    }

    // Return any available provider
    if (_activeProviders.isNotEmpty) {
      return _activeProviders.values.first;
    }

    return null;
  }

  /// Check if any AI providers are available
  bool hasAvailableProviders() {
    return _activeProviders.isNotEmpty;
  }

  /// Get provider status information
  Map<String, dynamic> getProviderStatus() {
    final status = <String, dynamic>{
      'initialized': _isInitialized,
    };

    for (final provider in AIProviderConstants.providerNames.keys) {
      status[provider] = _activeProviders.containsKey(provider);
    }

    return status;
  }

  Future<void> _loadAllConfigurations() async {
    _providerConfigs.clear();

    // Load configurations for all providers
    for (final providerId in AIProviderConstants.providerNames.keys) {
      try {
        final apiKey = await SecureApiStorage.getApiKey(providerId);
        final config = await SecureApiStorage.getConfiguration(providerId);

        if (apiKey != null && apiKey.isNotEmpty) {
          _providerConfigs[providerId] = {
            'apiKey': apiKey,
            ...?config,
          };
          _logger.info('Loaded configuration for $providerId');
        }
      } catch (e) {
        _logger.warning('Failed to load configuration for $providerId',
            error: e);
      }
    }
  }

  Future<void> _initializeAllProviders() async {
    _activeProviders.clear();

    // Initialize each configured provider
    for (final providerId in _providerConfigs.keys) {
      try {
        final provider = await _initializeProvider(
            providerId, _providerConfigs[providerId]!);
        if (provider != null) {
          _activeProviders[providerId] = provider;
          _logger.info('$providerId provider initialized successfully');
        }
      } catch (e) {
        _logger.error('Failed to initialize $providerId provider', error: e);
      }
    }
  }

  Future<BaseChatModel?> _initializeProvider(
      String providerId, Map<String, dynamic> config) async {
    final apiKey = config['apiKey'] as String;
    final defaultOptions = AIProviderConstants.defaultOptions[providerId] ?? {};

    // Always use the active model from ModelSelectionService
    final activeModels = _modelSelectionService.getAllActiveModels();
    String model = activeModels[providerId] ?? '';

    // If no active model is set, use the first favorite model
    if (model.isEmpty) {
      final favoriteModels =
          _modelSelectionService.getFavoriteModels(providerId);
      if (favoriteModels.isNotEmpty) {
        model = favoriteModels.first;
      } else {
        // If no favorites, try to use available models (including cached ones)
        final availableModels =
            _modelSelectionService.getAvailableModels(providerId);
        if (availableModels.isNotEmpty) {
          model = availableModels.first;
          AppLogger().info(
              'Using first available model from cache: $model for provider: $providerId');
        } else {
          // No available models - log error and return null
          _logger.warning(
              'No active, favorite, or available models found for provider: $providerId');
          return null;
        }
      }
    }

    _logger.info('Using model: $model for provider: $providerId');

    switch (providerId) {
      case 'openai':
        return ChatOpenAI(
          apiKey: apiKey,
          defaultOptions: ChatOpenAIOptions(
            model: model,
            maxTokens: defaultOptions['maxTokens'] ?? 1000,
            temperature: defaultOptions['temperature'] ?? 0.7,
            topP: defaultOptions['topP'] ?? 1.0,
          ),
        );

      case 'google':
        return ChatGoogleGenerativeAI(
          apiKey: apiKey,
          defaultOptions: ChatGoogleGenerativeAIOptions(
            model: model,
            temperature: defaultOptions['temperature'] ?? 0.7,
            topP: defaultOptions['topP'] ?? 1.0,
            topK: defaultOptions['topK'] ?? 40,
          ),
        );

      case 'claude':
      case 'anthropic': // Support both names
        final anthropicProvider = AnthropicProvider();
        return await anthropicProvider.initialize();

      case 'zhipuai':
      case 'z_ai': // Support both names
        final zhipuaiProvider = ZhipuAIProvider();
        return await zhipuaiProvider.initialize();

      // For now, we'll return null for unsupported providers
      default:
        return null;
    }
  }

  /// Check if a specific provider is configured and available
  bool isProviderAvailable(String providerId) {
    return _activeProviders.containsKey(providerId);
  }

  /// Get a specific provider by ID
  BaseChatModel? getProvider(String providerId) {
    return _activeProviders[providerId];
  }

  /// Refresh provider configurations
  Future<void> refreshProviders() async {
    await _loadAllConfigurations();
    await _initializeAllProviders();
  }

  /// Get list of all configured providers
  List<String> getConfiguredProviders() {
    return _activeProviders.keys.toList();
  }

  /// Get configuration for a specific provider
  Map<String, dynamic>? getProviderConfig(String providerId) {
    return _providerConfigs[providerId];
  }
}

/// Configuration class for OpenAI
class OpenAIConfig {
  final String apiKey;
  final String defaultModel;
  final int maxTokens;
  final double temperature;

  OpenAIConfig({
    required this.apiKey,
    String? defaultModel, // Model will be fetched dynamically
    this.maxTokens = 1000,
    this.temperature = 0.7,
  }) : defaultModel = defaultModel ?? 'gpt-4o-mini'; // Fallback model
}

/// Configuration class for Google AI
class GoogleGenerativeAIConfig {
  final String apiKey;
  final String defaultModel;
  final int maxTokens;
  final double temperature;

  GoogleGenerativeAIConfig({
    required this.apiKey,
    String? defaultModel, // Model will be fetched dynamically
    this.maxTokens = 1000,
    this.temperature = 0.7,
  }) : defaultModel = defaultModel ?? 'gemini-2.5-flash'; // Fallback model
}

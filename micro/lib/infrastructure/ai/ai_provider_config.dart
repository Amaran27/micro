import '../../core/utils/logger.dart';
import '../../config/ai_provider_constants.dart';
import 'secure_api_storage.dart';
import 'model_selection_service.dart';
import 'interfaces/provider_adapter.dart';
import 'interfaces/provider_config.dart';
import 'simple_ai_service.dart';
import 'adapters/simple_provider_adapter.dart';
import 'provider_storage_service.dart' as new_store;
import 'provider_config_model.dart' as model_cfg;

/// Configuration for AI providers in the autonomous agent system
/// Refactored to use SimpleAIService instead of individual adapters
class AIProviderConfig {
  final AppLogger _logger = AppLogger();
  late final ModelSelectionService _modelSelectionService;
  final SimpleAIService _aiService = SimpleAIService();

  // Provider configurations
  final Map<String, dynamic> _providerConfigs = {};
  final Map<String, ProviderAdapter> _activeProviders = {};

  bool _isInitialized = false;

  /// Check if the configuration has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize AI providers with API keys from secure storage
  Future<void> initialize(
      {ModelSelectionService? modelSelectionService}) async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing AI Provider Configuration');

      // Use provided service or create a singleton instance
      _modelSelectionService =
          modelSelectionService ?? ModelSelectionService.instance;

      // Initialize ModelSelectionService first
      await _modelSelectionService.initialize();
      await _modelSelectionService.fetchAvailableModels(forceRefresh: false);

      // Load configurations from secure storage
      await _loadAllConfigurations();

      // REMOVED: Eager initialization of all providers
      // Now using lazy initialization - providers are created only when needed
      // await _initializeAllProviders();

      _isInitialized = true;
      _logger.info('AI Provider Configuration initialized successfully (lazy loading enabled)');
    } catch (e) {
      _logger.error('Failed to initialize AI providers', error: e);
      // Continue without AI capabilities
    }
  }

  /// Get the best available chat provider
  ProviderAdapter? getBestAvailableChatModel() {
    // Prefer OpenAI GPT-4 for better reasoning
    if (_activeProviders.containsKey('openai')) {
      return _activeProviders['openai'];
    }

    // Fall back to Google Gemini
    if (_activeProviders.containsKey('google')) {
      return _activeProviders['google'];
    }

    // Try ZhipuAI next
    if (_activeProviders.containsKey('zhipuai')) {
      return _activeProviders['zhipuai'];
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

    // 1) Load configurations from new ProviderStorageService (secure)
    try {
      final store = new_store.ProviderStorageService();
      final List<model_cfg.ProviderConfig> enabledConfigs =
          await store.getEnabledConfigs();
      for (final cfg in enabledConfigs) {
        final pid = _canonicalProviderId(cfg.providerId);
        // Prefer new store; do not overwrite if already set
        _providerConfigs.putIfAbsent(
            pid,
            () => {
                  'apiKey': cfg.apiKey,
                  'configId': cfg.id,
                });
        _logger.info('Loaded configuration for $pid from new store');
      }
    } catch (e) {
      _logger.warning('Failed to load configurations from new store', error: e);
    }

    // 2) Backward-compat: Load from legacy SecureApiStorage if not present
    for (final providerId in AIProviderConstants.providerNames.keys) {
      try {
        final pid = _canonicalProviderId(providerId);
        if (_providerConfigs.containsKey(pid)) continue;

        final apiKey = await SecureApiStorage.getApiKey(providerId);
        final config = await SecureApiStorage.getConfiguration(providerId);

        if (apiKey != null && apiKey.isNotEmpty) {
          _providerConfigs[pid] = {
            'apiKey': apiKey,
            ...?config,
          };
          _logger.info('Loaded legacy configuration for $pid');
        }
      } catch (e) {
        _logger.warning('Failed to load legacy configuration for $providerId',
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

  Future<ProviderAdapter?> _initializeProvider(
      String providerId, Map<String, dynamic> config) async {
    final canonicalId = _canonicalProviderId(providerId);
    final apiKey = config['apiKey'] as String;

    // Always use the active model from ModelSelectionService (canonical id)
    final activeModels = _modelSelectionService.getAllActiveModels();
    String model = activeModels[canonicalId] ?? '';

    // If no active model is set, use the first favorite model
    if (model.isEmpty) {
      final favoriteModels =
          _modelSelectionService.getFavoriteModels(canonicalId);
      if (favoriteModels.isNotEmpty) {
        model = favoriteModels.first;
      } else {
        // If no favorites, try to use available models (including cached ones)
        final availableModels =
            _modelSelectionService.getAvailableModels(canonicalId);
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

    _logger.info('Using model: $model for provider: $canonicalId');

    try {
      // Create adapter using SimpleAIService
      final adapter = SimpleProviderAdapter(_aiService, canonicalId, model);
      
      // Initialize based on provider type
      ProviderConfig providerConfig;
      
      switch (canonicalId) {
        case 'openai':
          providerConfig = OpenAIConfig(model: model, apiKey: apiKey);
          break;

        case 'google':
          providerConfig = GoogleConfig(model: model, apiKey: apiKey);
          break;

        case 'zhipu-ai':
        case 'zhipuai':
        case 'z_ai':
          providerConfig = ZhipuAIConfig(model: model, apiKey: apiKey);
          break;

        default:
          _logger.warning('Unsupported provider: $canonicalId');
          return null;
      }
      
      await adapter.initialize(providerConfig);
      _activeProviders[canonicalId] = adapter;
      return adapter;
      
    } catch (e) {
      _logger.error('Failed to initialize $canonicalId provider', error: e);
      return null;
    }
  }

  /// Check if a specific provider is configured and available
  bool isProviderAvailable(String providerId) {
    return _activeProviders.containsKey(_canonicalProviderId(providerId));
  }

  /// Get a specific provider by ID (with lazy initialization)
  Future<ProviderAdapter?> getProvider(String providerId) async {
    final canonicalId = _canonicalProviderId(providerId);
    
    // Return cached provider if already initialized
    if (_activeProviders.containsKey(canonicalId)) {
      return _activeProviders[canonicalId];
    }
    
    // Lazy initialization: create provider on first use
    _logger.info('Lazy initializing provider: $canonicalId');
    
    final config = _providerConfigs[canonicalId];
    if (config == null) {
      _logger.warning('No configuration found for provider: $canonicalId');
      return null;
    }
    
    try {
      final adapter = await _initializeProvider(canonicalId, config);
      if (adapter != null) {
        _logger.info('Successfully lazy initialized provider: $canonicalId');
      }
      return adapter;
    } catch (e) {
      _logger.error('Failed to lazy initialize provider: $canonicalId', error: e);
      return null;
    }
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
    return _providerConfigs[_canonicalProviderId(providerId)];
  }

  /// Get all active models from ModelSelectionService
  Map<String, String> getAllActiveModels() {
    return _modelSelectionService.getAllActiveModels();
  }

  String _canonicalProviderId(String providerId) {
    switch (providerId) {
      case 'zhipu-ai':
      case 'zhipuai':
      case 'z_ai':
        return 'zhipu-ai';
      default:
        return providerId;
    }
  }
}

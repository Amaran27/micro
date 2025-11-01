import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/ai/provider_config_model.dart';
import '../../infrastructure/ai/provider_storage_service.dart';
import '../../infrastructure/ai/provider_registry.dart';

// Storage service provider
final providerStorageServiceProvider = Provider((ref) {
  return ProviderStorageService();
});

// Provider configurations - async loading
final providersConfigProvider =
    FutureProvider<List<ProviderConfig>>((ref) async {
  final storage = ref.watch(providerStorageServiceProvider);
  return await storage.getAllConfigs();
});

// Enabled provider configs only
final enabledProviderConfigsProvider =
    FutureProvider<List<ProviderConfig>>((ref) async {
  final configs = await ref.watch(providersConfigProvider.future);
  return configs.where((c) => c.isEnabled).toList();
});

// Configured and tested provider configs
final configuredProviderConfigsProvider =
    FutureProvider<List<ProviderConfig>>((ref) async {
  final configs = await ref.watch(enabledProviderConfigsProvider.future);
  return configs.where((c) => c.isConfigured && c.testPassed).toList();
});

// All favorite models from all enabled providers
final allFavoriteModelsProvider = FutureProvider<List<String>>((ref) async {
  final configs = await ref.watch(enabledProviderConfigsProvider.future);
  final models = <String>[];
  for (final config in configs) {
    models.addAll(config.favoriteModels);
  }
  return models;
});

// Favorite models by provider
final favoriteModelsByProviderProvider =
    FutureProvider.family<List<String>, String>((ref, providerId) async {
  final storage = ref.watch(providerStorageServiceProvider);
  return await storage.getFavoriteModelsByProvider(providerId);
});

// Get provider metadata from registry
final providerMetadataProvider =
    Provider.family<ProviderMetadata?, String>((ref, providerId) {
  final registry = ProviderRegistry();
  return registry.getProvider(providerId);
});

// All available providers from registry
final allAvailableProvidersProvider = Provider<List<ProviderMetadata>>((ref) {
  final registry = ProviderRegistry();
  return registry.getAllProviders().values.toList();
});

// Providers by category
final providersByCategoryProvider =
    Provider.family<List<ProviderMetadata>, String>((ref, category) {
  final registry = ProviderRegistry();
  return registry.getProvidersByCategory(category);
});

// All available categories
final providerCategoriesProvider = Provider<List<String>>((ref) {
  final registry = ProviderRegistry();
  return registry.getAllCategories();
});

// Check if any provider is configured
final hasConfiguredProvidersProvider = FutureProvider<bool>((ref) async {
  final configs = await ref.watch(configuredProviderConfigsProvider.future);
  return configs.isNotEmpty;
});

// Get statistics about providers
final providerStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final allConfigs = await ref.watch(providersConfigProvider.future);
  final enabledConfigs = await ref.watch(enabledProviderConfigsProvider.future);
  final configuredConfigs =
      await ref.watch(configuredProviderConfigsProvider.future);
  final models = await ref.watch(allFavoriteModelsProvider.future);

  return {
    'total': allConfigs.length,
    'enabled': enabledConfigs.length,
    'configured': configuredConfigs.length,
    'favoriteModels': models.length,
  };
});

// State modifiers
class ProvidersNotifier {
  final ProviderStorageService _storage;

  ProvidersNotifier(this._storage);

  Future<void> addConfig(ProviderConfig config) async {
    await _storage.saveConfig(config);
  }

  Future<void> updateConfig(ProviderConfig config) async {
    await _storage.saveConfig(config);
  }

  Future<void> deleteConfig(String configId) async {
    await _storage.deleteConfig(configId);
  }

  Future<void> toggleConfig(String configId) async {
    final config = await _storage.loadConfig(configId);
    if (config != null) {
      final updated = config.copyWith(isEnabled: !config.isEnabled);
      await _storage.saveConfig(updated);
    }
  }

  Future<void> setFavoriteModels(String configId, List<String> models) async {
    final config = await _storage.loadConfig(configId);
    if (config != null) {
      final updated = config.copyWith(favoriteModels: models);
      await _storage.saveConfig(updated);
    }
  }

  Future<void> markTestPassed(String configId, bool passed) async {
    final config = await _storage.loadConfig(configId);
    if (config != null) {
      final updated = config.copyWith(
        testPassed: passed,
        lastTestedAt: DateTime.now(),
        isConfigured: passed,
      );
      await _storage.saveConfig(updated);
    }
  }
}

// Providers notifier provider
final providersNotifierProvider = Provider((ref) {
  final storage = ref.watch(providerStorageServiceProvider);
  return ProvidersNotifier(storage);
});

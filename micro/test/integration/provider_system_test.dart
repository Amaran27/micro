import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../test_helpers/test_env_config.dart';
import '../../lib/infrastructure/ai/model_selection_service.dart';
import '../../lib/infrastructure/ai/provider_config_model.dart';
import '../../lib/infrastructure/ai/ai_provider_config.dart';

/// Comprehensive test for provider configuration system
/// Tests dynamic discovery, favorites, persistence, and caching
/// Uses real API keys to validate end-to-end functionality
void main() {
  group('Provider System Integration Tests', () {
    late ModelSelectionService modelService;
    late AIProviderConfig providerConfig;
    late FlutterSecureStorage storage;

    setUpAll(() async {
      await TestEnvConfig.init();
      storage = const FlutterSecureStorage();
    });

    setUp(() async {
      // Clean up storage before each test
      await storage.deleteAll();
      modelService = ModelSelectionService();
      providerConfig = AIProviderConfig();
      
      // Initialize with real API keys
      await providerConfig.initialize();
    });

    tearDown(() async {
      await storage.deleteAll();
      modelService.dispose();
    });

    group('Dynamic Model Discovery', () {
      test('should discover Google models with real API key', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        // Act
        final googleProvider = providerConfig.getProvider('google');
        expect(googleProvider, isNotNull);

        final models = await modelService.getAvailableModels('google');

        // Assert
        expect(models, isNotEmpty);
        expect(models.any((m) => m.contains('gemini')), isTrue);
        
        // Log discovered models for verification
        print('✓ Discovered ${models.length} Google models:');
        for (final model in models.take(5)) {
          print('  - $model');
        }
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('should discover ZhipuAI models with real API key', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('zhipuai')) {
          return; // Skip if no real API key
        }

        // Act
        final zhipuProvider = providerConfig.getProvider('zhipuai');
        expect(zhipuProvider, isNotNull);

        final models = await modelService.getAvailableModels('zhipuai');

        // Assert
        expect(models, isNotEmpty);
        expect(models.any((m) => m.contains('glm')), isTrue);
        
        // Log discovered models for verification
        print('✓ Discovered ${models.length} ZhipuAI models:');
        for (final model in models.take(5)) {
          print('  - $model');
        }
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('should discover OpenRouter models with real API key', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('openrouter')) {
          return; // Skip if no real API key
        }

        // Act - Update provider config with real API key
        providerConfig.updateProviderConfig(
          'openrouter',
          apiKey: TestEnvConfig.getApiKey('openrouter'),
        );

        final models = await modelService.getAvailableModels('openrouter');

        // Assert
        expect(models, isNotEmpty);
        
        // Log discovered models for verification
        print('✓ Discovered ${models.length} OpenRouter models:');
        for (final model in models.take(5)) {
          print('  - $model');
        }
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('should cache discovered models to avoid repeated API calls', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        final stopwatch = Stopwatch()..start();

        // Act - First call (should hit API)
        final models1 = await modelService.getAvailableModels('google');
        final firstCallTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.reset();
        
        // Act - Second call (should use cache)
        final models2 = await modelService.getAvailableModels('google');
        final secondCallTime = stopwatch.elapsedMilliseconds;

        // Assert
        expect(models1, equals(models2));
        expect(models1.length, greaterThan(0));
        
        // Second call should be significantly faster (cached)
        print('First call: ${firstCallTime}ms, Second call: ${secondCallTime}ms');
        expect(secondCallTime, lessThan(firstCallTime ~/ 2)); // At least 2x faster
      });

      test('should handle provider without API key gracefully', () async {
        // Arrange - Don't set API key for anthropic
        
        // Act
        final models = await modelService.getAvailableModels('anthropic');

        // Assert - Should return default models without throwing
        expect(models, isNotEmpty);
        expect(models.any((m) => m.contains('claude')), isTrue);
        
        print('✓ Fallback to default models for provider without API key');
      });
    });

    group('Favorite Model Selection', () {
      test('should persist favorite models across service restarts', () async {
        // Arrange
        const provider = 'google';
        const favoriteModels = ['gemini-1.5-flash', 'gemini-1.5-pro'];

        // Act
        await modelService.setFavoriteModels(provider, favoriteModels);
        
        // Create new service instance (simulating app restart)
        final newService = ModelSelectionService();
        await newService.initialize();

        // Assert
        final persistedFavorites = await newService.getFavoriteModels(provider);
        expect(persistedFavorites, equals(favoriteModels));
        
        print('✓ Favorite models persisted: $persistedFavorites');
      });

      test('should maintain active model selection across restarts', () async {
        // Arrange
        const provider = 'zhipuai';
        const activeModel = 'glm-4.5-flash';

        // Act
        await modelService.setActiveModel(provider, activeModel);
        
        // Create new service instance
        final newService = ModelSelectionService();
        await newService.initialize();

        // Assert
        final persistedActive = await newService.getActiveModel(provider);
        expect(persistedActive, equals(activeModel));
        
        print('✓ Active model persisted: $persistedActive');
      });

      test('should handle multiple provider favorites independently', () async {
        // Arrange
        const googleFavorites = ['gemini-1.5-flash', 'gemini-2.0-flash'];
        const zhipuaiFavorites = ['glm-4.5-flash', 'glm-4'];

        // Act
        await modelService.setFavoriteModels('google', googleFavorites);
        await modelService.setFavoriteModels('zhipuai', zhipuaiFavorites);
        
        // Create new service instance
        final newService = ModelSelectionService();
        await newService.initialize();

        // Assert
        final googleResult = await newService.getFavoriteModels('google');
        final zhipuaiResult = await newService.getFavoriteModels('zhipuai');
        
        expect(googleResult, equals(googleFavorites));
        expect(zhipuaiResult, equals(zhipuaiFavorites));
        expect(googleResult, isNot(equals(zhipuaiResult)));
        
        print('✓ Independent favorites per provider:');
        print('  Google: $googleResult');
        print('  ZhipuAI: $zhipuaiResult');
      });

      test('should validate favorite models exist in available models', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        final availableModels = await modelService.getAvailableModels('google');
        expect(availableModels, isNotEmpty);

        // Act - Set favorites including valid and invalid models
        const mixedFavorites = ['gemini-1.5-flash', 'invalid-model-name', 'non-existent-model'];
        await modelService.setFavoriteModels('google', mixedFavorites);

        // Assert - Should only return valid favorites
        final validFavorites = await modelService.getFavoriteModels('google');
        
        for (final favorite in validFavorites) {
          expect(availableModels, contains(favorite));
        }
        
        expect(validFavorites, contains('gemini-1.5-flash'));
        expect(validFavorites, isNot(contains('invalid-model-name')));
        expect(validFavorites, isNot(contains('non-existent-model')));
        
        print('✓ Favorite validation: ${validFavorites.length}/${mixedFavorites.length} are valid');
      });
    });

    group('Provider Configuration Management', () {
      test('should handle provider config updates with real API keys', () async {
        // Arrange
        const provider = 'google';
        final newApiKey = TestEnvConfig.getApiKey('google'); // Using real key from env

        // Act
        providerConfig.updateProviderConfig(
          provider,
          apiKey: newApiKey,
          customModels: ['custom-gemini-model'],
        );

        // Assert
        final config = providerConfig.getProviderConfig(provider);
        expect(config, isNotNull);
        expect(config!.apiKey, equals(newApiKey));
        expect(config.customModels, contains('custom-gemini-model'));
        
        print('✓ Provider config updated with custom models');
      });

      test('should maintain provider state across config changes', () async {
        // Arrange
        const provider = 'zhipuai';
        const activeModel = 'glm-4.5-flash';

        // Set initial state
        await modelService.setActiveModel(provider, activeModel);
        
        // Act - Update provider config
        providerConfig.updateProviderConfig(
          provider,
          apiKey: TestEnvConfig.getApiKey('zhipuai'),
          customModels: ['custom-model'],
        );

        // Assert - Active model should be preserved
        final currentActive = await modelService.getActiveModel(provider);
        expect(currentActive, equals(activeModel));
        
        print('✓ Active model preserved across config updates');
      });

      test('should handle custom models in addition to discovered models', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        const customModels = ['custom-gemini-1', 'custom-gemini-2'];
        
        // Act
        providerConfig.updateProviderConfig(
          'google',
          apiKey: TestEnvConfig.getApiKey('google'),
          customModels: customModels,
        );

        final availableModels = await modelService.getAvailableModels('google');

        // Assert
        for (final customModel in customModels) {
          expect(availableModels, contains(customModel));
        }
        
        print('✓ Custom models included in available models:');
        for (final model in customModels) {
          print('  - $model');
        }
      });
    });

    group('Performance and Caching', () {
      test('should cache model lists efficiently', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        final stopwatch = Stopwatch()..start();

        // Act - Multiple calls should use cache after first
        final models1 = await modelService.getAvailableModels('google');
        final time1 = stopwatch.elapsedMilliseconds;

        stopwatch.reset();
        final models2 = await modelService.getAvailableModels('google');
        final time2 = stopwatch.elapsedMilliseconds;

        stopwatch.reset();
        final models3 = await modelService.getAvailableModels('google');
        final time3 = stopwatch.elapsedMilliseconds;

        // Assert
        expect(models1, equals(models2));
        expect(models2, equals(models3));
        
        print('Performance comparison:');
        print('  Call 1 (API): ${time1}ms');
        print('  Call 2 (Cache): ${time2}ms');
        print('  Call 3 (Cache): ${time3}ms');
        
        // Cache calls should be significantly faster
        expect(time2, lessThan(time1 ~/ 3));
        expect(time3, lessThan(time1 ~/ 3));
      });

      test('should invalidate cache when provider config changes', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        // Prime the cache
        final models1 = await modelService.getAvailableModels('google');
        expect(models1, isNotEmpty);

        // Act - Change provider config (should invalidate cache)
        providerConfig.updateProviderConfig(
          'google',
          apiKey: TestEnvConfig.getApiKey('google'),
          customModels: ['new-custom-model'],
        );

        final models2 = await modelService.getAvailableModels('google');

        // Assert
        expect(models2.length, greaterThan(models1.length)); // Should include custom model
        expect(models2, contains('new-custom-model'));
        
        print('✓ Cache invalidated on config change: ${models1.length} → ${models2.length} models');
      });

      test('should handle concurrent requests gracefully', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google')) {
          return; // Skip if no real API key
        }

        // Act - Multiple concurrent requests
        final futures = <Future<List<String>>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(modelService.getAvailableModels('google'));
        }

        final results = await Future.wait(futures);

        // Assert - All results should be identical
        for (int i = 1; i < results.length; i++) {
          expect(results[i], equals(results[0]));
        }
        
        expect(results[0], isNotEmpty);
        
        print('✓ Handled ${results.length} concurrent requests successfully');
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid provider gracefully', () async {
        // Act
        final models = await modelService.getAvailableModels('invalid-provider');
        final activeModel = await modelService.getActiveModel('invalid-provider');
        final favorites = await modelService.getFavoriteModels('invalid-provider');

        // Assert
        expect(models, isEmpty);
        expect(activeModel, isNull);
        expect(favorites, isEmpty);
        
        print('✓ Invalid provider handled gracefully');
      });

      test('should handle empty favorite list', () async {
        // Arrange
        const provider = 'google';

        // Act
        await modelService.setFavoriteModels(provider, []);
        final favorites = await modelService.getFavoriteModels(provider);

        // Assert
        expect(favorites, isEmpty);
        
        print('✓ Empty favorite list handled correctly');
      });

      test('should handle storage corruption gracefully', () async {
        // Arrange - Corrupt storage with invalid data
        await storage.write(
          key: 'selectedModels',
          value: 'invalid-json-data',
        );

        // Act - Service should handle corruption gracefully
        final newService = ModelSelectionService();
        await newService.initialize();

        final favorites = await newService.getFavoriteModels('google');

        // Assert - Should recover with empty favorites
        expect(favorites, isEmpty);
        
        print('✓ Storage corruption handled gracefully');
      });

      test('should validate model names before setting as favorites', () async {
        // Arrange
        const provider = 'google';
        const invalidModels = ['', '   ', 'invalid@model', 'model with spaces'];

        // Act & Assert
        for (final invalidModel in invalidModels) {
          await modelService.setFavoriteModels(provider, [invalidModel]);
          final favorites = await modelService.getFavoriteModels(provider);
          
          // Should filter out invalid models
          expect(favorites, isNot(contains(invalidModel)));
        }
        
        print('✓ Invalid model names filtered from favorites');
      });
    });

    group('End-to-End Workflow Validation', () {
      test('should support complete user workflow', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google') && !TestEnvConfig.hasRealApiKey('zhipuai')) {
          return; // Skip if no real API keys
        }

        // Act - Simulate typical user workflow
        print('\n🔍 Testing Complete User Workflow:');
        
        // 1. Initialize provider with real API key
        final provider = TestEnvConfig.hasRealApiKey('google') ? 'google' : 'zhipuai';
        providerConfig.updateProviderConfig(
          provider,
          apiKey: TestEnvConfig.getApiKey(provider),
        );
        print('✓ 1. Provider initialized with real API key');

        // 2. Discover available models
        final availableModels = await modelService.getAvailableModels(provider);
        expect(availableModels, isNotEmpty);
        print('✓ 2. Discovered ${availableModels.length} models');

        // 3. Select favorite models
        final favorites = availableModels.take(3).toList();
        await modelService.setFavoriteModels(provider, favorites);
        print('✓ 3. Set favorite models: ${favorites.join(', ')}');

        // 4. Set active model
        final activeModel = favorites.first;
        await modelService.setActiveModel(provider, activeModel);
        print('✓ 4. Set active model: $activeModel');

        // 5. Verify persistence (simulated app restart)
        final newService = ModelSelectionService();
        await newService.initialize();
        
        final persistedActive = await newService.getActiveModel(provider);
        final persistedFavorites = await newService.getFavoriteModels(provider);
        
        expect(persistedActive, equals(activeModel));
        expect(persistedFavorites, equals(favorites));
        print('✓ 5. Verified persistence across restart');

        // 6. Update config with custom models
        const customModels = ['custom-test-model'];
        providerConfig.updateProviderConfig(
          provider,
          customModels: customModels,
        );
        
        final updatedModels = await newService.getAvailableModels(provider);
        expect(updatedModels, contains(customModels.first));
        print('✓ 6. Added custom models: ${customModels.join(', ')}');

        print('\n✅ Complete workflow validated successfully!');
      });
    });
  });
}
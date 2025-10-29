import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:micro/infrastructure/ai/model_cache_repository.dart';
import 'package:micro/domain/models/ai_model.dart';

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ModelCacheRepository Tests', () {
    late ModelCacheRepository repository;

    setUp(() async {
      repository = ModelCacheRepository();
      // Clear any existing data
      await repository.clearCache();
    });

    tearDown(() async {
      await repository.clearCache();
    });

    test('should save and retrieve models', () async {
      // Create test models
      final models = [
        AIModel(
          provider: 'google',
          modelId: 'gemini-2.5-pro-preview-03-25',
          displayName: 'Gemini 2.5 Pro Preview',
          description: 'Latest Gemini model',
        ),
        AIModel(
          provider: 'google',
          modelId: 'gemini-2.5-flash',
          displayName: 'Gemini 2.5 Flash',
          description: 'Fast Gemini model',
        ),
        AIModel(
          provider: 'openai',
          modelId: 'gpt-4o',
          displayName: 'GPT-4o',
          description: 'OpenAI GPT-4o model',
        ),
      ];

      // Save models
      await repository.saveModels(models);

      // Retrieve models
      final cachedModels = await repository.getCachedModels();

      // Verify
      expect(cachedModels.length, equals(3));
      expect(
          cachedModels.where((m) => m.provider == 'google').length, equals(2));
      expect(
          cachedModels.where((m) => m.provider == 'openai').length, equals(1));

      // Check specific models
      final geminiPro = cachedModels
          .firstWhere((m) => m.modelId == 'gemini-2.5-pro-preview-03-25');
      expect(geminiPro.displayName, equals('Gemini 2.5 Pro Preview'));
      expect(geminiPro.description, equals('Latest Gemini model'));
    });

    test('should handle empty cache', () async {
      final cachedModels = await repository.getCachedModels();
      expect(cachedModels, isEmpty);
    });

    test('should clear cache', () async {
      // Add some models
      final models = [
        AIModel(
          provider: 'test',
          modelId: 'test-model',
          displayName: 'Test Model',
          description: 'Test description',
        ),
      ];

      await repository.saveModels(models);

      // Verify they exist
      var cachedModels = await repository.getCachedModels();
      expect(cachedModels.length, equals(1));

      // Clear cache
      await repository.clearCache();

      // Verify they're gone
      cachedModels = await repository.getCachedModels();
      expect(cachedModels, isEmpty);
    });

    test('should check cache validity', () async {
      // Initially should be invalid (no cache)
      final isValid = await repository.isCacheValid();
      expect(isValid, isFalse);

      // Add models
      final models = [
        AIModel(
          provider: 'test',
          modelId: 'test-model',
          displayName: 'Test Model',
          description: 'Test description',
        ),
      ];

      await repository.saveModels(models);

      // Now should be valid
      final isValidAfterSave = await repository.isCacheValid();
      expect(isValidAfterSave, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:micro/infrastructure/ai/providers/anthropic_provider.dart';
import 'package:micro/infrastructure/ai/providers/zhipuai_provider.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/infrastructure/ai/model_selection_service.dart';

void main() {
  group('AI Providers', () {
    group('AnthropicProvider', () {
      test('should return default models when API key is not available',
          () async {
        // Act
        final provider = AnthropicProvider();
        final models = await provider.getAvailableModels();

        // Assert
        expect(models, isNotEmpty);
        expect(models.first.provider, equals('anthropic'));
        expect(models.first.modelId, contains('claude'));
      });
    });

    group('ZhipuAIProvider', () {
      test('should return default models when API key is not available',
          () async {
        // Act
        final provider = ZhipuAIProvider();
        final models = await provider.getAvailableModels();

        // Assert
        expect(models, isNotEmpty);
        expect(models.first.provider, equals('zhipuai'));
        expect(models.first.modelId, contains('glm'));
      });
    });

    group('AIProviderConfig', () {
      test('should initialize without errors', () async {
        // Act
        final config = AIProviderConfig();

        // Assert - should not throw
        expect(() async => await config.initialize(), returnsNormally);
      });

      test('should return provider status', () {
        // Act
        final config = AIProviderConfig();
        final status = config.getProviderStatus();

        // Assert
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('initialized'), isTrue);
      });
    });

    group('ModelSelectionService', () {
      test('should initialize without errors', () async {
        // Act
        final service = ModelSelectionService();

        // Assert - should not throw
        expect(() async => await service.initialize(), returnsNormally);
      });

      test('should return available models list', () {
        // Act
        final service = ModelSelectionService();
        final models = service.getAvailableModels('openai');

        // Assert
        expect(models, isA<List<String>>());
      });
    });
  });
}

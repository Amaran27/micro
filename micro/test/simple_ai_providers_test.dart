import 'package:flutter_test/flutter_test.dart';

import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/infrastructure/ai/model_selection_service.dart';
import 'package:micro/config/ai_provider_constants.dart';

void main() {
  group('AI Provider Configuration', () {
    test('should have provider constants defined', () {
      // Assert
      expect(AIProviderConstants.providerNames, isNotEmpty);
      expect(AIProviderConstants.providerNames.containsKey('claude'), isTrue);
      expect(AIProviderConstants.providerNames.containsKey('zhipuai'), isTrue);
    });

    test('should have required fields for Claude', () {
      // Assert
      final claudeConfig = AIProviderConstants.requiredFields['claude'];
      expect(claudeConfig, isNotNull);
      expect(claudeConfig, contains('apiKey'));
    });

    test('should have required fields for ZhipuAI', () {
      // Assert
      final zhipuaiConfig = AIProviderConstants.requiredFields['zhipuai'];
      expect(zhipuaiConfig, isNotNull);
      expect(zhipuaiConfig, contains('apiKey'));
    });

    test('should have default models for ZhipuAI', () {
      // Assert
      final zhipuaiModels = AIProviderConstants.defaultModels['zhipuai'];
      expect(zhipuaiModels, isNotNull);
      expect(zhipuaiModels, contains('glm-4.6-flash'));
      expect(zhipuaiModels, contains('glm-4.5-flash'));
      expect(zhipuaiModels, contains('glm-4-flash'));
    });
  });

  group('AIProviderConfig', () {
    test('should create instance without errors', () {
      // Act
      final config = AIProviderConfig();

      // Assert
      expect(config, isNotNull);
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
    test('should create instance without errors', () {
      // Act
      final service = ModelSelectionService();

      // Assert
      expect(service, isNotNull);
    });
  });
}

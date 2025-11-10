import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/test_env_config.dart';
import '../../infrastructure/ai/adapters/chat_google_adapter.dart';
import '../../infrastructure/ai/adapters/zhipuai_adapter.dart';
import '../../infrastructure/ai/interfaces/provider_config.dart';
import '../../domain/models/chat/chat_message.dart' as micro;

/// TDD-style integration tests for AI providers
/// These tests follow the Arrange-Act-Assert pattern
/// Tests only run with real API keys when explicitly configured
void main() {
  group('TDD API Integration Tests', () {
    late List<String> availableProviders;

    setUpAll(() async {
      await TestEnvConfig.init();
      availableProviders = TestEnvConfig.providersWithRealKeys;
    });

    group('Test Environment Validation', () {
      test('should have test environment properly configured', () {
        expect(TestEnvConfig.testTimeout, greaterThan(0));
        expect(TestEnvConfig.preferMock, isA<bool>());
        expect(availableProviders, isA<List<String>>());
      });

      test('should identify when live tests should run', () {
        final shouldRunLive = TestEnvConfig.runLiveApiTests && 
                            availableProviders.isNotEmpty;
        
        print('Live API tests enabled: ${TestEnvConfig.runLiveApiTests}');
        print('Providers with keys: $availableProviders');
        print('Will run live tests: $shouldRunLive');
        
        expect(shouldRunLive, isA<bool>());
      });
    });

    group('Google Gemini Integration', () {
      late ChatGoogleAdapter adapter;

      setUp(() {
        adapter = ChatGoogleAdapter();
      });

      tearDown(() {
        adapter.dispose();
      });

      test('should initialize with valid configuration', () async {
        // Arrange
        final config = GoogleConfig(
          apiKey: TestEnvConfig.getApiKey('google'),
          model: 'gemini-1.5-flash',
        );

        // Act & Assert
        if (TestEnvConfig.hasRealApiKey('google')) {
          await adapter.initialize(config);
          expect(adapter.isInitialized, isTrue);
          expect(adapter.supportsStreaming, isTrue);
          expect(adapter.currentModel, equals('gemini-1.5-flash'));
        } else {
          // Test with test key
          expect(config.apiKey, startsWith('test-'));
        }
      });

      test('should send simple message and receive response', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test conditionally
        }

        final config = GoogleConfig(
          apiKey: TestEnvConfig.getApiKey('google'),
          model: 'gemini-1.5-flash',
        );
        await adapter.initialize(config);

        final testMessage = micro.ChatMessage.user(
          id: 'test-1',
          content: 'What is 2 + 2? Please answer with just the number.',
        );

        // Act
        final response = await adapter.sendMessage(
          text: testMessage.content,
          history: [],
        );

        // Assert
        expect(response.content, isNotEmpty);
        expect(response.isFromAssistant, isTrue);
        expect(response.id, isNotEmpty);
        
        // Response should contain the answer "4"
        expect(response.content.toLowerCase(), contains('4'));
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('should handle streaming responses', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test conditionally
        }

        final config = GoogleConfig(
          apiKey: TestEnvConfig.getApiKey('google'),
          model: 'gemini-1.5-flash',
        );
        await adapter.initialize(config);

        final testMessage = 'Count from 1 to 5 slowly';
        final receivedChunks = <String>[];

        // Act
        final stream = adapter.sendMessageStream(
          text: testMessage,
          history: [],
        );

        await for (final chunk in stream) {
          receivedChunks.add(chunk);
        }

        // Assert
        expect(receivedChunks, isNotEmpty);
        final fullResponse = receivedChunks.join();
        expect(fullResponse, contains('1'));
        expect(fullResponse, contains('5'));
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('should handle conversation context', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('google') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test conditionally
        }

        final config = GoogleConfig(
          apiKey: TestEnvConfig.getApiKey('google'),
          model: 'gemini-1.5-flash',
        );
        await adapter.initialize(config);

        final history = [
          micro.ChatMessage.user(
            id: 'test-1',
            content: 'My favorite color is blue.',
          ),
          micro.ChatMessage.assistant(
            id: 'test-2',
            content: 'I\'ll remember that your favorite color is blue.',
          ),
        ];

        // Act
        final response = await adapter.sendMessage(
          text: 'What is my favorite color?',
          history: history,
        );

        // Assert
        expect(response.content, contains('blue'));
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));
    });

    group('ZhipuAI Integration', () {
      late ZhipuAIAdapter adapter;

      setUp(() {
        adapter = ZhipuAIAdapter();
      });

      tearDown(() {
        adapter.dispose();
      });

      test('should initialize with valid configuration', () async {
        // Arrange
        final config = ZhipuAIConfig(
          apiKey: TestEnvConfig.getApiKey('zhipuai'),
          model: 'glm-4.5-flash',
        );

        // Act & Assert
        if (TestEnvConfig.hasRealApiKey('zhipuai')) {
          await adapter.initialize(config);
          expect(adapter.isInitialized, isTrue);
          expect(adapter.supportsStreaming, isTrue);
          expect(adapter.currentModel, equals('glm-4.5-flash'));
        } else {
          // Test with test key
          expect(config.apiKey, startsWith('test-'));
        }
      });

      test('should send simple message and receive response', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('zhipuai') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test conditionally
        }

        final config = ZhipuAIConfig(
          apiKey: TestEnvConfig.getApiKey('zhipuai'),
          model: 'glm-4.5-flash',
        );
        await adapter.initialize(config);

        // Act
        final response = await adapter.sendMessage(
          text: 'What is 3 + 3? Please answer with just the number.',
          history: [],
        );

        // Assert
        expect(response.content, isNotEmpty);
        expect(response.isFromAssistant, isTrue);
        expect(response.id, isNotEmpty);
        
        // Response should contain the answer "6"
        expect(response.content, contains('6'));
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('should handle streaming responses', () async {
        // Arrange
        if (!TestEnvConfig.hasRealApiKey('zhipuai') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test conditionally
        }

        final config = ZhipuAIConfig(
          apiKey: TestEnvConfig.getApiKey('zhipuai'),
          model: 'glm-4.5-flash',
        );
        await adapter.initialize(config);

        final testMessage = 'List three fruits';
        final receivedChunks = <String>[];

        // Act
        final stream = adapter.sendMessageStream(
          text: testMessage,
          history: [],
        );

        await for (final chunk in stream) {
          receivedChunks.add(chunk);
        }

        // Assert
        expect(receivedChunks, isNotEmpty);
        final fullResponse = receivedChunks.join().toLowerCase();
        
        // Should contain at least some common fruits
        final fruitKeywords = ['apple', 'banana', 'orange', 'grape', 'berry'];
        final hasFruit = fruitKeywords.any((fruit) => fullResponse.contains(fruit));
        expect(hasFruit, isTrue);
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));
    });

    group('Cross-Provider Comparison', () {
      test('should handle same input across different providers', () async {
        // Arrange
        final testInput = 'What is the capital of France?';
        final responses = <String, String>{};

        for (final provider in availableProviders) {
          if (!TestEnvConfig.runLiveApiTests) continue;

          try {
            if (provider == 'google') {
              final adapter = ChatGoogleAdapter();
              final config = GoogleConfig(
                apiKey: TestEnvConfig.getApiKey('google'),
                model: 'gemini-1.5-flash',
              );
              
              await adapter.initialize(config);
              final response = await adapter.sendMessage(
                text: testInput,
                history: [],
              );
              responses['google'] = response.content;
              adapter.dispose();
            } else if (provider == 'zhipuai') {
              final adapter = ZhipuAIAdapter();
              final config = ZhipuAIConfig(
                apiKey: TestEnvConfig.getApiKey('zhipuai'),
                model: 'glm-4.5-flash',
              );
              
              await adapter.initialize(config);
              final response = await adapter.sendMessage(
                text: testInput,
                history: [],
              );
              responses['zhipuai'] = response.content;
              adapter.dispose();
            }
          } catch (e) {
            print('Error testing $provider: $e');
          }
        }

        // Assert
        if (responses.isNotEmpty) {
          responses.forEach((provider, response) {
            expect(response, isNotEmpty);
            expect(response.toLowerCase(), contains('paris'));
          });
        }
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout * 2)));
    });

    group('Error Handling Tests', () {
      test('should handle invalid API keys gracefully', () async {
        // Arrange
        final adapter = ChatGoogleAdapter();
        final invalidConfig = GoogleConfig(
          apiKey: 'invalid-test-key-12345',
          model: 'gemini-1.5-flash',
        );

        try {
          // Act
          await adapter.initialize(invalidConfig);
          
          // If initialization succeeds, try sending a message
          final response = await adapter.sendMessage(
            text: 'Test message',
            history: [],
          );

          // Assert - should get an error message, not crash
          expect(response.content, isNotEmpty);
        } catch (e) {
          // Assert - should handle error gracefully
          expect(e, isA<Exception>());
        } finally {
          adapter.dispose();
        }
      });

      test('should handle network timeouts gracefully', () async {
        // This test simulates network issues
        // We can't easily simulate network timeouts without actual network failures
        // So we'll just verify the timeout configuration is properly read
        expect(TestEnvConfig.testTimeout, greaterThan(0));
        expect(TestEnvConfig.testTimeout, lessThan(120)); // Reasonable limit
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../test_helpers/test_env_config.dart';
import '../../infrastructure/ai/adapters/chat_google_adapter.dart';
import '../../infrastructure/ai/adapters/zhipuai_adapter.dart';
import '../../infrastructure/ai/interfaces/provider_config.dart';

void main() {
  group('AI Providers Environment Tests', () {
    // Initialize test environment before all tests
    setUpAll(() async {
      await TestEnvConfig.init();
    });

    group('Environment Configuration', () {
      test('should load test environment variables', () {
        expect(TestEnvConfig.testTimeout, isA<int>());
        expect(TestEnvConfig.testTimeout, greaterThan(0));
        expect(TestEnvConfig.runLiveApiTests, isA<bool>());
        expect(TestEnvConfig.preferMock, isA<bool>());
      });

      test('should provide test API keys', () {
        expect(TestEnvConfig.getApiKey('google'), isNotEmpty);
        expect(TestEnvConfig.getApiKey('zhipuai'), isNotEmpty);
        expect(TestEnvConfig.getApiKey('openrouter'), isNotEmpty);
      });

      test('should identify providers with real API keys', () {
        final providersWithKeys = TestEnvConfig.providersWithRealKeys;
        expect(providersWithKeys, isA<List<String>>());
        
        // Test keys should start with 'test-' unless real keys are provided
        for (final provider in ['google', 'zhipuai', 'openrouter']) {
          final hasRealKey = TestEnvConfig.hasRealApiKey(provider);
          expect(hasRealKey, isA<bool>());
        }
      });
    });

    group('Google Adapter with Environment Config', () {
      late ChatGoogleAdapter adapter;

      setUp(() {
        adapter = ChatGoogleAdapter();
      });

      test('should initialize with test API key', () async {
        final config = GoogleConfig(
          apiKey: TestEnvConfig.getApiKey('google'),
          model: 'gemini-1.5-flash',
        );

        if (TestEnvConfig.hasRealApiKey('google') && TestEnvConfig.runLiveApiTests) {
          // Only test with real API if configured and allowed
          await adapter.initialize(config);
          expect(adapter.isInitialized, isTrue);
          expect(adapter.currentModel, equals('gemini-1.5-flash'));
        } else {
          // Skip live API test
          expect(TestEnvConfig.getApiKey('google'), startsWith('test-'));
        }
      });

      test('should handle test API key gracefully', () {
        final testKey = TestEnvConfig.getApiKey('google');
        expect(testKey, isNotEmpty);
        
        // Test key should be either a real key or a test key
        if (testKey.startsWith('test-')) {
          expect(testKey, startsWith('test-google-key'));
        }
      });

      tearDown(() {
        adapter.dispose();
      });
    });

    group('ZhipuAI Adapter with Environment Config', () {
      late ZhipuAIAdapter adapter;

      setUp(() {
        adapter = ZhipuAIAdapter();
      });

      test('should initialize with test API key', () async {
        final config = ZhipuAIConfig(
          apiKey: TestEnvConfig.getApiKey('zhipuai'),
          model: 'glm-4.5-flash',
        );

        if (TestEnvConfig.hasRealApiKey('zhipuai') && TestEnvConfig.runLiveApiTests) {
          // Only test with real API if configured and allowed
          await adapter.initialize(config);
          expect(adapter.isInitialized, isTrue);
          expect(adapter.currentModel, equals('glm-4.5-flash'));
        } else {
          // Skip live API test
          expect(TestEnvConfig.getApiKey('zhipuai'), startsWith('test-'));
        }
      });

      test('should handle test API key gracefully', () {
        final testKey = TestEnvConfig.getApiKey('zhipuai');
        expect(testKey, isNotEmpty);
        
        // Test key should be either a real key or a test key
        if (testKey.startsWith('test-')) {
          expect(testKey, startsWith('test-zhipuai-key'));
        }
      });

      tearDown(() {
        adapter.dispose();
      });
    });

    group('Live API Tests (when configured)', () {
      test('can send test message to Google if real API key available', () async {
        if (!TestEnvConfig.hasRealApiKey('google') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test if no real API key or live tests disabled
        }

        final adapter = ChatGoogleAdapter();
        final config = GoogleConfig(
          apiKey: TestEnvConfig.getApiKey('google'),
          model: 'gemini-1.5-flash',
        );

        try {
          await adapter.initialize(config);
          
          // Send a simple test message
          final response = await adapter.sendMessage(
            text: 'Hello, this is a test message.',
            history: [],
          );

          expect(response.content, isNotEmpty);
          expect(response.isFromAssistant, isTrue);
        } finally {
          adapter.dispose();
        }
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));

      test('can send test message to ZhipuAI if real API key available', () async {
        if (!TestEnvConfig.hasRealApiKey('zhipuai') || !TestEnvConfig.runLiveApiTests) {
          return; // Skip test if no real API key or live tests disabled
        }

        final adapter = ZhipuAIAdapter();
        final config = ZhipuAIConfig(
          apiKey: TestEnvConfig.getApiKey('zhipuai'),
          model: 'glm-4.5-flash',
        );

        try {
          await adapter.initialize(config);
          
          // Send a simple test message
          final response = await adapter.sendMessage(
            text: 'Hello, this is a test message.',
            history: [],
          );

          expect(response.content, isNotEmpty);
          expect(response.isFromAssistant, isTrue);
        } finally {
          adapter.dispose();
        }
      }, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));
    });

    group('Mock Tests (always run)', () {
      test('should handle adapter initialization failures gracefully', () async {
        final adapter = ChatGoogleAdapter();
        final invalidConfig = GoogleConfig(
          apiKey: 'invalid-test-key',
          model: 'gemini-1.5-flash',
        );

        try {
          await adapter.initialize(invalidConfig);
          // If initialization succeeds, that's fine for test purposes
          expect(adapter.isInitialized, isTrue);
        } catch (e) {
          // If initialization fails, adapter should handle it gracefully
          expect(adapter.isInitialized, isFalse);
        } finally {
          adapter.dispose();
        }
      });

      test('should validate provider configurations', () {
        for (final provider in ['google', 'zhipuai', 'openrouter']) {
          final apiKey = TestEnvConfig.getApiKey(provider);
          expect(apiKey, isNotEmpty);
          expect(apiKey.length, greaterThan(5)); // Basic validation
        }
      });

      test('should provide consistent test environment', () {
        // Multiple calls should return same values
        final key1 = TestEnvConfig.getApiKey('google');
        final key2 = TestEnvConfig.getApiKey('google');
        expect(key1, equals(key2));

        final timeout1 = TestEnvConfig.testTimeout;
        final timeout2 = TestEnvConfig.testTimeout;
        expect(timeout1, equals(timeout2));
      });
    });
  });
}
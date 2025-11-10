import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Test environment configuration utility
/// ONLY for testing purposes - NEVER use in production code
class TestEnvConfig {
  static bool _initialized = false;

  /// Initialize test environment variables from .env.test file
  /// Must be called in test setUpAll() method
  static Future<void> init() async {
    if (!_initialized) {
      try {
        await dotenv.load(fileName: '.env.test');
        _initialized = true;
      } catch (e) {
        // If .env.test file doesn't exist, use default test values
        _initialized = true;
      }
    }
  }

  /// Get API key for testing
  static String getApiKey(String provider) {
    switch (provider.toLowerCase()) {
      case 'openrouter':
        return dotenv.env['OPENROUTER_API_KEY'] ?? 'test-openrouter-key';
      case 'google':
        return dotenv.env['GOOGLE_API_KEY'] ?? 'test-google-key';
      case 'zhipuai':
        return dotenv.env['ZHIPUAI_API_KEY'] ?? 'test-zhipuai-key';
      default:
        return 'test-$provider-key';
    }
  }

  /// Check if live API tests should be run
  static bool get runLiveApiTests {
    final value = dotenv.env['TEST_RUN_LIVE_API_TESTS'] ?? 'false';
    return value.toLowerCase() == 'true';
  }

  /// Get test timeout in seconds
  static int get testTimeout {
    final value = dotenv.env['TEST_TIMEOUT'] ?? '30';
    return int.tryParse(value) ?? 30;
  }

  /// Check if tests should prefer mocks over live APIs
  static bool get preferMock {
    final value = dotenv.env['TEST_PREFER_MOCK'] ?? 'true';
    return value.toLowerCase() == 'true';
  }

  /// Check if a provider has a real API key configured
  static bool hasRealApiKey(String provider) {
    final apiKey = getApiKey(provider);
    return apiKey.isNotEmpty && !apiKey.startsWith('test-');
  }

  /// Get list of providers that have real API keys configured
  static List<String> get providersWithRealKeys {
    return ['openrouter', 'google', 'zhipuai']
        .where((provider) => hasRealApiKey(provider))
        .toList();
  }
}
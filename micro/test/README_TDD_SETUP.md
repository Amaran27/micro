# TDD Environment Setup for AI Provider Testing

This directory contains test utilities and TDD-style test cases for AI providers with environment configuration.

## Files Overview

### Environment Configuration
- **`.env.test`** - Test environment file with API keys and test configuration
- **`test/test_helpers/test_env_config.dart`** - Utility class for loading test environment variables

### Test Files
- **`test/unit/ai_providers_env_test.dart`** - Unit tests using environment configuration
- **`test/integration/tdd_api_integration_test.dart`** - TDD-style integration tests with live API calls

## Setup Instructions

### 1. Configure Test API Keys

Edit the `.env.test` file and add your actual API keys:

```bash
# Replace with your actual API keys for testing
OPENROUTER_API_KEY=sk-or-v1-your-openrouter-key-here
GOOGLE_API_KEY=your-google-ai-api-key-here
ZHIPUAI_API_KEY=your-zhipuai-api-key-here
```

### 2. Configure Test Behavior

Update test configuration in `.env.test`:

```bash
# Run tests with actual API calls (slower but more comprehensive)
TEST_RUN_LIVE_API_TESTS=true

# Test timeout in seconds
TEST_TIMEOUT=30

# Prefer mocks over live APIs when possible
TEST_PREFER_MOCK=true
```

### 3. Install Dependencies

The setup requires `flutter_dotenv` for environment variable loading:

```bash
flutter pub get
```

### 4. Run Tests

#### Run All Tests
```bash
flutter test
```

#### Run Only Environment Tests
```bash
flutter test test/unit/ai_providers_env_test.dart
```

#### Run Integration Tests
```bash
flutter test test/integration/tdd_api_integration_test.dart
```

#### Run with Coverage
```bash
flutter test --coverage
```

## TDD Test Patterns

### 1. Environment-Aware Testing
Tests automatically detect if real API keys are available and adjust behavior:

```dart
// Only runs with real API if configured and allowed
if (TestEnvConfig.hasRealApiKey('google') && TestEnvConfig.runLiveApiTests) {
  // Live API test
} else {
  // Mock/skip test
}
```

### 2. Arrange-Act-Assert Pattern
All tests follow the classic TDD pattern:

```dart
test('should send message and receive response', () async {
  // Arrange
  final config = GoogleConfig(apiKey: TestEnvConfig.getApiKey('google'));
  await adapter.initialize(config);

  // Act
  final response = await adapter.sendMessage(text: 'Hello', history: []);

  // Assert
  expect(response.content, isNotEmpty);
});
```

### 3. Conditional Test Execution
Tests can be conditionally skipped based on environment:

```dart
test('expensive live test', () async {
  if (!TestEnvConfig.runLiveApiTests) return; // Skip
  
  // Test implementation
}, timeout: Timeout(Duration(seconds: TestEnvConfig.testTimeout)));
```

## Test Categories

### Unit Tests
- Environment configuration validation
- Adapter initialization with test keys
- Error handling scenarios
- Configuration validation

### Integration Tests
- Live API calls (when enabled)
- Streaming response handling
- Cross-provider comparison
- Conversation context management

### Mock Tests
- Always run regardless of API key availability
- Test error handling and edge cases
- Validate test environment consistency

## Best Practices

### 1. Never Commit Real API Keys
The `.env.test` file should contain test keys or be added to `.gitignore`:

```gitignore
.env.test
```

### 2. Use Test Keys When Possible
For development, use test API keys that have limited quotas:
- Google AI Studio: Get free test keys
- ZhipuAI: Free tier available
- OpenRouter: Free tier with limits

### 3. Configure Test Timeouts
Set appropriate timeouts based on your network and API response times:

```dart
// Default 30 seconds, adjust as needed
TEST_TIMEOUT=30
```

### 4. Prefer Mocks for CI/CD
In continuous integration, disable live API tests:

```bash
TEST_RUN_LIVE_API_TESTS=false
TEST_PREFER_MOCK=true
```

## Example Test Output

```
Live API tests enabled: true
Providers with keys: [google, zhipuai]
Will run live tests: true

✓ should load test environment variables
✓ should initialize with test API key (google)
✓ should send simple message and receive response
✓ should handle streaming responses
✓ should handle conversation context

4 tests completed in 15.2s
```

## Troubleshooting

### Tests are Skipped
- Check if API keys are configured in `.env.test`
- Verify `TEST_RUN_LIVE_API_TESTS=true` for live tests
- Ensure `flutter_dotenv` dependency is installed

### API Key Errors
- Verify API keys are correct and active
- Check if the provider supports the selected model
- Ensure adequate quota/balance on the API account

### Timeout Errors
- Increase `TEST_TIMEOUT` in `.env.test`
- Check network connectivity
- Verify API provider status

## Security Notes

⚠️ **IMPORTANT**: This setup is for testing purposes only:
- Never use real production API keys in tests
- Never commit `.env.test` to version control
- Use test/development API keys with limited quotas
- Rotate test keys regularly

The `TestEnvConfig` class is designed specifically for testing and should never be imported into production code.
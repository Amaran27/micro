import 'package:dio/dio.dart';
import 'secure_api_storage.dart';
import 'package:micro/core/utils/logger.dart';

/// Debug helper for ZhipuAI API key issues
class ZhipuAIDebugHelper {
  /// Store API key directly for debugging
  static Future<void> storeDebugApiKey(String apiKey) async {
    try {
      await SecureApiStorage.saveApiKey('zhipuai', apiKey);
      AppLogger().info('Stored debug ZhipuAI API key');
    } catch (e) {
      AppLogger().error('Failed to store debug API key', error: e);
    }
  }

  /// Retrieve and log API key details (without revealing the key)
  static Future<void> debugApiKey() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('zhipuai');
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger().warning('No ZhipuAI API key found in secure storage');
        return;
      }

      final keyType = apiKey.contains('.') ? 'multi-part (old format)' : 'simple (new format)';
      final keyLength = apiKey.length;
      
      AppLogger().info('ZhipuAI API Key Debug:');
      AppLogger().info('  - Format: $keyType');
      AppLogger().info('  - Length: $keyLength characters');
      AppLogger().info('  - First 3 chars: ${apiKey.substring(0, apiKey.length > 3 ? 3 : 0)}***');
      AppLogger().info('  - Last 3 chars: ***${apiKey.length > 3 ? apiKey.substring(apiKey.length - 3) : ''}');
      
      // Check if it looks like the old JWT format
      if (apiKey.contains('.') && apiKey.split('.').length == 3) {
        AppLogger().warning('  - API key appears to be in old JWT format (id.secret.signature)');
        AppLogger().warning('  - This format is deprecated, please get a new API key from ZhipuAI platform');
      }
    } catch (e) {
      AppLogger().error('Failed to debug API key', error: e);
    }
  }

  /// Test the API key with a simple request
  static Future<bool> testApiKey() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('zhipuai');
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger().warning('No ZhipuAI API key to test');
        return false;
      }

      final dio = Dio();
      final response = await dio.post(
        'https://api.z.ai/api/paas/v4/chat/completions',
        data: {
          'model': 'glm-4.6',
          'messages': [{'role': 'user', 'content': 'test'}],
          'max_tokens': 1,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept-Language': 'en-US,en',
          },
        ),
      );

      if (response.statusCode == 200) {
        AppLogger().info('ZhipuAI API key test successful');
        return true;
      } else {
        AppLogger().warning('ZhipuAI API key test failed with status: ${response.statusCode}');
        AppLogger().warning('Response body: ${response.data}');
        return false;
      }
    } catch (e) {
      AppLogger().error('ZhipuAI API key test failed', error: e);
      return false;
    }
  }
}
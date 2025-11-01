import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 ZHIPUAI AUTHENTICATION DEBUG\n');

  // Test different API key formats
  const testKeys = [
    '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt', // Working temp key
    '39char_simple_key_test_format_for_debug', // Simulating the failing key
  ];

  for (final apiKey in testKeys) {
    print('🔑 Testing API key:');
    print('   Length: ${apiKey.length}');
    print('   Contains dot: ${apiKey.contains('.')}');
    print('   Format: ${apiKey.contains('.') ? 'multi-part' : 'simple'}');

    // Test with the API
    try {
      final httpClient = HttpClient();
      final request = await httpClient
          .getUrl(Uri.parse('https://api.z.ai/api/paas/v4/models'));
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();

      print('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('   ✅ Authentication successful');
      } else if (response.statusCode == 401) {
        print('   ❌ Authentication failed - 401 Unauthorized');

        // Read response body for more details
        final responseBody = await response.transform(utf8.decoder).join();
        print('   Response: $responseBody');
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }

      httpClient.close();
    } catch (e) {
      print('   ❌ Error: $e');
    }

    print('');
  }

  print('💡 RECOMMENDATION:');
  print(
      'The correct ZhipuAI API key format should be a multi-part key with a dot (.)');
  print('Example: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxx');
  print('Length should be around 50+ characters, not 39 characters');
}

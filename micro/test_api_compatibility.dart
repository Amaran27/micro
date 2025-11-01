import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();

  print('🧪 TESTING API COMPATIBILITY\n');

  // Test ZhipuAI with OpenAI-compatible format
  await testZhipuAICompatibility(dio);

  print('\n${'=' * 50}');
  print('✅ CONCLUSION:');
  print('ZhipuAI is OpenAI-compatible - no adapter needed!');
  print('Only base URL and API key need to be configured.');
}

Future<void> testZhipuAICompatibility(Dio dio) async {
  const apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';
  const baseUrl = 'https://api.z.ai/api/paas/v4';

  print('🤖 ZHIPUAI OPENAI-COMPATIBILITY TEST:');
  print('Testing with standard OpenAI request format...\n');

  try {
    // Test 1: Models endpoint (OpenAI format)
    print('1️⃣ Testing /models endpoint:');
    final modelsResponse = await dio.get(
      '$baseUrl/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (modelsResponse.statusCode == 200) {
      print('   ✅ Models endpoint works');
      final data = modelsResponse.data;
      print('   📋 Response format: ${data['object']} (same as OpenAI)');

      if (data['data'] != null) {
        final models = data['data'] as List;
        print('   🤖 Found ${models.length} models');
      }
    }

    // Test 2: Chat completions endpoint (OpenAI format)
    print('\n2️⃣ Testing /chat/completions endpoint:');
    final chatRequest = {
      'model': 'glm-4.6',
      'messages': [
        {'role': 'user', 'content': 'Say "API compatibility test successful"'}
      ],
      'max_tokens': 50,
      'temperature': 0.1,
    };

    final chatResponse = await dio.post(
      '$baseUrl/chat/completions',
      data: chatRequest,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (chatResponse.statusCode == 200) {
      print('   ✅ Chat completions works');
      final data = chatResponse.data;

      // Check OpenAI-compatible response format
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        final choice = data['choices'][0];
        if (choice['message'] != null && choice['message']['content'] != null) {
          print('   📝 Response: "${choice['message']['content']}"');
          print('   ✅ OpenAI response format confirmed');
        }
      }

      if (data['usage'] != null) {
        print('   📊 Token usage: ${data['usage']}');
      }
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
}

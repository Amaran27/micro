import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  try {
    print('Testing ZhipuAI chat completions endpoint...');

    final requestData = {
      'model': 'glm-4.6',
      'messages': [
        {
          'role': 'user',
          'content': 'Hello, this is a test. What models are available?'
        }
      ],
      'max_tokens': 100,
    };

    final response = await dio.post(
      'https://api.z.ai/api/paas/v4/chat/completions',
      data: requestData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('✅ Chat completions works!');
      print('Response data:');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
    } else {
      print('❌ Error: ${response.statusCode}');
      print('Response: ${response.data}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }

  // Now try to check if models endpoint exists
  try {
    print('\n\nTesting ZhipuAI models endpoint...');

    final response = await dio.get(
      'https://api.z.ai/api/paas/v4/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('✅ Models endpoint works!');
      print('Response data:');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
    } else {
      print('❌ Models endpoint error: ${response.statusCode}');
      print('Response: ${response.data}');
    }
  } catch (e) {
    print('❌ Models endpoint exception: $e');

    // Try alternative endpoints
    print('\n\nTrying alternative model endpoints...');

    final alternatives = [
      'https://api.z.ai/api/paas/v4/model/list',
      'https://api.z.ai/api/paas/v4/models/list',
      'https://api.z.ai/api/paas/v4/models', // without coding
      'https://open.bigmodel.cn/api/paas/v4/models', // China endpoint
    ];

    for (final endpoint in alternatives) {
      try {
        print('\nTrying: $endpoint');
        final response = await dio.get(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
        );
        print('✅ Success with: $endpoint');
        print('Response: ${response.data}');
        break;
      } catch (e) {
        print('❌ Failed: $e');
      }
    }
  }
}

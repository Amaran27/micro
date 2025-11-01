import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  print('=== Testing Both Z.AI Endpoints ===\n');

  // Test general endpoint
  try {
    print('1️⃣ Testing GENERAL endpoint: https://api.z.ai/api/paas/v4/models');
    final response1 = await dio.get(
      'https://api.z.ai/api/paas/v4/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
      ),
    );

    if (response1.statusCode == 200) {
      print('✅ Success!');
      final data1 = response1.data['data'] as List;
      print('Found ${data1.length} models:');
      for (var model in data1) {
        print('  - ${model['id']}');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n---\n');

  // Test coding endpoint
  try {
    print(
        '2️⃣ Testing CODING endpoint: https://api.z.ai/api/coding/paas/v4/models');
    final response2 = await dio.get(
      'https://api.z.ai/api/coding/paas/v4/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
      ),
    );

    if (response2.statusCode == 200) {
      print('✅ Success!');
      final data2 = response2.data['data'] as List;
      print('Found ${data2.length} models:');
      for (var model in data2) {
        print('  - ${model['id']}');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n---\n');

  // Test if flash model works directly
  try {
    print('3️⃣ Testing glm-4.5-flash chat with GENERAL endpoint');
    final response3 = await dio.post(
      'https://api.z.ai/api/paas/v4/chat/completions',
      data: {
        'model': 'glm-4.5-flash',
        'messages': [
          {'role': 'user', 'content': 'Say "hello" in one word'}
        ],
        'max_tokens': 10,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
      ),
    );

    if (response3.statusCode == 200) {
      print('✅ Flash model WORKS on general endpoint!');
      print('Response: ${response3.data['choices'][0]['message']['content']}');
    }
  } catch (e) {
    print('❌ Flash model error: $e');
  }

  print('\n---\n');

  // Test if flash model works on coding endpoint
  try {
    print('4️⃣ Testing glm-4.5-flash chat with CODING endpoint');
    final response4 = await dio.post(
      'https://api.z.ai/api/coding/paas/v4/chat/completions',
      data: {
        'model': 'glm-4.5-flash',
        'messages': [
          {'role': 'user', 'content': 'Say "hello" in one word'}
        ],
        'max_tokens': 10,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
      ),
    );

    if (response4.statusCode == 200) {
      print('✅ Flash model WORKS on coding endpoint!');
      print('Response: ${response4.data['choices'][0]['message']['content']}');
    }
  } catch (e) {
    print('❌ Flash model error: $e');
  }
}

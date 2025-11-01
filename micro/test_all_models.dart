import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  print('=== Z.AI Models Investigation ===\n');

  // Test 1: Check what /models endpoint returns
  print('1️⃣ Testing /models endpoint:');
  try {
    final response = await dio.get(
      'https://api.z.ai/api/paas/v4/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('✅ Success!');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
      final models =
          (response.data['data'] as List).map((m) => m['id']).toList();
      print('\nListed models: $models');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n---\n');

  // Test 2: Try each model from pricing page individually
  final pricingModels = [
    'glm-4.6',
    'glm-4.5',
    'glm-4.5v',
    'glm-4.5-x',
    'glm-4.5-air',
    'glm-4.5-airx',
    'glm-4-32b-0414-128k',
    'glm-4.5-flash',
  ];

  print('2️⃣ Testing each model from pricing page:\n');

  for (final model in pricingModels) {
    try {
      final response = await dio.post(
        'https://api.z.ai/api/paas/v4/chat/completions',
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 5,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ $model - WORKS');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final status = e.response!.statusCode;
        final body = e.response!.data;
        print('❌ $model - Error $status: ${body['error']?['message'] ?? body}');
      } else {
        print('❌ $model - Error: $e');
      }
    }
  }
}

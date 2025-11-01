import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  print('Testing ZhipuAI dynamic model fetching...\n');

  try {
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
      print('✅ API call successful');
      print('Status Code: ${response.statusCode}');

      final data = response.data;
      print('\n📋 Raw API Response:');
      print(JsonEncoder.withIndent('  ').convert(data));

      if (data['data'] != null) {
        final models = data['data'] as List;
        print('\n🤖 Available Models:');
        for (final model in models) {
          print('- ${model['id']} (${model['object']})');
        }
      }
    } else {
      print('❌ API call failed with status: ${response.statusCode}');
      print('Response: ${response.data}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

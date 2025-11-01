import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  try {
    print('Testing ZhipuAI models endpoint...');

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
      print('✅ Success!');
      print('Response data:');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
    } else {
      print('❌ Error: ${response.statusCode}');
      print('Response: ${response.data}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}

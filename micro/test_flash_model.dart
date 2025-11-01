import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  print('Testing GLM-4.5-Flash (FREE) model on general endpoint\n');

  try {
    final response = await dio.post(
      'https://api.z.ai/api/paas/v4/chat/completions',
      data: {
        'model': 'glm-4.5-flash',
        'messages': [
          {
            'role': 'user',
            'content': 'Do you know where Chennai is? Answer in one sentence.'
          }
        ],
        'max_tokens': 100,
        'temperature': 0.7,
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
      print('✅ SUCCESS! GLM-4.5-Flash works on general endpoint!\n');
      print('Model: ${response.data['model']}');
      print('Response: ${response.data['choices'][0]['message']['content']}');
      print('\nUsage:');
      print('  Input tokens: ${response.data['usage']['prompt_tokens']}');
      print('  Output tokens: ${response.data['usage']['completion_tokens']}');
      print('  Total tokens: ${response.data['usage']['total_tokens']}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

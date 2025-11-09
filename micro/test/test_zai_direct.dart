import 'package:dio/dio.dart';
import 'dart:convert';

/// Direct Z.AI API test to see exact error response
Future<void> main() async {
  final dio = Dio();
  final apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  // Test with AGENT prompt (long text)
  final agentPrompt =
      '''You are an autonomous agent planner. Create a detailed plan to accomplish the following task.

Task: Calculate 2+2

Available Tools:
[]

Break this down into clear, sequential steps. Each step should:
1. State the action to perform
2. Specify which tool to use (if any)
3. Define expected outputs

Return the plan in this exact JSON format:
{
  "steps": [
    {"stepNumber": 1, "action": "description", "tool": "tool_name or null", "expectedOutput": "what this produces"},
    ...
  ]
}''';

  // Test 1: Coding endpoint with AGENT prompt
  print('🧪 Testing CODING endpoint with AGENT prompt:');
  // Test 1: Coding endpoint with AGENT prompt
  print('🧪 Testing CODING endpoint with AGENT prompt:');
  try {
    final response = await dio.post(
      'https://api.z.ai/api/coding/paas/v4/chat/completions',
      data: json.encode({
        'model': 'GLM-4.5',
        'messages': [
          {'role': 'user', 'content': agentPrompt},
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
        validateStatus: (_) => true, // Don't throw on any status
      ),
    );
    print('✅ Coding endpoint - Status: ${response.statusCode}');
    print('✅ Coding endpoint - Response: ${response.data}');
  } catch (e) {
    print('❌ Coding endpoint error: $e');
  }

  print('\n' + ('=' * 80) + '\n');

  // Test 2: General endpoint (old)
  print(
    '🧪 Testing GENERAL endpoint: https://api.z.ai/api/paas/v4/chat/completions',
  );
  try {
    final response = await dio.post(
      'https://api.z.ai/api/paas/v4/chat/completions',
      data: {
        'model': 'GLM-4.5',
        'messages': [
          {'role': 'user', 'content': 'Say "hello" in one word'},
        ],
        'max_tokens': 50,
        'temperature': 0.7,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en',
        },
        validateStatus: (_) => true, // Don't throw on any status
      ),
    );
    print('✅ General endpoint - Status: ${response.statusCode}');
    print('✅ General endpoint - Response: ${response.data}');
  } catch (e) {
    print('❌ General endpoint error: $e');
  }
}

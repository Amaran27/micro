import 'package:openai_dart/openai_dart.dart';

void main() async {
  print('=== Testing OpenAI Dart Client with Z.AI ===\n');

  // Create OpenAI client configured for Z.AI
  final client = OpenAIClient(
    apiKey: '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt',
    baseUrl: 'https://api.z.ai/api/paas/v4',
  );

  try {
    print('Fetching models from Z.AI using OpenAI client...\n');

    // Try to list models
    final models = await client.listModels();

    print('✅ Success! Found ${models.data.length} models:\n');

    for (final model in models.data) {
      print('  📦 ${model.id}');
      if (model.created != null) {
        print(
            '     Created: ${DateTime.fromMillisecondsSinceEpoch((model.created ?? 0) * 1000)}');
      }
      print('     Owner: ${model.ownedBy}');
      print('');
    }
  } catch (e) {
    print('❌ Error listing models: $e');
  }

  print('\n---\n');

  // Test if we can manually query specific models
  print('Testing specific models availability:\n');

  final testModels = [
    'glm-4.5-flash',
    'glm-4.6',
    'glm-4.5',
    'glm-4.5-air',
    'glm-4.5v',
  ];

  for (final modelId in testModels) {
    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(modelId),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string('Hi'),
            ),
          ],
          maxTokens: 5,
        ),
      );

      print('✅ $modelId - Available');
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Insufficient balance')) {
        print('💰 $modelId - Requires payment');
      } else {
        final truncated =
            errorMsg.length > 60 ? '${errorMsg.substring(0, 60)}...' : errorMsg;
        print('❌ $modelId - Error: $truncated');
      }
    }
  }

  client.endSession();
}

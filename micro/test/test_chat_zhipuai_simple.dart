import 'package:micro/infrastructure/ai/providers/chat_zhipuai.dart';
import 'package:langchain/langchain.dart';

/// Minimal test of ChatZhipuAI with simple prompt
Future<void> main() async {
  final apiKey = '72eec5b691ba4ab49f20630cd28473fd.wEPV775TMA5tTDGt';

  final chat = ChatZhipuAI(apiKey: apiKey, model: 'GLM-4.5');

  print('🧪 Testing ChatZhipuAI with simple prompt...');

  try {
    // Test 1: Simple string (same as direct test)
    final simpleMessages = [ChatMessage.humanText('Say "hello" in one word')];
    final simplePrompt = PromptValue.chat(simpleMessages);

    print('\n📝 Test 1: Simple prompt');
    final response1 = await chat.invoke(simplePrompt);
    print('✅ Response: ${response1.output}');
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n' + ('=' * 80) + '\n');

  try {
    // Test 2: Agent-style prompt (complex)
    final agentPrompt =
        '''You are an autonomous agent planner. Create a detailed plan to accomplish the following task.

Task: Calculate 2+2

Available Tools:


Create a step-by-step plan. For each step, specify:
1. Step ID (e.g., step_1, step_2)
2. Description of what the step does
3. Which tool to use
4. Parameters for the tool

Format your response as a JSON array of steps.''';

    final agentMessages = [ChatMessage.humanText(agentPrompt)];
    final complexPrompt = PromptValue.chat(agentMessages);

    print('\n📝 Test 2: Agent prompt (complex)');
    final response2 = await chat.invoke(complexPrompt);
    print('✅ Response length: ${response2.output.length}');
    print('✅ Response preview: ${response2.output.substring(0, 200)}...');
  } catch (e) {
    print('❌ Error: $e');
  }
}

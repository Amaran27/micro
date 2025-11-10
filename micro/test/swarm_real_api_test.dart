/// Real API test for Swarm Intelligence
/// Tests with actual ZhipuAI API to verify swarm functionality end-to-end

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:micro/infrastructure/ai/adapters/zhipuai_adapter.dart';
import 'package:micro/infrastructure/ai/agent/agent_service.dart';
import 'package:micro/infrastructure/ai/agent/swarm/swarm_orchestrator.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/mock_tools.dart';
import 'package:micro/infrastructure/ai/swarm_settings_service.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'dart:convert';

void main() {
  group('Swarm Real API Tests', () {
    const String testApiKey = 'your-api-key-here'; // Replace with actual key
    
    setUp(() async {
      // Setup secure storage with real API key
      SharedPreferences.setMockInitialValues({
        'selectedModels': '{"zhipuai":"glm-4.5-flash"}',
        'zhipuai_config': json.encode({
          'apiKey': testApiKey,
          'isActive': true,
          'baseUrl': 'https://api.z.ai/api/paas/v4',
        }),
      });
    });

    test('Direct ZhipuAI API test', () async {
      print('🔍 Testing direct ZhipuAI API connection...');
      
      if (testApiKey == 'your-api-key-here') {
        print('⚠️  Please replace "your-api-key-here" with actual ZhipuAI API key');
        return;
      }
      
      try {
        // Create ZhipuAI chat model
        final chatModel = ChatOpenAI(
          apiKey: testApiKey,
          model: 'glm-4.5-flash',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          temperature: 0.7,
        );
        
        print('✅ Chat model created');
        
        // Test simple conversation
        final systemMessage = ChatMessage.system('You are a helpful assistant.');
        final userMessage = ChatMessage.human(ChatMessageContent.text('Hello! How are you?'));
        
        print('📤 Sending test message...');
        final response = await chatModel.invoke(PromptValue.chat([systemMessage, userMessage]));
        
        print('✅ Response received:');
        print(response.output.content);
        
        expect(response.output.content, isNotNull);
        expect(response.output.content!.toString().isNotEmpty, isTrue);
        
      } catch (e) {
        print('❌ Direct API test failed: $e');
        rethrow;
      }
    });

    test('Swarm routing decision test', () async {
      print('🧠 Testing swarm routing decision...');
      
      if (testApiKey == 'your-api-key-here') {
        print('⚠️  Please replace "your-api-key-here" with actual ZhipuAI API key');
        return;
      }
      
      try {
        final chatModel = ChatOpenAI(
          apiKey: testApiKey,
          model: 'glm-4.5-flash',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          temperature: 0.1,
        );
        
        // Test simple message routing
        print('📝 Testing simple message: "hi"');
        final routingPrompt = '''
You are a routing controller. Decide if the user's request requires multi-agent swarm planning or a single direct conversational response.
Return ONLY compact JSON with these fields and nothing else:
{
  "use_swarm": true|false,
  "reason": "short reason",
  "max_specialists": integer  
}

USER_GOAL:
hi
''';

        final systemMessage = ChatMessage.system(routingPrompt);
        final response = await chatModel.invoke(PromptValue.chat([systemMessage]));
        
        print('📥 Routing response:');
        print(response.output.content);
        
        // Parse routing decision
        String responseText = response.output.content?.toString() ?? '';
        final match = RegExp(r"\{[\s\S]*\}").firstMatch(responseText);
        if (match != null) {
          responseText = match.group(0)!;
        }
        
        final routingDecision = json.decode(responseText) as Map<String, dynamic>;
        print('✅ Parsed routing decision:');
        print('   Use Swarm: ${routingDecision['use_swarm']}');
        print('   Reason: ${routingDecision['reason']}');
        print('   Max Specialists: ${routingDecision['max_specialists']}');
        
        expect(routingDecision['use_swarm'], isA<bool>());
        
      } catch (e) {
        print('❌ Swarm routing test failed: $e');
        rethrow;
      }
    });

    test('Swarm meta-planning test', () async {
      print('🤖 Testing swarm meta-planning (specialist generation)...');
      
      if (testApiKey == 'your-api-key-here') {
        print('⚠️  Please replace "your-api-key-here" with actual ZhipuAI API key');
        return;
      }
      
      try {
        final chatModel = ChatOpenAI(
          apiKey: testApiKey,
          model: 'glm-4.5-flash',
          baseUrl: 'https://api.z.ai/api/paas/v4',
          temperature: 0.3,
        );
        
        final customerAnalysisTask = '''
Analyze these customer reviews and provide actionable insights:
1. "The UI is beautiful but the app crashes when I upload large files"
2. "Love the new dark mode! Performance is great" 
3. "App is slow on my old phone. Takes 10 seconds to open"
4. "Best productivity app I've used. Only issue: can't export to PDF"
5. "Keeps crashing. Fix the bugs!"

Provide sentiment analysis, issue identification, and recommendations.
''';

        final metaPlanningPrompt = '''
You are a meta-planning AI. Analyze the following task and generate a team of specialist agents.

TASK GOAL:
$customerAnalysisTask

AVAILABLE TOOLS:
sentiment_tool: Analyze text sentiment and emotion
stats_tool: Calculate statistics and numerical insights
knowledge_base_tool: Extract and categorize information
echo_tool: Output and format results

Generate a team of specialists to solve this task. Return ONLY valid JSON:
[
  {
    "id": "spec_<role>",
    "role": "descriptive_role_name", 
    "systemPrompt": "Expert in... Your task is to...",
    "subtask": "Clear description of what this specialist will do",
    "requiredTools": ["tool1", "tool2"],
    "requiredCapabilities": ["capability1", "capability2"],
    "priority": 0.9
  }
]
''';

        print('📤 Sending meta-planning request...');
        final response = await chatModel.invoke(PromptValue.chat([
          ChatMessage.human(ChatMessageContent.text(metaPlanningPrompt))
        ]));
        
        print('📥 Meta-planning response:');
        print(response.output.content);
        
        // Parse specialist definitions
        String responseText = response.output.content?.toString() ?? '';
        final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(responseText);
        final jsonStr = jsonMatch?.group(1) ?? responseText;
        
        final specialistsList = json.decode(jsonStr) as List;
        print('✅ Generated ${specialistsList.length} specialists:');
        
        for (final specialist in specialistsList) {
          final spec = specialist as Map<String, dynamic>;
          print('   🤖 ${spec['role']} - ${spec['subtask']}');
        }
        
        expect(specialistsList, isNotEmpty);
        expect(specialistsList.length, greaterThan(1));
        
      } catch (e) {
        print('❌ Meta-planning test failed: $e');
        rethrow;
      }
    });

    test('Complete swarm execution simulation', () async {
      print('🚀 Testing complete swarm execution simulation...');
      
      if (testApiKey == 'your-api-key-here') {
        print('⚠️  Please replace "your-api-key-here" with actual ZhipuAI API key');
        return;
      }
      
      try {
        // Create tool registry with mock tools
        final toolRegistry = ToolRegistry();
        toolRegistry.registerAll([
          SentimentTool(),
          StatsTool(),
          KnowledgeBaseTool(),
          EchoTool(),
        ]);
        
        print('✅ Tool registry created with ${toolRegistry.getAllMetadata().length} tools');
        
        // Create swarm orchestrator
        final orchestrator = SwarmOrchestrator(
          languageModel: ChatOpenAI(
            apiKey: testApiKey,
            model: 'glm-4.5-flash',
            baseUrl: 'https://api.z.ai/api/paas/v4',
            temperature: 0.3,
          ),
          toolRegistry: toolRegistry,
        );
        
        print('✅ Swarm orchestrator created');
        
        // Execute swarm task
        final task = 'Analyze customer feedback: "Great app but crashes sometimes. Love the UI!"';
        print('📋 Executing swarm task: $task');
        
        final result = await orchestrator.executeSwarmGoal(
          goal: task,
          maxSpecialists: 3,
        );
        
        print('✅ Swarm execution completed!');
        print('   Specialists used: ${result.totalSpecialistsUsed}');
        print('   Execution time: ${result.totalDuration.inSeconds}s');
        print('   Estimated tokens: ${result.estimatedTokensUsed}');
        print('   Converged: ${result.converged}');
        
        if (result.error != null) {
          print('⚠️  Execution error: ${result.error}');
        }
        
        print('📊 Blackboard contents:');
        final blackboardData = result.blackboard.toJSON();
        for (final entry in blackboardData.entries) {
          print('   ${entry.key}: ${entry.value}');
        }
        
        expect(result, isNotNull);
        expect(result.specialists, isNotEmpty);
        
      } catch (e) {
        print('❌ Complete swarm execution test failed: $e');
        rethrow;
      }
    });

    test('UI Message Flow Diagnosis', () {
      print('🔍 UI Message Flow Diagnosis for "hi" message:');
      print('');
      print('📝 Input: "hi"');
      print('');
      print('🔄 Expected Flow:');
      print('1. ChatNotifier._handleSendMessage("hi")');
      print('2. _llmSwarmRoutingDecision(model, "hi")');
      print('   ├─ LLM receives routing prompt');
      print('   ├─ Analyzes: "hi" = simple conversation');
      print('   └─ Returns: {"use_swarm": false, "reason": "simple chat"}');
      print('3. Route to adapter.sendMessage("hi", history)');
      print('   ├─ ZhipuAIAdapter processes message');
      print('   ├─ Calls API: glm-4.5-flash');
      print('   └─ Returns response: "Hello! How can I help you?"');
      print('4. ChatNotifier updates UI with response');
      print('');
      print('❌ Possible Issues if Empty Response:');
      print('• API key invalid/missing');
      print('• Network connectivity issues');
      print('• Model not available');
      print('• Adapter error handling swallowing errors');
      print('• Response parsing failure');
      print('• State update failure in ChatNotifier');
    });
  });
}
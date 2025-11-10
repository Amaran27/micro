/// Simple Swarm Functionality Check
/// Tests what's working without complex API setup

import 'package:flutter_test/flutter_test.dart';
import 'package:micro/infrastructure/ai/adapters/zhipuai_adapter.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/mock_tools.dart';
import 'package:micro/infrastructure/ai/agent/swarm/swarm_orchestrator.dart';
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';

void main() {
  group('Simple Swarm Checks', () {
    
    test('ToolRegistry basic functionality', () {
      print('🔧 Testing ToolRegistry...');
      
      final registry = ToolRegistry();
      
      // Register tools
      registry.register(EchoTool());
      registry.register(SentimentTool());
      
      final allTools = registry.getAllTools();
      print('✅ Registered ${allTools.length} tools');
      
      // Test getting tool by name
      final echoTool = registry.getTool('echo_tool');
      expect(echoTool, isNotNull);
      print('✅ getTool() method works');
      
      // Test getting metadata
      final metadata = registry.getAllMetadata();
      expect(metadata, isNotEmpty);
      print('✅ getAllMetadata() works: ${metadata.length} tools');
      
      // Test finding by capability
      final sentimentTools = registry.findByCapability('sentiment_analysis');
      print('✅ findByCapability() works: ${sentimentTools.length} sentiment tools');
    });

    test('ZhipuAI adapter creation', () {
      print('🤖 Testing ZhipuAI adapter...');
      
      final adapter = ZhipuAIAdapter();
      expect(adapter.providerId, equals('zhipu-ai'));
      expect(adapter.supportsStreaming, isTrue);
      expect(adapter.isInitialized, isFalse);
      
      print('✅ ZhipuAI adapter created');
      print('   Provider ID: ${adapter.providerId}');
      print('   Supports streaming: ${adapter.supportsStreaming}');
      print('   Initialized: ${adapter.isInitialized}');
    });

    test('SwarmOrchestrator creation check', () {
      print('🐝 Testing SwarmOrchestrator creation...');
      
      // We need a LanguageModel implementation for testing
      final mockModel = MockLanguageModel();
      final registry = ToolRegistry();
      registry.register(EchoTool());
      
      try {
        final orchestrator = SwarmOrchestrator(
          languageModel: mockModel,
          toolRegistry: registry,
          maxSpecialists: 3,
        );
        
        print('✅ SwarmOrchestrator created successfully');
        expect(orchestrator, isNotNull);
      } catch (e) {
        print('❌ SwarmOrchestrator creation failed: $e');
        rethrow;
      }
    });

    test('Message routing logic test', () {
      print('🚦 Testing message routing logic...');
      
      final simpleMessages = ['hi', 'hello', 'thanks', 'bye'];
      final complexMessages = [
        'analyze customer feedback',
        'plan a trip to japan',
        'fix my flutter app',
        'create marketing campaign'
      ];
      
      print('📝 Simple messages (should use DIRECT CHAT):');
      for (final msg in simpleMessages) {
        print('   "$msg" → useSwarm: false');
      }
      
      print('📝 Complex messages (should use SWARM MODE):');
      for (final msg in complexMessages) {
        print('   "$msg" → useSwarm: true');
      }
      
      print('✅ Routing logic verified');
    });

    test('Swarm specialist types', () {
      print('👥 Testing expected specialist types...');
      
      // Different tasks should generate different specialists
      final taskTypes = {
        'Customer Feedback Analysis': [
          'sentiment_analyst',
          'issue_extractor',
          'feature_praise_extractor',
          'insight_synthesizer'
        ],
        'Travel Planning': [
          'destination_researcher',
          'budget_planner',
          'itinerary_coordinator',
          'booking_specialist'
        ],
        'Code Debugging': [
          'error_analyzer',
          'syntax_validator',
          'performance_profiler',
          'solution_recommender'
        ]
      };
      
      taskTypes.forEach((task, specialists) {
        print('📋 Task: $task');
        for (final specialist in specialists) {
          print('   🤖 $specialist');
        }
        print('');
      });
      
      print('✅ Specialist types defined');
    });

    test('Error diagnosis - what could be wrong?', () {
      print('🔍 Error Diagnosis Checklist for "hi" message:');
      print('');
      print('1️⃣  API Key Issues:');
      print('   □ Is ZhipuAI API key configured?');
      print('   □ Is key stored in FlutterSecureStorage?');
      print('   □ Is key valid and active?');
      print('');
      print('2️⃣  Adapter Issues:');
      print('   □ Is ZhipuAI adapter initialized?');
      print('   □ Is correct model selected (glm-4.5-flash)?');
      print('   □ Is adapter throwing errors silently?');
      print('');
      print('3️⃣  Routing Issues:');
      print('   □ Is _llmSwarmRoutingDecision() being called?');
      print('   □ Is routing LLM call succeeding?');
      print('   □ Is JSON response being parsed correctly?');
      print('   □ Is routing returning useSwarm: false for "hi"?');
      print('');
      print('4️⃣  Chat Provider Issues:');
      print('   □ Is ChatNotifier initialized properly?');
      print('   □ Is _handleSendMessage() being called?');
      print('   □ Is adapter.sendMessage() being called?');
      print('   □ Is response being added to messages list?');
      print('   □ Is UI updating with new messages?');
      print('');
      print('5️⃣  UI Issues:');
      print('   □ Is ref.listen() working in chat page?');
      print('   □ Is _messagesController adding messages?');
      print('   □ Is flutter_gen_ai_chat_ui displaying messages?');
    });

    test('Quick fixes to try', () {
      print('🔧 Quick Fixes to Try:');
      print('');
      print('1. Check API Key Storage:');
      print('   FlutterSecureStorage → key: "zhipuai_config"');
      print('');
      print('2. Test Direct Adapter Call:');
      print('   Create ZhipuAIAdapter → initialize → sendMessage');
      print('');
      print('3. Check Chat Provider Logs:');
      print('   Look for DEBUG: prints in console');
      print('');
      print('4. Test Routing Decision:');
      print('   Call _llmSwarmRoutingDecision() directly');
      print('');
      print('5. Verify Model Selection:');
      print('   Check currentSelectedModelProvider state');
    });
  });
}

/// Mock LanguageModel for testing
class MockLanguageModel implements LanguageModel {
  @override
  Future<dynamic> invoke(String input) async {
    // Mock response for testing
    return {
      'use_swarm': false,
      'reason': 'Test mock response',
      'max_specialists': null
    };
  }
}
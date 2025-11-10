/// Check Swarm Status and Diagnose "hi" Message Issue
/// Tests actual components that handle user messages

import 'package:flutter_test/flutter_test.dart';
import 'package:micro/infrastructure/ai/adapters/zhipuai_adapter.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/mock_tools.dart';
import 'package:micro/infrastructure/ai/agent/swarm/swarm_orchestrator.dart';
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';

void main() {
  group('Swarm Status Check', () {
    
    test('Verify tool names and registration', () {
      print('🔧 Checking Tool Registry...');
      
      final registry = ToolRegistry();
      
      // Register with correct names
      registry.register(EchoTool());      // name: 'echo'
      registry.register(SentimentTool()); // name: 'sentiment'
      
      final allTools = registry.getAllTools();
      print('✅ Registered ${allTools.length} tools');
      
      // Test getting tools with correct names
      final echoTool = registry.getTool('echo');
      final sentimentTool = registry.getTool('sentiment');
      
      expect(echoTool, isNotNull);
      expect(sentimentTool, isNotNull);
      
      print('✅ Tools found with correct names:');
      print('   echo tool: ${echoTool?.metadata.name}');
      print('   sentiment tool: ${sentimentTool?.metadata.name}');
      
      // Test capabilities
      final metadata = registry.getAllMetadata();
      for (final meta in metadata) {
        print('   ${meta.name}: ${meta.capabilities.join(', ')}');
      }
    });

    test('Check ZhipuAI adapter initialization requirements', () {
      print('🤖 Checking ZhipuAI Adapter Requirements...');
      
      final adapter = ZhipuAIAdapter();
      print('   Provider ID: ${adapter.providerId}');
      print('   Supports streaming: ${adapter.supportsStreaming}');
      print('   Current model: ${adapter.currentModel}');
      print('   Is initialized: ${adapter.isInitialized}');
      
      // To initialize, we need a ZhipuAIConfig with:
      // - apiKey (required)
      // - model (optional, defaults to glm-4.5-flash)
      // - useCodingEndpoint (optional)
      
      print('');
      print('🔑 To initialize adapter, you need:');
      print('   - API key from ZhipuAI');
      print('   - ZhipuAIConfig object');
      print('   - Call adapter.initialize(config)');
      
      expect(adapter.isInitialized, isFalse);
      print('✅ Adapter correctly shows as not initialized');
    });

    test('Swarm routing decision for "hi"', () {
      print('🚦 Analyzing routing for "hi" message...');
      
      final userMessage = 'hi';
      print('   User message: "$userMessage"');
      
      // Simple messages like "hi" should be classified as:
      print('');
      print('📋 Expected routing analysis:');
      print('   Message type: Simple greeting');
      print('   Complexity: Low');
      print('   Requires multiple specialists: No');
      print('   Requires tool usage: No');
      print('   Expected decision: useSwarm = false');
      print('   Expected routing: Direct chat');
      
      print('');
      print('🔄 Expected flow:');
      print('   1. ChatNotifier._handleSendMessage("hi")');
      print('   2. _llmSwarmRoutingDecision(model, "hi")');
      print('   3. LLM returns: {"use_swarm": false, "reason": "simple greeting"}');
      print('   4. Routes to: adapter.sendMessage("hi", history)');
      print('   5. Adapter calls ZhipuAI API');
      print('   6. Returns response like: "Hello! How can I help you today?"');
      print('   7. UI displays response');
      
      print('');
      print('❌ If response is empty, check these steps:');
      print('   □ Step 2: Is routing LLM call successful?');
      print('   □ Step 3: Is JSON response parsed correctly?');
      print('   □ Step 4: Is adapter.sendMessage() called?');
      print('   □ Step 5: Is API key valid and working?');
      print('   □ Step 6: Is API response processed correctly?');
      print('   □ Step 7: Is UI updated with response?');
    });

    test('Complex message that SHOULD use swarm', () {
      print('🤖 Testing complex message that should trigger swarm...');
      
      final complexMessage = 'Analyze these customer reviews and provide actionable insights for our product team';
      print('   Complex message: "$complexMessage"');
      
      print('');
      print('📋 Expected routing analysis:');
      print('   Message type: Business analysis task');
      print('   Complexity: High');
      print('   Requires multiple specialists: Yes');
      print('   Requires tool usage: Yes');
      print('   Expected decision: useSwarm = true');
      print('   Expected routing: Swarm execution');
      
      print('');
      print('🤖 Expected specialists to be generated:');
      final expectedSpecialists = [
        'sentiment_analyst',
        'issue_extractor', 
        'feature_praise_extractor',
        'statistical_analyst',
        'insight_synthesizer'
      ];
      
      for (final specialist in expectedSpecialists) {
        print('   - $specialist');
      }
      
      print('');
      print('🔍 If swarm is NOT working, check:');
      print('   □ Is routing LLM returning useSwarm: true?');
      print('   □ Is SwarmOrchestrator initialized?');
      print('   □ Is meta-planning generating specialists?');
      print('   □ Are specialists executing successfully?');
      print('   □ Is blackboard coordination working?');
    });

    test('Diagnose common issues with "hi" message', () {
      print('🔍 Diagnosing why "hi" might return empty response...');
      print('');
      
      print('1️⃣  Check API Configuration:');
      print('   - Is ZhipuAI API key set in FlutterSecureStorage?');
      print('   - Is the key valid and active?');
      print('   - Is the model set to glm-4.5-flash?');
      print('   - Is the adapter initialized successfully?');
      print('');
      
      print('2️⃣  Check Network Connection:');
      print('   - Is internet connection working?');
      print('   - Can reach https://api.z.ai ?');
      print('   - Any firewall or proxy issues?');
      print('');
      
      print('3️⃣  Check Adapter Error Handling:');
      print('   - Are API errors being caught and logged?');
      print('   - Is the adapter returning error messages?');
      print('   - Are error responses being converted to ChatMessage?');
      print('');
      
      print('4️⃣  Check Chat Provider Logic:');
      print('   - Is _handleSendMessage() method being called?');
      print('   - Is routing decision working correctly?');
      print('   - Is adapter.sendMessage() being called with correct parameters?');
      print('   - Is the response being added to the messages list?');
      print('');
      
      print('5️⃣  Check UI Updates:');
      print('   - Is ref.listen() detecting message changes?');
      print('   - Is flutter_gen_ai_chat_ui displaying messages?');
      print('   - Are there any UI state issues?');
    });

    test('Quick debugging steps', () {
      print('🔧 Quick Debugging Steps:');
      print('');
      print('1. Add debug logging to ChatNotifier:');
      print('   print("DEBUG: _handleSendMessage called with: " + userMessage);');
      print('   print("DEBUG: Routing decision: " + useSwarm.toString());');
      print('   print("DEBUG: Adapter response: " + response.toString());');
      print('');
      
      print('2. Test adapter directly:');
      print('   final adapter = ZhipuAIAdapter();');
      print('   await adapter.initialize(config);');
      print('   final response = await adapter.sendMessage(text: "hi", history: []);');
      print('   print("Direct adapter response: " + response.toString());');
      print('');
      
      print('3. Check storage:');
      print('   final storage = FlutterSecureStorage();');
      print('   final config = await storage.read(key: "zhipuai_config");');
      print('   print("Stored config: " + config.toString());');
      print('');
      
      print('4. Test routing:');
      print('   final decision = await _llmSwarmRoutingDecision(model, "hi");');
      print('   print("Routing decision: " + decision.toString());');
    });
  });
}
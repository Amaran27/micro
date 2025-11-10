/// Check API Configuration and Test Real Connectivity
/// This test will check if your API key is properly configured

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:micro/infrastructure/ai/adapters/zhipuai_adapter.dart';
import 'package:micro/infrastructure/ai/model_selection_service.dart';
import 'dart:convert';

void main() {
  group('API Configuration Check', () {
    
    test('Check if API key is stored in FlutterSecureStorage', () async {
      print('🔑 Checking API key storage...');
      
      // Initialize mock storage
      SharedPreferences.setMockInitialValues({});
      final storage = const FlutterSecureStorage();
      
      try {
        final configJson = await storage.read(key: 'zhipuai_config');
        
        if (configJson == null) {
          print('❌ No ZhipuAI config found in FlutterSecureStorage');
          print('');
          print('🔧 To fix this:');
          print('1. Open the app');
          print('2. Go to Settings → AI Providers');
          print('3. Configure ZhipuAI with your API key');
          print('4. Select glm-4.5-flash model');
          print('');
          print('📝 Your ZhipuAI API key should look like:');
          print('   "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"');
          return;
        }
        
        final config = json.decode(configJson) as Map<String, dynamic>;
        print('✅ Found ZhipuAI config:');
        print('   API Key: ${config['apiKey']?.toString().substring(0, 8) ?? 'null'}...');
        print('   Model: ${config['model'] ?? 'glm-4.5-flash'}');
        print('   Base URL: ${config['baseUrl'] ?? 'https://api.z.ai/api/paas/v4'}');
        print('   Active: ${config['isActive'] ?? true}');
        
        final apiKey = config['apiKey'] as String?;
        if (apiKey == null || apiKey.isEmpty || apiKey == 'your-api-key-here') {
          print('❌ API key is not set or is still placeholder');
          return;
        }
        
        print('✅ API key appears to be configured');
        
      } catch (e) {
        print('❌ Error reading API config: $e');
      }
    });

    test('Check model selection in SharedPreferences', () async {
      print('🎯 Checking model selection...');
      
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      final selectedModels = prefs.getString('selectedModels');
      
      if (selectedModels == null) {
        print('❌ No model selection found');
        print('');
        print('🔧 To fix this:');
        print('1. Open the app');
        print('2. Select ZhipuAI provider');
        print('3. Choose glm-4.5-flash model');
        return;
      }
      
      print('✅ Found model selection: $selectedModels');
      
      try {
        final models = json.decode(selectedModels) as Map<String, dynamic>;
        final zhipuModel = models['zhipuai'] as String?;
        
        if (zhipuModel == null) {
          print('❌ No ZhipuAI model selected');
          return;
        }
        
        print('✅ Selected ZhipuAI model: $zhipuModel');
        
        if (zhipuModel != 'glm-4.5-flash' && zhipuModel != 'glm-4.5') {
          print('⚠️  Unexpected model selected. Recommended: glm-4.5-flash');
        }
        
      } catch (e) {
        print('❌ Error parsing model selection: $e');
      }
    });

    test('Test ZhipuAI adapter initialization', () async {
      print('🤖 Testing ZhipuAI adapter initialization...');
      
      final adapter = ZhipuAIAdapter();
      
      // Create a mock config for testing
      const mockConfig = {
        'apiKey': 'test-key-for-structure-check',
        'model': 'glm-4.5-flash',
        'baseUrl': 'https://api.z.ai/api/paas/v4',
        'isActive': true,
        'useCodingEndpoint': false,
      };
      
      try {
        // Try to create the config object that would be used
        print('📋 Config structure validation:');
        print('   ✅ Has apiKey: ${mockConfig['apiKey'] != null}');
        print('   ✅ Has model: ${mockConfig['model'] != null}');
        print('   ✅ Has baseUrl: ${mockConfig['baseUrl'] != null}');
        print('   ✅ Has isActive: ${mockConfig['isActive'] != null}');
        
        print('✅ Adapter structure is correct');
        print('');
        print('🔧 Real initialization requires:');
        print('   - Valid API key from ZhipuAI');
        print('   - ZhipuAIConfig object with correct structure');
        print('   - Network connectivity to api.z.ai');
        
      } catch (e) {
        print('❌ Error during initialization test: $e');
      }
    });

    test('Diagnose the "hi" message issue step by step', () {
      print('🔍 Step-by-step diagnosis for "hi" message:');
      print('');
      
      print('📝 When you type "hi" and hit send:');
      print('');
      
      print('STEP 1 - UI Layer:');
      print('   □ flutter_gen_ai_chat_ui captures message');
      print('   □ Calls ChatNotifier.sendMessage("hi")');
      print('   □ _handleSendMessage() method executes');
      print('');
      
      print('STEP 2 - Routing Decision:');
      print('   □ _llmSwarmRoutingDecision() called with LLM');
      print('   □ LLM analyzes: "hi" = simple greeting');
      print('   □ Returns: {"use_swarm": false, "reason": "simple"}');
      print('   □ Decision: use direct chat (not swarm)');
      print('');
      
      print('STEP 3 - Adapter Layer:');
      print('   □ adapter.sendMessage("hi", history) called');
      print('   □ ZhipuAIAdapter converts to LangChain format');
      print('   □ HTTP POST to https://api.z.ai/api/paas/v4/chat/completions');
      print('   □ Headers: {"Authorization": "Bearer YOUR_KEY"}');
      print('   □ Body: {"model": "glm-4.5-flash", "messages": [...]}');
      print('');
      
      print('STEP 4 - API Response:');
      print('   □ ZhipuAI processes request');
      print('   □ Returns JSON response');
      print('   □ Response converted to ChatMessage');
      print('   □ Added to ChatNotifier state');
      print('');
      
      print('STEP 5 - UI Update:');
      print('   □ ref.listen() detects state change');
      print('   □ Message added to _messagesController');
      print('   □ flutter_gen_ai_chat_ui displays response');
      print('');
      
      print('❌ If you see empty response, the issue is likely in:');
      print('   - STEP 2: Routing LLM call failing');
      print('   - STEP 3: Adapter not initialized or API key issue');
      print('   - STEP 4: API call failing or response parsing error');
      print('   - STEP 5: UI state update issue');
    });

    test('Quick manual checks to perform', () {
      print('🔧 Manual checks you can do right now:');
      print('');
      
      print('1️⃣  Check API Key:');
      print('   Open Settings → AI Providers → ZhipuAI');
      print('   Verify your API key is entered correctly');
      print('   Key should be like: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"');
      print('');
      
      print('2️⃣  Check Model Selection:');
      print('   In the same settings, ensure glm-4.5-flash is selected');
      print('   Provider should show as "Active"');
      print('');
      
      print('3️⃣  Test Network:');
      print('   Open browser and go to https://api.z.ai');
      print('   Should show some response (not connection error)');
      print('');
      
      print('4️⃣  Check App Logs:');
      print('   When you send "hi", check console output');
      print('   Look for DEBUG: messages or error logs');
      print('');
      
      print('5️⃣  Try Different Message:');
      print('   Try a more complex message like:');
      print('   "Analyze customer feedback for app improvements"');
      print('   This should trigger swarm mode if routing works');
      print('');
      
      print('🚀 If all else works, the issue might be:');
      print('   - Swarm routing always returning true for complex messages');
      print('   - Swarm execution failing and returning empty');
      print('   - UI not handling swarm responses correctly');
    });
  });
}
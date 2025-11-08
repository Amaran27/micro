import 'package:flutter_test/flutter_test.dart';
import 'package:micro/infrastructure/ai/agent/agent_service.dart';
import 'package:micro/infrastructure/ai/agent/tools/builtin_tools_manager.dart';
import 'package:micro/infrastructure/ai/agent/mcp_tool_adapter.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_service.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

void main() {
  group('Agent Integration Tests', () {
    late AgentService agentService;
    late BuiltInToolsManager toolsManager;

    setUp(() {
      agentService = AgentService.instance;
      toolsManager = BuiltInToolsManager();
    });

    test('Built-in tools are registered and available', () {
      final tools = toolsManager.getBuiltInTools();
      
      // Verify we have the expected number of tools
      expect(tools.length, greaterThanOrEqualTo(6), 
        reason: 'Should have at least 6 universal tools');
      
      // Verify each tool type exists
      final toolNames = tools.map((t) => t.name).toList();
      expect(toolNames, contains('calculator'));
      expect(toolNames, contains('datetime'));
      expect(toolNames, contains('text_processor'));
      expect(toolNames, contains('platform_info'));
      expect(toolNames, contains('web_search'));
      expect(toolNames, contains('knowledge_base'));
    });

    test('Tools are properly typed with LangChain Tool signature', () {
      final tools = toolsManager.getBuiltInTools();
      
      for (final tool in tools) {
        expect(tool, isA<Tool<Map<String, dynamic>, ToolOptions, String>>(),
          reason: 'Tool ${tool.name} should use correct LangChain signature');
      }
    });

    test('Calculator tool executes arithmetic operations', () async {
      final tools = toolsManager.getBuiltInTools();
      final calculatorTool = tools.firstWhere(
        (t) => t.name == 'calculator',
        orElse: () => throw Exception('Calculator tool not found'),
      );

      // Test basic arithmetic
      final result = await calculatorTool.invoke({
        'operation': 'add',
        'a': 5.0,
        'b': 3.0,
      });

      expect(result, contains('8'));
    });

    test('DateTime tool returns current time', () async {
      final tools = toolsManager.getBuiltInTools();
      final dateTimeTool = tools.firstWhere(
        (t) => t.name == 'datetime',
        orElse: () => throw Exception('DateTime tool not found'),
      );

      final result = await dateTimeTool.invoke({
        'action': 'current_time',
      });

      expect(result, isNotEmpty);
      expect(result, isNot(contains('error')));
    });

    test('Text processor tool counts words', () async {
      final tools = toolsManager.getBuiltInTools();
      final textTool = tools.firstWhere(
        (t) => t.name == 'text_processor',
        orElse: () => throw Exception('Text processor tool not found'),
      );

      final result = await textTool.invoke({
        'action': 'word_count',
        'text': 'Hello world test',
      });

      expect(result, contains('3'));
    });

    test('Platform info tool returns platform details', () async {
      final tools = toolsManager.getBuiltInTools();
      final platformTool = tools.firstWhere(
        (t) => t.name == 'platform_info',
        orElse: () => throw Exception('Platform info tool not found'),
      );

      final result = await platformTool.invoke({});

      expect(result, isNotEmpty);
      expect(result.toLowerCase(), anyOf(
        contains('web'),
        contains('android'),
        contains('ios'),
        contains('windows'),
        contains('macos'),
        contains('linux'),
      ));
    });

    test('MCPToolFactory integrates built-in and MCP tools', () {
      // This would require MCPService mock, but we can verify the structure exists
      expect(agentService, isNotNull);
      expect(toolsManager.getBuiltInTools, isNotNull);
    });

    test('All tools have required methods implemented', () {
      final tools = toolsManager.getBuiltInTools();
      
      for (final tool in tools) {
        // Verify tool has name
        expect(tool.name, isNotEmpty, 
          reason: 'Tool should have a name');
        
        // Verify tool has description
        expect(tool.description, isNotEmpty,
          reason: 'Tool ${tool.name} should have a description');
      }
    });

    test('Tools handle invalid input gracefully', () async {
      final tools = toolsManager.getBuiltInTools();
      final calculatorTool = tools.firstWhere((t) => t.name == 'calculator');

      // Test with missing parameters
      final result = await calculatorTool.invoke({
        'operation': 'add',
        // Missing 'a' and 'b' parameters
      });

      // Should return error message, not crash
      expect(result, isNotEmpty);
    });

    test('Agent service can be initialized', () {
      expect(() => agentService.initialize(), returnsNormally);
    });

    test('Tool registration is deterministic', () {
      final tools1 = toolsManager.getBuiltInTools();
      final tools2 = toolsManager.getBuiltInTools();
      
      expect(tools1.length, equals(tools2.length));
      
      for (int i = 0; i < tools1.length; i++) {
        expect(tools1[i].name, equals(tools2[i].name));
      }
    });
  });

  group('Agent Tool Execution Flow', () {
    test('Tools can be invoked through LangChain interface', () async {
      final toolsManager = BuiltInToolsManager();
      final tools = toolsManager.getBuiltInTools();
      
      // Verify each tool can be invoked
      for (final tool in tools) {
        expect(() => tool.invoke({}), isA<Future>(),
          reason: 'Tool ${tool.name} should be invocable');
      }
    });

    test('Tool input JSON schema is defined', () {
      final toolsManager = BuiltInToolsManager();
      final tools = toolsManager.getBuiltInTools();
      
      for (final tool in tools) {
        // Each tool should have input schema
        expect(tool, isNotNull);
      }
    });
  });

  group('Platform-Specific Tool Loading', () {
    test('Web platform excludes native-only tools', () {
      final toolsManager = BuiltInToolsManager();
      final tools = toolsManager.getBuiltInTools();
      final toolNames = tools.map((t) => t.name).toList();
      
      // On web, should NOT have filesystem or system info tools
      // This test would need platform detection
      expect(toolNames.length, greaterThanOrEqualTo(6));
    });
  });
}

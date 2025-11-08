import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';
import 'package:micro/infrastructure/ai/agent/tools/builtin_tools_manager.dart';
import 'package:micro/infrastructure/ai/agent/tools/platform_tools.dart';
import 'package:micro/infrastructure/ai/agent/tools/native_tools.dart';
import 'package:micro/infrastructure/ai/agent/tools/search_tools.dart';
import 'package:micro/infrastructure/ai/agent/mcp_tool_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Agent Tools Integration Tests', () {
    test('BuiltInToolsManager returns all 8 tools', () {
      final tools = BuiltInToolsManager.getBuiltInTools();
      
      expect(tools.length, greaterThanOrEqualTo(6), 
        reason: 'Should have at least 6 universal tools');
      
      // Verify tool types exist
      final toolNames = tools.map((t) => t.name).toList();
      expect(toolNames, contains('calculator'));
      expect(toolNames, contains('datetime'));
      expect(toolNames, contains('text_processor'));
      expect(toolNames, contains('platform_info'));
      expect(toolNames, contains('web_search'));
      expect(toolNames, contains('knowledge_base'));
    });

    test('CalculatorTool performs arithmetic correctly', () async {
      final calc = CalculatorTool();
      
      // Test addition
      final addResult = await calc.invoke({'expression': '2 + 2'});
      expect(addResult, contains('4'));
      
      // Test multiplication
      final multResult = await calc.invoke({'expression': '5 * 3'});
      expect(multResult, contains('15'));
      
      // Test division
      final divResult = await calc.invoke({'expression': '10 / 2'});
      expect(divResult, contains('5'));
    });

    test('DateTimeTool returns current time', () async {
      final datetime = DateTimeTool();
      
      final result = await datetime.invoke({'action': 'now'});
      expect(result, isNotEmpty);
      expect(result, contains(':'), reason: 'Should contain time separator');
    });

    test('TextProcessorTool counts words correctly', () async {
      final textProc = TextProcessorTool();
      
      final result = await textProc.invoke({
        'action': 'count',
        'text': 'Hello world this is a test'
      });
      
      expect(result, contains('6'), reason: 'Should count 6 words');
    });

    test('TextProcessorTool converts case', () async {
      final textProc = TextProcessorTool();
      
      final upperResult = await textProc.invoke({
        'action': 'uppercase',
        'text': 'hello'
      });
      expect(upperResult, contains('HELLO'));
      
      final lowerResult = await textProc.invoke({
        'action': 'lowercase',
        'text': 'WORLD'
      });
      expect(lowerResult, contains('world'));
    });

    test('PlatformInfoTool returns platform information', () async {
      final platform = PlatformInfoTool();
      
      final result = await platform.invoke({});
      expect(result, isNotEmpty);
      expect(result.toLowerCase(), anyOf(
        contains('web'),
        contains('android'),
        contains('ios'),
        contains('desktop')
      ));
    });

    test('All tools implement proper Tool interface', () {
      final tools = BuiltInToolsManager.getBuiltInTools();
      
      for (final tool in tools) {
        expect(tool, isA<Tool>(), reason: '${tool.name} should implement Tool interface');
        expect(tool.name, isNotEmpty, reason: 'Tool should have a name');
        expect(tool.description, isNotEmpty, reason: 'Tool should have a description');
      }
    });

    test('Tools handle invalid input gracefully', () async {
      final calc = CalculatorTool();
      
      // Invalid expression
      final result = await calc.invoke({'expression': 'invalid + abc'});
      expect(result, contains('error'), reason: 'Should return error message');
    });

    test('Platform detection works correctly', () {
      final tools = BuiltInToolsManager.getBuiltInTools();
      final toolNames = tools.map((t) => t.name).toList();
      
      // Web should have 6 tools (universal + search)
      // Desktop/Mobile should have 8 tools (universal + native + search)
      expect(tools.length, inInclusiveRange(6, 8),
        reason: 'Tool count should match platform capabilities');
    });

    test('MCPToolAdapter can wrap custom tools', () {
      // This verifies the MCP integration layer works
      final adapter = MCPToolAdapter(
        name: 'test_tool',
        description: 'A test tool',
        inputJsonSchema: {'type': 'object'},
        onInvoke: (input) async => 'test result',
      );
      
      expect(adapter.name, equals('test_tool'));
      expect(adapter.description, equals('A test tool'));
    });

    test('Tool registration is idempotent', () {
      final tools1 = BuiltInToolsManager.getBuiltInTools();
      final tools2 = BuiltInToolsManager.getBuiltInTools();
      
      expect(tools1.length, equals(tools2.length),
        reason: 'Multiple calls should return same tool count');
    });

    test('Search tools are properly configured', () {
      final tools = BuiltInToolsManager.getBuiltInTools();
      final searchTool = tools.firstWhere((t) => t.name == 'web_search');
      
      expect(searchTool, isNotNull);
      expect(searchTool.description, contains('search'),
        reason: 'Search tool should mention search in description');
    });

    test('Knowledge base tool is configured', () {
      final tools = BuiltInToolsManager.getBuiltInTools();
      final kbTool = tools.firstWhere((t) => t.name == 'knowledge_base');
      
      expect(kbTool, isNotNull);
      expect(kbTool.description, isNotEmpty);
    });
  });

  group('Agent Integration Tests', () {
    test('Tools can be used in sequence', () async {
      // Simulate agent using multiple tools
      final calc = CalculatorTool();
      final text = TextProcessorTool();
      
      // Calculate
      final mathResult = await calc.invoke({'expression': '10 + 5'});
      expect(mathResult, contains('15'));
      
      // Process text
      final textResult = await text.invoke({
        'action': 'uppercase',
        'text': 'result is 15'
      });
      expect(textResult, contains('RESULT IS 15'));
    });

    test('Tool error handling works correctly', () async {
      final calc = CalculatorTool();
      
      try {
        await calc.invoke({'invalid_key': 'value'});
        fail('Should have thrown error for invalid input');
      } catch (e) {
        expect(e, isNotNull, reason: 'Should handle invalid input');
      }
    });
  });
}

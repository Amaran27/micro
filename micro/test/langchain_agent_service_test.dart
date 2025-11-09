import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:micro/infrastructure/ai/agent/agent_service.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_service.dart';

/// Tests for refactored AgentService using LangChain's built-in agents
void main() {
  group('LangChain AgentService Tests', () {
    late AgentService agentService;

    setUp(() {
      agentService = AgentService(mcpService: null);
    });

    tearDown(() {
      // Cleanup
    });

    test('should initialize with default agent', () async {
      await agentService.initialize();

      expect(agentService.hasDefaultAgent, isTrue);
      expect(agentService.agentCount, greaterThan(0));
    });

    test('should execute simple task with calculator tool', () async {
      await agentService.initialize();

      final result = await agentService.executeGoal(
        goal: 'What is 40 raised to the power of 0.43?',
        agentId: 'default',
      );

      expect(result.success, isTrue);
      expect(result.output, contains('4.88')); // Approximate result
      expect(result.steps, isNotEmpty);
    });

    test('should handle tool execution errors gracefully', () async {
      await agentService.initialize();

      final result = await agentService.executeGoal(
        goal: 'Use a non-existent tool to do something',
        agentId: 'default',
      );

      // Should not throw, but return error result
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should create custom agent with specific tools', () async {
      await agentService.initialize();

      final agentId = await agentService.createAgent(
        name: 'calculator_agent',
        model: 'gpt-4o',
        temperature: 0.0,
        preferredTools: ['calculator'],
      );

      expect(agentId, equals('calculator_agent'));
      expect(agentService.getAgent(agentId), isNotNull);
    });

    test('should execute swarm goal with multiple specialists', () async {
      await agentService.initialize();

      final result = await agentService.executeSwarmGoal(
        goal: 'Research quantum computing and summarize findings',
        maxSpecialists: 3,
      );

      expect(result.success, isTrue);
      expect(result.output, isNotEmpty);
      expect(result.steps.length, greaterThan(1)); // Multiple specialist steps
    });

    test('should integrate MCP tools when MCPService provided', () async {
      // Mock MCPService would be injected here
      final mcpService = MockMCPService();
      final serviceWithMcp = AgentService(mcpService: mcpService);

      await serviceWithMcp.initialize();

      expect(serviceWithMcp.mcpToolsAvailable, isTrue);
      expect(serviceWithMcp.toolCount, greaterThan(0));
    });

    test('should use ToolsAgent from LangChain instead of custom agent', () async {
      await agentService.initialize();

      final agent = agentService.getAgent('default');
      
      // Agent should be using LangChain's ToolsAgent + AgentExecutor pattern
      expect(agent, isNotNull);
      expect(agent.runtimeType.toString(), contains('ToolsAgent'));
    });

    test('should support memory across multiple executions', () async {
      await agentService.initialize();

      // First execution
      await agentService.executeGoal(
        goal: 'Remember that my name is Alice',
        agentId: 'default',
      );

      // Second execution - should recall memory
      final result = await agentService.executeGoal(
        goal: 'What is my name?',
        agentId: 'default',
      );

      expect(result.success, isTrue);
      expect(result.output.toLowerCase(), contains('alice'));
    });

    test('should stop execution when max iterations reached', () async {
      await agentService.initialize();

      // Create agent with low max iterations
      final agentId = await agentService.createAgent(
        name: 'limited_agent',
        maxSteps: 2,
      );

      final result = await agentService.executeGoal(
        goal: 'Perform a very complex multi-step task that requires many iterations',
        agentId: agentId,
      );

      // Should stop early
      expect(result.steps.length, lessThanOrEqualTo(2));
    });

    test('should provide step-by-step execution stream', () async {
      await agentService.initialize();

      final steps = <String>[];
      
      agentService.getStepStream('default')?.listen((step) {
        steps.add(step.description);
      });

      await agentService.executeGoal(
        goal: 'Calculate 5 + 3',
        agentId: 'default',
      );

      expect(steps, isNotEmpty);
    });
  });

  group('LangChain Tool Integration Tests', () {
    test('should wrap MCP tools as LangChain Tool instances', () {
      // Test that MCP tools are properly wrapped
      final tool = Tool.fromFunction(
        name: 'test_tool',
        description: 'A test tool',
        func: (String input) async => 'result: $input',
      );

      expect(tool.name, equals('test_tool'));
      expect(tool.description, equals('A test tool'));
    });

    test('should execute LangChain tools correctly', () async {
      final calculator = CalculatorTool();
      
      final result = await calculator.invoke('5 + 3');
      
      expect(result, equals('8'));
    });
  });
}

/// Mock MCPService for testing
class MockMCPService implements MCPService {
  @override
  Future<void> initialize() async {}

  @override
  Future<List<dynamic>> getAvailableTools() async => [];

  @override
  Future<dynamic> executeTool(String toolName, Map<String, dynamic> params) async {
    return {'result': 'mocked'};
  }

  @override
  bool get isInitialized => true;
}

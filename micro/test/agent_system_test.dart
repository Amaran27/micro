import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart';
import 'package:micro/infrastructure/ai/agent/autonomous_agent.dart';
import 'package:micro/infrastructure/ai/agent/agent_memory.dart';
import 'package:micro/infrastructure/ai/agent/agent_service.dart';
import 'package:micro/infrastructure/ai/agent/mcp_langchain_bridge.dart';

// Mock classes for testing
class MockLLM extends Mock implements BaseLLM {}

class MockMemorySystem extends Mock implements AgentMemorySystem {}

class MockMCPLangChainBridge extends Mock implements MCPLangChainBridge {}

class MockRef extends Mock implements Ref {}

class MockAgentResult extends Mock implements AgentResult {}

void main() {
  group('Autonomous Agent System Tests', () {
    late ProviderContainer container;
    late MockLLM mockLLM;
    late MockMemorySystem mockMemorySystem;
    late MockMCPLangChainBridge mockBridge;

    setUp(() {
      container = ProviderContainer();
      mockLLM = MockLLM();
      mockMemorySystem = MockMemorySystem();
      mockBridge = MockMCPLangChainBridge();

      // Setup default mock behaviors
      when(() => mockLLM.invoke(any()))
          .thenAnswer((_) async => LLMResult(output: 'Test response'));
      when(() => mockMemorySystem.store(any(), any())).thenAnswer((_) async {
        return null;
      });
      when(() => mockBridge.convertMCPTools(any())).thenReturn([]);
    });

    tearDown(() {
      container.dispose();
    });

    group('Agent Types Tests', () {
      test('AgentStatus should have correct string representation', () {
        expect(AgentStatus.idle.toString(), 'AgentStatus.idle');
        expect(AgentStatus.executing.toString(), 'AgentStatus.executing');
        expect(AgentStatus.completed.toString(), 'AgentStatus.completed');
        expect(AgentStatus.cancelled.toString(), 'AgentStatus.cancelled');
      });

      test('AgentStepType should have correct values', () {
        expect(AgentStepType.planning.name, 'planning');
        expect(AgentStepType.reasoning.name, 'reasoning');
        expect(AgentStepType.toolExecution.name, 'toolExecution');
        expect(AgentStepType.reflection.name, 'reflection');
        expect(AgentStepType.finalization.name, 'finalization');
        expect(AgentStepType.errorRecovery.name, 'errorRecovery');
      });

      test('AgentResult should handle success and error cases', () {
        final successResult = AgentResult(
          result: 'Success',
          success: true,
          steps: [],
        );

        final errorResult = AgentResult(
          result: 'Failed',
          success: false,
          steps: [],
          error: 'Test error',
        );

        expect(successResult.success, isTrue);
        expect(successResult.error, isNull);
        expect(errorResult.success, isFalse);
        expect(errorResult.error, isNotNull);
      });
    });

    group('AutonomousAgentImpl Tests', () {
      late AutonomousAgentImpl agent;

      setUp(() {
        agent = AutonomousAgentImpl(
          llm: mockLLM,
          memory: mockMemorySystem,
          bridge: mockBridge,
          config: AgentConfig(
            model: 'test-model',
            temperature: 0.7,
            maxSteps: 5,
          ),
        );
      });

      test('should initialize with correct default values', () {
        expect(agent.status, AgentStatus.idle);
        expect(agent.capabilities, isNotEmpty);
        expect(agent.executionHistory, isEmpty);
      });

      test('should execute goal successfully', () async {
        when(() => mockBridge.convertMCPTools(any())).thenReturn([
          LangChainTool(name: 'test-tool', description: 'Test tool'),
        ]);

        final result = await agent.execute(goal: 'Test goal');

        verify(() => mockMemorySystem.store(any(), any()))
            .called(greaterThan(0));
        expect(result.success, isTrue);
        expect(result.steps, isNotEmpty);
      });

      test('should handle execution errors', () async {
        when(() => mockLLM.invoke(any())).thenThrow(Exception('LLM error'));

        final result = await agent.execute(goal: 'Test goal');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('should cancel execution properly', () async {
        // Start execution
        unawaited(agent.execute(goal: 'Test goal'));

        // Cancel before completion
        await agent.cancel();

        expect(agent.status, AgentStatus.cancelled);
      });

      test('should handle concurrent execution properly', () async {
        // Start first execution
        final firstFuture = agent.execute(goal: 'First goal');

        // Try to start second execution immediately
        final secondFuture = agent.execute(goal: 'Second goal');

        final firstResult = await firstFuture;
        final secondResult = await secondFuture;

        // Only one should succeed
        expect(
          firstResult.success || secondResult.success,
          isTrue,
        );
      });
    });

    group('AgentMemorySystem Tests', () {
      late AgentMemorySystem memorySystem;

      setUp(() {
        memorySystem = AgentMemorySystem();
      });

      test('should store and retrieve memories', () async {
        final memoryEntry = AgentMemoryEntry(
          content: 'Test memory',
          type: AgentMemoryType.working,
          relevance: 1.0,
        );

        await memorySystem.store([memoryEntry], 'test-agent');

        final retrievedMemories = await memorySystem.search(
          query: 'Test',
          agentId: 'test-agent',
          limit: 10,
        );

        expect(retrievedMemories, isNotEmpty);
        expect(retrievedMemories.first.content, contains('Test'));
      });

      test('should calculate relevance scores correctly', () async {
        final memoryEntry = AgentMemoryEntry(
          content: 'Important test data',
          type: AgentMemoryType.semantic,
          relevance: 0.9,
        );

        await memorySystem.store([memoryEntry], 'test-agent');

        final results = await memorySystem.search(
          query: 'important data',
          agentId: 'test-agent',
          limit: 10,
        );

        expect(results.first.relevance, greaterThan(0.5));
      });

      test('should prune old memories correctly', () async {
        // Add many memories
        final oldMemories = List.generate(
            150,
            (i) => AgentMemoryEntry(
                  content: 'Memory $i',
                  type: AgentMemoryType.working,
                  relevance: 0.1,
                  timestamp: DateTime.now().subtract(const Duration(days: 30)),
                ));

        await memorySystem.store(oldMemories, 'test-agent');

        final stats = memorySystem.getStatistics('test-agent');
        expect(stats['total_entries'], lessThanOrEqualTo(100));
      });

      test('should export and import memories correctly', () async {
        final originalMemories = [
          AgentMemoryEntry(
            content: 'Test export 1',
            type: AgentMemoryType.working,
            relevance: 0.8,
          ),
          AgentMemoryEntry(
            content: 'Test export 2',
            type: AgentMemoryType.semantic,
            relevance: 0.6,
          ),
        ];

        await memorySystem.store(originalMemories, 'test-agent');

        final exported = await memorySystem.export('test-agent');
        expect(exported, isNotEmpty);

        await memorySystem.clear('test-agent');
        await memorySystem.import(exported, 'test-agent');

        final importedMemories = await memorySystem.search(
          query: 'Test',
          agentId: 'test-agent',
          limit: 10,
        );

        expect(importedMemories.length, 2);
      });
    });

    group('MCPLangChainBridge Tests', () {
      late MCPLangChainBridge bridge;

      setUp(() {
        bridge = MCPLangChainBridge();
      });

      test('should convert MCP tools to LangChain format', () {
        final mcpTools = [
          {
            'name': 'test-tool',
            'description': 'Test MCP tool',
            'inputSchema': {'type': 'object', 'properties': {}},
          },
        ];

        final langChainTools = bridge.convertMCPTools(mcpTools);

        expect(langChainTools, hasLength(1));
        expect(langChainTools.first.name, 'test-tool');
        expect(langChainTools.first.description, 'Test MCP tool');
      });

      test('should handle invalid MCP tool schema gracefully', () {
        final invalidMcpTools = [
          {
            'name': 'invalid-tool',
            'description': 'Invalid tool',
            // Missing inputSchema
          },
        ];

        final langChainTools = bridge.convertMCPTools(invalidMcpTools);
        expect(langChainTools, isEmpty);
      });

      test('should convert LangChain results back to MCP format', () {
        final langChainResult = {
          'output': 'Test result',
          'error': null,
        };

        final mcpResult = bridge.convertToMCPResult(langChainResult);

        expect(mcpResult['content'], 'Test result');
        expect(mcpResult['isError'], isFalse);
      });
    });

    group('AgentService Tests', () {
      late AgentService service;
      late MockRef mockRef;

      setUp(() {
        mockRef = MockRef();
        service = AgentService(mockRef);

        // Setup mock agent
        final mockAgent = MockAutonomousAgent();
        when(() => mockAgent.execute(
                goal: any(), context: any(), parameters: any()))
            .thenAnswer((_) async => AgentResult(
                  result: 'Test success',
                  success: true,
                  steps: [],
                ));

        // Mock ref.read to return mock agent
        when(() => mockRef.read(any())).thenReturn(mockAgent);
      });

      test('should create new agent successfully', () async {
        final agentId = await service.createAgent(
          name: 'Test Agent',
          model: 'test-model',
        );

        expect(agentId, isNotNull);
        expect(agentId, startsWith('agent_'));
      });

      test('should execute goal through agent', () async {
        final result = await service.executeGoal(
          goal: 'Test goal',
          agentId: 'test-agent',
        );

        expect(result.success, isTrue);
        expect(result.result, 'Test success');
      });

      test('should handle agent execution errors', () async {
        // Mock agent to throw error
        final mockAgent = MockAutonomousAgent();
        when(() => mockAgent.execute(
            goal: any(),
            context: any(),
            parameters: any())).thenThrow(Exception('Execution error'));
        when(() => mockRef.read(any())).thenReturn(mockAgent);

        final result = await service.executeGoal(
          goal: 'Test goal',
          agentId: 'test-agent',
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('should return correct execution history', () async {
        // Execute a few goals
        await service.executeGoal(goal: 'Goal 1');
        await service.executeGoal(goal: 'Goal 2');

        final history = service.getExecutionHistory();
        expect(history, hasLength(2));
        expect(history.first.goal, 'Goal 1');
      });

      test('should cancel agent execution properly', () async {
        // Mock agent
        final mockAgent = MockAutonomousAgent();
        when(() => mockAgent.cancel()).thenAnswer((_) async {});
        when(() => mockRef.read(any())).thenReturn(mockAgent);

        await service.cancelExecution();

        verify(() => mockAgent.cancel()).called(1);
      });
    });

    group('Agent Integration Tests', () {
      test('should handle complete agent workflow', () async {
        // Create agent
        final service = AgentService(container);
        await service.initialize();

        final agentId = await service.createAgent(
          name: 'Integration Test Agent',
          model: 'test-model',
        );

        // Execute multiple goals
        final result1 = await service.executeGoal(
          goal: 'Research AI developments',
          agentId: agentId,
        );

        final result2 = await service.executeGoal(
          goal: 'Analyze system performance',
          agentId: agentId,
          context: 'Previous research completed',
        );

        // Verify results
        expect(result1.success || result2.success, isTrue);

        // Check history
        final history = service.getExecutionHistory(agentId: agentId);
        expect(history, isNotEmpty);

        // Check memory
        final stats = service.getMemoryStatistics(agentId: agentId);
        expect(stats, isNotNull);
      });

      test('should handle concurrent agent operations', () async {
        final service = AgentService(container);
        await service.initialize();

        // Create multiple agents
        final agent1Id = await service.createAgent(name: 'Agent 1');
        final agent2Id = await service.createAgent(name: 'Agent 2');

        // Execute goals concurrently
        final results = await Future.wait([
          service.executeGoal(goal: 'Goal 1', agentId: agent1Id),
          service.executeGoal(goal: 'Goal 2', agentId: agent2Id),
        ]);

        expect(results, hasLength(2));
        expect(results.any((r) => r.success), isTrue);
      });

      test('should handle agent memory persistence', () async {
        final service = AgentService(container);
        await service.initialize();

        final agentId = await service.createAgent(
          name: 'Memory Test Agent',
          enableMemory: true,
        );

        // Add custom memory
        await service.addMemory(
          type: AgentMemoryType.semantic,
          content: 'Important system information',
          metadata: {'priority': 'high'},
          agentId: agentId,
        );

        // Search for memory
        final memories = await service.searchMemories(
          query: 'system information',
          agentId: agentId,
        );

        expect(memories, isNotEmpty);
        expect(memories.first.content, contains('system information'));
      });
    });

    group('Agent Performance Tests', () {
      test('should execute simple goal within time limit', () async {
        final service = AgentService(container);
        await service.initialize();

        final stopwatch = Stopwatch()..start();

        await service.executeGoal(goal: 'Simple test goal');

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds
      });

      test('should handle memory search performance', () async {
        final service = AgentService(container);
        await service.initialize();

        // Add many memories
        for (int i = 0; i < 100; i++) {
          await service.addMemory(
            type: AgentMemoryType.working,
            content: 'Memory content $i',
            metadata: {'index': i},
          );
        }

        final stopwatch = Stopwatch()..start();

        final results = await service.searchMemories(
          query: 'content 50',
          limit: 10,
        );

        stopwatch.stop();

        expect(results, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second
      });

      test('should handle multiple concurrent agent operations', () async {
        final service = AgentService(container);
        await service.initialize();

        // Create multiple agents
        final agentIds = await Future.wait(
          List.generate(5, (i) => service.createAgent(name: 'Agent $i')),
        );

        // Execute goals concurrently
        final futures = agentIds.map((agentId) async {
          return await service.executeGoal(
            goal: 'Concurrent goal for $agentId',
            agentId: agentId,
          );
        });

        final stopwatch = Stopwatch()..start();

        final results = await Future.wait(futures);

        stopwatch.stop();

        expect(results, hasLength(5));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds
      });
    });
  });
}

// Mock implementation for testing
class MockAutonomousAgent extends Mock implements AutonomousAgent {}

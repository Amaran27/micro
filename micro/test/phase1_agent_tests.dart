import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

import 'package:micro/infrastructure/ai/agent/models/agent_models.dart'
    as agent_models;
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';
import 'package:micro/infrastructure/ai/agent/agent_factory.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/example_mobile_tools.dart';

// Mock implementations for testing
class MockLanguageModel extends Mock implements LanguageModel {}

class MockChatModel extends Mock implements BaseChatModel {}

void main() {
  late ToolRegistry toolRegistry;
  late Logger logger;

  setUp(() {
    toolRegistry = ToolRegistry();
    logger = Logger();

    // Register example tools
    toolRegistry.register(UIValidationTool(logger: logger));
    toolRegistry.register(SensorAccessTool(logger: logger));
    toolRegistry.register(FileOperationTool(logger: logger));
    toolRegistry.register(AppNavigationTool(logger: logger));
  });

  group('ToolRegistry Tests', () {
    test('can register and retrieve tools', () {
      expect(toolRegistry.toolCount, equals(4));
      expect(toolRegistry.getTool('ui_validation'), isNotNull);
      expect(toolRegistry.getTool('sensor_access'), isNotNull);
    });

    test('can find tools by capability', () {
      final uiTools = toolRegistry.findByCapability('ui-inspection');
      expect(uiTools, isNotEmpty);
      expect(uiTools.first.metadata.name, equals('ui_validation'));
    });

    test('can find tools by action', () {
      final tools = toolRegistry.findByAction('ui_');
      expect(tools, isNotEmpty);
    });

    test('can check if capabilities are available', () {
      expect(toolRegistry.hasCapability('ui-inspection'), isTrue);
      expect(toolRegistry.hasCapability('nonexistent'), isFalse);
    });

    test('can check if all required tools are available', () {
      expect(
        toolRegistry.hasAllTools(['ui_validation', 'file_operations']),
        isTrue,
      );
      expect(
        toolRegistry.hasAllTools(['ui_validation', 'nonexistent']),
        isFalse,
      );
    });

    test('can unregister tools', () {
      expect(toolRegistry.toolCount, equals(4));
      final unregistered = toolRegistry.unregister('ui_validation');
      expect(unregistered, isTrue);
      expect(toolRegistry.toolCount, equals(3));
    });

    test('can execute tools', () async {
      final result = await toolRegistry.executeTool('ui_validation', {
        'action': 'validate',
        'target': 'button_1',
      });
      expect(result, isNotNull);
      expect((result as Map)['isValid'], isTrue);
    });

    test('tool metadata is correct', () {
      final uiTool = toolRegistry.getTool('ui_validation');
      expect(uiTool?.metadata.name, equals('ui_validation'));
      expect(uiTool?.metadata.capabilities, contains('ui-inspection'));
    });
  });

  group('Example Tools Tests', () {
    test('UIValidationTool can validate elements', () async {
      final tool = UIValidationTool(logger: logger);
      final result = await tool.execute({
        'action': 'validate',
        'target': 'button_1',
      });
      expect(result, isNotNull);
      expect((result as Map)['isValid'], isTrue);
    });

    test('SensorAccessTool can read sensors', () async {
      final tool = SensorAccessTool(logger: logger);
      final result = await tool.execute({
        'sensor': 'gps',
        'duration_seconds': 1,
      });
      expect(result, isNotNull);
      expect((result as Map)['latitude'], equals(37.7749));
    });

    test('FileOperationTool can perform file operations', () async {
      final tool = FileOperationTool(logger: logger);
      final result = await tool.execute({
        'action': 'read',
        'path': '/tmp/test.txt',
      });
      expect(result, isNotNull);
      expect(result is String, isTrue);
    });

    test('AppNavigationTool can navigate', () async {
      final tool = AppNavigationTool(logger: logger);
      final result = await tool.execute({
        'action': 'goto',
        'target': 'home_screen',
      });
      expect(result, isNotNull);
      expect((result as Map)['navigated'], isTrue);
    });
  });

  group('Agent Data Models Tests', () {
    test('AgentPlan can be created', () {
      final plan = agent_models.AgentPlan(
        id: 'plan_1',
        taskDescription: 'Test task',
        steps: [
          agent_models.PlanStep(
            id: 'step_1',
            description: 'Step 1',
            action: 'validate',
            parameters: {'target': 'button'},
            requiredTools: ['ui_validation'],
            estimatedDurationSeconds: 60,
          ),
        ],
        status: agent_models.ExecutionStatus.pending,
      );
      expect(plan.id, equals('plan_1'));
      expect(plan.steps.length, equals(1));
      expect(plan.status, equals(agent_models.ExecutionStatus.pending));
    });

    test('StepResult can be created', () {
      final result = agent_models.StepResult(
        stepId: 'step_1',
        status: agent_models.ExecutionStatus.completed,
        result: {'isValid': true},
      );
      expect(result.stepId, equals('step_1'));
      expect(result.status, equals(agent_models.ExecutionStatus.completed));
    });

    test('Verification can be created', () {
      final agentVerification = agent_models.Verification(
        stepId: 'step_1',
        result: agent_models.VerificationResult.success,
        reasoning: 'Step completed successfully',
      );
      expect(agentVerification.stepId, equals('step_1'));
      expect(
        agentVerification.result,
        equals(agent_models.VerificationResult.success),
      );
    });

    test('AgentResult can be created', () {
      final result = agent_models.AgentResult(
        planId: 'plan_1',
        finalStatus: agent_models.ExecutionStatus.completed,
        result: {'message': 'success'},
      );
      expect(result.planId, equals('plan_1'));
      expect(
        result.finalStatus,
        equals(agent_models.ExecutionStatus.completed),
      );
    });
  });

  group('Tool Registry Extension Tests', () {
    test('can find tools by multiple capabilities', () {
      final tools = toolRegistry.findByCapabilities([
        'ui-inspection',
        'sensor-data',
      ]);
      expect(tools.length, greaterThanOrEqualTo(2));
    });

    test('returns empty list for empty capabilities', () {
      final tools = toolRegistry.findByCapabilities([]);
      expect(tools, isEmpty);
    });
  });

  group('AgentFactory Tests', () {
    test('can create agent factory', () {
      final factory = AgentFactory(
        model: MockLanguageModel() as LanguageModel,
        toolRegistry: toolRegistry,
        logger: logger,
      );
      expect(factory, isNotNull);
      expect(factory.toolRegistry.toolCount, equals(4));
    });

    test('can get planning context', () {
      final factory = AgentFactory(
        model: MockLanguageModel() as LanguageModel,
        toolRegistry: toolRegistry,
        logger: logger,
      );
      final context = factory.getPlanningContext('Test task');
      expect(context.taskDescription, equals('Test task'));
      expect(context.availableTools.length, equals(4));
    });
  });
}

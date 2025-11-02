import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/example_mobile_tools.dart';

/// Represents a single execution step
class ExecutionStep {
  final String id;
  final String name;
  final StepExecutionStatus status;
  final DateTime timestamp;
  final String? details;
  final dynamic result;

  ExecutionStep({
    required this.id,
    required this.name,
    required this.status,
    required this.timestamp,
    this.details,
    this.result,
  });

  @override
  String toString() => 'ExecutionStep($name: $status)';
}

/// Status of an execution step
enum StepExecutionStatus {
  pending,
  running,
  completed,
  failed,
}

/// State for agent execution UI
class AgentExecutionUIState {
  final List<dynamic> availableTools;
  final bool isExecuting;
  final List<ExecutionStep> executionSteps;
  final String? currentToolName;
  final Map<String, dynamic>? lastToolResult;
  final String? errorMessage;

  const AgentExecutionUIState({
    this.availableTools = const [],
    this.isExecuting = false,
    this.executionSteps = const [],
    this.currentToolName,
    this.lastToolResult,
    this.errorMessage,
  });

  AgentExecutionUIState copyWith({
    List<dynamic>? availableTools,
    bool? isExecuting,
    List<ExecutionStep>? executionSteps,
    String? currentToolName,
    Map<String, dynamic>? lastToolResult,
    String? errorMessage,
  }) {
    return AgentExecutionUIState(
      availableTools: availableTools ?? this.availableTools,
      isExecuting: isExecuting ?? this.isExecuting,
      executionSteps: executionSteps ?? this.executionSteps,
      currentToolName: currentToolName ?? this.currentToolName,
      lastToolResult: lastToolResult ?? this.lastToolResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier for managing agent execution UI state
class AgentExecutionUINotifier extends StateNotifier<AgentExecutionUIState> {
  final ToolRegistry toolRegistry;

  AgentExecutionUINotifier(this.toolRegistry)
      : super(AgentExecutionUIState(
          availableTools: _initializeTools(toolRegistry),
        ));

  /// Initialize available tools from registry
  static List<dynamic> _initializeTools(ToolRegistry registry) {
    return registry.getAllMetadata();
  }

  /// Start tool execution
  void startToolExecution(String toolName, Map<String, dynamic> parameters) {
    final step = ExecutionStep(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: toolName,
      status: StepExecutionStatus.running,
      timestamp: DateTime.now(),
      details: 'Executing: ${_describeParameters(parameters)}',
    );

    state = state.copyWith(
      isExecuting: true,
      currentToolName: toolName,
      executionSteps: [...state.executionSteps, step],
      errorMessage: null,
    );
  }

  /// Complete tool execution
  void completeToolExecution(String toolName, dynamic result) {
    if (state.executionSteps.isEmpty) return;
    final lastStep = state.executionSteps.last;
    final updatedStep = ExecutionStep(
      id: lastStep.id,
      name: lastStep.name,
      status: StepExecutionStatus.completed,
      timestamp: lastStep.timestamp,
      details: lastStep.details,
      result: result,
    );

    state = state.copyWith(
      isExecuting: false,
      currentToolName: null,
      executionSteps: [
        ...state.executionSteps.sublist(0, state.executionSteps.length - 1),
        updatedStep
      ],
      lastToolResult: result,
    );
  }

  /// Mark tool execution as failed
  void failToolExecution(String toolName, String error) {
    if (state.executionSteps.isEmpty) return;
    final lastStep = state.executionSteps.last;
    final updatedStep = ExecutionStep(
      id: lastStep.id,
      name: lastStep.name,
      status: StepExecutionStatus.failed,
      timestamp: lastStep.timestamp,
      details: error,
    );

    state = state.copyWith(
      isExecuting: false,
      currentToolName: null,
      executionSteps: [
        ...state.executionSteps.sublist(0, state.executionSteps.length - 1),
        updatedStep
      ],
      errorMessage: error,
    );
  }

  /// Clear execution history
  void clearExecutionHistory() {
    state = state.copyWith(
      executionSteps: [],
      currentToolName: null,
      lastToolResult: null,
      errorMessage: null,
    );
  }

  /// Get tool by name
  dynamic getToolMetadata(String toolName) {
    try {
      return state.availableTools.firstWhere(
        (tool) => (tool as dynamic)?.name == toolName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper to describe parameters
  static String _describeParameters(Map<String, dynamic> params) {
    if (params.isEmpty) return 'with no parameters';
    final entries =
        params.entries.take(2).map((e) => '${e.key}=${e.value}').join(', ');
    final more = params.length > 2 ? ' +${params.length - 2} more' : '';
    return 'with $entries$more';
  }
}

/// Provider for tool registry
final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  final registry = ToolRegistry();

  // Register all available tools
  registry.register(UIValidationTool(logger: null));
  registry.register(SensorAccessTool(logger: null));
  registry.register(FileOperationTool(logger: null));
  registry.register(AppNavigationTool(logger: null));
  registry.register(LocationTool(logger: null));

  return registry;
});

/// Provider for agent execution UI state
final agentExecutionUIProvider =
    StateNotifierProvider<AgentExecutionUINotifier, AgentExecutionUIState>(
  (ref) {
    final registry = ref.watch(toolRegistryProvider);
    return AgentExecutionUINotifier(registry);
  },
);

/// Provider to get available tools as a list
final availableToolsProvider = Provider<List<dynamic>>((ref) {
  final state = ref.watch(agentExecutionUIProvider);
  return state.availableTools;
});

/// Provider to get current execution status
final executionStatusProvider = Provider<bool>((ref) {
  final state = ref.watch(agentExecutionUIProvider);
  return state.isExecuting;
});

/// Provider to get execution steps
final executionStepsProvider = Provider<List<ExecutionStep>>((ref) {
  final state = ref.watch(agentExecutionUIProvider);
  return state.executionSteps;
});

/// Base interface for all autonomous agents
abstract class AutonomousAgent {
  /// Execute the agent with a given goal
  Future<AgentResult> execute({
    required String goal,
    String? context,
    Map<String, dynamic>? parameters,
  });

  /// Get current agent status
  AgentStatus get status;

  /// Get agent execution history
  List<AgentExecution> get executionHistory;

  /// Cancel current execution
  Future<void> cancel();

  /// Get agent capabilities
  List<AgentCapability> get capabilities;
}

/// Agent execution result
class AgentResult {
  final String result;
  final bool success;
  final List<AgentStep> steps;
  final String? error;
  final Map<String, dynamic>? metadata;
  final String? reasoning; // Added for LangChain compatibility
  final List<String>? toolsUsed; // Added for LangChain compatibility

  AgentResult({
    required this.result,
    required this.success,
    required this.steps,
    this.error,
    this.metadata,
    this.reasoning,
    this.toolsUsed,
  });
}

/// Single step in agent execution
class AgentStep {
  final String stepId;
  final String description;
  final AgentStepType type;
  final Map<String, dynamic>? input;
  final dynamic output; // Can be String or Map for LangChain compatibility
  final DateTime timestamp;
  final Duration duration;
  final String? error;

  AgentStep({
    required this.stepId,
    required this.description,
    required this.type,
    this.input,
    this.output,
    required this.timestamp,
    required this.duration,
    this.error,
  });
}

/// Types of agent steps
enum AgentStepType {
  planning,
  reasoning,
  toolExecution,
  toolUse, // Added for LangChain compatibility
  reflection,
  errorRecovery,
  finalization,
}

/// Agent execution status
enum AgentStatus {
  idle,
  planning,
  executing,
  reasoning,
  waiting,
  completed,
  failed,
  error, // Added for LangChain compatibility
  cancelled,
}

/// Agent capabilities
class AgentCapability {
  final String name;
  final String description;
  final List<String> inputTypes;
  final List<String> outputTypes;
  final Map<String, dynamic> parameters;
  final bool enabled; // Added for LangChain compatibility

  AgentCapability({
    required this.name,
    required this.description,
    this.inputTypes = const [],
    this.outputTypes = const [],
    this.parameters = const {},
    this.enabled = true,
  });
}

/// Agent execution record
class AgentExecution {
  final String executionId;
  final String goal;
  final AgentResult result;
  final DateTime startTime;
  final DateTime? endTime;
  final AgentStatus status;

  AgentExecution({
    required this.executionId,
    required this.goal,
    required this.result,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  /// Get execution duration
  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }
}

/// Agent configuration
class AgentConfig {
  final String model;
  final double temperature;
  final int maxTokens;
  final int maxSteps;
  final bool enableMemory;
  final bool enableReasoning;
  final List<String> availableTools;
  final Map<String, dynamic> customParameters;

  AgentConfig({
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.maxSteps = 10,
    this.enableMemory = true,
    this.enableReasoning = true,
    this.availableTools = const [],
    this.customParameters = const {},
  });

  /// Copy with modifications
  AgentConfig copyWith({
    String? model,
    double? temperature,
    int? maxTokens,
    int? maxSteps,
    bool? enableMemory,
    bool? enableReasoning,
    List<String>? availableTools,
    Map<String, dynamic>? customParameters,
  }) {
    return AgentConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      maxSteps: maxSteps ?? this.maxSteps,
      enableMemory: enableMemory ?? this.enableMemory,
      enableReasoning: enableReasoning ?? this.enableReasoning,
      availableTools: availableTools ?? this.availableTools,
      customParameters: customParameters ?? this.customParameters,
    );
  }
}

/// Agent memory types
enum AgentMemoryType {
  conversation,
  episodic,
  semantic,
  working,
}

/// Agent types
enum AgentType {
  general,
  specialized,
  collaborative,
}

/// Memory entry for agent
class AgentMemoryEntry {
  final String id;
  final AgentMemoryType type;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  double relevance;

  AgentMemoryEntry({
    required this.id,
    required this.type,
    required this.content,
    required this.metadata,
    required this.timestamp,
    this.relevance = 1.0,
  });
}

/// Tool execution request
class ToolExecutionRequest {
  final String toolName;
  final Map<String, dynamic> parameters;
  final String? context;

  ToolExecutionRequest({
    required this.toolName,
    required this.parameters,
    this.context,
  });
}

/// Tool execution result
class ToolExecutionResult {
  final String toolName;
  final bool success;
  final dynamic result;
  final String? error;
  final Duration duration;

  ToolExecutionResult({
    required this.toolName,
    required this.success,
    this.result,
    this.error,
    required this.duration,
  });
}

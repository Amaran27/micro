import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_models.g.dart';

/// Represents the execution status of a plan or step
enum ExecutionStatus {
  pending,
  planning,
  executing,
  verifying,
  completed,
  failed,
  replanning,
  cancelled,
}

/// Represents the result of step verification
enum VerificationResult {
  success,
  partial,
  failed,
  needsReplanning,
}

/// Represents a single step in the execution plan
@JsonSerializable()
class PlanStep {
  final String id;
  final String description;
  final String action;
  final Map<String, dynamic> parameters;
  final List<String> requiredTools;
  final int estimatedDurationSeconds;
  final ExecutionStatus status;
  final List<String> dependencies;
  final int? sequenceNumber;
  final String? toolName;

  const PlanStep({
    required this.id,
    required this.description,
    required this.action,
    required this.parameters,
    required this.requiredTools,
    required this.estimatedDurationSeconds,
    this.status = ExecutionStatus.pending,
    this.dependencies = const [],
    this.sequenceNumber,
    this.toolName,
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);

  Map<String, dynamic> toJson() => _$PlanStepToJson(this);
}

/// Represents the result of executing a step
@JsonSerializable()
class StepResult {
  final String stepId;
  final ExecutionStatus status;
  final dynamic result;
  final String? error;
  final DateTime? executedAt;
  final int? durationMilliseconds;
  final Map<String, dynamic> metadata;

  const StepResult({
    required this.stepId,
    required this.status,
    required this.result,
    this.error,
    this.executedAt,
    this.durationMilliseconds,
    this.metadata = const {},
  });

  factory StepResult.fromJson(Map<String, dynamic> json) =>
      _$StepResultFromJson(json);

  Map<String, dynamic> toJson() => _$StepResultToJson(this);
}

/// Represents the verification of step execution
@JsonSerializable()
class Verification {
  final String stepId;
  final VerificationResult result;
  final String reasoning;
  final List<String> issues;
  final DateTime? verifiedAt;
  final Map<String, dynamic> evidence;

  const Verification({
    required this.stepId,
    required this.result,
    required this.reasoning,
    this.issues = const [],
    this.verifiedAt,
    this.evidence = const {},
  });

  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationToJson(this);
}

/// Represents a complete agent plan
@JsonSerializable()
class AgentPlan {
  final String id;
  final String taskDescription;
  final List<PlanStep> steps;
  final ExecutionStatus status;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<Verification> verifications;
  final List<StepResult> results;
  final int replannedCount;
  final String? finalReasoning;

  const AgentPlan({
    required this.id,
    required this.taskDescription,
    required this.steps,
    this.status = ExecutionStatus.pending,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.verifications = const [],
    this.results = const [],
    this.replannedCount = 0,
    this.finalReasoning,
  });

  factory AgentPlan.fromJson(Map<String, dynamic> json) =>
      _$AgentPlanFromJson(json);

  Map<String, dynamic> toJson() => _$AgentPlanToJson(this);
}

/// Represents the final result of agent execution
@JsonSerializable()
class AgentResult {
  final String planId;
  final ExecutionStatus finalStatus;
  final dynamic result;
  final String? error;
  final DateTime? completedAt;
  final int? totalDurationSeconds;
  final int stepsCompleted;
  final int stepsFailed;
  final Map<String, dynamic> metadata;

  const AgentResult({
    required this.planId,
    required this.finalStatus,
    required this.result,
    this.error,
    this.completedAt,
    this.totalDurationSeconds,
    this.stepsCompleted = 0,
    this.stepsFailed = 0,
    this.metadata = const {},
  });

  factory AgentResult.fromJson(Map<String, dynamic> json) =>
      _$AgentResultFromJson(json);

  Map<String, dynamic> toJson() => _$AgentResultToJson(this);
}

/// Metadata about a tool's capabilities
@JsonSerializable()
class ToolMetadata {
  final String name;
  final String description;
  final List<String> capabilities;
  final List<String> requiredPermissions;
  final String executionContext; // 'local', 'remote', or 'hybrid'
  final Map<String, dynamic> parameters;
  final bool isAsync;
  final Duration? timeout;

  const ToolMetadata({
    required this.name,
    required this.description,
    required this.capabilities,
    required this.requiredPermissions,
    this.executionContext = 'local',
    this.parameters = const {},
    this.isAsync = false,
    this.timeout,
  });

  factory ToolMetadata.fromJson(Map<String, dynamic> json) =>
      _$ToolMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ToolMetadataToJson(this);
}

/// Represents task execution capabilities
@JsonSerializable()
class TaskCapabilities {
  final List<String> requiredTools;
  final List<String> requiredPermissions;
  final String suggestedExecutionContext;
  final Map<String, dynamic> estimatedResources;

  const TaskCapabilities({
    required this.requiredTools,
    required this.requiredPermissions,
    this.suggestedExecutionContext = 'local',
    this.estimatedResources = const {},
  });

  factory TaskCapabilities.fromJson(Map<String, dynamic> json) =>
      _$TaskCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$TaskCapabilitiesToJson(this);
}

/// Represents the context for agent planning
@JsonSerializable()
class PlanningContext {
  final String taskDescription;
  final List<ToolMetadata> availableTools;
  final List<String> availablePermissions;
  final Map<String, dynamic> environmentInfo;
  final DateTime? deadline;
  final Map<String, dynamic> constraints;

  const PlanningContext({
    required this.taskDescription,
    required this.availableTools,
    required this.availablePermissions,
    this.environmentInfo = const {},
    this.deadline,
    this.constraints = const {},
  });

  factory PlanningContext.fromJson(Map<String, dynamic> json) =>
      _$PlanningContextFromJson(json);

  Map<String, dynamic> toJson() => _$PlanningContextToJson(this);
}

/// Analyzes a task to determine required capabilities and complexity
@JsonSerializable()
class TaskAnalysis {
  final String taskDescription;
  final int estimatedComplexity; // 1-10 scale
  final List<String> requiredCapabilities;
  final bool shouldRunRemotely;
  final String reasoning;

  const TaskAnalysis({
    required this.taskDescription,
    required this.estimatedComplexity,
    required this.requiredCapabilities,
    required this.shouldRunRemotely,
    required this.reasoning,
  });

  factory TaskAnalysis.fromJson(Map<String, dynamic> json) =>
      _$TaskAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$TaskAnalysisToJson(this);
}

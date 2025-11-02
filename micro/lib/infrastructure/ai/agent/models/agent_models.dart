import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_models.freezed.dart';
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
@freezed
class PlanStep with _$PlanStep {
  const factory PlanStep({
    required String id,
    required String description,
    required String action,
    required Map<String, dynamic> parameters,
    required List<String> requiredTools,
    required int estimatedDurationSeconds,
    @Default(ExecutionStatus.pending) ExecutionStatus status,
    @Default([]) List<String> dependencies,
    int? sequenceNumber,
    String? toolName,
  }) = _PlanStep;

  factory PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);
}

/// Represents the result of executing a step
@freezed
class StepResult with _$StepResult {
  const factory StepResult({
    required String stepId,
    required ExecutionStatus status,
    required dynamic result,
    String? error,
    DateTime? executedAt,
    int? durationMilliseconds,
    @Default({}) Map<String, dynamic> metadata,
  }) = _StepResult;

  factory StepResult.fromJson(Map<String, dynamic> json) =>
      _$StepResultFromJson(json);
}

/// Represents the verification of step execution
@freezed
class Verification with _$Verification {
  const factory Verification({
    required String stepId,
    required VerificationResult result,
    required String reasoning,
    @Default([]) List<String> issues,
    DateTime? verifiedAt,
    @Default({}) Map<String, dynamic> evidence,
  }) = _Verification;

  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);
}

/// Represents a complete agent plan
@freezed
class AgentPlan with _$AgentPlan {
  const factory AgentPlan({
    required String id,
    required String taskDescription,
    required List<PlanStep> steps,
    @Default(ExecutionStatus.pending) ExecutionStatus status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    @Default([]) List<Verification> verifications,
    @Default([]) List<StepResult> results,
    @Default(0) int replannedCount,
    String? finalReasoning,
  }) = _AgentPlan;

  factory AgentPlan.fromJson(Map<String, dynamic> json) =>
      _$AgentPlanFromJson(json);
}

/// Represents the final result of agent execution
@freezed
class AgentResult with _$AgentResult {
  const factory AgentResult({
    required String planId,
    required ExecutionStatus finalStatus,
    required dynamic result,
    String? error,
    DateTime? completedAt,
    int? totalDurationSeconds,
    @Default(0) int stepsCompleted,
    @Default(0) int stepsFailed,
    @Default({}) Map<String, dynamic> metadata,
  }) = _AgentResult;

  factory AgentResult.fromJson(Map<String, dynamic> json) =>
      _$AgentResultFromJson(json);
}

/// Metadata about a tool's capabilities
@freezed
class ToolMetadata with _$ToolMetadata {
  const factory ToolMetadata({
    required String name,
    required String description,
    required List<String> capabilities,
    required List<String> requiredPermissions,
    @Default('local') String executionContext, // 'local', 'remote', or 'hybrid'
    @Default({}) Map<String, dynamic> parameters,
    @Default(false) bool isAsync,
    @Default(null) Duration? timeout,
  }) = _ToolMetadata;

  factory ToolMetadata.fromJson(Map<String, dynamic> json) =>
      _$ToolMetadataFromJson(json);
}

/// Represents task execution capabilities
@freezed
class TaskCapabilities with _$TaskCapabilities {
  const factory TaskCapabilities({
    required List<String> requiredTools,
    required List<String> requiredPermissions,
    @Default('local') String suggestedExecutionContext,
    @Default({}) Map<String, dynamic> estimatedResources,
  }) = _TaskCapabilities;

  factory TaskCapabilities.fromJson(Map<String, dynamic> json) =>
      _$TaskCapabilitiesFromJson(json);
}

/// Represents the context for agent planning
@freezed
class PlanningContext with _$PlanningContext {
  const factory PlanningContext({
    required String taskDescription,
    required List<ToolMetadata> availableTools,
    required List<String> availablePermissions,
    @Default({}) Map<String, dynamic> environmentInfo,
    @Default(null) DateTime? deadline,
    @Default({}) Map<String, dynamic> constraints,
  }) = _PlanningContext;

  factory PlanningContext.fromJson(Map<String, dynamic> json) =>
      _$PlanningContextFromJson(json);
}

/// Analyzes a task to determine required capabilities and complexity
@freezed
class TaskAnalysis with _$TaskAnalysis {
  const factory TaskAnalysis({
    required String taskDescription,
    required int estimatedComplexity, // 1-10 scale
    required List<String> requiredCapabilities,
    required bool shouldRunRemotely,
    required String reasoning,
  }) = _TaskAnalysis;

  factory TaskAnalysis.fromJson(Map<String, dynamic> json) =>
      _$TaskAnalysisFromJson(json);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanStep _$PlanStepFromJson(Map<String, dynamic> json) => _PlanStep(
      id: json['id'] as String,
      description: json['description'] as String,
      action: json['action'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      requiredTools: (json['requiredTools'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      estimatedDurationSeconds:
          (json['estimatedDurationSeconds'] as num).toInt(),
      status: $enumDecodeNullable(_$ExecutionStatusEnumMap, json['status']) ??
          ExecutionStatus.pending,
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sequenceNumber: (json['sequenceNumber'] as num?)?.toInt(),
      toolName: json['toolName'] as String?,
    );

Map<String, dynamic> _$PlanStepToJson(_PlanStep instance) => <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'action': instance.action,
      'parameters': instance.parameters,
      'requiredTools': instance.requiredTools,
      'estimatedDurationSeconds': instance.estimatedDurationSeconds,
      'status': _$ExecutionStatusEnumMap[instance.status]!,
      'dependencies': instance.dependencies,
      'sequenceNumber': instance.sequenceNumber,
      'toolName': instance.toolName,
    };

const _$ExecutionStatusEnumMap = {
  ExecutionStatus.pending: 'pending',
  ExecutionStatus.planning: 'planning',
  ExecutionStatus.executing: 'executing',
  ExecutionStatus.verifying: 'verifying',
  ExecutionStatus.completed: 'completed',
  ExecutionStatus.failed: 'failed',
  ExecutionStatus.replanning: 'replanning',
  ExecutionStatus.cancelled: 'cancelled',
};

_StepResult _$StepResultFromJson(Map<String, dynamic> json) => _StepResult(
      stepId: json['stepId'] as String,
      status: $enumDecode(_$ExecutionStatusEnumMap, json['status']),
      result: json['result'],
      error: json['error'] as String?,
      executedAt: json['executedAt'] == null
          ? null
          : DateTime.parse(json['executedAt'] as String),
      durationMilliseconds: (json['durationMilliseconds'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$StepResultToJson(_StepResult instance) =>
    <String, dynamic>{
      'stepId': instance.stepId,
      'status': _$ExecutionStatusEnumMap[instance.status]!,
      'result': instance.result,
      'error': instance.error,
      'executedAt': instance.executedAt?.toIso8601String(),
      'durationMilliseconds': instance.durationMilliseconds,
      'metadata': instance.metadata,
    };

_Verification _$VerificationFromJson(Map<String, dynamic> json) =>
    _Verification(
      stepId: json['stepId'] as String,
      result: $enumDecode(_$VerificationResultEnumMap, json['result']),
      reasoning: json['reasoning'] as String,
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      evidence: json['evidence'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$VerificationToJson(_Verification instance) =>
    <String, dynamic>{
      'stepId': instance.stepId,
      'result': _$VerificationResultEnumMap[instance.result]!,
      'reasoning': instance.reasoning,
      'issues': instance.issues,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'evidence': instance.evidence,
    };

const _$VerificationResultEnumMap = {
  VerificationResult.success: 'success',
  VerificationResult.partial: 'partial',
  VerificationResult.failed: 'failed',
  VerificationResult.needsReplanning: 'needsReplanning',
};

_AgentPlan _$AgentPlanFromJson(Map<String, dynamic> json) => _AgentPlan(
      id: json['id'] as String,
      taskDescription: json['taskDescription'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => PlanStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecodeNullable(_$ExecutionStatusEnumMap, json['status']) ??
          ExecutionStatus.pending,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      verifications: (json['verifications'] as List<dynamic>?)
              ?.map((e) => Verification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => StepResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      replannedCount: (json['replannedCount'] as num?)?.toInt() ?? 0,
      finalReasoning: json['finalReasoning'] as String?,
    );

Map<String, dynamic> _$AgentPlanToJson(_AgentPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskDescription': instance.taskDescription,
      'steps': instance.steps,
      'status': _$ExecutionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'verifications': instance.verifications,
      'results': instance.results,
      'replannedCount': instance.replannedCount,
      'finalReasoning': instance.finalReasoning,
    };

_AgentResult _$AgentResultFromJson(Map<String, dynamic> json) => _AgentResult(
      planId: json['planId'] as String,
      finalStatus: $enumDecode(_$ExecutionStatusEnumMap, json['finalStatus']),
      result: json['result'],
      error: json['error'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt(),
      stepsCompleted: (json['stepsCompleted'] as num?)?.toInt() ?? 0,
      stepsFailed: (json['stepsFailed'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$AgentResultToJson(_AgentResult instance) =>
    <String, dynamic>{
      'planId': instance.planId,
      'finalStatus': _$ExecutionStatusEnumMap[instance.finalStatus]!,
      'result': instance.result,
      'error': instance.error,
      'completedAt': instance.completedAt?.toIso8601String(),
      'totalDurationSeconds': instance.totalDurationSeconds,
      'stepsCompleted': instance.stepsCompleted,
      'stepsFailed': instance.stepsFailed,
      'metadata': instance.metadata,
    };

_ToolMetadata _$ToolMetadataFromJson(Map<String, dynamic> json) =>
    _ToolMetadata(
      name: json['name'] as String,
      description: json['description'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      executionContext: json['executionContext'] as String? ?? 'local',
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
      isAsync: json['isAsync'] as bool? ?? false,
      timeout: json['timeout'] == null
          ? null
          : Duration(microseconds: (json['timeout'] as num).toInt()),
    );

Map<String, dynamic> _$ToolMetadataToJson(_ToolMetadata instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'capabilities': instance.capabilities,
      'requiredPermissions': instance.requiredPermissions,
      'executionContext': instance.executionContext,
      'parameters': instance.parameters,
      'isAsync': instance.isAsync,
      'timeout': instance.timeout?.inMicroseconds,
    };

_TaskCapabilities _$TaskCapabilitiesFromJson(Map<String, dynamic> json) =>
    _TaskCapabilities(
      requiredTools: (json['requiredTools'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suggestedExecutionContext:
          json['suggestedExecutionContext'] as String? ?? 'local',
      estimatedResources:
          json['estimatedResources'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TaskCapabilitiesToJson(_TaskCapabilities instance) =>
    <String, dynamic>{
      'requiredTools': instance.requiredTools,
      'requiredPermissions': instance.requiredPermissions,
      'suggestedExecutionContext': instance.suggestedExecutionContext,
      'estimatedResources': instance.estimatedResources,
    };

_PlanningContext _$PlanningContextFromJson(Map<String, dynamic> json) =>
    _PlanningContext(
      taskDescription: json['taskDescription'] as String,
      availableTools: (json['availableTools'] as List<dynamic>)
          .map((e) => ToolMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      availablePermissions: (json['availablePermissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      environmentInfo:
          json['environmentInfo'] as Map<String, dynamic>? ?? const {},
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      constraints: json['constraints'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$PlanningContextToJson(_PlanningContext instance) =>
    <String, dynamic>{
      'taskDescription': instance.taskDescription,
      'availableTools': instance.availableTools,
      'availablePermissions': instance.availablePermissions,
      'environmentInfo': instance.environmentInfo,
      'deadline': instance.deadline?.toIso8601String(),
      'constraints': instance.constraints,
    };

_TaskAnalysis _$TaskAnalysisFromJson(Map<String, dynamic> json) =>
    _TaskAnalysis(
      taskDescription: json['taskDescription'] as String,
      estimatedComplexity: (json['estimatedComplexity'] as num).toInt(),
      requiredCapabilities: (json['requiredCapabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      shouldRunRemotely: json['shouldRunRemotely'] as bool,
      reasoning: json['reasoning'] as String,
    );

Map<String, dynamic> _$TaskAnalysisToJson(_TaskAnalysis instance) =>
    <String, dynamic>{
      'taskDescription': instance.taskDescription,
      'estimatedComplexity': instance.estimatedComplexity,
      'requiredCapabilities': instance.requiredCapabilities,
      'shouldRunRemotely': instance.shouldRunRemotely,
      'reasoning': instance.reasoning,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => ToolCall(
      id: json['id'] as String,
      toolId: json['toolId'] as String,
      toolName: json['toolName'] as String,
      serverName: json['serverName'] as String,
      capabilityId: json['capabilityId'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>,
      context:
          ExecutionContext.fromJson(json['context'] as Map<String, dynamic>),
      priority:
          $enumDecodeNullable(_$ExecutionPriorityEnumMap, json['priority']) ??
              ExecutionPriority.normal,
      timeout: json['timeout'] == null
          ? const Duration(seconds: 30)
          : Duration(microseconds: (json['timeout'] as num).toInt()),
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
      isDryRun: json['isDryRun'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledFor: json['scheduledFor'] == null
          ? null
          : DateTime.parse(json['scheduledFor'] as String),
    );

Map<String, dynamic> _$ToolCallToJson(ToolCall instance) => <String, dynamic>{
      'id': instance.id,
      'toolId': instance.toolId,
      'toolName': instance.toolName,
      'serverName': instance.serverName,
      'capabilityId': instance.capabilityId,
      'parameters': instance.parameters,
      'context': instance.context,
      'priority': _$ExecutionPriorityEnumMap[instance.priority]!,
      'timeout': instance.timeout.inMicroseconds,
      'maxRetries': instance.maxRetries,
      'isDryRun': instance.isDryRun,
      'createdAt': instance.createdAt.toIso8601String(),
      'scheduledFor': instance.scheduledFor?.toIso8601String(),
    };

const _$ExecutionPriorityEnumMap = {
  ExecutionPriority.low: 'low',
  ExecutionPriority.normal: 'normal',
  ExecutionPriority.high: 'high',
  ExecutionPriority.critical: 'critical',
};

ExecutionContext _$ExecutionContextFromJson(Map<String, dynamic> json) =>
    ExecutionContext(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      requestId: json['requestId'] as String,
      deviceInfo:
          DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
      networkContext: NetworkContext.fromJson(
          json['networkContext'] as Map<String, dynamic>),
      securityContext: json['securityContext'] as Map<String, dynamic>,
      performanceConstraints: PerformanceConstraints.fromJson(
          json['performanceConstraints'] as Map<String, dynamic>),
      mobileContext:
          MobileContext.fromJson(json['mobileContext'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExecutionContextToJson(ExecutionContext instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'sessionId': instance.sessionId,
      'requestId': instance.requestId,
      'deviceInfo': instance.deviceInfo,
      'networkContext': instance.networkContext,
      'securityContext': instance.securityContext,
      'performanceConstraints': instance.performanceConstraints,
      'mobileContext': instance.mobileContext,
    };

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      deviceType: json['deviceType'] as String,
      operatingSystem: json['operatingSystem'] as String,
      osVersion: json['osVersion'] as String,
      availableMemoryMB: (json['availableMemoryMB'] as num).toDouble(),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
      isOnBattery: json['isOnBattery'] as bool,
      networkType: json['networkType'] as String,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'deviceType': instance.deviceType,
      'operatingSystem': instance.operatingSystem,
      'osVersion': instance.osVersion,
      'availableMemoryMB': instance.availableMemoryMB,
      'batteryLevel': instance.batteryLevel,
      'isOnBattery': instance.isOnBattery,
      'networkType': instance.networkType,
    };

NetworkContext _$NetworkContextFromJson(Map<String, dynamic> json) =>
    NetworkContext(
      connectionType: json['connectionType'] as String,
      networkQuality: json['networkQuality'] as String,
      availableBandwidthKBps:
          (json['availableBandwidthKBps'] as num).toDouble(),
      latencyMs: (json['latencyMs'] as num).toInt(),
      isMetered: json['isMetered'] as bool,
    );

Map<String, dynamic> _$NetworkContextToJson(NetworkContext instance) =>
    <String, dynamic>{
      'connectionType': instance.connectionType,
      'networkQuality': instance.networkQuality,
      'availableBandwidthKBps': instance.availableBandwidthKBps,
      'latencyMs': instance.latencyMs,
      'isMetered': instance.isMetered,
    };

PerformanceConstraints _$PerformanceConstraintsFromJson(
        Map<String, dynamic> json) =>
    PerformanceConstraints(
      maxExecutionTime:
          Duration(microseconds: (json['maxExecutionTime'] as num).toInt()),
      maxMemoryUsageMB: (json['maxMemoryUsageMB'] as num).toDouble(),
      maxCpuUsagePercent: (json['maxCpuUsagePercent'] as num).toDouble(),
      optimizeForBattery: json['optimizeForBattery'] as bool? ?? true,
    );

Map<String, dynamic> _$PerformanceConstraintsToJson(
        PerformanceConstraints instance) =>
    <String, dynamic>{
      'maxExecutionTime': instance.maxExecutionTime.inMicroseconds,
      'maxMemoryUsageMB': instance.maxMemoryUsageMB,
      'maxCpuUsagePercent': instance.maxCpuUsagePercent,
      'optimizeForBattery': instance.optimizeForBattery,
    };

MobileContext _$MobileContextFromJson(Map<String, dynamic> json) =>
    MobileContext(
      optimizeForMobile: json['optimizeForMobile'] as bool,
      allowOffline: json['allowOffline'] as bool? ?? false,
      allowBackgroundExecution:
          json['allowBackgroundExecution'] as bool? ?? false,
      batteryOptimizationLevel: json['batteryOptimizationLevel'] as String,
      memoryOptimizationLevel: json['memoryOptimizationLevel'] as String,
    );

Map<String, dynamic> _$MobileContextToJson(MobileContext instance) =>
    <String, dynamic>{
      'optimizeForMobile': instance.optimizeForMobile,
      'allowOffline': instance.allowOffline,
      'allowBackgroundExecution': instance.allowBackgroundExecution,
      'batteryOptimizationLevel': instance.batteryOptimizationLevel,
      'memoryOptimizationLevel': instance.memoryOptimizationLevel,
    };

ToolCallStatus _$ToolCallStatusFromJson(Map<String, dynamic> json) =>
    ToolCallStatus(
      id: json['id'] as String,
      toolCallId: json['toolCallId'] as String,
      state: $enumDecode(_$ToolCallStateEnumMap, json['state']),
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] == null
          ? null
          : ToolCallError.fromJson(json['error'] as Map<String, dynamic>),
      metrics: json['metrics'] == null
          ? null
          : ToolCallMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ToolCallStatusToJson(ToolCallStatus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'toolCallId': instance.toolCallId,
      'state': _$ToolCallStateEnumMap[instance.state]!,
      'progress': instance.progress,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'error': instance.error,
      'metrics': instance.metrics,
    };

const _$ToolCallStateEnumMap = {
  ToolCallState.queued: 'queued',
  ToolCallState.running: 'running',
  ToolCallState.completed: 'completed',
  ToolCallState.failed: 'failed',
  ToolCallState.cancelled: 'cancelled',
  ToolCallState.timeout: 'timeout',
};

ToolCallError _$ToolCallErrorFromJson(Map<String, dynamic> json) =>
    ToolCallError(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
      stackTrace: json['stackTrace'] as String?,
    );

Map<String, dynamic> _$ToolCallErrorToJson(ToolCallError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
      'stackTrace': instance.stackTrace,
    };

ToolCallMetrics _$ToolCallMetricsFromJson(Map<String, dynamic> json) =>
    ToolCallMetrics(
      executionTime:
          Duration(microseconds: (json['executionTime'] as num).toInt()),
      memoryUsageMB: (json['memoryUsageMB'] as num).toDouble(),
      cpuUsagePercent: (json['cpuUsagePercent'] as num).toDouble(),
      networkUsageKB: (json['networkUsageKB'] as num).toDouble(),
      batteryConsumptionPercent:
          (json['batteryConsumptionPercent'] as num).toDouble(),
    );

Map<String, dynamic> _$ToolCallMetricsToJson(ToolCallMetrics instance) =>
    <String, dynamic>{
      'executionTime': instance.executionTime.inMicroseconds,
      'memoryUsageMB': instance.memoryUsageMB,
      'cpuUsagePercent': instance.cpuUsagePercent,
      'networkUsageKB': instance.networkUsageKB,
      'batteryConsumptionPercent': instance.batteryConsumptionPercent,
    };

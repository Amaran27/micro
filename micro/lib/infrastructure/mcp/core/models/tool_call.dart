import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_call.g.dart';

/// Represents a request to execute a tool
@JsonSerializable()
class ToolCall extends Equatable {
  /// Unique identifier for the tool call
  final String id;

  /// ID of the tool to execute
  final String toolId;

  /// Name of the tool (for reference)
  final String toolName;

  /// Server providing the tool
  final String serverName;

  /// Capability to use
  final String? capabilityId;

  /// Parameters for the tool execution
  final Map<String, dynamic> parameters;

  /// Execution context
  final ExecutionContext context;

  /// Priority of the execution
  final ExecutionPriority priority;

  /// Timeout for the execution
  final Duration timeout;

  /// Maximum retry attempts
  final int maxRetries;

  /// Whether this is a dry run
  final bool isDryRun;

  /// Timestamp when the call was created
  final DateTime createdAt;

  /// Timestamp when the call should be executed
  final DateTime? scheduledFor;

  const ToolCall({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.serverName,
    this.capabilityId,
    required this.parameters,
    required this.context,
    this.priority = ExecutionPriority.normal,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.isDryRun = false,
    required this.createdAt,
    this.scheduledFor,
  });

  /// Creates a ToolCall from JSON
  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  /// Converts ToolCall to JSON
  Map<String, dynamic> toJson() => _$ToolCallToJson(this);

  /// Creates a copy with updated values
  ToolCall copyWith({
    String? id,
    String? toolId,
    String? toolName,
    String? serverName,
    String? capabilityId,
    Map<String, dynamic>? parameters,
    ExecutionContext? context,
    ExecutionPriority? priority,
    Duration? timeout,
    int? maxRetries,
    bool? isDryRun,
    DateTime? createdAt,
    DateTime? scheduledFor,
  }) {
    return ToolCall(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      serverName: serverName ?? this.serverName,
      capabilityId: capabilityId ?? this.capabilityId,
      parameters: parameters ?? this.parameters,
      context: context ?? this.context,
      priority: priority ?? this.priority,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      isDryRun: isDryRun ?? this.isDryRun,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }

  /// Checks if the call is scheduled for future execution
  bool get isScheduled =>
      scheduledFor != null && scheduledFor!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        toolId,
        toolName,
        serverName,
        capabilityId,
        parameters,
        context,
        priority,
        timeout,
        maxRetries,
        isDryRun,
        createdAt,
        scheduledFor,
      ];

  @override
  String toString() =>
      'ToolCall(id: $id, tool: $toolName, server: $serverName)';
}

/// Execution context for a tool call
@JsonSerializable()
class ExecutionContext extends Equatable {
  /// User ID making the request
  final String userId;

  /// Session ID
  final String sessionId;

  /// Request ID for tracking
  final String requestId;

  /// Device information
  final DeviceInfo deviceInfo;

  /// Network context
  final NetworkContext networkContext;

  /// Security context
  final Map<String, dynamic> securityContext;

  /// Performance constraints
  final PerformanceConstraints performanceConstraints;

  /// Mobile-specific context
  final MobileContext mobileContext;

  const ExecutionContext({
    required this.userId,
    required this.sessionId,
    required this.requestId,
    required this.deviceInfo,
    required this.networkContext,
    required this.securityContext,
    required this.performanceConstraints,
    required this.mobileContext,
  });

  factory ExecutionContext.fromJson(Map<String, dynamic> json) =>
      _$ExecutionContextFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionContextToJson(this);

  @override
  List<Object?> get props => [
        userId,
        sessionId,
        requestId,
        deviceInfo,
        networkContext,
        securityContext,
        performanceConstraints,
        mobileContext,
      ];

  @override
  String toString() =>
      'ExecutionContext(userId: $userId, sessionId: $sessionId)';
}

/// Device information
@JsonSerializable()
class DeviceInfo extends Equatable {
  /// Device type
  final String deviceType;

  /// Operating system
  final String operatingSystem;

  /// OS version
  final String osVersion;

  /// Available memory in MB
  final double availableMemoryMB;

  /// Battery level (0.0 to 1.0)
  final double batteryLevel;

  /// Whether device is on battery power
  final bool isOnBattery;

  /// Network type
  final String networkType;

  const DeviceInfo({
    required this.deviceType,
    required this.operatingSystem,
    required this.osVersion,
    required this.availableMemoryMB,
    required this.batteryLevel,
    required this.isOnBattery,
    required this.networkType,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  List<Object?> get props => [
        deviceType,
        operatingSystem,
        osVersion,
        availableMemoryMB,
        batteryLevel,
        isOnBattery,
        networkType,
      ];

  @override
  String toString() =>
      'DeviceInfo($deviceType, $operatingSystem $osVersion, battery: ${(batteryLevel * 100).toInt()}%)';
}

/// Network context
@JsonSerializable()
class NetworkContext extends Equatable {
  /// Connection type
  final String connectionType;

  /// Network quality
  final String networkQuality;

  /// Available bandwidth in KB/s
  final double availableBandwidthKBps;

  /// Latency in milliseconds
  final int latencyMs;

  /// Whether connection is metered
  final bool isMetered;

  const NetworkContext({
    required this.connectionType,
    required this.networkQuality,
    required this.availableBandwidthKBps,
    required this.latencyMs,
    required this.isMetered,
  });

  factory NetworkContext.fromJson(Map<String, dynamic> json) =>
      _$NetworkContextFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkContextToJson(this);

  @override
  List<Object?> get props => [
        connectionType,
        networkQuality,
        availableBandwidthKBps,
        latencyMs,
        isMetered,
      ];

  @override
  String toString() =>
      'NetworkContext($connectionType, quality: $networkQuality, latency: ${latencyMs}ms)';
}

/// Performance constraints
@JsonSerializable()
class PerformanceConstraints extends Equatable {
  /// Maximum execution time
  final Duration maxExecutionTime;

  /// Maximum memory usage in MB
  final double maxMemoryUsageMB;

  /// Maximum CPU usage percentage
  final double maxCpuUsagePercent;

  /// Whether to optimize for battery
  final bool optimizeForBattery;

  const PerformanceConstraints({
    required this.maxExecutionTime,
    required this.maxMemoryUsageMB,
    required this.maxCpuUsagePercent,
    this.optimizeForBattery = true,
  });

  factory PerformanceConstraints.fromJson(Map<String, dynamic> json) =>
      _$PerformanceConstraintsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceConstraintsToJson(this);

  @override
  List<Object?> get props => [
        maxExecutionTime,
        maxMemoryUsageMB,
        maxCpuUsagePercent,
        optimizeForBattery,
      ];

  @override
  String toString() =>
      'PerformanceConstraints(maxTime: ${maxExecutionTime.inMilliseconds}ms, maxMemory: ${maxMemoryUsageMB}MB)';
}

/// Mobile-specific context
@JsonSerializable()
class MobileContext extends Equatable {
  /// Whether to optimize for mobile
  final bool optimizeForMobile;

  /// Whether offline mode is allowed
  final bool allowOffline;

  /// Background execution allowed
  final bool allowBackgroundExecution;

  /// Battery optimization level
  final String batteryOptimizationLevel;

  /// Memory optimization level
  final String memoryOptimizationLevel;

  const MobileContext({
    required this.optimizeForMobile,
    this.allowOffline = false,
    this.allowBackgroundExecution = false,
    required this.batteryOptimizationLevel,
    required this.memoryOptimizationLevel,
  });

  factory MobileContext.fromJson(Map<String, dynamic> json) =>
      _$MobileContextFromJson(json);

  Map<String, dynamic> toJson() => _$MobileContextToJson(this);

  @override
  List<Object?> get props => [
        optimizeForMobile,
        allowOffline,
        allowBackgroundExecution,
        batteryOptimizationLevel,
        memoryOptimizationLevel,
      ];

  @override
  String toString() =>
      'MobileContext(optimized: $optimizeForMobile, battery: $batteryOptimizationLevel)';
}

/// Execution priority levels
enum ExecutionPriority {
  /// Low priority execution
  @JsonValue('low')
  low,

  /// Normal priority execution
  @JsonValue('normal')
  normal,

  /// High priority execution
  @JsonValue('high')
  high,

  /// Critical priority execution
  @JsonValue('critical')
  critical,
}

/// Represents the status of a tool call
@JsonSerializable()
class ToolCallStatus extends Equatable {
  /// Unique identifier for the status update
  final String id;

  /// Tool call ID this status belongs to
  final String toolCallId;

  /// Current status
  final ToolCallState state;

  /// Progress percentage (0.0 to 1.0)
  final double progress;

  /// Status message
  final String message;

  /// Timestamp of the status update
  final DateTime timestamp;

  /// Error information if failed
  final ToolCallError? error;

  /// Performance metrics
  final ToolCallMetrics? metrics;

  const ToolCallStatus({
    required this.id,
    required this.toolCallId,
    required this.state,
    required this.progress,
    required this.message,
    required this.timestamp,
    this.error,
    this.metrics,
  });

  factory ToolCallStatus.fromJson(Map<String, dynamic> json) =>
      _$ToolCallStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallStatusToJson(this);

  @override
  List<Object?> get props => [
        id,
        toolCallId,
        state,
        progress,
        message,
        timestamp,
        error,
        metrics,
      ];

  @override
  String toString() =>
      'ToolCallStatus(id: $toolCallId, state: $state, progress: ${(progress * 100).toInt()}%)';
}

/// Tool call execution states
enum ToolCallState {
  /// Tool call is queued
  @JsonValue('queued')
  queued,

  /// Tool call is running
  @JsonValue('running')
  running,

  /// Tool call completed successfully
  @JsonValue('completed')
  completed,

  /// Tool call failed
  @JsonValue('failed')
  failed,

  /// Tool call was cancelled
  @JsonValue('cancelled')
  cancelled,

  /// Tool call timed out
  @JsonValue('timeout')
  timeout,
}

/// Error information for a failed tool call
@JsonSerializable()
class ToolCallError extends Equatable {
  /// Error code
  final String code;

  /// Error message
  final String message;

  /// Error details
  final Map<String, dynamic>? details;

  /// Stack trace if available
  final String? stackTrace;

  const ToolCallError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });

  factory ToolCallError.fromJson(Map<String, dynamic> json) =>
      _$ToolCallErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallErrorToJson(this);

  @override
  List<Object?> get props => [code, message, details, stackTrace];

  @override
  String toString() => 'ToolCallError(code: $code, message: $message)';
}

/// Performance metrics for a tool call
@JsonSerializable()
class ToolCallMetrics extends Equatable {
  /// Execution time
  final Duration executionTime;

  /// Memory usage in MB
  final double memoryUsageMB;

  /// CPU usage percentage
  final double cpuUsagePercent;

  /// Network usage in KB
  final double networkUsageKB;

  /// Battery consumption percentage
  final double batteryConsumptionPercent;

  const ToolCallMetrics({
    required this.executionTime,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.networkUsageKB,
    required this.batteryConsumptionPercent,
  });

  factory ToolCallMetrics.fromJson(Map<String, dynamic> json) =>
      _$ToolCallMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallMetricsToJson(this);

  @override
  List<Object?> get props => [
        executionTime,
        memoryUsageMB,
        cpuUsagePercent,
        networkUsageKB,
        batteryConsumptionPercent,
      ];

  @override
  String toString() =>
      'ToolCallMetrics(time: ${executionTime.inMilliseconds}ms, memory: ${memoryUsageMB}MB)';
}

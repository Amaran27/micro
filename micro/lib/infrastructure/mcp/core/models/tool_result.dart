import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_result.g.dart';

/// Represents the result of a tool execution
@JsonSerializable()
class ToolResult extends Equatable {
  /// Unique identifier for the result
  final String id;

  /// Tool call ID this result belongs to
  final String toolCallId;

  /// Execution status
  final ToolExecutionStatus status;

  /// Whether the execution was successful
  final bool isSuccess;

  /// Result data
  final dynamic data;

  /// Error information if execution failed
  final ToolResultError? error;

  /// Execution metadata
  final ToolResultMetadata metadata;

  /// Performance metrics
  final ToolResultMetrics metrics;

  /// Timestamp when the result was generated
  final DateTime timestamp;

  const ToolResult({
    required this.id,
    required this.toolCallId,
    required this.status,
    required this.isSuccess,
    this.data,
    this.error,
    required this.metadata,
    required this.metrics,
    required this.timestamp,
  });

  /// Creates a ToolResult from JSON
  factory ToolResult.fromJson(Map<String, dynamic> json) =>
      _$ToolResultFromJson(json);

  /// Converts ToolResult to JSON
  Map<String, dynamic> toJson() => _$ToolResultToJson(this);

  /// Creates a successful result
  factory ToolResult.success({
    required String id,
    required String toolCallId,
    required dynamic data,
    required ToolResultMetadata metadata,
    required ToolResultMetrics metrics,
  }) {
    return ToolResult(
      id: id,
      toolCallId: toolCallId,
      status: ToolExecutionStatus.completed,
      isSuccess: true,
      data: data,
      metadata: metadata,
      metrics: metrics,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a failed result
  factory ToolResult.failure({
    required String id,
    required String toolCallId,
    required ToolResultError error,
    required ToolResultMetadata metadata,
    required ToolResultMetrics metrics,
  }) {
    return ToolResult(
      id: id,
      toolCallId: toolCallId,
      status: ToolExecutionStatus.failed,
      isSuccess: false,
      error: error,
      metadata: metadata,
      metrics: metrics,
      timestamp: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        toolCallId,
        status,
        isSuccess,
        data,
        error,
        metadata,
        metrics,
        timestamp,
      ];

  @override
  String toString() =>
      'ToolResult(id: $id, status: $status, success: $isSuccess)';
}

/// Tool execution status
enum ToolExecutionStatus {
  /// Execution is pending
  @JsonValue('pending')
  pending,

  /// Execution is in progress
  @JsonValue('running')
  running,

  /// Execution completed successfully
  @JsonValue('completed')
  completed,

  /// Execution failed
  @JsonValue('failed')
  failed,

  /// Execution was cancelled
  @JsonValue('cancelled')
  cancelled,

  /// Execution timed out
  @JsonValue('timeout')
  timeout,
}

/// Error information for a failed tool execution
@JsonSerializable()
class ToolResultError extends Equatable {
  /// Error code
  final String code;

  /// Error message
  final String message;

  /// Error type
  final String type;

  /// Error details
  final Map<String, dynamic>? details;

  /// Stack trace if available
  final String? stackTrace;

  /// Whether the error is retryable
  final bool isRetryable;

  /// Suggested retry delay
  final Duration? retryDelay;

  const ToolResultError({
    required this.code,
    required this.message,
    required this.type,
    this.details,
    this.stackTrace,
    this.isRetryable = false,
    this.retryDelay,
  });

  factory ToolResultError.fromJson(Map<String, dynamic> json) =>
      _$ToolResultErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResultErrorToJson(this);

  @override
  List<Object?> get props => [
        code,
        message,
        type,
        details,
        stackTrace,
        isRetryable,
        retryDelay,
      ];

  @override
  String toString() =>
      'ToolResultError(code: $code, message: $message, type: $type)';
}

/// Metadata about the tool execution result
@JsonSerializable()
class ToolResultMetadata extends Equatable {
  /// Tool ID that was executed
  final String toolId;

  /// Tool name
  final String toolName;

  /// Server that provided the tool
  final String serverName;

  /// Capability that was used
  final String? capabilityId;

  /// Execution version
  final String executionVersion;

  /// Execution environment
  final String executionEnvironment;

  /// Security context used
  final Map<String, dynamic> securityContext;

  /// Compliance information
  final List<ComplianceInfo> complianceInfo;

  const ToolResultMetadata({
    required this.toolId,
    required this.toolName,
    required this.serverName,
    this.capabilityId,
    required this.executionVersion,
    required this.executionEnvironment,
    required this.securityContext,
    this.complianceInfo = const [],
  });

  factory ToolResultMetadata.fromJson(Map<String, dynamic> json) =>
      _$ToolResultMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResultMetadataToJson(this);

  @override
  List<Object?> get props => [
        toolId,
        toolName,
        serverName,
        capabilityId,
        executionVersion,
        executionEnvironment,
        securityContext,
        complianceInfo,
      ];

  @override
  String toString() =>
      'ToolResultMetadata(tool: $toolName, server: $serverName, version: $executionVersion)';
}

/// Compliance information
@JsonSerializable()
class ComplianceInfo extends Equatable {
  /// Compliance standard
  final String standard;

  /// Version of the standard
  final String version;

  /// Whether compliance was verified
  final bool isVerified;

  /// Verification details
  final Map<String, dynamic>? verificationDetails;

  const ComplianceInfo({
    required this.standard,
    required this.version,
    required this.isVerified,
    this.verificationDetails,
  });

  factory ComplianceInfo.fromJson(Map<String, dynamic> json) =>
      _$ComplianceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ComplianceInfoToJson(this);

  @override
  List<Object?> get props =>
      [standard, version, isVerified, verificationDetails];

  @override
  String toString() =>
      'ComplianceInfo($standard v$version, verified: $isVerified)';
}

/// Performance metrics for the tool execution result
@JsonSerializable()
class ToolResultMetrics extends Equatable {
  /// Total execution time
  final Duration totalExecutionTime;

  /// CPU time used
  final Duration cpuTime;

  /// Memory usage in MB
  final double memoryUsageMB;

  /// Peak memory usage in MB
  final double peakMemoryUsageMB;

  /// Network usage in KB
  final double networkUsageKB;

  /// Disk usage in KB
  final double diskUsageKB;

  /// Battery consumption percentage
  final double batteryConsumptionPercent;

  /// Number of retry attempts
  final int retryAttempts;

  /// Cache hit rate (0.0 to 1.0)
  final double cacheHitRate;

  /// Mobile optimization score (0.0 to 1.0)
  final double mobileOptimizationScore;

  const ToolResultMetrics({
    required this.totalExecutionTime,
    required this.cpuTime,
    required this.memoryUsageMB,
    required this.peakMemoryUsageMB,
    required this.networkUsageKB,
    required this.diskUsageKB,
    required this.batteryConsumptionPercent,
    this.retryAttempts = 0,
    this.cacheHitRate = 0.0,
    this.mobileOptimizationScore = 0.0,
  });

  factory ToolResultMetrics.fromJson(Map<String, dynamic> json) =>
      _$ToolResultMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResultMetricsToJson(this);

  /// Checks if the execution meets mobile optimization requirements
  bool get meetsMobileOptimizationRequirements =>
      totalExecutionTime.inMilliseconds < 200 &&
      memoryUsageMB < 30 &&
      mobileOptimizationScore >= 0.8;

  @override
  List<Object?> get props => [
        totalExecutionTime,
        cpuTime,
        memoryUsageMB,
        peakMemoryUsageMB,
        networkUsageKB,
        diskUsageKB,
        batteryConsumptionPercent,
        retryAttempts,
        cacheHitRate,
        mobileOptimizationScore,
      ];

  @override
  String toString() =>
      'ToolResultMetrics(time: ${totalExecutionTime.inMilliseconds}ms, memory: ${memoryUsageMB}MB, mobile: $meetsMobileOptimizationRequirements)';
}

/// Represents a paginated result set
@JsonSerializable()
class PaginatedResult extends Equatable {
  /// List of items in the current page
  final List<dynamic> items;

  /// Current page number (1-based)
  final int currentPage;

  /// Total number of pages
  final int totalPages;

  /// Total number of items
  final int totalItems;

  /// Items per page
  final int itemsPerPage;

  /// Whether there's a next page
  final bool hasNextPage;

  /// Whether there's a previous page
  final bool hasPreviousPage;

  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResult.fromJson(Map<String, dynamic> json) =>
      _$PaginatedResultFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedResultToJson(this);

  @override
  List<Object?> get props => [
        items,
        currentPage,
        totalPages,
        totalItems,
        itemsPerPage,
        hasNextPage,
        hasPreviousPage,
      ];

  @override
  String toString() =>
      'PaginatedResult(page: $currentPage/$totalPages, items: ${items.length}/$totalItems)';
}

/// Represents a streaming result
@JsonSerializable()
class StreamingResult extends Equatable {
  /// Unique identifier for the stream
  final String streamId;

  /// Current chunk of data
  final dynamic chunk;

  /// Whether this is the final chunk
  final bool isFinal;

  /// Chunk index (0-based)
  final int chunkIndex;

  /// Total number of chunks (if known)
  final int? totalChunks;

  /// Stream metadata
  final Map<String, dynamic> metadata;

  const StreamingResult({
    required this.streamId,
    required this.chunk,
    required this.isFinal,
    required this.chunkIndex,
    this.totalChunks,
    this.metadata = const {},
  });

  factory StreamingResult.fromJson(Map<String, dynamic> json) =>
      _$StreamingResultFromJson(json);

  Map<String, dynamic> toJson() => _$StreamingResultToJson(this);

  @override
  List<Object?> get props => [
        streamId,
        chunk,
        isFinal,
        chunkIndex,
        totalChunks,
        metadata,
      ];

  @override
  String toString() =>
      'StreamingResult(id: $streamId, chunk: $chunkIndex${totalChunks != null ? '/$totalChunks' : ''}, final: $isFinal)';
}

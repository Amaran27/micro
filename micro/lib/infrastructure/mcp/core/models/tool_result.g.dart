// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolResult _$ToolResultFromJson(Map<String, dynamic> json) => ToolResult(
      id: json['id'] as String,
      toolCallId: json['toolCallId'] as String,
      status: $enumDecode(_$ToolExecutionStatusEnumMap, json['status']),
      isSuccess: json['isSuccess'] as bool,
      data: json['data'],
      error: json['error'] == null
          ? null
          : ToolResultError.fromJson(json['error'] as Map<String, dynamic>),
      metadata:
          ToolResultMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      metrics:
          ToolResultMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ToolResultToJson(ToolResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'toolCallId': instance.toolCallId,
      'status': _$ToolExecutionStatusEnumMap[instance.status]!,
      'isSuccess': instance.isSuccess,
      'data': instance.data,
      'error': instance.error,
      'metadata': instance.metadata,
      'metrics': instance.metrics,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$ToolExecutionStatusEnumMap = {
  ToolExecutionStatus.pending: 'pending',
  ToolExecutionStatus.running: 'running',
  ToolExecutionStatus.completed: 'completed',
  ToolExecutionStatus.failed: 'failed',
  ToolExecutionStatus.cancelled: 'cancelled',
  ToolExecutionStatus.timeout: 'timeout',
};

ToolResultError _$ToolResultErrorFromJson(Map<String, dynamic> json) =>
    ToolResultError(
      code: json['code'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      details: json['details'] as Map<String, dynamic>?,
      stackTrace: json['stackTrace'] as String?,
      isRetryable: json['isRetryable'] as bool? ?? false,
      retryDelay: json['retryDelay'] == null
          ? null
          : Duration(microseconds: (json['retryDelay'] as num).toInt()),
    );

Map<String, dynamic> _$ToolResultErrorToJson(ToolResultError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'type': instance.type,
      'details': instance.details,
      'stackTrace': instance.stackTrace,
      'isRetryable': instance.isRetryable,
      'retryDelay': instance.retryDelay?.inMicroseconds,
    };

ToolResultMetadata _$ToolResultMetadataFromJson(Map<String, dynamic> json) =>
    ToolResultMetadata(
      toolId: json['toolId'] as String,
      toolName: json['toolName'] as String,
      serverName: json['serverName'] as String,
      capabilityId: json['capabilityId'] as String?,
      executionVersion: json['executionVersion'] as String,
      executionEnvironment: json['executionEnvironment'] as String,
      securityContext: json['securityContext'] as Map<String, dynamic>,
      complianceInfo: (json['complianceInfo'] as List<dynamic>?)
              ?.map((e) => ComplianceInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ToolResultMetadataToJson(ToolResultMetadata instance) =>
    <String, dynamic>{
      'toolId': instance.toolId,
      'toolName': instance.toolName,
      'serverName': instance.serverName,
      'capabilityId': instance.capabilityId,
      'executionVersion': instance.executionVersion,
      'executionEnvironment': instance.executionEnvironment,
      'securityContext': instance.securityContext,
      'complianceInfo': instance.complianceInfo,
    };

ComplianceInfo _$ComplianceInfoFromJson(Map<String, dynamic> json) =>
    ComplianceInfo(
      standard: json['standard'] as String,
      version: json['version'] as String,
      isVerified: json['isVerified'] as bool,
      verificationDetails: json['verificationDetails'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ComplianceInfoToJson(ComplianceInfo instance) =>
    <String, dynamic>{
      'standard': instance.standard,
      'version': instance.version,
      'isVerified': instance.isVerified,
      'verificationDetails': instance.verificationDetails,
    };

ToolResultMetrics _$ToolResultMetricsFromJson(Map<String, dynamic> json) =>
    ToolResultMetrics(
      totalExecutionTime:
          Duration(microseconds: (json['totalExecutionTime'] as num).toInt()),
      cpuTime: Duration(microseconds: (json['cpuTime'] as num).toInt()),
      memoryUsageMB: (json['memoryUsageMB'] as num).toDouble(),
      peakMemoryUsageMB: (json['peakMemoryUsageMB'] as num).toDouble(),
      networkUsageKB: (json['networkUsageKB'] as num).toDouble(),
      diskUsageKB: (json['diskUsageKB'] as num).toDouble(),
      batteryConsumptionPercent:
          (json['batteryConsumptionPercent'] as num).toDouble(),
      retryAttempts: (json['retryAttempts'] as num?)?.toInt() ?? 0,
      cacheHitRate: (json['cacheHitRate'] as num?)?.toDouble() ?? 0.0,
      mobileOptimizationScore:
          (json['mobileOptimizationScore'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ToolResultMetricsToJson(ToolResultMetrics instance) =>
    <String, dynamic>{
      'totalExecutionTime': instance.totalExecutionTime.inMicroseconds,
      'cpuTime': instance.cpuTime.inMicroseconds,
      'memoryUsageMB': instance.memoryUsageMB,
      'peakMemoryUsageMB': instance.peakMemoryUsageMB,
      'networkUsageKB': instance.networkUsageKB,
      'diskUsageKB': instance.diskUsageKB,
      'batteryConsumptionPercent': instance.batteryConsumptionPercent,
      'retryAttempts': instance.retryAttempts,
      'cacheHitRate': instance.cacheHitRate,
      'mobileOptimizationScore': instance.mobileOptimizationScore,
    };

PaginatedResult _$PaginatedResultFromJson(Map<String, dynamic> json) =>
    PaginatedResult(
      items: json['items'] as List<dynamic>,
      currentPage: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalItems: (json['totalItems'] as num).toInt(),
      itemsPerPage: (json['itemsPerPage'] as num).toInt(),
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );

Map<String, dynamic> _$PaginatedResultToJson(PaginatedResult instance) =>
    <String, dynamic>{
      'items': instance.items,
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'totalItems': instance.totalItems,
      'itemsPerPage': instance.itemsPerPage,
      'hasNextPage': instance.hasNextPage,
      'hasPreviousPage': instance.hasPreviousPage,
    };

StreamingResult _$StreamingResultFromJson(Map<String, dynamic> json) =>
    StreamingResult(
      streamId: json['streamId'] as String,
      chunk: json['chunk'],
      isFinal: json['isFinal'] as bool,
      chunkIndex: (json['chunkIndex'] as num).toInt(),
      totalChunks: (json['totalChunks'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$StreamingResultToJson(StreamingResult instance) =>
    <String, dynamic>{
      'streamId': instance.streamId,
      'chunk': instance.chunk,
      'isFinal': instance.isFinal,
      'chunkIndex': instance.chunkIndex,
      'totalChunks': instance.totalChunks,
      'metadata': instance.metadata,
    };

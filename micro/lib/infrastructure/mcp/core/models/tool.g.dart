// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tool _$ToolFromJson(Map<String, dynamic> json) => Tool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      category: json['category'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => ToolCapability.fromJson(e as Map<String, dynamic>))
          .toList(),
      inputSchema: json['inputSchema'] as Map<String, dynamic>,
      outputSchema: json['outputSchema'] as Map<String, dynamic>,
      domainContext:
          DomainContext.fromJson(json['domainContext'] as Map<String, dynamic>),
      serverName: json['serverName'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      executionMetadata: ToolExecutionMetadata.fromJson(
          json['executionMetadata'] as Map<String, dynamic>),
      performanceMetrics: ToolPerformanceMetrics.fromJson(
          json['performanceMetrics'] as Map<String, dynamic>),
      securityRequirements: ToolSecurityRequirements.fromJson(
          json['securityRequirements'] as Map<String, dynamic>),
      mobileOptimizations: ToolMobileOptimizations.fromJson(
          json['mobileOptimizations'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ToolToJson(Tool instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'category': instance.category,
      'capabilities': instance.capabilities,
      'inputSchema': instance.inputSchema,
      'outputSchema': instance.outputSchema,
      'domainContext': instance.domainContext,
      'serverName': instance.serverName,
      'isAvailable': instance.isAvailable,
      'executionMetadata': instance.executionMetadata,
      'performanceMetrics': instance.performanceMetrics,
      'securityRequirements': instance.securityRequirements,
      'mobileOptimizations': instance.mobileOptimizations,
    };

ToolExecutionMetadata _$ToolExecutionMetadataFromJson(
        Map<String, dynamic> json) =>
    ToolExecutionMetadata(
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      timeout: Duration(microseconds: (json['timeout'] as num).toInt()),
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
      requiresAuth: json['requiresAuth'] as bool? ?? false,
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$ToolExecutionMetadataToJson(
        ToolExecutionMetadata instance) =>
    <String, dynamic>{
      'author': instance.author,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'timeout': instance.timeout.inMicroseconds,
      'maxRetries': instance.maxRetries,
      'requiresAuth': instance.requiresAuth,
      'requiredPermissions': instance.requiredPermissions,
      'tags': instance.tags,
    };

ToolPerformanceMetrics _$ToolPerformanceMetricsFromJson(
        Map<String, dynamic> json) =>
    ToolPerformanceMetrics(
      averageExecutionTime:
          Duration(microseconds: (json['averageExecutionTime'] as num).toInt()),
      memoryUsageMB: (json['memoryUsageMB'] as num).toDouble(),
      successRate: (json['successRate'] as num).toDouble(),
      executionCount: (json['executionCount'] as num).toInt(),
      lastExecution: json['lastExecution'] == null
          ? null
          : DateTime.parse(json['lastExecution'] as String),
      networkBandwidthKBps: (json['networkBandwidthKBps'] as num).toDouble(),
    );

Map<String, dynamic> _$ToolPerformanceMetricsToJson(
        ToolPerformanceMetrics instance) =>
    <String, dynamic>{
      'averageExecutionTime': instance.averageExecutionTime.inMicroseconds,
      'memoryUsageMB': instance.memoryUsageMB,
      'successRate': instance.successRate,
      'executionCount': instance.executionCount,
      'lastExecution': instance.lastExecution?.toIso8601String(),
      'networkBandwidthKBps': instance.networkBandwidthKBps,
    };

ToolSecurityRequirements _$ToolSecurityRequirementsFromJson(
        Map<String, dynamic> json) =>
    ToolSecurityRequirements(
      securityLevel: json['securityLevel'] as String,
      requiresEncryption: json['requiresEncryption'] as bool? ?? false,
      dataSensitivity: json['dataSensitivity'] as String,
      auditRequirements: (json['auditRequirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      complianceRequirements: (json['complianceRequirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ToolSecurityRequirementsToJson(
        ToolSecurityRequirements instance) =>
    <String, dynamic>{
      'securityLevel': instance.securityLevel,
      'requiresEncryption': instance.requiresEncryption,
      'dataSensitivity': instance.dataSensitivity,
      'auditRequirements': instance.auditRequirements,
      'complianceRequirements': instance.complianceRequirements,
    };

ToolMobileOptimizations _$ToolMobileOptimizationsFromJson(
        Map<String, dynamic> json) =>
    ToolMobileOptimizations(
      isOptimized: json['isOptimized'] as bool,
      supportsOffline: json['supportsOffline'] as bool? ?? false,
      batteryOptimization: json['batteryOptimization'] as String,
      networkOptimized: json['networkOptimized'] as bool? ?? false,
      memoryOptimizations: (json['memoryOptimizations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      supportsBackgroundExecution:
          json['supportsBackgroundExecution'] as bool? ?? false,
    );

Map<String, dynamic> _$ToolMobileOptimizationsToJson(
        ToolMobileOptimizations instance) =>
    <String, dynamic>{
      'isOptimized': instance.isOptimized,
      'supportsOffline': instance.supportsOffline,
      'batteryOptimization': instance.batteryOptimization,
      'networkOptimized': instance.networkOptimized,
      'memoryOptimizations': instance.memoryOptimizations,
      'supportsBackgroundExecution': instance.supportsBackgroundExecution,
    };

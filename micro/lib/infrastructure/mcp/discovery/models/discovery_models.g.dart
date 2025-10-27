// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoveredTool _$DiscoveredToolFromJson(Map<String, dynamic> json) =>
    DiscoveredTool(
      tool: Tool.fromJson(json['tool'] as Map<String, dynamic>),
      sourceName: json['sourceName'] as String,
      sourceType: $enumDecode(_$DiscoverySourceTypeEnumMap, json['sourceType']),
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      discoveryMetadata:
          json['discoveryMetadata'] as Map<String, dynamic>? ?? const {},
      isReachable: json['isReachable'] as bool? ?? true,
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt'] as String),
      discoveryLatencyMs: (json['discoveryLatencyMs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DiscoveredToolToJson(DiscoveredTool instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'sourceName': instance.sourceName,
      'sourceType': _$DiscoverySourceTypeEnumMap[instance.sourceType]!,
      'discoveredAt': instance.discoveredAt.toIso8601String(),
      'confidenceScore': instance.confidenceScore,
      'discoveryMetadata': instance.discoveryMetadata,
      'isReachable': instance.isReachable,
      'lastVerifiedAt': instance.lastVerifiedAt?.toIso8601String(),
      'discoveryLatencyMs': instance.discoveryLatencyMs,
    };

const _$DiscoverySourceTypeEnumMap = {
  DiscoverySourceType.localDevice: 'localDevice',
  DiscoverySourceType.network: 'network',
  DiscoverySourceType.mcpServer: 'mcpServer',
  DiscoverySourceType.cloudRegistry: 'cloudRegistry',
  DiscoverySourceType.manual: 'manual',
  DiscoverySourceType.cache: 'cache',
};

ToolClassification _$ToolClassificationFromJson(Map<String, dynamic> json) =>
    ToolClassification(
      primaryCategory: json['primaryCategory'] as String,
      secondaryCategories: (json['secondaryCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      method: $enumDecode(_$ClassificationMethodEnumMap, json['method']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      securityLevel: $enumDecode(_$SecurityLevelEnumMap, json['securityLevel']),
      mobileOptimizationLevel: $enumDecode(
          _$MobileOptimizationLevelEnumMap, json['mobileOptimizationLevel']),
      performanceClass:
          $enumDecode(_$PerformanceClassEnumMap, json['performanceClass']),
      classificationMetadata:
          json['classificationMetadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ToolClassificationToJson(ToolClassification instance) =>
    <String, dynamic>{
      'primaryCategory': instance.primaryCategory,
      'secondaryCategories': instance.secondaryCategories,
      'confidenceScore': instance.confidenceScore,
      'method': _$ClassificationMethodEnumMap[instance.method]!,
      'tags': instance.tags,
      'securityLevel': _$SecurityLevelEnumMap[instance.securityLevel]!,
      'mobileOptimizationLevel':
          _$MobileOptimizationLevelEnumMap[instance.mobileOptimizationLevel]!,
      'performanceClass': _$PerformanceClassEnumMap[instance.performanceClass]!,
      'classificationMetadata': instance.classificationMetadata,
    };

const _$ClassificationMethodEnumMap = {
  ClassificationMethod.manual: 'manual',
  ClassificationMethod.automated: 'automated',
  ClassificationMethod.mlBased: 'mlBased',
  ClassificationMethod.hybrid: 'hybrid',
  ClassificationMethod.behaviorBased: 'behaviorBased',
};

const _$SecurityLevelEnumMap = {
  SecurityLevel.none: 'none',
  SecurityLevel.basic: 'basic',
  SecurityLevel.standard: 'standard',
  SecurityLevel.high: 'high',
  SecurityLevel.critical: 'critical',
};

const _$MobileOptimizationLevelEnumMap = {
  MobileOptimizationLevel.none: 'none',
  MobileOptimizationLevel.basic: 'basic',
  MobileOptimizationLevel.good: 'good',
  MobileOptimizationLevel.excellent: 'excellent',
  MobileOptimizationLevel.native: 'native',
};

const _$PerformanceClassEnumMap = {
  PerformanceClass.low: 'low',
  PerformanceClass.medium: 'medium',
  PerformanceClass.high: 'high',
  PerformanceClass.realtime: 'realtime',
  PerformanceClass.batch: 'batch',
};

ToolValidation _$ToolValidationFromJson(Map<String, dynamic> json) =>
    ToolValidation(
      status: $enumDecode(_$ValidationStatusEnumMap, json['status']),
      validationScore: (json['validationScore'] as num).toDouble(),
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map(
                  (e) => ValidationWarning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      schemaValidation: SchemaValidationResult.fromJson(
          json['schemaValidation'] as Map<String, dynamic>),
      securityValidation: SecurityValidationResult.fromJson(
          json['securityValidation'] as Map<String, dynamic>),
      mobileValidation: MobileValidationResult.fromJson(
          json['mobileValidation'] as Map<String, dynamic>),
      performanceValidation: PerformanceValidationResult.fromJson(
          json['performanceValidation'] as Map<String, dynamic>),
      validatedAt: DateTime.parse(json['validatedAt'] as String),
      validationDurationMs:
          (json['validationDurationMs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ToolValidationToJson(ToolValidation instance) =>
    <String, dynamic>{
      'status': _$ValidationStatusEnumMap[instance.status]!,
      'validationScore': instance.validationScore,
      'errors': instance.errors,
      'warnings': instance.warnings,
      'schemaValidation': instance.schemaValidation,
      'securityValidation': instance.securityValidation,
      'mobileValidation': instance.mobileValidation,
      'performanceValidation': instance.performanceValidation,
      'validatedAt': instance.validatedAt.toIso8601String(),
      'validationDurationMs': instance.validationDurationMs,
    };

const _$ValidationStatusEnumMap = {
  ValidationStatus.passed: 'passed',
  ValidationStatus.passedWithWarnings: 'passedWithWarnings',
  ValidationStatus.failed: 'failed',
  ValidationStatus.incomplete: 'incomplete',
};

ValidationError _$ValidationErrorFromJson(Map<String, dynamic> json) =>
    ValidationError(
      code: json['code'] as String,
      message: json['message'] as String,
      severity: $enumDecode(_$ErrorSeverityEnumMap, json['severity']),
      category: json['category'] as String,
      field: json['field'] as String?,
      suggestedFix: json['suggestedFix'] as String?,
      context: json['context'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'severity': _$ErrorSeverityEnumMap[instance.severity]!,
      'category': instance.category,
      'field': instance.field,
      'suggestedFix': instance.suggestedFix,
      'context': instance.context,
    };

const _$ErrorSeverityEnumMap = {
  ErrorSeverity.low: 'low',
  ErrorSeverity.medium: 'medium',
  ErrorSeverity.high: 'high',
  ErrorSeverity.critical: 'critical',
};

ValidationWarning _$ValidationWarningFromJson(Map<String, dynamic> json) =>
    ValidationWarning(
      code: json['code'] as String,
      message: json['message'] as String,
      category: json['category'] as String,
      field: json['field'] as String?,
      recommendation: json['recommendation'] as String?,
      context: json['context'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ValidationWarningToJson(ValidationWarning instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'category': instance.category,
      'field': instance.field,
      'recommendation': instance.recommendation,
      'context': instance.context,
    };

SchemaValidationResult _$SchemaValidationResultFromJson(
        Map<String, dynamic> json) =>
    SchemaValidationResult(
      isValid: json['isValid'] as bool,
      inputSchemaValid: json['inputSchemaValid'] as bool,
      outputSchemaValid: json['outputSchemaValid'] as bool,
      schemaErrors: (json['schemaErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SchemaValidationResultToJson(
        SchemaValidationResult instance) =>
    <String, dynamic>{
      'isValid': instance.isValid,
      'inputSchemaValid': instance.inputSchemaValid,
      'outputSchemaValid': instance.outputSchemaValid,
      'schemaErrors': instance.schemaErrors,
    };

SecurityValidationResult _$SecurityValidationResultFromJson(
        Map<String, dynamic> json) =>
    SecurityValidationResult(
      isSecure: json['isSecure'] as bool,
      securityLevelValid: json['securityLevelValid'] as bool,
      encryptionValid: json['encryptionValid'] as bool,
      authValid: json['authValid'] as bool,
      authzValid: json['authzValid'] as bool,
      securityErrors: (json['securityErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SecurityValidationResultToJson(
        SecurityValidationResult instance) =>
    <String, dynamic>{
      'isSecure': instance.isSecure,
      'securityLevelValid': instance.securityLevelValid,
      'encryptionValid': instance.encryptionValid,
      'authValid': instance.authValid,
      'authzValid': instance.authzValid,
      'securityErrors': instance.securityErrors,
    };

MobileValidationResult _$MobileValidationResultFromJson(
        Map<String, dynamic> json) =>
    MobileValidationResult(
      isMobileCompatible: json['isMobileCompatible'] as bool,
      memoryUsageValid: json['memoryUsageValid'] as bool,
      batteryUsageValid: json['batteryUsageValid'] as bool,
      networkUsageValid: json['networkUsageValid'] as bool,
      offlineCapabilityValid: json['offlineCapabilityValid'] as bool,
      mobileErrors: (json['mobileErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MobileValidationResultToJson(
        MobileValidationResult instance) =>
    <String, dynamic>{
      'isMobileCompatible': instance.isMobileCompatible,
      'memoryUsageValid': instance.memoryUsageValid,
      'batteryUsageValid': instance.batteryUsageValid,
      'networkUsageValid': instance.networkUsageValid,
      'offlineCapabilityValid': instance.offlineCapabilityValid,
      'mobileErrors': instance.mobileErrors,
    };

PerformanceValidationResult _$PerformanceValidationResultFromJson(
        Map<String, dynamic> json) =>
    PerformanceValidationResult(
      isPerformant: json['isPerformant'] as bool,
      executionTimeValid: json['executionTimeValid'] as bool,
      memoryValid: json['memoryValid'] as bool,
      cpuValid: json['cpuValid'] as bool,
      bandwidthValid: json['bandwidthValid'] as bool,
      performanceErrors: (json['performanceErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PerformanceValidationResultToJson(
        PerformanceValidationResult instance) =>
    <String, dynamic>{
      'isPerformant': instance.isPerformant,
      'executionTimeValid': instance.executionTimeValid,
      'memoryValid': instance.memoryValid,
      'cpuValid': instance.cpuValid,
      'bandwidthValid': instance.bandwidthValid,
      'performanceErrors': instance.performanceErrors,
    };

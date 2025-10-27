// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_capability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCapability _$ToolCapabilityFromJson(Map<String, dynamic> json) =>
    ToolCapability(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
      inputParameters: (json['inputParameters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, CapabilityParameter.fromJson(e as Map<String, dynamic>)),
      ),
      outputParameters: (json['outputParameters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, CapabilityParameter.fromJson(e as Map<String, dynamic>)),
      ),
      constraints: CapabilityConstraints.fromJson(
          json['constraints'] as Map<String, dynamic>),
      securityRequirements: (json['securityRequirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      performance: CapabilityPerformance.fromJson(
          json['performance'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ToolCapabilityToJson(ToolCapability instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'isPrimary': instance.isPrimary,
      'inputParameters': instance.inputParameters,
      'outputParameters': instance.outputParameters,
      'constraints': instance.constraints,
      'securityRequirements': instance.securityRequirements,
      'performance': instance.performance,
    };

CapabilityParameter _$CapabilityParameterFromJson(Map<String, dynamic> json) =>
    CapabilityParameter(
      name: json['name'] as String,
      dataType: json['dataType'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      description: json['description'] as String,
      validationRules: (json['validationRules'] as List<dynamic>?)
              ?.map((e) => ValidationRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      examples: json['examples'] as List<dynamic>? ?? const [],
    );

Map<String, dynamic> _$CapabilityParameterToJson(
        CapabilityParameter instance) =>
    <String, dynamic>{
      'name': instance.name,
      'dataType': instance.dataType,
      'isRequired': instance.isRequired,
      'defaultValue': instance.defaultValue,
      'description': instance.description,
      'validationRules': instance.validationRules,
      'examples': instance.examples,
    };

ValidationRule _$ValidationRuleFromJson(Map<String, dynamic> json) =>
    ValidationRule(
      type: json['type'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      errorMessage: json['errorMessage'] as String,
    );

Map<String, dynamic> _$ValidationRuleToJson(ValidationRule instance) =>
    <String, dynamic>{
      'type': instance.type,
      'parameters': instance.parameters,
      'errorMessage': instance.errorMessage,
    };

CapabilityConstraints _$CapabilityConstraintsFromJson(
        Map<String, dynamic> json) =>
    CapabilityConstraints(
      maxExecutionTime:
          Duration(microseconds: (json['maxExecutionTime'] as num).toInt()),
      maxMemoryUsageMB: (json['maxMemoryUsageMB'] as num).toDouble(),
      maxNetworkBandwidthKBps:
          (json['maxNetworkBandwidthKBps'] as num).toDouble(),
      rateLimit: json['rateLimit'] == null
          ? null
          : RateLimit.fromJson(json['rateLimit'] as Map<String, dynamic>),
      resourceRequirements:
          json['resourceRequirements'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CapabilityConstraintsToJson(
        CapabilityConstraints instance) =>
    <String, dynamic>{
      'maxExecutionTime': instance.maxExecutionTime.inMicroseconds,
      'maxMemoryUsageMB': instance.maxMemoryUsageMB,
      'maxNetworkBandwidthKBps': instance.maxNetworkBandwidthKBps,
      'rateLimit': instance.rateLimit,
      'resourceRequirements': instance.resourceRequirements,
    };

RateLimit _$RateLimitFromJson(Map<String, dynamic> json) => RateLimit(
      maxRequests: (json['maxRequests'] as num).toInt(),
      period: Duration(microseconds: (json['period'] as num).toInt()),
      strategy: json['strategy'] as String,
    );

Map<String, dynamic> _$RateLimitToJson(RateLimit instance) => <String, dynamic>{
      'maxRequests': instance.maxRequests,
      'period': instance.period.inMicroseconds,
      'strategy': instance.strategy,
    };

CapabilityPerformance _$CapabilityPerformanceFromJson(
        Map<String, dynamic> json) =>
    CapabilityPerformance(
      averageExecutionTime:
          Duration(microseconds: (json['averageExecutionTime'] as num).toInt()),
      memoryUsageMB: (json['memoryUsageMB'] as num).toDouble(),
      cpuUsagePercent: (json['cpuUsagePercent'] as num).toDouble(),
      networkUsageKB: (json['networkUsageKB'] as num).toDouble(),
      successRate: (json['successRate'] as num).toDouble(),
      mobileOptimizationScore:
          (json['mobileOptimizationScore'] as num).toDouble(),
    );

Map<String, dynamic> _$CapabilityPerformanceToJson(
        CapabilityPerformance instance) =>
    <String, dynamic>{
      'averageExecutionTime': instance.averageExecutionTime.inMicroseconds,
      'memoryUsageMB': instance.memoryUsageMB,
      'cpuUsagePercent': instance.cpuUsagePercent,
      'networkUsageKB': instance.networkUsageKB,
      'successRate': instance.successRate,
      'mobileOptimizationScore': instance.mobileOptimizationScore,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adapter_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdaptationResult _$AdaptationResultFromJson(Map<String, dynamic> json) =>
    AdaptationResult(
      id: json['id'] as String,
      originalTool: Tool.fromJson(json['originalTool'] as Map<String, dynamic>),
      adaptedTool: Tool.fromJson(json['adaptedTool'] as Map<String, dynamic>),
      targetContext:
          DomainContext.fromJson(json['targetContext'] as Map<String, dynamic>),
      isSuccess: json['isSuccess'] as bool,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      adaptationDetails: json['adaptationDetails'] as Map<String, dynamic>,
      parameterMappings: (json['parameterMappings'] as List<dynamic>)
          .map((e) => ParameterMapping.fromJson(e as Map<String, dynamic>))
          .toList(),
      performanceImpact: AdaptationPerformanceImpact.fromJson(
          json['performanceImpact'] as Map<String, dynamic>),
      securityAssessment: SecurityAssessment.fromJson(
          json['securityAssessment'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$AdaptationResultToJson(AdaptationResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalTool': instance.originalTool,
      'adaptedTool': instance.adaptedTool,
      'targetContext': instance.targetContext,
      'isSuccess': instance.isSuccess,
      'confidenceScore': instance.confidenceScore,
      'adaptationDetails': instance.adaptationDetails,
      'parameterMappings': instance.parameterMappings,
      'performanceImpact': instance.performanceImpact,
      'securityAssessment': instance.securityAssessment,
      'timestamp': instance.timestamp.toIso8601String(),
    };

SecurityAssessment _$SecurityAssessmentFromJson(Map<String, dynamic> json) =>
    SecurityAssessment(
      id: json['id'] as String,
      riskLevel: $enumDecode(_$SecurityRiskLevelEnumMap, json['riskLevel']),
      securityScore: (json['securityScore'] as num).toDouble(),
      securityIssues: (json['securityIssues'] as List<dynamic>)
          .map((e) => SecurityIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      requiredMeasures: (json['requiredMeasures'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      complianceStatus: Map<String, bool>.from(json['complianceStatus'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SecurityAssessmentToJson(SecurityAssessment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'riskLevel': _$SecurityRiskLevelEnumMap[instance.riskLevel]!,
      'securityScore': instance.securityScore,
      'securityIssues': instance.securityIssues,
      'recommendations': instance.recommendations,
      'requiredMeasures': instance.requiredMeasures,
      'complianceStatus': instance.complianceStatus,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$SecurityRiskLevelEnumMap = {
  SecurityRiskLevel.low: 'low',
  SecurityRiskLevel.medium: 'medium',
  SecurityRiskLevel.high: 'high',
  SecurityRiskLevel.critical: 'critical',
};

SecurityIssue _$SecurityIssueFromJson(Map<String, dynamic> json) =>
    SecurityIssue(
      id: json['id'] as String,
      type: json['type'] as String,
      severity: $enumDecode(_$SecurityRiskLevelEnumMap, json['severity']),
      description: json['description'] as String,
      affectedComponents: (json['affectedComponents'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      potentialImpact: json['potentialImpact'] as String,
      mitigationSteps: (json['mitigationSteps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SecurityIssueToJson(SecurityIssue instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'severity': _$SecurityRiskLevelEnumMap[instance.severity]!,
      'description': instance.description,
      'affectedComponents': instance.affectedComponents,
      'potentialImpact': instance.potentialImpact,
      'mitigationSteps': instance.mitigationSteps,
    };

ParameterMapping _$ParameterMappingFromJson(Map<String, dynamic> json) =>
    ParameterMapping(
      sourceParameter: json['sourceParameter'] as String,
      targetParameter: json['targetParameter'] as String,
      sourceType: json['sourceType'] as String,
      targetType: json['targetType'] as String,
      transformationFunction: json['transformationFunction'] as String?,
      defaultValue: json['defaultValue'],
      isRequired: json['isRequired'] as bool? ?? false,
      validationRules: (json['validationRules'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ParameterMappingToJson(ParameterMapping instance) =>
    <String, dynamic>{
      'sourceParameter': instance.sourceParameter,
      'targetParameter': instance.targetParameter,
      'sourceType': instance.sourceType,
      'targetType': instance.targetType,
      'transformationFunction': instance.transformationFunction,
      'defaultValue': instance.defaultValue,
      'isRequired': instance.isRequired,
      'validationRules': instance.validationRules,
    };

ExecutionEnvironment _$ExecutionEnvironmentFromJson(
        Map<String, dynamic> json) =>
    ExecutionEnvironment(
      id: json['id'] as String,
      type: json['type'] as String,
      resourceLimits: ResourceLimits.fromJson(
          json['resourceLimits'] as Map<String, dynamic>),
      securityPolicies: (json['securityPolicies'] as List<dynamic>)
          .map((e) => SecurityPolicy.fromJson(e as Map<String, dynamic>))
          .toList(),
      networkConfiguration: NetworkConfiguration.fromJson(
          json['networkConfiguration'] as Map<String, dynamic>),
      environmentVariables:
          Map<String, String>.from(json['environmentVariables'] as Map),
      availableCapabilities: (json['availableCapabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isolationLevel:
          $enumDecode(_$IsolationLevelEnumMap, json['isolationLevel']),
    );

Map<String, dynamic> _$ExecutionEnvironmentToJson(
        ExecutionEnvironment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'resourceLimits': instance.resourceLimits,
      'securityPolicies': instance.securityPolicies,
      'networkConfiguration': instance.networkConfiguration,
      'environmentVariables': instance.environmentVariables,
      'availableCapabilities': instance.availableCapabilities,
      'isolationLevel': _$IsolationLevelEnumMap[instance.isolationLevel]!,
    };

const _$IsolationLevelEnumMap = {
  IsolationLevel.none: 'none',
  IsolationLevel.process: 'process',
  IsolationLevel.container: 'container',
  IsolationLevel.vm: 'vm',
  IsolationLevel.sandbox: 'sandbox',
};

ResourceLimits _$ResourceLimitsFromJson(Map<String, dynamic> json) =>
    ResourceLimits(
      maxMemoryMB: (json['maxMemoryMB'] as num).toDouble(),
      maxCpuPercent: (json['maxCpuPercent'] as num).toDouble(),
      maxExecutionTime:
          Duration(microseconds: (json['maxExecutionTime'] as num).toInt()),
      maxNetworkMB: (json['maxNetworkMB'] as num).toDouble(),
      maxDiskMB: (json['maxDiskMB'] as num).toDouble(),
    );

Map<String, dynamic> _$ResourceLimitsToJson(ResourceLimits instance) =>
    <String, dynamic>{
      'maxMemoryMB': instance.maxMemoryMB,
      'maxCpuPercent': instance.maxCpuPercent,
      'maxExecutionTime': instance.maxExecutionTime.inMicroseconds,
      'maxNetworkMB': instance.maxNetworkMB,
      'maxDiskMB': instance.maxDiskMB,
    };

SecurityPolicy _$SecurityPolicyFromJson(Map<String, dynamic> json) =>
    SecurityPolicy(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      rules: json['rules'] as Map<String, dynamic>,
      enforcementLevel:
          $enumDecode(_$EnforcementLevelEnumMap, json['enforcementLevel']),
    );

Map<String, dynamic> _$SecurityPolicyToJson(SecurityPolicy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'rules': instance.rules,
      'enforcementLevel': _$EnforcementLevelEnumMap[instance.enforcementLevel]!,
    };

const _$EnforcementLevelEnumMap = {
  EnforcementLevel.advisory: 'advisory',
  EnforcementLevel.warning: 'warning',
  EnforcementLevel.block: 'block',
  EnforcementLevel.terminate: 'terminate',
};

NetworkConfiguration _$NetworkConfigurationFromJson(
        Map<String, dynamic> json) =>
    NetworkConfiguration(
      allowNetworkAccess: json['allowNetworkAccess'] as bool,
      allowedDomains: (json['allowedDomains'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      blockedDomains: (json['blockedDomains'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      maxBandwidthKBps: (json['maxBandwidthKBps'] as num).toDouble(),
      proxyConfiguration: json['proxyConfiguration'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NetworkConfigurationToJson(
        NetworkConfiguration instance) =>
    <String, dynamic>{
      'allowNetworkAccess': instance.allowNetworkAccess,
      'allowedDomains': instance.allowedDomains,
      'blockedDomains': instance.blockedDomains,
      'maxBandwidthKBps': instance.maxBandwidthKBps,
      'proxyConfiguration': instance.proxyConfiguration,
    };

AdaptationPerformanceImpact _$AdaptationPerformanceImpactFromJson(
        Map<String, dynamic> json) =>
    AdaptationPerformanceImpact(
      executionTimeOverheadPercent:
          (json['executionTimeOverheadPercent'] as num).toDouble(),
      memoryOverheadPercent: (json['memoryOverheadPercent'] as num).toDouble(),
      networkOverheadPercent:
          (json['networkOverheadPercent'] as num).toDouble(),
      cpuOverheadPercent: (json['cpuOverheadPercent'] as num).toDouble(),
    );

Map<String, dynamic> _$AdaptationPerformanceImpactToJson(
        AdaptationPerformanceImpact instance) =>
    <String, dynamic>{
      'executionTimeOverheadPercent': instance.executionTimeOverheadPercent,
      'memoryOverheadPercent': instance.memoryOverheadPercent,
      'networkOverheadPercent': instance.networkOverheadPercent,
      'cpuOverheadPercent': instance.cpuOverheadPercent,
    };

AdapterPerformanceMetrics _$AdapterPerformanceMetricsFromJson(
        Map<String, dynamic> json) =>
    AdapterPerformanceMetrics(
      totalAdaptations: (json['totalAdaptations'] as num).toInt(),
      successfulAdaptations: (json['successfulAdaptations'] as num).toInt(),
      averageAdaptationTimeMs:
          (json['averageAdaptationTimeMs'] as num).toDouble(),
      cacheHitRate: (json['cacheHitRate'] as num).toDouble(),
      memoryUsageMB: (json['memoryUsageMB'] as num).toDouble(),
      cpuUsagePercent: (json['cpuUsagePercent'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$AdapterPerformanceMetricsToJson(
        AdapterPerformanceMetrics instance) =>
    <String, dynamic>{
      'totalAdaptations': instance.totalAdaptations,
      'successfulAdaptations': instance.successfulAdaptations,
      'averageAdaptationTimeMs': instance.averageAdaptationTimeMs,
      'cacheHitRate': instance.cacheHitRate,
      'memoryUsageMB': instance.memoryUsageMB,
      'cpuUsagePercent': instance.cpuUsagePercent,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

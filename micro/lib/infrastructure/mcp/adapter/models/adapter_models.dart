import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/models/tool.dart';
import '../../core/models/domain_context.dart';

part 'adapter_models.g.dart';

/// Result of tool adaptation process
@JsonSerializable()
class AdaptationResult extends Equatable {
  /// Unique identifier for the adaptation result
  final String id;

  /// Tool that was adapted
  final Tool originalTool;

  /// Adapted tool
  final Tool adaptedTool;

  /// Target domain context
  final DomainContext targetContext;

  /// Whether the adaptation was successful
  final bool isSuccess;

  /// Adaptation confidence score (0.0 to 1.0)
  final double confidenceScore;

  /// Adaptation details
  final Map<String, dynamic> adaptationDetails;

  /// Parameter mappings applied
  final List<ParameterMapping> parameterMappings;

  /// Performance impact of adaptation
  final AdaptationPerformanceImpact performanceImpact;

  /// Security assessment
  final SecurityAssessment securityAssessment;

  /// Timestamp when adaptation was performed
  final DateTime timestamp;

  const AdaptationResult({
    required this.id,
    required this.originalTool,
    required this.adaptedTool,
    required this.targetContext,
    required this.isSuccess,
    required this.confidenceScore,
    required this.adaptationDetails,
    required this.parameterMappings,
    required this.performanceImpact,
    required this.securityAssessment,
    required this.timestamp,
  });

  /// Creates a successful adaptation result
  factory AdaptationResult.success({
    required String id,
    required Tool originalTool,
    required Tool adaptedTool,
    required DomainContext targetContext,
    required double confidenceScore,
    required Map<String, dynamic> adaptationDetails,
    required List<ParameterMapping> parameterMappings,
    required AdaptationPerformanceImpact performanceImpact,
    required SecurityAssessment securityAssessment,
  }) {
    return AdaptationResult(
      id: id,
      originalTool: originalTool,
      adaptedTool: adaptedTool,
      targetContext: targetContext,
      isSuccess: true,
      confidenceScore: confidenceScore,
      adaptationDetails: adaptationDetails,
      parameterMappings: parameterMappings,
      performanceImpact: performanceImpact,
      securityAssessment: securityAssessment,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a failed adaptation result
  factory AdaptationResult.failure({
    required String id,
    required Tool originalTool,
    required DomainContext targetContext,
    required Map<String, dynamic> adaptationDetails,
    required SecurityAssessment securityAssessment,
  }) {
    return AdaptationResult(
      id: id,
      originalTool: originalTool,
      adaptedTool: originalTool, // Return original tool on failure
      targetContext: targetContext,
      isSuccess: false,
      confidenceScore: 0.0,
      adaptationDetails: adaptationDetails,
      parameterMappings: const [],
      performanceImpact: AdaptationPerformanceImpact.none(),
      securityAssessment: securityAssessment,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an AdaptationResult from JSON
  factory AdaptationResult.fromJson(Map<String, dynamic> json) =>
      _$AdaptationResultFromJson(json);

  /// Converts AdaptationResult to JSON
  Map<String, dynamic> toJson() => _$AdaptationResultToJson(this);

  @override
  List<Object?> get props => [
        id,
        originalTool,
        adaptedTool,
        targetContext,
        isSuccess,
        confidenceScore,
        adaptationDetails,
        parameterMappings,
        performanceImpact,
        securityAssessment,
        timestamp,
      ];

  @override
  String toString() =>
      'AdaptationResult(id: $id, success: $isSuccess, confidence: $confidenceScore)';
}

/// Security assessment result
@JsonSerializable()
class SecurityAssessment extends Equatable {
  /// Unique identifier for the assessment
  final String id;

  /// Overall security risk level
  final SecurityRiskLevel riskLevel;

  /// Security score (0.0 to 1.0, higher is more secure)
  final double securityScore;

  /// Identified security issues
  final List<SecurityIssue> securityIssues;

  /// Security recommendations
  final List<String> recommendations;

  /// Required security measures
  final List<String> requiredMeasures;

  /// Compliance status
  final Map<String, bool> complianceStatus;

  /// Assessment timestamp
  final DateTime timestamp;

  const SecurityAssessment({
    required this.id,
    required this.riskLevel,
    required this.securityScore,
    required this.securityIssues,
    required this.recommendations,
    required this.requiredMeasures,
    required this.complianceStatus,
    required this.timestamp,
  });

  /// Creates a SecurityAssessment from JSON
  factory SecurityAssessment.fromJson(Map<String, dynamic> json) =>
      _$SecurityAssessmentFromJson(json);

  /// Converts SecurityAssessment to JSON
  Map<String, dynamic> toJson() => _$SecurityAssessmentToJson(this);

  /// Checks if the assessment passed security requirements
  bool get isSecure =>
      riskLevel != SecurityRiskLevel.high && securityScore >= 0.7;

  @override
  List<Object?> get props => [
        id,
        riskLevel,
        securityScore,
        securityIssues,
        recommendations,
        requiredMeasures,
        complianceStatus,
        timestamp,
      ];

  @override
  String toString() =>
      'SecurityAssessment(id: $id, risk: $riskLevel, score: $securityScore)';
}

/// Security risk levels
enum SecurityRiskLevel {
  /// Low risk level
  @JsonValue('low')
  low,

  /// Medium risk level
  @JsonValue('medium')
  medium,

  /// High risk level
  @JsonValue('high')
  high,

  /// Critical risk level
  @JsonValue('critical')
  critical,
}

/// Security issue identified during assessment
@JsonSerializable()
class SecurityIssue extends Equatable {
  /// Unique identifier for the issue
  final String id;

  /// Type of security issue
  final String type;

  /// Severity level
  final SecurityRiskLevel severity;

  /// Description of the issue
  final String description;

  /// Affected components
  final List<String> affectedComponents;

  /// Potential impact
  final String potentialImpact;

  /// Mitigation steps
  final List<String> mitigationSteps;

  const SecurityIssue({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.affectedComponents,
    required this.potentialImpact,
    required this.mitigationSteps,
  });

  /// Creates a SecurityIssue from JSON
  factory SecurityIssue.fromJson(Map<String, dynamic> json) =>
      _$SecurityIssueFromJson(json);

  /// Converts SecurityIssue to JSON
  Map<String, dynamic> toJson() => _$SecurityIssueToJson(this);

  @override
  List<Object?> get props => [
        id,
        type,
        severity,
        description,
        affectedComponents,
        potentialImpact,
        mitigationSteps,
      ];

  @override
  String toString() =>
      'SecurityIssue(id: $id, type: $type, severity: $severity)';
}

/// Parameter mapping definition
@JsonSerializable()
class ParameterMapping extends Equatable {
  /// Source parameter name
  final String sourceParameter;

  /// Target parameter name
  final String targetParameter;

  /// Source parameter type
  final String sourceType;

  /// Target parameter type
  final String targetType;

  /// Transformation function to apply
  final String? transformationFunction;

  /// Default value if source is missing
  final dynamic defaultValue;

  /// Whether the mapping is required
  final bool isRequired;

  /// Validation rules for the mapping
  final List<String> validationRules;

  const ParameterMapping({
    required this.sourceParameter,
    required this.targetParameter,
    required this.sourceType,
    required this.targetType,
    this.transformationFunction,
    this.defaultValue,
    this.isRequired = false,
    this.validationRules = const [],
  });

  /// Creates a ParameterMapping from JSON
  factory ParameterMapping.fromJson(Map<String, dynamic> json) =>
      _$ParameterMappingFromJson(json);

  /// Converts ParameterMapping to JSON
  Map<String, dynamic> toJson() => _$ParameterMappingToJson(this);

  @override
  List<Object?> get props => [
        sourceParameter,
        targetParameter,
        sourceType,
        targetType,
        transformationFunction,
        defaultValue,
        isRequired,
        validationRules,
      ];

  @override
  String toString() =>
      'ParameterMapping($sourceParameter -> $targetParameter, $sourceType -> $targetType)';
}

/// Execution environment configuration
@JsonSerializable()
class ExecutionEnvironment extends Equatable {
  /// Unique identifier for the environment
  final String id;

  /// Environment type
  final String type;

  /// Resource limits
  final ResourceLimits resourceLimits;

  /// Security policies
  final List<SecurityPolicy> securityPolicies;

  /// Network configuration
  final NetworkConfiguration networkConfiguration;

  /// Environment variables
  final Map<String, String> environmentVariables;

  /// Available capabilities
  final List<String> availableCapabilities;

  /// Isolation level
  final IsolationLevel isolationLevel;

  const ExecutionEnvironment({
    required this.id,
    required this.type,
    required this.resourceLimits,
    required this.securityPolicies,
    required this.networkConfiguration,
    required this.environmentVariables,
    required this.availableCapabilities,
    required this.isolationLevel,
  });

  /// Creates an ExecutionEnvironment from JSON
  factory ExecutionEnvironment.fromJson(Map<String, dynamic> json) =>
      _$ExecutionEnvironmentFromJson(json);

  /// Converts ExecutionEnvironment to JSON
  Map<String, dynamic> toJson() => _$ExecutionEnvironmentToJson(this);

  @override
  List<Object?> get props => [
        id,
        type,
        resourceLimits,
        securityPolicies,
        networkConfiguration,
        environmentVariables,
        availableCapabilities,
        isolationLevel,
      ];

  @override
  String toString() => 'ExecutionEnvironment(id: $id, type: $type)';
}

/// Resource limits for execution
@JsonSerializable()
class ResourceLimits extends Equatable {
  /// Maximum memory usage in MB
  final double maxMemoryMB;

  /// Maximum CPU usage percentage
  final double maxCpuPercent;

  /// Maximum execution time
  final Duration maxExecutionTime;

  /// Maximum network usage in MB
  final double maxNetworkMB;

  /// Maximum disk usage in MB
  final double maxDiskMB;

  const ResourceLimits({
    required this.maxMemoryMB,
    required this.maxCpuPercent,
    required this.maxExecutionTime,
    required this.maxNetworkMB,
    required this.maxDiskMB,
  });

  /// Creates a ResourceLimits from JSON
  factory ResourceLimits.fromJson(Map<String, dynamic> json) =>
      _$ResourceLimitsFromJson(json);

  /// Converts ResourceLimits to JSON
  Map<String, dynamic> toJson() => _$ResourceLimitsToJson(this);

  @override
  List<Object?> get props => [
        maxMemoryMB,
        maxCpuPercent,
        maxExecutionTime,
        maxNetworkMB,
        maxDiskMB,
      ];

  @override
  String toString() =>
      'ResourceLimits(memory: ${maxMemoryMB}MB, cpu: $maxCpuPercent%, time: ${maxExecutionTime.inSeconds}s)';
}

/// Security policy for execution environment
@JsonSerializable()
class SecurityPolicy extends Equatable {
  /// Unique identifier for the policy
  final String id;

  /// Policy name
  final String name;

  /// Policy type
  final String type;

  /// Policy rules
  final Map<String, dynamic> rules;

  /// Enforcement level
  final EnforcementLevel enforcementLevel;

  const SecurityPolicy({
    required this.id,
    required this.name,
    required this.type,
    required this.rules,
    required this.enforcementLevel,
  });

  /// Creates a SecurityPolicy from JSON
  factory SecurityPolicy.fromJson(Map<String, dynamic> json) =>
      _$SecurityPolicyFromJson(json);

  /// Converts SecurityPolicy to JSON
  Map<String, dynamic> toJson() => _$SecurityPolicyToJson(this);

  @override
  List<Object?> get props => [id, name, type, rules, enforcementLevel];

  @override
  String toString() => 'SecurityPolicy(id: $id, name: $name, type: $type)';
}

/// Security policy enforcement levels
enum EnforcementLevel {
  /// Advisory only
  @JsonValue('advisory')
  advisory,

  /// Warning on violation
  @JsonValue('warning')
  warning,

  /// Block on violation
  @JsonValue('block')
  block,

  /// Terminate on violation
  @JsonValue('terminate')
  terminate,
}

/// Network configuration for execution environment
@JsonSerializable()
class NetworkConfiguration extends Equatable {
  /// Whether network access is allowed
  final bool allowNetworkAccess;

  /// Allowed domains
  final List<String> allowedDomains;

  /// Blocked domains
  final List<String> blockedDomains;

  /// Maximum bandwidth in KB/s
  final double maxBandwidthKBps;

  /// Proxy configuration
  final Map<String, dynamic>? proxyConfiguration;

  const NetworkConfiguration({
    required this.allowNetworkAccess,
    required this.allowedDomains,
    required this.blockedDomains,
    required this.maxBandwidthKBps,
    this.proxyConfiguration,
  });

  /// Creates a NetworkConfiguration from JSON
  factory NetworkConfiguration.fromJson(Map<String, dynamic> json) =>
      _$NetworkConfigurationFromJson(json);

  /// Converts NetworkConfiguration to JSON
  Map<String, dynamic> toJson() => _$NetworkConfigurationToJson(this);

  @override
  List<Object?> get props => [
        allowNetworkAccess,
        allowedDomains,
        blockedDomains,
        maxBandwidthKBps,
        proxyConfiguration,
      ];

  @override
  String toString() =>
      'NetworkConfiguration(allowed: $allowNetworkAccess, bandwidth: ${maxBandwidthKBps}KB/s)';
}

/// Isolation levels for execution environment
enum IsolationLevel {
  /// No isolation
  @JsonValue('none')
  none,

  /// Process isolation
  @JsonValue('process')
  process,

  /// Container isolation
  @JsonValue('container')
  container,

  /// VM isolation
  @JsonValue('vm')
  vm,

  /// Sandbox isolation
  @JsonValue('sandbox')
  sandbox,
}

/// Performance impact of adaptation
@JsonSerializable()
class AdaptationPerformanceImpact extends Equatable {
  /// Execution time overhead percentage
  final double executionTimeOverheadPercent;

  /// Memory overhead percentage
  final double memoryOverheadPercent;

  /// Network overhead percentage
  final double networkOverheadPercent;

  /// CPU overhead percentage
  final double cpuOverheadPercent;

  const AdaptationPerformanceImpact({
    required this.executionTimeOverheadPercent,
    required this.memoryOverheadPercent,
    required this.networkOverheadPercent,
    required this.cpuOverheadPercent,
  });

  /// Creates an AdaptationPerformanceImpact from JSON
  factory AdaptationPerformanceImpact.fromJson(Map<String, dynamic> json) =>
      _$AdaptationPerformanceImpactFromJson(json);

  /// Converts AdaptationPerformanceImpact to JSON
  Map<String, dynamic> toJson() => _$AdaptationPerformanceImpactToJson(this);

  /// Creates a zero impact instance
  factory AdaptationPerformanceImpact.none() {
    return const AdaptationPerformanceImpact(
      executionTimeOverheadPercent: 0.0,
      memoryOverheadPercent: 0.0,
      networkOverheadPercent: 0.0,
      cpuOverheadPercent: 0.0,
    );
  }

  /// Checks if the impact is significant (>10% overhead)
  bool get isSignificant =>
      executionTimeOverheadPercent > 10.0 ||
      memoryOverheadPercent > 10.0 ||
      networkOverheadPercent > 10.0 ||
      cpuOverheadPercent > 10.0;

  @override
  List<Object?> get props => [
        executionTimeOverheadPercent,
        memoryOverheadPercent,
        networkOverheadPercent,
        cpuOverheadPercent,
      ];

  @override
  String toString() =>
      'AdaptationPerformanceImpact(time: $executionTimeOverheadPercent%, memory: $memoryOverheadPercent%)';
}

/// Performance metrics for the adapter
@JsonSerializable()
class AdapterPerformanceMetrics extends Equatable {
  /// Total adaptations performed
  final int totalAdaptations;

  /// Successful adaptations
  final int successfulAdaptations;

  /// Average adaptation time in milliseconds
  final double averageAdaptationTimeMs;

  /// Cache hit rate (0.0 to 1.0)
  final double cacheHitRate;

  /// Memory usage in MB
  final double memoryUsageMB;

  /// CPU usage percentage
  final double cpuUsagePercent;

  /// Last updated timestamp
  final DateTime lastUpdated;

  const AdapterPerformanceMetrics({
    required this.totalAdaptations,
    required this.successfulAdaptations,
    required this.averageAdaptationTimeMs,
    required this.cacheHitRate,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.lastUpdated,
  });

  /// Creates an AdapterPerformanceMetrics from JSON
  factory AdapterPerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$AdapterPerformanceMetricsFromJson(json);

  /// Converts AdapterPerformanceMetrics to JSON
  Map<String, dynamic> toJson() => _$AdapterPerformanceMetricsToJson(this);

  /// Success rate (0.0 to 1.0)
  double get successRate =>
      totalAdaptations > 0 ? successfulAdaptations / totalAdaptations : 0.0;

  /// Checks if adapter meets mobile optimization requirements
  bool get meetsMobileOptimizationRequirements =>
      averageAdaptationTimeMs < 200 && memoryUsageMB < 30;

  @override
  List<Object?> get props => [
        totalAdaptations,
        successfulAdaptations,
        averageAdaptationTimeMs,
        cacheHitRate,
        memoryUsageMB,
        cpuUsagePercent,
        lastUpdated,
      ];

  @override
  String toString() =>
      'AdapterPerformanceMetrics(adaptations: $totalAdaptations, success: ${(successRate * 100).toInt()}%, time: ${averageAdaptationTimeMs}ms)';
}

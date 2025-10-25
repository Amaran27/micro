import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_capability.g.dart';

/// Represents a capability that a tool can provide
@JsonSerializable()
class ToolCapability extends Equatable {
  /// Unique identifier for the capability
  final String id;

  /// Type of capability
  final String type;

  /// Human-readable name
  final String name;

  /// Detailed description
  final String description;

  /// Version of the capability
  final String version;

  /// Whether this is the primary capability of the tool
  final bool isPrimary;

  /// Input parameters this capability accepts
  final Map<String, CapabilityParameter> inputParameters;

  /// Output this capability produces
  final Map<String, CapabilityParameter> outputParameters;

  /// Execution constraints
  final CapabilityConstraints constraints;

  /// Security requirements
  final List<String> securityRequirements;

  /// Performance characteristics
  final CapabilityPerformance performance;

  const ToolCapability({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.version,
    this.isPrimary = false,
    required this.inputParameters,
    required this.outputParameters,
    required this.constraints,
    this.securityRequirements = const [],
    required this.performance,
  });

  /// Creates a ToolCapability from JSON
  factory ToolCapability.fromJson(Map<String, dynamic> json) =>
      _$ToolCapabilityFromJson(json);

  /// Converts ToolCapability to JSON
  Map<String, dynamic> toJson() => _$ToolCapabilityToJson(this);

  /// Creates a copy with updated values
  ToolCapability copyWith({
    String? id,
    String? type,
    String? name,
    String? description,
    String? version,
    bool? isPrimary,
    Map<String, CapabilityParameter>? inputParameters,
    Map<String, CapabilityParameter>? outputParameters,
    CapabilityConstraints? constraints,
    List<String>? securityRequirements,
    CapabilityPerformance? performance,
  }) {
    return ToolCapability(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      isPrimary: isPrimary ?? this.isPrimary,
      inputParameters: inputParameters ?? this.inputParameters,
      outputParameters: outputParameters ?? this.outputParameters,
      constraints: constraints ?? this.constraints,
      securityRequirements: securityRequirements ?? this.securityRequirements,
      performance: performance ?? this.performance,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        description,
        version,
        isPrimary,
        inputParameters,
        outputParameters,
        constraints,
        securityRequirements,
        performance,
      ];

  @override
  String toString() => 'ToolCapability(id: $id, type: $type, name: $name)';
}

/// Represents a parameter for a capability
@JsonSerializable()
class CapabilityParameter extends Equatable {
  /// Name of the parameter
  final String name;

  /// Data type of the parameter
  final String dataType;

  /// Whether the parameter is required
  final bool isRequired;

  /// Default value if not provided
  final dynamic defaultValue;

  /// Description of the parameter
  final String description;

  /// Validation rules
  final List<ValidationRule> validationRules;

  /// Example values
  final List<dynamic> examples;

  const CapabilityParameter({
    required this.name,
    required this.dataType,
    this.isRequired = false,
    this.defaultValue,
    required this.description,
    this.validationRules = const [],
    this.examples = const [],
  });

  factory CapabilityParameter.fromJson(Map<String, dynamic> json) =>
      _$CapabilityParameterFromJson(json);

  Map<String, dynamic> toJson() => _$CapabilityParameterToJson(this);

  @override
  List<Object?> get props => [
        name,
        dataType,
        isRequired,
        defaultValue,
        description,
        validationRules,
        examples,
      ];

  @override
  String toString() => 'CapabilityParameter(name: $name, type: $dataType)';
}

/// Validation rule for a parameter
@JsonSerializable()
class ValidationRule extends Equatable {
  /// Type of validation
  final String type;

  /// Validation parameters
  final Map<String, dynamic> parameters;

  /// Error message if validation fails
  final String errorMessage;

  const ValidationRule({
    required this.type,
    required this.parameters,
    required this.errorMessage,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) =>
      _$ValidationRuleFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationRuleToJson(this);

  @override
  List<Object?> get props => [type, parameters, errorMessage];

  @override
  String toString() => 'ValidationRule(type: $type)';
}

/// Execution constraints for a capability
@JsonSerializable()
class CapabilityConstraints extends Equatable {
  /// Maximum execution time
  final Duration maxExecutionTime;

  /// Maximum memory usage in MB
  final double maxMemoryUsageMB;

  /// Maximum network bandwidth in KB/s
  final double maxNetworkBandwidthKBps;

  /// Rate limits
  final RateLimit? rateLimit;

  /// Resource requirements
  final Map<String, dynamic> resourceRequirements;

  const CapabilityConstraints({
    required this.maxExecutionTime,
    required this.maxMemoryUsageMB,
    required this.maxNetworkBandwidthKBps,
    this.rateLimit,
    this.resourceRequirements = const {},
  });

  factory CapabilityConstraints.fromJson(Map<String, dynamic> json) =>
      _$CapabilityConstraintsFromJson(json);

  Map<String, dynamic> toJson() => _$CapabilityConstraintsToJson(this);

  @override
  List<Object?> get props => [
        maxExecutionTime,
        maxMemoryUsageMB,
        maxNetworkBandwidthKBps,
        rateLimit,
        resourceRequirements,
      ];

  @override
  String toString() =>
      'CapabilityConstraints(maxTime: ${maxExecutionTime.inSeconds}s)';
}

/// Rate limit configuration
@JsonSerializable()
class RateLimit extends Equatable {
  /// Maximum requests per period
  final int maxRequests;

  /// Time period for rate limit
  final Duration period;

  /// Strategy for handling rate limit exceeded
  final String strategy;

  const RateLimit({
    required this.maxRequests,
    required this.period,
    required this.strategy,
  });

  factory RateLimit.fromJson(Map<String, dynamic> json) =>
      _$RateLimitFromJson(json);

  Map<String, dynamic> toJson() => _$RateLimitToJson(this);

  @override
  List<Object?> get props => [maxRequests, period, strategy];

  @override
  String toString() => 'RateLimit($maxRequests per ${period.inSeconds}s)';
}

/// Performance characteristics of a capability
@JsonSerializable()
class CapabilityPerformance extends Equatable {
  /// Average execution time
  final Duration averageExecutionTime;

  /// Memory usage in MB
  final double memoryUsageMB;

  /// CPU usage percentage
  final double cpuUsagePercent;

  /// Network usage in KB
  final double networkUsageKB;

  /// Success rate (0.0 to 1.0)
  final double successRate;

  /// Mobile optimization score (0.0 to 1.0)
  final double mobileOptimizationScore;

  const CapabilityPerformance({
    required this.averageExecutionTime,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.networkUsageKB,
    required this.successRate,
    required this.mobileOptimizationScore,
  });

  factory CapabilityPerformance.fromJson(Map<String, dynamic> json) =>
      _$CapabilityPerformanceFromJson(json);

  Map<String, dynamic> toJson() => _$CapabilityPerformanceToJson(this);

  /// Checks if the capability is optimized for mobile
  bool get isMobileOptimized =>
      mobileOptimizationScore >= 0.8 &&
      averageExecutionTime.inMilliseconds < 200 &&
      memoryUsageMB < 30;

  @override
  List<Object?> get props => [
        averageExecutionTime,
        memoryUsageMB,
        cpuUsagePercent,
        networkUsageKB,
        successRate,
        mobileOptimizationScore,
      ];

  @override
  String toString() =>
      'CapabilityPerformance(avgTime: ${averageExecutionTime.inMilliseconds}ms, mobile: $isMobileOptimized)';
}

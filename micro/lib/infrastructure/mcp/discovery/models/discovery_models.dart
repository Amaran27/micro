import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/models/tool.dart';

part 'discovery_models.g.dart';

/// Represents a tool that has been discovered from a source
@JsonSerializable()
class DiscoveredTool extends Equatable {
  /// The discovered tool
  final Tool tool;

  /// Source where the tool was discovered
  final String sourceName;

  /// Type of discovery source
  final DiscoverySourceType sourceType;

  /// Timestamp when the tool was discovered
  final DateTime discoveredAt;

  /// Confidence score of the discovery (0.0 to 1.0)
  final double confidenceScore;

  /// Metadata about the discovery process
  final Map<String, dynamic> discoveryMetadata;

  /// Whether the tool is currently reachable
  final bool isReachable;

  /// Last time the tool was verified as reachable
  final DateTime? lastVerifiedAt;

  /// Discovery latency in milliseconds
  final int discoveryLatencyMs;

  const DiscoveredTool({
    required this.tool,
    required this.sourceName,
    required this.sourceType,
    required this.discoveredAt,
    this.confidenceScore = 1.0,
    this.discoveryMetadata = const {},
    this.isReachable = true,
    this.lastVerifiedAt,
    this.discoveryLatencyMs = 0,
  });

  factory DiscoveredTool.fromJson(Map<String, dynamic> json) =>
      _$DiscoveredToolFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveredToolToJson(this);

  DiscoveredTool copyWith({
    Tool? tool,
    String? sourceName,
    DiscoverySourceType? sourceType,
    DateTime? discoveredAt,
    double? confidenceScore,
    Map<String, dynamic>? discoveryMetadata,
    bool? isReachable,
    DateTime? lastVerifiedAt,
    int? discoveryLatencyMs,
  }) {
    return DiscoveredTool(
      tool: tool ?? this.tool,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      discoveryMetadata: discoveryMetadata ?? this.discoveryMetadata,
      isReachable: isReachable ?? this.isReachable,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      discoveryLatencyMs: discoveryLatencyMs ?? this.discoveryLatencyMs,
    );
  }

  @override
  List<Object?> get props => [
        tool,
        sourceName,
        sourceType,
        discoveredAt,
        confidenceScore,
        discoveryMetadata,
        isReachable,
        lastVerifiedAt,
        discoveryLatencyMs,
      ];
}

/// Types of discovery sources
enum DiscoverySourceType {
  /// Local device scanning
  localDevice,

  /// Network discovery
  network,

  /// MCP server discovery
  mcpServer,

  /// Cloud registry
  cloudRegistry,

  /// Manual registration
  manual,

  /// Cached discovery
  cache,
}

/// Classification result for a tool
@JsonSerializable()
class ToolClassification extends Equatable {
  /// Primary category of the tool
  final String primaryCategory;

  /// Secondary categories
  final List<String> secondaryCategories;

  /// Confidence score of the classification (0.0 to 1.0)
  final double confidenceScore;

  /// Classification method used
  final ClassificationMethod method;

  /// Tags associated with the tool
  final List<String> tags;

  /// Security classification level
  final SecurityLevel securityLevel;

  /// Mobile optimization classification
  final MobileOptimizationLevel mobileOptimizationLevel;

  /// Performance classification
  final PerformanceClass performanceClass;

  /// Metadata about the classification process
  final Map<String, dynamic> classificationMetadata;

  const ToolClassification({
    required this.primaryCategory,
    this.secondaryCategories = const [],
    required this.confidenceScore,
    required this.method,
    this.tags = const [],
    required this.securityLevel,
    required this.mobileOptimizationLevel,
    required this.performanceClass,
    this.classificationMetadata = const {},
  });

  factory ToolClassification.fromJson(Map<String, dynamic> json) =>
      _$ToolClassificationFromJson(json);

  Map<String, dynamic> toJson() => _$ToolClassificationToJson(this);

  @override
  List<Object?> get props => [
        primaryCategory,
        secondaryCategories,
        confidenceScore,
        method,
        tags,
        securityLevel,
        mobileOptimizationLevel,
        performanceClass,
        classificationMetadata,
      ];
}

/// Methods used for tool classification
enum ClassificationMethod {
  /// Manual classification by user
  manual,

  /// Automated classification based on metadata
  automated,

  /// Machine learning based classification
  mlBased,

  /// Hybrid approach combining multiple methods
  hybrid,

  /// Inferred from tool behavior
  behaviorBased,
}

/// Security classification levels
enum SecurityLevel {
  /// No security requirements
  none,

  /// Basic security requirements
  basic,

  /// Standard security requirements
  standard,

  /// High security requirements
  high,

  /// Critical security requirements
  critical,
}

/// Mobile optimization levels
enum MobileOptimizationLevel {
  /// Not optimized for mobile
  none,

  /// Basic mobile optimization
  basic,

  /// Good mobile optimization
  good,

  /// Excellent mobile optimization
  excellent,

  /// Native mobile optimization
  native,
}

/// Performance classification
enum PerformanceClass {
  /// Low performance requirements
  low,

  /// Medium performance requirements
  medium,

  /// High performance requirements
  high,

  /// Real-time performance requirements
  realtime,

  /// Batch processing performance
  batch,
}

/// Validation result for a tool
@JsonSerializable()
class ToolValidation extends Equatable {
  /// Overall validation status
  final ValidationStatus status;

  /// Validation score (0.0 to 1.0)
  final double validationScore;

  /// List of validation errors
  final List<ValidationError> errors;

  /// List of validation warnings
  final List<ValidationWarning> warnings;

  /// Schema validation result
  final SchemaValidationResult schemaValidation;

  /// Security validation result
  final SecurityValidationResult securityValidation;

  /// Mobile compatibility validation result
  final MobileValidationResult mobileValidation;

  /// Performance validation result
  final PerformanceValidationResult performanceValidation;

  /// Timestamp when validation was performed
  final DateTime validatedAt;

  /// Validation duration in milliseconds
  final int validationDurationMs;

  const ToolValidation({
    required this.status,
    required this.validationScore,
    this.errors = const [],
    this.warnings = const [],
    required this.schemaValidation,
    required this.securityValidation,
    required this.mobileValidation,
    required this.performanceValidation,
    required this.validatedAt,
    this.validationDurationMs = 0,
  });

  factory ToolValidation.fromJson(Map<String, dynamic> json) =>
      _$ToolValidationFromJson(json);

  Map<String, dynamic> toJson() => _$ToolValidationToJson(this);

  /// Returns true if the tool passed validation
  bool get isValid => status == ValidationStatus.passed;

  /// Returns true if the tool has warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Returns true if the tool has errors
  bool get hasErrors => errors.isNotEmpty;

  @override
  List<Object?> get props => [
        status,
        validationScore,
        errors,
        warnings,
        schemaValidation,
        securityValidation,
        mobileValidation,
        performanceValidation,
        validatedAt,
        validationDurationMs,
      ];
}

/// Validation status
enum ValidationStatus {
  /// Tool passed all validations
  passed,

  /// Tool passed with warnings
  passedWithWarnings,

  /// Tool failed validation
  failed,

  /// Validation could not be completed
  incomplete,
}

/// Validation error
@JsonSerializable()
class ValidationError extends Equatable {
  /// Error code
  final String code;

  /// Error message
  final String message;

  /// Severity level
  final ErrorSeverity severity;

  /// Category of the error
  final String category;

  /// Field or component that caused the error
  final String? field;

  /// Suggested fix for the error
  final String? suggestedFix;

  /// Additional context
  final Map<String, dynamic> context;

  const ValidationError({
    required this.code,
    required this.message,
    required this.severity,
    required this.category,
    this.field,
    this.suggestedFix,
    this.context = const {},
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @override
  List<Object?> get props => [
        code,
        message,
        severity,
        category,
        field,
        suggestedFix,
        context,
      ];
}

/// Error severity levels
enum ErrorSeverity {
  /// Low severity error
  low,

  /// Medium severity error
  medium,

  /// High severity error
  high,

  /// Critical error
  critical,
}

/// Validation warning
@JsonSerializable()
class ValidationWarning extends Equatable {
  /// Warning code
  final String code;

  /// Warning message
  final String message;

  /// Category of the warning
  final String category;

  /// Field or component that caused the warning
  final String? field;

  /// Recommendation for addressing the warning
  final String? recommendation;

  /// Additional context
  final Map<String, dynamic> context;

  const ValidationWarning({
    required this.code,
    required this.message,
    required this.category,
    this.field,
    this.recommendation,
    this.context = const {},
  });

  factory ValidationWarning.fromJson(Map<String, dynamic> json) =>
      _$ValidationWarningFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationWarningToJson(this);

  @override
  List<Object?> get props => [
        code,
        message,
        category,
        field,
        recommendation,
        context,
      ];
}

/// Schema validation result
@JsonSerializable()
class SchemaValidationResult extends Equatable {
  /// Whether the schema is valid
  final bool isValid;

  /// Input schema validation result
  final bool inputSchemaValid;

  /// Output schema validation result
  final bool outputSchemaValid;

  /// Schema validation errors
  final List<String> schemaErrors;

  const SchemaValidationResult({
    required this.isValid,
    required this.inputSchemaValid,
    required this.outputSchemaValid,
    this.schemaErrors = const [],
  });

  factory SchemaValidationResult.fromJson(Map<String, dynamic> json) =>
      _$SchemaValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$SchemaValidationResultToJson(this);

  @override
  List<Object?> get props => [
        isValid,
        inputSchemaValid,
        outputSchemaValid,
        schemaErrors,
      ];
}

/// Security validation result
@JsonSerializable()
class SecurityValidationResult extends Equatable {
  /// Whether security requirements are met
  final bool isSecure;

  /// Security level validation
  final bool securityLevelValid;

  /// Encryption requirements validation
  final bool encryptionValid;

  /// Authentication requirements validation
  final bool authValid;

  /// Authorization requirements validation
  final bool authzValid;

  /// Security validation errors
  final List<String> securityErrors;

  const SecurityValidationResult({
    required this.isSecure,
    required this.securityLevelValid,
    required this.encryptionValid,
    required this.authValid,
    required this.authzValid,
    this.securityErrors = const [],
  });

  factory SecurityValidationResult.fromJson(Map<String, dynamic> json) =>
      _$SecurityValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityValidationResultToJson(this);

  @override
  List<Object?> get props => [
        isSecure,
        securityLevelValid,
        encryptionValid,
        authValid,
        authzValid,
        securityErrors,
      ];
}

/// Mobile validation result
@JsonSerializable()
class MobileValidationResult extends Equatable {
  /// Whether the tool is mobile compatible
  final bool isMobileCompatible;

  /// Memory usage validation
  final bool memoryUsageValid;

  /// Battery usage validation
  final bool batteryUsageValid;

  /// Network usage validation
  final bool networkUsageValid;

  /// Offline capability validation
  final bool offlineCapabilityValid;

  /// Mobile validation errors
  final List<String> mobileErrors;

  const MobileValidationResult({
    required this.isMobileCompatible,
    required this.memoryUsageValid,
    required this.batteryUsageValid,
    required this.networkUsageValid,
    required this.offlineCapabilityValid,
    this.mobileErrors = const [],
  });

  factory MobileValidationResult.fromJson(Map<String, dynamic> json) =>
      _$MobileValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$MobileValidationResultToJson(this);

  @override
  List<Object?> get props => [
        isMobileCompatible,
        memoryUsageValid,
        batteryUsageValid,
        networkUsageValid,
        offlineCapabilityValid,
        mobileErrors,
      ];
}

/// Performance validation result
@JsonSerializable()
class PerformanceValidationResult extends Equatable {
  /// Whether performance requirements are met
  final bool isPerformant;

  /// Execution time validation
  final bool executionTimeValid;

  /// Memory usage validation
  final bool memoryValid;

  /// CPU usage validation
  final bool cpuValid;

  /// Network bandwidth validation
  final bool bandwidthValid;

  /// Performance validation errors
  final List<String> performanceErrors;

  const PerformanceValidationResult({
    required this.isPerformant,
    required this.executionTimeValid,
    required this.memoryValid,
    required this.cpuValid,
    required this.bandwidthValid,
    this.performanceErrors = const [],
  });

  factory PerformanceValidationResult.fromJson(Map<String, dynamic> json) =>
      _$PerformanceValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceValidationResultToJson(this);

  @override
  List<Object?> get props => [
        isPerformant,
        executionTimeValid,
        memoryValid,
        cpuValid,
        bandwidthValid,
        performanceErrors,
      ];
}

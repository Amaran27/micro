import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_context.g.dart';

/// Represents the domain context where a tool operates
@JsonSerializable()
class DomainContext extends Equatable {
  /// Unique identifier for the domain
  final String id;

  /// Name of the domain
  final String name;

  /// Description of the domain
  final String description;

  /// Category of the domain
  final String category;

  /// Version of the domain specification
  final String version;

  /// Context parameters
  final Map<String, dynamic> parameters;

  /// Security context
  final SecurityContext securityContext;

  /// Performance context
  final PerformanceContext performanceContext;

  /// Mobile context
  final MobileContext mobileContext;

  /// Compliance requirements
  final List<ComplianceRequirement> complianceRequirements;

  const DomainContext({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.version,
    required this.parameters,
    required this.securityContext,
    required this.performanceContext,
    required this.mobileContext,
    this.complianceRequirements = const [],
  });

  /// Creates a DomainContext from JSON
  factory DomainContext.fromJson(Map<String, dynamic> json) =>
      _$DomainContextFromJson(json);

  /// Converts DomainContext to JSON
  Map<String, dynamic> toJson() => _$DomainContextToJson(this);

  /// Creates a copy with updated values
  DomainContext copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? version,
    Map<String, dynamic>? parameters,
    SecurityContext? securityContext,
    PerformanceContext? performanceContext,
    MobileContext? mobileContext,
    List<ComplianceRequirement>? complianceRequirements,
  }) {
    return DomainContext(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      parameters: parameters ?? this.parameters,
      securityContext: securityContext ?? this.securityContext,
      performanceContext: performanceContext ?? this.performanceContext,
      mobileContext: mobileContext ?? this.mobileContext,
      complianceRequirements:
          complianceRequirements ?? this.complianceRequirements,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        version,
        parameters,
        securityContext,
        performanceContext,
        mobileContext,
        complianceRequirements,
      ];

  @override
  String toString() =>
      'DomainContext(id: $id, name: $name, category: $category)';
}

/// Security context for the domain
@JsonSerializable()
class SecurityContext extends Equatable {
  /// Security level required
  final String securityLevel;

  /// Authentication requirements
  final List<String> authenticationRequirements;

  /// Authorization requirements
  final List<String> authorizationRequirements;

  /// Data encryption requirements
  final EncryptionRequirements encryptionRequirements;

  /// Audit requirements
  final List<String> auditRequirements;

  /// Privacy requirements
  final List<String> privacyRequirements;

  const SecurityContext({
    required this.securityLevel,
    this.authenticationRequirements = const [],
    this.authorizationRequirements = const [],
    required this.encryptionRequirements,
    this.auditRequirements = const [],
    this.privacyRequirements = const [],
  });

  factory SecurityContext.fromJson(Map<String, dynamic> json) =>
      _$SecurityContextFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityContextToJson(this);

  @override
  List<Object?> get props => [
        securityLevel,
        authenticationRequirements,
        authorizationRequirements,
        encryptionRequirements,
        auditRequirements,
        privacyRequirements,
      ];

  @override
  String toString() => 'SecurityContext(level: $securityLevel)';
}

/// Encryption requirements
@JsonSerializable()
class EncryptionRequirements extends Equatable {
  /// Whether encryption is required
  final bool required;

  /// Encryption algorithm
  final String? algorithm;

  /// Key length
  final int? keyLength;

  /// Whether to encrypt data at rest
  final bool encryptAtRest;

  /// Whether to encrypt data in transit
  final bool encryptInTransit;

  const EncryptionRequirements({
    required this.required,
    this.algorithm,
    this.keyLength,
    this.encryptAtRest = true,
    this.encryptInTransit = true,
  });

  factory EncryptionRequirements.fromJson(Map<String, dynamic> json) =>
      _$EncryptionRequirementsFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptionRequirementsToJson(this);

  @override
  List<Object?> get props => [
        required,
        algorithm,
        keyLength,
        encryptAtRest,
        encryptInTransit,
      ];

  @override
  String toString() => 'EncryptionRequirements(required: $required)';
}

/// Performance context for the domain
@JsonSerializable()
class PerformanceContext extends Equatable {
  /// Maximum execution time
  final Duration maxExecutionTime;

  /// Maximum memory usage in MB
  final double maxMemoryUsageMB;

  /// Maximum CPU usage percentage
  final double maxCpuUsagePercent;

  /// Maximum network bandwidth in KB/s
  final double maxNetworkBandwidthKBps;

  /// Performance targets
  final PerformanceTargets targets;

  const PerformanceContext({
    required this.maxExecutionTime,
    required this.maxMemoryUsageMB,
    required this.maxCpuUsagePercent,
    required this.maxNetworkBandwidthKBps,
    required this.targets,
  });

  factory PerformanceContext.fromJson(Map<String, dynamic> json) =>
      _$PerformanceContextFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceContextToJson(this);

  @override
  List<Object?> get props => [
        maxExecutionTime,
        maxMemoryUsageMB,
        maxCpuUsagePercent,
        maxNetworkBandwidthKBps,
        targets,
      ];

  @override
  String toString() =>
      'PerformanceContext(maxTime: ${maxExecutionTime.inMilliseconds}ms, maxMemory: ${maxMemoryUsageMB}MB)';
}

/// Performance targets
@JsonSerializable()
class PerformanceTargets extends Equatable {
  /// Target execution time
  final Duration targetExecutionTime;

  /// Target memory usage in MB
  final double targetMemoryUsageMB;

  /// Target success rate (0.0 to 1.0)
  final double targetSuccessRate;

  /// Target availability (0.0 to 1.0)
  final double targetAvailability;

  const PerformanceTargets({
    required this.targetExecutionTime,
    required this.targetMemoryUsageMB,
    required this.targetSuccessRate,
    required this.targetAvailability,
  });

  factory PerformanceTargets.fromJson(Map<String, dynamic> json) =>
      _$PerformanceTargetsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceTargetsToJson(this);

  @override
  List<Object?> get props => [
        targetExecutionTime,
        targetMemoryUsageMB,
        targetSuccessRate,
        targetAvailability,
      ];

  @override
  String toString() =>
      'PerformanceTargets(time: ${targetExecutionTime.inMilliseconds}ms, memory: ${targetMemoryUsageMB}MB)';
}

/// Mobile context for the domain
@JsonSerializable()
class MobileContext extends Equatable {
  /// Whether mobile optimization is required
  final bool requiresMobileOptimization;

  /// Battery optimization requirements
  final String batteryOptimizationLevel;

  /// Network optimization requirements
  final List<String> networkOptimizations;

  /// Memory optimization requirements
  final List<String> memoryOptimizations;

  /// Offline capability requirements
  final OfflineRequirements offlineRequirements;

  /// Background execution requirements
  final BackgroundExecutionRequirements backgroundRequirements;

  const MobileContext({
    required this.requiresMobileOptimization,
    required this.batteryOptimizationLevel,
    this.networkOptimizations = const [],
    this.memoryOptimizations = const [],
    required this.offlineRequirements,
    required this.backgroundRequirements,
  });

  factory MobileContext.fromJson(Map<String, dynamic> json) =>
      _$MobileContextFromJson(json);

  Map<String, dynamic> toJson() => _$MobileContextToJson(this);

  @override
  List<Object?> get props => [
        requiresMobileOptimization,
        batteryOptimizationLevel,
        networkOptimizations,
        memoryOptimizations,
        offlineRequirements,
        backgroundRequirements,
      ];

  @override
  String toString() =>
      'MobileContext(optimized: $requiresMobileOptimization, battery: $batteryOptimizationLevel)';
}

/// Offline requirements
@JsonSerializable()
class OfflineRequirements extends Equatable {
  /// Whether offline capability is required
  final bool required;

  /// Maximum offline duration
  final Duration maxOfflineDuration;

  /// Data synchronization requirements
  final List<String> syncRequirements;

  /// Cache requirements
  final CacheRequirements cacheRequirements;

  const OfflineRequirements({
    required this.required,
    required this.maxOfflineDuration,
    this.syncRequirements = const [],
    required this.cacheRequirements,
  });

  factory OfflineRequirements.fromJson(Map<String, dynamic> json) =>
      _$OfflineRequirementsFromJson(json);

  Map<String, dynamic> toJson() => _$OfflineRequirementsToJson(this);

  @override
  List<Object?> get props => [
        required,
        maxOfflineDuration,
        syncRequirements,
        cacheRequirements,
      ];

  @override
  String toString() => 'OfflineRequirements(required: $required)';
}

/// Cache requirements
@JsonSerializable()
class CacheRequirements extends Equatable {
  /// Maximum cache size in MB
  final double maxCacheSizeMB;

  /// Cache eviction policy
  final String evictionPolicy;

  /// Cache TTL
  final Duration ttl;

  const CacheRequirements({
    required this.maxCacheSizeMB,
    required this.evictionPolicy,
    required this.ttl,
  });

  factory CacheRequirements.fromJson(Map<String, dynamic> json) =>
      _$CacheRequirementsFromJson(json);

  Map<String, dynamic> toJson() => _$CacheRequirementsToJson(this);

  @override
  List<Object?> get props => [maxCacheSizeMB, evictionPolicy, ttl];

  @override
  String toString() => 'CacheRequirements(maxSize: ${maxCacheSizeMB}MB)';
}

/// Background execution requirements
@JsonSerializable()
class BackgroundExecutionRequirements extends Equatable {
  /// Whether background execution is required
  final bool required;

  /// Maximum background execution time
  final Duration maxExecutionTime;

  /// Resource limits for background execution
  final ResourceLimits resourceLimits;

  const BackgroundExecutionRequirements({
    required this.required,
    required this.maxExecutionTime,
    required this.resourceLimits,
  });

  factory BackgroundExecutionRequirements.fromJson(Map<String, dynamic> json) =>
      _$BackgroundExecutionRequirementsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$BackgroundExecutionRequirementsToJson(this);

  @override
  List<Object?> get props => [required, maxExecutionTime, resourceLimits];

  @override
  String toString() => 'BackgroundExecutionRequirements(required: $required)';
}

/// Resource limits
@JsonSerializable()
class ResourceLimits extends Equatable {
  /// Maximum memory usage in MB
  final double maxMemoryMB;

  /// Maximum CPU usage percentage
  final double maxCpuPercent;

  /// Maximum network usage in MB
  final double maxNetworkMB;

  const ResourceLimits({
    required this.maxMemoryMB,
    required this.maxCpuPercent,
    required this.maxNetworkMB,
  });

  factory ResourceLimits.fromJson(Map<String, dynamic> json) =>
      _$ResourceLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceLimitsToJson(this);

  @override
  List<Object?> get props => [maxMemoryMB, maxCpuPercent, maxNetworkMB];

  @override
  String toString() =>
      'ResourceLimits(memory: ${maxMemoryMB}MB, cpu: $maxCpuPercent%, network: ${maxNetworkMB}MB)';
}

/// Compliance requirement
@JsonSerializable()
class ComplianceRequirement extends Equatable {
  /// Name of the compliance standard
  final String standard;

  /// Version of the standard
  final String version;

  /// Specific requirements
  final List<String> requirements;

  /// Whether compliance is mandatory
  final bool isMandatory;

  const ComplianceRequirement({
    required this.standard,
    required this.version,
    required this.requirements,
    this.isMandatory = true,
  });

  factory ComplianceRequirement.fromJson(Map<String, dynamic> json) =>
      _$ComplianceRequirementFromJson(json);

  Map<String, dynamic> toJson() => _$ComplianceRequirementToJson(this);

  @override
  List<Object?> get props => [standard, version, requirements, isMandatory];

  @override
  String toString() => 'ComplianceRequirement($standard v$version)';
}

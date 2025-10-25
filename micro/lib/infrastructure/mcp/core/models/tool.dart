import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'tool_capability.dart';
import 'domain_context.dart';

part 'tool.g.dart';

/// Represents a tool available in the MCP ecosystem
@JsonSerializable()
class Tool extends Equatable {
  /// Unique identifier for the tool
  final String id;

  /// Human-readable name of the tool
  final String name;

  /// Detailed description of what the tool does
  final String description;

  /// Version of the tool
  final String version;

  /// Category the tool belongs to
  final String category;

  /// List of capabilities this tool provides
  final List<ToolCapability> capabilities;

  /// Input schema for the tool
  final Map<String, dynamic> inputSchema;

  /// Output schema for the tool
  final Map<String, dynamic> outputSchema;

  /// Domain context where this tool operates
  final DomainContext domainContext;

  /// Server that provides this tool
  final String serverName;

  /// Whether the tool is currently available
  final bool isAvailable;

  /// Execution metadata
  final ToolExecutionMetadata executionMetadata;

  /// Performance characteristics
  final ToolPerformanceMetrics performanceMetrics;

  /// Security requirements
  final ToolSecurityRequirements securityRequirements;

  /// Mobile-specific optimizations
  final ToolMobileOptimizations mobileOptimizations;

  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.category,
    required this.capabilities,
    required this.inputSchema,
    required this.outputSchema,
    required this.domainContext,
    required this.serverName,
    this.isAvailable = true,
    required this.executionMetadata,
    required this.performanceMetrics,
    required this.securityRequirements,
    required this.mobileOptimizations,
  });

  /// Creates a Tool from JSON
  factory Tool.fromJson(Map<String, dynamic> json) => _$ToolFromJson(json);

  /// Converts Tool to JSON
  Map<String, dynamic> toJson() => _$ToolToJson(this);

  /// Creates a copy of the Tool with updated values
  Tool copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? category,
    List<ToolCapability>? capabilities,
    Map<String, dynamic>? inputSchema,
    Map<String, dynamic>? outputSchema,
    DomainContext? domainContext,
    String? serverName,
    bool? isAvailable,
    ToolExecutionMetadata? executionMetadata,
    ToolPerformanceMetrics? performanceMetrics,
    ToolSecurityRequirements? securityRequirements,
    ToolMobileOptimizations? mobileOptimizations,
  }) {
    return Tool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      category: category ?? this.category,
      capabilities: capabilities ?? this.capabilities,
      inputSchema: inputSchema ?? this.inputSchema,
      outputSchema: outputSchema ?? this.outputSchema,
      domainContext: domainContext ?? this.domainContext,
      serverName: serverName ?? this.serverName,
      isAvailable: isAvailable ?? this.isAvailable,
      executionMetadata: executionMetadata ?? this.executionMetadata,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      securityRequirements: securityRequirements ?? this.securityRequirements,
      mobileOptimizations: mobileOptimizations ?? this.mobileOptimizations,
    );
  }

  /// Checks if the tool supports a specific capability
  bool hasCapability(String capabilityType) {
    return capabilities.any((cap) => cap.type == capabilityType);
  }

  /// Checks if the tool is compatible with mobile execution
  bool get isMobileOptimized =>
      mobileOptimizations.isOptimized &&
      performanceMetrics.averageExecutionTime.inMilliseconds < 200 &&
      performanceMetrics.memoryUsageMB < 30;

  /// Gets the primary capability of the tool
  ToolCapability? get primaryCapability {
    if (capabilities.isEmpty) return null;
    return capabilities.firstWhere((cap) => cap.isPrimary,
        orElse: () => capabilities.first);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        version,
        category,
        capabilities,
        inputSchema,
        outputSchema,
        domainContext,
        serverName,
        isAvailable,
        executionMetadata,
        performanceMetrics,
        securityRequirements,
        mobileOptimizations,
      ];

  @override
  String toString() => 'Tool(id: $id, name: $name, version: $version)';
}

/// Metadata about tool execution
@JsonSerializable()
class ToolExecutionMetadata extends Equatable {
  /// Author of the tool
  final String author;

  /// Creation date
  final DateTime createdAt;

  /// Last updated date
  final DateTime updatedAt;

  /// Execution timeout
  final Duration timeout;

  /// Maximum retry attempts
  final int maxRetries;

  /// Whether the tool requires authentication
  final bool requiresAuth;

  /// Required permissions
  final List<String> requiredPermissions;

  /// Tags for tool discovery
  final List<String> tags;

  const ToolExecutionMetadata({
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    required this.timeout,
    this.maxRetries = 3,
    this.requiresAuth = false,
    this.requiredPermissions = const [],
    this.tags = const [],
  });

  factory ToolExecutionMetadata.fromJson(Map<String, dynamic> json) =>
      _$ToolExecutionMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExecutionMetadataToJson(this);

  @override
  List<Object?> get props => [
        author,
        createdAt,
        updatedAt,
        timeout,
        maxRetries,
        requiresAuth,
        requiredPermissions,
        tags,
      ];
}

/// Performance metrics for the tool
@JsonSerializable()
class ToolPerformanceMetrics extends Equatable {
  /// Average execution time
  final Duration averageExecutionTime;

  /// Memory usage in MB
  final double memoryUsageMB;

  /// Success rate (0.0 to 1.0)
  final double successRate;

  /// Total execution count
  final int executionCount;

  /// Last execution timestamp
  final DateTime? lastExecution;

  /// Network bandwidth requirement in KB/s
  final double networkBandwidthKBps;

  const ToolPerformanceMetrics({
    required this.averageExecutionTime,
    required this.memoryUsageMB,
    required this.successRate,
    required this.executionCount,
    this.lastExecution,
    required this.networkBandwidthKBps,
  });

  factory ToolPerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$ToolPerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ToolPerformanceMetricsToJson(this);

  @override
  List<Object?> get props => [
        averageExecutionTime,
        memoryUsageMB,
        successRate,
        executionCount,
        lastExecution,
        networkBandwidthKBps,
      ];
}

/// Security requirements for the tool
@JsonSerializable()
class ToolSecurityRequirements extends Equatable {
  /// Security level required
  final String securityLevel;

  /// Whether the tool requires encryption
  final bool requiresEncryption;

  /// Data sensitivity level
  final String dataSensitivity;

  /// Audit requirements
  final List<String> auditRequirements;

  /// Compliance requirements
  final List<String> complianceRequirements;

  const ToolSecurityRequirements({
    required this.securityLevel,
    this.requiresEncryption = false,
    required this.dataSensitivity,
    this.auditRequirements = const [],
    this.complianceRequirements = const [],
  });

  factory ToolSecurityRequirements.fromJson(Map<String, dynamic> json) =>
      _$ToolSecurityRequirementsFromJson(json);

  Map<String, dynamic> toJson() => _$ToolSecurityRequirementsToJson(this);

  @override
  List<Object?> get props => [
        securityLevel,
        requiresEncryption,
        dataSensitivity,
        auditRequirements,
        complianceRequirements,
      ];
}

/// Mobile-specific optimizations for the tool
@JsonSerializable()
class ToolMobileOptimizations extends Equatable {
  /// Whether the tool is optimized for mobile
  final bool isOptimized;

  /// Offline capability
  final bool supportsOffline;

  /// Battery optimization level
  final String batteryOptimization;

  /// Network optimization
  final bool networkOptimized;

  /// Memory optimization techniques
  final List<String> memoryOptimizations;

  /// Background execution support
  final bool supportsBackgroundExecution;

  const ToolMobileOptimizations({
    required this.isOptimized,
    this.supportsOffline = false,
    required this.batteryOptimization,
    this.networkOptimized = false,
    this.memoryOptimizations = const [],
    this.supportsBackgroundExecution = false,
  });

  factory ToolMobileOptimizations.fromJson(Map<String, dynamic> json) =>
      _$ToolMobileOptimizationsFromJson(json);

  Map<String, dynamic> toJson() => _$ToolMobileOptimizationsToJson(this);

  @override
  List<Object?> get props => [
        isOptimized,
        supportsOffline,
        batteryOptimization,
        networkOptimized,
        memoryOptimizations,
        supportsBackgroundExecution,
      ];
}

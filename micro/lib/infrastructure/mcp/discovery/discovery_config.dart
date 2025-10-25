import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'models/discovery_models.dart';

part 'discovery_config.g.dart';

/// Configuration for the Tool Discovery Engine
///
/// Contains settings for discovery behavior, performance optimization,
/// and mobile-specific configurations.
@JsonSerializable()
class DiscoveryConfig extends Equatable {
  /// Maximum time allowed for tool discovery in milliseconds
  /// Default: 5000ms (5 seconds) for mobile optimization
  final int maxDiscoveryTimeMs;

  /// Maximum memory usage for discovery in MB
  /// Default: 30MB for mobile optimization
  final double maxMemoryUsageMB;

  /// Whether to enable caching of discovered tools
  final bool enableCaching;

  /// Cache expiration time in minutes
  final int cacheExpirationMinutes;

  /// Whether to enable parallel discovery
  final bool enableParallelDiscovery;

  /// Maximum number of concurrent discovery operations
  final int maxConcurrentDiscoveries;

  /// Whether to enable battery optimization
  final bool enableBatteryOptimization;

  /// Battery optimization level (0.0 to 1.0)
  final double batteryOptimizationLevel;

  /// Whether to enable network optimization
  final bool enableNetworkOptimization;

  /// Maximum network bandwidth for discovery in KB/s
  final double maxNetworkBandwidthKBps;

  /// Whether to enable mobile-specific optimizations
  final bool enableMobileOptimizations;

  /// Mobile optimization level (0.0 to 1.0)
  final double mobileOptimizationLevel;

  /// List of enabled discovery sources
  final List<DiscoverySourceType> enabledSources;

  /// Source-specific configurations
  final Map<DiscoverySourceType, SourceConfig> sourceConfigs;

  /// Validation settings
  final ValidationConfig validationConfig;

  /// Classification settings
  final ClassificationConfig classificationConfig;

  /// Performance monitoring settings
  final PerformanceConfig performanceConfig;

  /// Security settings
  final SecurityConfig securityConfig;

  const DiscoveryConfig({
    this.maxDiscoveryTimeMs = 5000,
    this.maxMemoryUsageMB = 30.0,
    this.enableCaching = true,
    this.cacheExpirationMinutes = 60,
    this.enableParallelDiscovery = true,
    this.maxConcurrentDiscoveries = 3,
    this.enableBatteryOptimization = true,
    this.batteryOptimizationLevel = 0.7,
    this.enableNetworkOptimization = true,
    this.maxNetworkBandwidthKBps = 100.0,
    this.enableMobileOptimizations = true,
    this.mobileOptimizationLevel = 0.8,
    this.enabledSources = const [
      DiscoverySourceType.localDevice,
      DiscoverySourceType.network,
      DiscoverySourceType.mcpServer,
    ],
    this.sourceConfigs = const {},
    this.validationConfig = const ValidationConfig(),
    this.classificationConfig = const ClassificationConfig(),
    this.performanceConfig = const PerformanceConfig(),
    this.securityConfig = const SecurityConfig(),
  });

  factory DiscoveryConfig.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveryConfigToJson(this);

  DiscoveryConfig copyWith({
    int? maxDiscoveryTimeMs,
    double? maxMemoryUsageMB,
    bool? enableCaching,
    int? cacheExpirationMinutes,
    bool? enableParallelDiscovery,
    int? maxConcurrentDiscoveries,
    bool? enableBatteryOptimization,
    double? batteryOptimizationLevel,
    bool? enableNetworkOptimization,
    double? maxNetworkBandwidthKBps,
    bool? enableMobileOptimizations,
    double? mobileOptimizationLevel,
    List<DiscoverySourceType>? enabledSources,
    Map<DiscoverySourceType, SourceConfig>? sourceConfigs,
    ValidationConfig? validationConfig,
    ClassificationConfig? classificationConfig,
    PerformanceConfig? performanceConfig,
    SecurityConfig? securityConfig,
  }) {
    return DiscoveryConfig(
      maxDiscoveryTimeMs: maxDiscoveryTimeMs ?? this.maxDiscoveryTimeMs,
      maxMemoryUsageMB: maxMemoryUsageMB ?? this.maxMemoryUsageMB,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheExpirationMinutes:
          cacheExpirationMinutes ?? this.cacheExpirationMinutes,
      enableParallelDiscovery:
          enableParallelDiscovery ?? this.enableParallelDiscovery,
      maxConcurrentDiscoveries:
          maxConcurrentDiscoveries ?? this.maxConcurrentDiscoveries,
      enableBatteryOptimization:
          enableBatteryOptimization ?? this.enableBatteryOptimization,
      batteryOptimizationLevel:
          batteryOptimizationLevel ?? this.batteryOptimizationLevel,
      enableNetworkOptimization:
          enableNetworkOptimization ?? this.enableNetworkOptimization,
      maxNetworkBandwidthKBps:
          maxNetworkBandwidthKBps ?? this.maxNetworkBandwidthKBps,
      enableMobileOptimizations:
          enableMobileOptimizations ?? this.enableMobileOptimizations,
      mobileOptimizationLevel:
          mobileOptimizationLevel ?? this.mobileOptimizationLevel,
      enabledSources: enabledSources ?? this.enabledSources,
      sourceConfigs: sourceConfigs ?? this.sourceConfigs,
      validationConfig: validationConfig ?? this.validationConfig,
      classificationConfig: classificationConfig ?? this.classificationConfig,
      performanceConfig: performanceConfig ?? this.performanceConfig,
      securityConfig: securityConfig ?? this.securityConfig,
    );
  }

  /// Creates a mobile-optimized configuration
  factory DiscoveryConfig.mobileOptimized() {
    return const DiscoveryConfig(
      maxDiscoveryTimeMs: 3000, // 3 seconds for mobile
      maxMemoryUsageMB: 25.0, // 25MB for mobile
      enableBatteryOptimization: true,
      batteryOptimizationLevel: 0.9,
      enableNetworkOptimization: true,
      maxNetworkBandwidthKBps: 50.0, // Lower bandwidth for mobile
      enableMobileOptimizations: true,
      mobileOptimizationLevel: 0.9,
      enableParallelDiscovery: false, // Disable parallel for battery saving
      maxConcurrentDiscoveries: 1,
    );
  }

  /// Creates a high-performance configuration
  factory DiscoveryConfig.highPerformance() {
    return const DiscoveryConfig(
      maxDiscoveryTimeMs: 10000, // 10 seconds for thorough discovery
      maxMemoryUsageMB: 100.0, // 100MB for high performance
      enableCaching: true,
      cacheExpirationMinutes: 120, // 2 hours cache
      enableParallelDiscovery: true,
      maxConcurrentDiscoveries: 5,
      enableBatteryOptimization: false,
      enableNetworkOptimization: true,
      maxNetworkBandwidthKBps: 500.0, // High bandwidth
      enableMobileOptimizations: false,
      mobileOptimizationLevel: 0.3,
    );
  }

  /// Creates a battery-saving configuration
  factory DiscoveryConfig.batterySaving() {
    return const DiscoveryConfig(
      maxDiscoveryTimeMs: 8000, // 8 seconds for slower discovery
      maxMemoryUsageMB: 15.0, // 15MB for battery saving
      enableCaching: true,
      cacheExpirationMinutes: 180, // 3 hours cache
      enableParallelDiscovery: false,
      maxConcurrentDiscoveries: 1,
      enableBatteryOptimization: true,
      batteryOptimizationLevel: 1.0,
      enableNetworkOptimization: true,
      maxNetworkBandwidthKBps: 25.0, // Very low bandwidth
      enableMobileOptimizations: true,
      mobileOptimizationLevel: 1.0,
    );
  }

  @override
  List<Object?> get props => [
        maxDiscoveryTimeMs,
        maxMemoryUsageMB,
        enableCaching,
        cacheExpirationMinutes,
        enableParallelDiscovery,
        maxConcurrentDiscoveries,
        enableBatteryOptimization,
        batteryOptimizationLevel,
        enableNetworkOptimization,
        maxNetworkBandwidthKBps,
        enableMobileOptimizations,
        mobileOptimizationLevel,
        enabledSources,
        sourceConfigs,
        validationConfig,
        classificationConfig,
        performanceConfig,
        securityConfig,
      ];
}

/// Configuration for a specific discovery source
@JsonSerializable()
class SourceConfig extends Equatable {
  /// Whether the source is enabled
  final bool enabled;

  /// Priority of the source (lower number = higher priority)
  final int priority;

  /// Timeout for the source in milliseconds
  final int timeoutMs;

  /// Maximum retry attempts
  final int maxRetries;

  /// Source-specific settings
  final Map<String, dynamic> settings;

  const SourceConfig({
    this.enabled = true,
    this.priority = 100,
    this.timeoutMs = 5000,
    this.maxRetries = 3,
    this.settings = const {},
  });

  factory SourceConfig.fromJson(Map<String, dynamic> json) =>
      _$SourceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SourceConfigToJson(this);

  @override
  List<Object?> get props => [
        enabled,
        priority,
        timeoutMs,
        maxRetries,
        settings,
      ];
}

/// Configuration for tool validation
@JsonSerializable()
class ValidationConfig extends Equatable {
  /// Whether to enable strict validation
  final bool enableStrictValidation;

  /// Whether to validate schemas
  final bool validateSchemas;

  /// Whether to validate security requirements
  final bool validateSecurity;

  /// Whether to validate mobile compatibility
  final bool validateMobileCompatibility;

  /// Whether to validate performance requirements
  final bool validatePerformance;

  /// Maximum allowed validation time in milliseconds
  final int maxValidationTimeMs;

  const ValidationConfig({
    this.enableStrictValidation = false,
    this.validateSchemas = true,
    this.validateSecurity = true,
    this.validateMobileCompatibility = true,
    this.validatePerformance = true,
    this.maxValidationTimeMs = 2000,
  });

  factory ValidationConfig.fromJson(Map<String, dynamic> json) =>
      _$ValidationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationConfigToJson(this);

  @override
  List<Object?> get props => [
        enableStrictValidation,
        validateSchemas,
        validateSecurity,
        validateMobileCompatibility,
        validatePerformance,
        maxValidationTimeMs,
      ];
}

/// Configuration for tool classification
@JsonSerializable()
class ClassificationConfig extends Equatable {
  /// Whether to enable automatic classification
  final bool enableAutomaticClassification;

  /// Classification method to use
  final ClassificationMethod primaryMethod;

  /// Confidence threshold for automatic classification
  final double confidenceThreshold;

  /// Whether to use machine learning for classification
  final bool enableMLClassification;

  /// Custom classification rules
  final Map<String, List<String>> customRules;

  const ClassificationConfig({
    this.enableAutomaticClassification = true,
    this.primaryMethod = ClassificationMethod.hybrid,
    this.confidenceThreshold = 0.7,
    this.enableMLClassification = false,
    this.customRules = const {},
  });

  factory ClassificationConfig.fromJson(Map<String, dynamic> json) =>
      _$ClassificationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ClassificationConfigToJson(this);

  @override
  List<Object?> get props => [
        enableAutomaticClassification,
        primaryMethod,
        confidenceThreshold,
        enableMLClassification,
        customRules,
      ];
}

/// Configuration for performance monitoring
@JsonSerializable()
class PerformanceConfig extends Equatable {
  /// Whether to enable performance monitoring
  final bool enableMonitoring;

  /// Whether to collect detailed metrics
  final bool collectDetailedMetrics;

  /// Metrics retention period in days
  final int metricsRetentionDays;

  /// Whether to enable performance alerts
  final bool enableAlerts;

  /// Performance thresholds
  final Map<String, double> thresholds;

  const PerformanceConfig({
    this.enableMonitoring = true,
    this.collectDetailedMetrics = false,
    this.metricsRetentionDays = 7,
    this.enableAlerts = true,
    this.thresholds = const {
      'discovery_time_ms': 5000.0,
      'memory_usage_mb': 30.0,
      'network_usage_kb': 100.0,
      'battery_usage_percent': 5.0,
    },
  });

  factory PerformanceConfig.fromJson(Map<String, dynamic> json) =>
      _$PerformanceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceConfigToJson(this);

  @override
  List<Object?> get props => [
        enableMonitoring,
        collectDetailedMetrics,
        metricsRetentionDays,
        enableAlerts,
        thresholds,
      ];
}

/// Configuration for security settings
@JsonSerializable()
class SecurityConfig extends Equatable {
  /// Whether to enable security validation
  final bool enableSecurityValidation;

  /// Minimum security level required
  final SecurityLevel minSecurityLevel;

  /// Whether to require encryption
  final bool requireEncryption;

  /// Allowed security contexts
  final List<String> allowedContexts;

  /// Security validation rules
  final Map<String, List<String>> validationRules;

  const SecurityConfig({
    this.enableSecurityValidation = true,
    this.minSecurityLevel = SecurityLevel.basic,
    this.requireEncryption = false,
    this.allowedContexts = const ['public', 'private'],
    this.validationRules = const {},
  });

  factory SecurityConfig.fromJson(Map<String, dynamic> json) =>
      _$SecurityConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityConfigToJson(this);

  @override
  List<Object?> get props => [
        enableSecurityValidation,
        minSecurityLevel,
        requireEncryption,
        allowedContexts,
        validationRules,
      ];
}

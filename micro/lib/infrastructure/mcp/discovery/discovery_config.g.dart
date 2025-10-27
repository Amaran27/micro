// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoveryConfig _$DiscoveryConfigFromJson(Map<String, dynamic> json) =>
    DiscoveryConfig(
      maxDiscoveryTimeMs: (json['maxDiscoveryTimeMs'] as num?)?.toInt() ?? 5000,
      maxMemoryUsageMB: (json['maxMemoryUsageMB'] as num?)?.toDouble() ?? 30.0,
      enableCaching: json['enableCaching'] as bool? ?? true,
      cacheExpirationMinutes:
          (json['cacheExpirationMinutes'] as num?)?.toInt() ?? 60,
      enableParallelDiscovery: json['enableParallelDiscovery'] as bool? ?? true,
      maxConcurrentDiscoveries:
          (json['maxConcurrentDiscoveries'] as num?)?.toInt() ?? 3,
      enableBatteryOptimization:
          json['enableBatteryOptimization'] as bool? ?? true,
      batteryOptimizationLevel:
          (json['batteryOptimizationLevel'] as num?)?.toDouble() ?? 0.7,
      enableNetworkOptimization:
          json['enableNetworkOptimization'] as bool? ?? true,
      maxNetworkBandwidthKBps:
          (json['maxNetworkBandwidthKBps'] as num?)?.toDouble() ?? 100.0,
      enableMobileOptimizations:
          json['enableMobileOptimizations'] as bool? ?? true,
      mobileOptimizationLevel:
          (json['mobileOptimizationLevel'] as num?)?.toDouble() ?? 0.8,
      enabledSources: (json['enabledSources'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$DiscoverySourceTypeEnumMap, e))
              .toList() ??
          const [
            DiscoverySourceType.localDevice,
            DiscoverySourceType.network,
            DiscoverySourceType.mcpServer
          ],
      sourceConfigs: (json['sourceConfigs'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry($enumDecode(_$DiscoverySourceTypeEnumMap, k),
                SourceConfig.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      validationConfig: json['validationConfig'] == null
          ? const ValidationConfig()
          : ValidationConfig.fromJson(
              json['validationConfig'] as Map<String, dynamic>),
      classificationConfig: json['classificationConfig'] == null
          ? const ClassificationConfig()
          : ClassificationConfig.fromJson(
              json['classificationConfig'] as Map<String, dynamic>),
      performanceConfig: json['performanceConfig'] == null
          ? const PerformanceConfig()
          : PerformanceConfig.fromJson(
              json['performanceConfig'] as Map<String, dynamic>),
      securityConfig: json['securityConfig'] == null
          ? const SecurityConfig()
          : SecurityConfig.fromJson(
              json['securityConfig'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DiscoveryConfigToJson(DiscoveryConfig instance) =>
    <String, dynamic>{
      'maxDiscoveryTimeMs': instance.maxDiscoveryTimeMs,
      'maxMemoryUsageMB': instance.maxMemoryUsageMB,
      'enableCaching': instance.enableCaching,
      'cacheExpirationMinutes': instance.cacheExpirationMinutes,
      'enableParallelDiscovery': instance.enableParallelDiscovery,
      'maxConcurrentDiscoveries': instance.maxConcurrentDiscoveries,
      'enableBatteryOptimization': instance.enableBatteryOptimization,
      'batteryOptimizationLevel': instance.batteryOptimizationLevel,
      'enableNetworkOptimization': instance.enableNetworkOptimization,
      'maxNetworkBandwidthKBps': instance.maxNetworkBandwidthKBps,
      'enableMobileOptimizations': instance.enableMobileOptimizations,
      'mobileOptimizationLevel': instance.mobileOptimizationLevel,
      'enabledSources': instance.enabledSources
          .map((e) => _$DiscoverySourceTypeEnumMap[e]!)
          .toList(),
      'sourceConfigs': instance.sourceConfigs
          .map((k, e) => MapEntry(_$DiscoverySourceTypeEnumMap[k]!, e)),
      'validationConfig': instance.validationConfig,
      'classificationConfig': instance.classificationConfig,
      'performanceConfig': instance.performanceConfig,
      'securityConfig': instance.securityConfig,
    };

const _$DiscoverySourceTypeEnumMap = {
  DiscoverySourceType.localDevice: 'localDevice',
  DiscoverySourceType.network: 'network',
  DiscoverySourceType.mcpServer: 'mcpServer',
  DiscoverySourceType.cloudRegistry: 'cloudRegistry',
  DiscoverySourceType.manual: 'manual',
  DiscoverySourceType.cache: 'cache',
};

SourceConfig _$SourceConfigFromJson(Map<String, dynamic> json) => SourceConfig(
      enabled: json['enabled'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 100,
      timeoutMs: (json['timeoutMs'] as num?)?.toInt() ?? 5000,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$SourceConfigToJson(SourceConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'priority': instance.priority,
      'timeoutMs': instance.timeoutMs,
      'maxRetries': instance.maxRetries,
      'settings': instance.settings,
    };

ValidationConfig _$ValidationConfigFromJson(Map<String, dynamic> json) =>
    ValidationConfig(
      enableStrictValidation: json['enableStrictValidation'] as bool? ?? false,
      validateSchemas: json['validateSchemas'] as bool? ?? true,
      validateSecurity: json['validateSecurity'] as bool? ?? true,
      validateMobileCompatibility:
          json['validateMobileCompatibility'] as bool? ?? true,
      validatePerformance: json['validatePerformance'] as bool? ?? true,
      maxValidationTimeMs:
          (json['maxValidationTimeMs'] as num?)?.toInt() ?? 2000,
    );

Map<String, dynamic> _$ValidationConfigToJson(ValidationConfig instance) =>
    <String, dynamic>{
      'enableStrictValidation': instance.enableStrictValidation,
      'validateSchemas': instance.validateSchemas,
      'validateSecurity': instance.validateSecurity,
      'validateMobileCompatibility': instance.validateMobileCompatibility,
      'validatePerformance': instance.validatePerformance,
      'maxValidationTimeMs': instance.maxValidationTimeMs,
    };

ClassificationConfig _$ClassificationConfigFromJson(
        Map<String, dynamic> json) =>
    ClassificationConfig(
      enableAutomaticClassification:
          json['enableAutomaticClassification'] as bool? ?? true,
      primaryMethod: $enumDecodeNullable(
              _$ClassificationMethodEnumMap, json['primaryMethod']) ??
          ClassificationMethod.hybrid,
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.7,
      enableMLClassification: json['enableMLClassification'] as bool? ?? false,
      customRules: (json['customRules'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, (e as List<dynamic>).map((e) => e as String).toList()),
          ) ??
          const {},
    );

Map<String, dynamic> _$ClassificationConfigToJson(
        ClassificationConfig instance) =>
    <String, dynamic>{
      'enableAutomaticClassification': instance.enableAutomaticClassification,
      'primaryMethod': _$ClassificationMethodEnumMap[instance.primaryMethod]!,
      'confidenceThreshold': instance.confidenceThreshold,
      'enableMLClassification': instance.enableMLClassification,
      'customRules': instance.customRules,
    };

const _$ClassificationMethodEnumMap = {
  ClassificationMethod.manual: 'manual',
  ClassificationMethod.automated: 'automated',
  ClassificationMethod.mlBased: 'mlBased',
  ClassificationMethod.hybrid: 'hybrid',
  ClassificationMethod.behaviorBased: 'behaviorBased',
};

PerformanceConfig _$PerformanceConfigFromJson(Map<String, dynamic> json) =>
    PerformanceConfig(
      enableMonitoring: json['enableMonitoring'] as bool? ?? true,
      collectDetailedMetrics: json['collectDetailedMetrics'] as bool? ?? false,
      metricsRetentionDays:
          (json['metricsRetentionDays'] as num?)?.toInt() ?? 7,
      enableAlerts: json['enableAlerts'] as bool? ?? true,
      thresholds: (json['thresholds'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {
            'discovery_time_ms': 5000.0,
            'memory_usage_mb': 30.0,
            'network_usage_kb': 100.0,
            'battery_usage_percent': 5.0
          },
    );

Map<String, dynamic> _$PerformanceConfigToJson(PerformanceConfig instance) =>
    <String, dynamic>{
      'enableMonitoring': instance.enableMonitoring,
      'collectDetailedMetrics': instance.collectDetailedMetrics,
      'metricsRetentionDays': instance.metricsRetentionDays,
      'enableAlerts': instance.enableAlerts,
      'thresholds': instance.thresholds,
    };

SecurityConfig _$SecurityConfigFromJson(Map<String, dynamic> json) =>
    SecurityConfig(
      enableSecurityValidation:
          json['enableSecurityValidation'] as bool? ?? true,
      minSecurityLevel: $enumDecodeNullable(
              _$SecurityLevelEnumMap, json['minSecurityLevel']) ??
          SecurityLevel.basic,
      requireEncryption: json['requireEncryption'] as bool? ?? false,
      allowedContexts: (json['allowedContexts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['public', 'private'],
      validationRules: (json['validationRules'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, (e as List<dynamic>).map((e) => e as String).toList()),
          ) ??
          const {},
    );

Map<String, dynamic> _$SecurityConfigToJson(SecurityConfig instance) =>
    <String, dynamic>{
      'enableSecurityValidation': instance.enableSecurityValidation,
      'minSecurityLevel': _$SecurityLevelEnumMap[instance.minSecurityLevel]!,
      'requireEncryption': instance.requireEncryption,
      'allowedContexts': instance.allowedContexts,
      'validationRules': instance.validationRules,
    };

const _$SecurityLevelEnumMap = {
  SecurityLevel.none: 'none',
  SecurityLevel.basic: 'basic',
  SecurityLevel.standard: 'standard',
  SecurityLevel.high: 'high',
  SecurityLevel.critical: 'critical',
};

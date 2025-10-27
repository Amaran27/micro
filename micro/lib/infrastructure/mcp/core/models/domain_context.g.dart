// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainContext _$DomainContextFromJson(Map<String, dynamic> json) =>
    DomainContext(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      version: json['version'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      securityContext: SecurityContext.fromJson(
          json['securityContext'] as Map<String, dynamic>),
      performanceContext: PerformanceContext.fromJson(
          json['performanceContext'] as Map<String, dynamic>),
      mobileContext:
          MobileContext.fromJson(json['mobileContext'] as Map<String, dynamic>),
      complianceRequirements: (json['complianceRequirements'] as List<dynamic>?)
              ?.map((e) =>
                  ComplianceRequirement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DomainContextToJson(DomainContext instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'version': instance.version,
      'parameters': instance.parameters,
      'securityContext': instance.securityContext,
      'performanceContext': instance.performanceContext,
      'mobileContext': instance.mobileContext,
      'complianceRequirements': instance.complianceRequirements,
    };

SecurityContext _$SecurityContextFromJson(Map<String, dynamic> json) =>
    SecurityContext(
      securityLevel: json['securityLevel'] as String,
      authenticationRequirements:
          (json['authenticationRequirements'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      authorizationRequirements:
          (json['authorizationRequirements'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      encryptionRequirements: EncryptionRequirements.fromJson(
          json['encryptionRequirements'] as Map<String, dynamic>),
      auditRequirements: (json['auditRequirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      privacyRequirements: (json['privacyRequirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SecurityContextToJson(SecurityContext instance) =>
    <String, dynamic>{
      'securityLevel': instance.securityLevel,
      'authenticationRequirements': instance.authenticationRequirements,
      'authorizationRequirements': instance.authorizationRequirements,
      'encryptionRequirements': instance.encryptionRequirements,
      'auditRequirements': instance.auditRequirements,
      'privacyRequirements': instance.privacyRequirements,
    };

EncryptionRequirements _$EncryptionRequirementsFromJson(
        Map<String, dynamic> json) =>
    EncryptionRequirements(
      required: json['required'] as bool,
      algorithm: json['algorithm'] as String?,
      keyLength: (json['keyLength'] as num?)?.toInt(),
      encryptAtRest: json['encryptAtRest'] as bool? ?? true,
      encryptInTransit: json['encryptInTransit'] as bool? ?? true,
    );

Map<String, dynamic> _$EncryptionRequirementsToJson(
        EncryptionRequirements instance) =>
    <String, dynamic>{
      'required': instance.required,
      'algorithm': instance.algorithm,
      'keyLength': instance.keyLength,
      'encryptAtRest': instance.encryptAtRest,
      'encryptInTransit': instance.encryptInTransit,
    };

PerformanceContext _$PerformanceContextFromJson(Map<String, dynamic> json) =>
    PerformanceContext(
      maxExecutionTime:
          Duration(microseconds: (json['maxExecutionTime'] as num).toInt()),
      maxMemoryUsageMB: (json['maxMemoryUsageMB'] as num).toDouble(),
      maxCpuUsagePercent: (json['maxCpuUsagePercent'] as num).toDouble(),
      maxNetworkBandwidthKBps:
          (json['maxNetworkBandwidthKBps'] as num).toDouble(),
      targets:
          PerformanceTargets.fromJson(json['targets'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PerformanceContextToJson(PerformanceContext instance) =>
    <String, dynamic>{
      'maxExecutionTime': instance.maxExecutionTime.inMicroseconds,
      'maxMemoryUsageMB': instance.maxMemoryUsageMB,
      'maxCpuUsagePercent': instance.maxCpuUsagePercent,
      'maxNetworkBandwidthKBps': instance.maxNetworkBandwidthKBps,
      'targets': instance.targets,
    };

PerformanceTargets _$PerformanceTargetsFromJson(Map<String, dynamic> json) =>
    PerformanceTargets(
      targetExecutionTime:
          Duration(microseconds: (json['targetExecutionTime'] as num).toInt()),
      targetMemoryUsageMB: (json['targetMemoryUsageMB'] as num).toDouble(),
      targetSuccessRate: (json['targetSuccessRate'] as num).toDouble(),
      targetAvailability: (json['targetAvailability'] as num).toDouble(),
    );

Map<String, dynamic> _$PerformanceTargetsToJson(PerformanceTargets instance) =>
    <String, dynamic>{
      'targetExecutionTime': instance.targetExecutionTime.inMicroseconds,
      'targetMemoryUsageMB': instance.targetMemoryUsageMB,
      'targetSuccessRate': instance.targetSuccessRate,
      'targetAvailability': instance.targetAvailability,
    };

MobileContext _$MobileContextFromJson(Map<String, dynamic> json) =>
    MobileContext(
      requiresMobileOptimization: json['requiresMobileOptimization'] as bool,
      batteryOptimizationLevel: json['batteryOptimizationLevel'] as String,
      networkOptimizations: (json['networkOptimizations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      memoryOptimizations: (json['memoryOptimizations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      offlineRequirements: OfflineRequirements.fromJson(
          json['offlineRequirements'] as Map<String, dynamic>),
      backgroundRequirements: BackgroundExecutionRequirements.fromJson(
          json['backgroundRequirements'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MobileContextToJson(MobileContext instance) =>
    <String, dynamic>{
      'requiresMobileOptimization': instance.requiresMobileOptimization,
      'batteryOptimizationLevel': instance.batteryOptimizationLevel,
      'networkOptimizations': instance.networkOptimizations,
      'memoryOptimizations': instance.memoryOptimizations,
      'offlineRequirements': instance.offlineRequirements,
      'backgroundRequirements': instance.backgroundRequirements,
    };

OfflineRequirements _$OfflineRequirementsFromJson(Map<String, dynamic> json) =>
    OfflineRequirements(
      required: json['required'] as bool,
      maxOfflineDuration:
          Duration(microseconds: (json['maxOfflineDuration'] as num).toInt()),
      syncRequirements: (json['syncRequirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cacheRequirements: CacheRequirements.fromJson(
          json['cacheRequirements'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OfflineRequirementsToJson(
        OfflineRequirements instance) =>
    <String, dynamic>{
      'required': instance.required,
      'maxOfflineDuration': instance.maxOfflineDuration.inMicroseconds,
      'syncRequirements': instance.syncRequirements,
      'cacheRequirements': instance.cacheRequirements,
    };

CacheRequirements _$CacheRequirementsFromJson(Map<String, dynamic> json) =>
    CacheRequirements(
      maxCacheSizeMB: (json['maxCacheSizeMB'] as num).toDouble(),
      evictionPolicy: json['evictionPolicy'] as String,
      ttl: Duration(microseconds: (json['ttl'] as num).toInt()),
    );

Map<String, dynamic> _$CacheRequirementsToJson(CacheRequirements instance) =>
    <String, dynamic>{
      'maxCacheSizeMB': instance.maxCacheSizeMB,
      'evictionPolicy': instance.evictionPolicy,
      'ttl': instance.ttl.inMicroseconds,
    };

BackgroundExecutionRequirements _$BackgroundExecutionRequirementsFromJson(
        Map<String, dynamic> json) =>
    BackgroundExecutionRequirements(
      required: json['required'] as bool,
      maxExecutionTime:
          Duration(microseconds: (json['maxExecutionTime'] as num).toInt()),
      resourceLimits: ResourceLimits.fromJson(
          json['resourceLimits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BackgroundExecutionRequirementsToJson(
        BackgroundExecutionRequirements instance) =>
    <String, dynamic>{
      'required': instance.required,
      'maxExecutionTime': instance.maxExecutionTime.inMicroseconds,
      'resourceLimits': instance.resourceLimits,
    };

ResourceLimits _$ResourceLimitsFromJson(Map<String, dynamic> json) =>
    ResourceLimits(
      maxMemoryMB: (json['maxMemoryMB'] as num).toDouble(),
      maxCpuPercent: (json['maxCpuPercent'] as num).toDouble(),
      maxNetworkMB: (json['maxNetworkMB'] as num).toDouble(),
    );

Map<String, dynamic> _$ResourceLimitsToJson(ResourceLimits instance) =>
    <String, dynamic>{
      'maxMemoryMB': instance.maxMemoryMB,
      'maxCpuPercent': instance.maxCpuPercent,
      'maxNetworkMB': instance.maxNetworkMB,
    };

ComplianceRequirement _$ComplianceRequirementFromJson(
        Map<String, dynamic> json) =>
    ComplianceRequirement(
      standard: json['standard'] as String,
      version: json['version'] as String,
      requirements: (json['requirements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isMandatory: json['isMandatory'] as bool? ?? true,
    );

Map<String, dynamic> _$ComplianceRequirementToJson(
        ComplianceRequirement instance) =>
    <String, dynamic>{
      'standard': instance.standard,
      'version': instance.version,
      'requirements': instance.requirements,
      'isMandatory': instance.isMandatory,
    };

import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import '../core/models/domain_context.dart';
import '../core/models/tool.dart';
import '../core/exceptions/mcp_exceptions.dart';
import 'models/adapter_models.dart';

/// Handles domain-specific configuration and context management for tool adaptation
class DomainContextHandler {
  /// Cache for domain configurations
  final Map<String, DomainContext> _domainCache = {};

  /// Cache for domain constraints
  final Map<String, DomainConstraints> _constraintsCache = {};

  /// Cache for adaptation rules
  final Map<String, List<AdaptationRule>> _rulesCache = {};

  /// Performance metrics
  final _ContextHandlerMetrics _metrics = _ContextHandlerMetrics();

  /// Constructor
  DomainContextHandler() {
    _initializeDefaultDomains();
  }

  /// Configures the handler for a specific domain
  Future<void> configureForDomain(String domainId) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Check cache first
      if (_domainCache.containsKey(domainId)) {
        _metrics.recordCacheHit();
        return;
      }

      // Load domain configuration
      final domain = await _loadDomainConfiguration(domainId);
      if (domain != null) {
        _domainCache[domainId] = domain;

        // Load domain constraints
        final constraints = await _loadDomainConstraints(domainId);
        if (constraints != null) {
          _constraintsCache[domainId] = constraints;
        }

        // Load adaptation rules
        final rules = await _loadAdaptationRules(domainId);
        if (rules != null) {
          _rulesCache[domainId] = rules;
        }

        _metrics.recordDomainLoad(stopwatch.elapsedMilliseconds);
      } else {
        _metrics.recordError();
        throw McpConfigurationException(
          'Domain configuration not found: $domainId',
          configKey: 'domain_id',
          configValue: domainId,
        );
      }
    } catch (e) {
      _metrics.recordError();
      throw McpConfigurationException(
        'Failed to configure domain: $domainId',
        configKey: 'domain_configuration',
        originalError: e,
      );
    }
  }

  /// Gets the current domain context
  DomainContext? getCurrentDomain(String domainId) {
    return _domainCache[domainId];
  }

  /// Validates if a tool can be adapted to a domain
  Future<bool> canAdaptTool(Tool tool, String targetDomainId) async {
    try {
      final targetDomain = _domainCache[targetDomainId];
      if (targetDomain == null) {
        await configureForDomain(targetDomainId);
        return _domainCache[targetDomainId] != null;
      }

      // Check domain compatibility
      final isCompatible = await _checkDomainCompatibility(
        tool.domainContext,
        targetDomain,
      );

      // Check tool constraints
      final meetsConstraints = await _checkToolConstraints(tool, targetDomain);

      // Check security requirements
      final meetsSecurity =
          await _checkSecurityRequirements(tool, targetDomain);

      return isCompatible && meetsConstraints && meetsSecurity;
    } catch (e) {
      _metrics.recordError();
      return false;
    }
  }

  /// Adapts a tool for a specific domain context
  Future<Tool> adaptToolForDomain(
    Tool tool,
    String targetDomainId,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final targetDomain = _domainCache[targetDomainId];
      if (targetDomain == null) {
        await configureForDomain(targetDomainId);
      }

      final domain = _domainCache[targetDomainId]!;
      final constraints = _constraintsCache[targetDomainId];
      final rules = _rulesCache[targetDomainId] ?? [];

      // Apply domain adaptations
      final adaptedTool = await _applyDomainAdaptations(
        tool,
        domain,
        constraints,
        rules,
      );

      _metrics.recordAdaptation(stopwatch.elapsedMilliseconds);
      return adaptedTool;
    } catch (e) {
      _metrics.recordError();
      throw McpAdapterException(
        'Failed to adapt tool for domain: $targetDomainId',
        adapterType: 'DomainContextHandler',
        targetTool: tool.id,
        originalError: e,
      );
    }
  }

  /// Gets domain constraints for a domain
  DomainConstraints? getDomainConstraints(String domainId) {
    return _constraintsCache[domainId];
  }

  /// Gets adaptation rules for a domain
  List<AdaptationRule> getAdaptationRules(String domainId) {
    return _rulesCache[domainId] ?? [];
  }

  /// Updates domain configuration
  Future<void> updateDomainConfiguration(
    String domainId,
    DomainContext domain,
  ) async {
    try {
      // Update cache
      _domainCache[domainId] = domain;

      // Persist changes
      await _saveDomainConfiguration(domainId, domain);

      // Reload constraints and rules
      final constraints = await _loadDomainConstraints(domainId);
      if (constraints != null) {
        _constraintsCache[domainId] = constraints;
      }

      final rules = await _loadAdaptationRules(domainId);
      if (rules != null) {
        _rulesCache[domainId] = rules;
      }

      _metrics.recordDomainUpdate();
    } catch (e) {
      _metrics.recordError();
      throw McpConfigurationException(
        'Failed to update domain configuration: $domainId',
        configKey: 'domain_update',
        originalError: e,
      );
    }
  }

  /// Clears domain cache
  void clearCache() {
    _domainCache.clear();
    _constraintsCache.clear();
    _rulesCache.clear();
  }

  /// Gets performance metrics
  Map<String, dynamic> getMetrics() => _metrics.toJson();

  /// Loads domain configuration from storage or remote source
  Future<DomainContext?> _loadDomainConfiguration(String domainId) async {
    // In a real implementation, this would load from a database or API
    // For now, return predefined domains
    return _getPredefinedDomain(domainId);
  }

  /// Saves domain configuration to storage
  Future<void> _saveDomainConfiguration(
      String domainId, DomainContext domain) async {
    // In a real implementation, this would save to a database or API
    // For now, just simulate success
    await Future.delayed(Duration(milliseconds: 10));
  }

  /// Loads domain constraints
  Future<DomainConstraints?> _loadDomainConstraints(String domainId) async {
    // In a real implementation, this would load from a database or API
    // For now, return predefined constraints
    return _getPredefinedConstraints(domainId);
  }

  /// Loads adaptation rules
  Future<List<AdaptationRule>?> _loadAdaptationRules(String domainId) async {
    // In a real implementation, this would load from a database or API
    // For now, return predefined rules
    return _getPredefinedRules(domainId);
  }

  /// Checks if two domains are compatible
  Future<bool> _checkDomainCompatibility(
    DomainContext sourceDomain,
    DomainContext targetDomain,
  ) async {
    // Check category compatibility
    if (!_isCategoryCompatible(sourceDomain.category, targetDomain.category)) {
      return false;
    }

    // Check version compatibility
    if (!_isVersionCompatible(sourceDomain.version, targetDomain.version)) {
      return false;
    }

    // Check security level compatibility
    if (!_isSecurityLevelCompatible(sourceDomain.securityContext.securityLevel,
        targetDomain.securityContext.securityLevel)) {
      return false;
    }

    return true;
  }

  /// Checks if tool meets domain constraints
  Future<bool> _checkToolConstraints(
    Tool tool,
    DomainContext targetDomain,
  ) async {
    final constraints = _constraintsCache[targetDomain.id];
    if (constraints == null) return true;

    // Check performance constraints
    if (tool.performanceMetrics.averageExecutionTime >
        targetDomain.performanceContext.maxExecutionTime) {
      return false;
    }

    if (tool.performanceMetrics.memoryUsageMB >
        targetDomain.performanceContext.maxMemoryUsageMB) {
      return false;
    }

    // Check mobile constraints
    if (targetDomain.mobileContext.requiresMobileOptimization &&
        !tool.isMobileOptimized) {
      return false;
    }

    return true;
  }

  /// Checks if tool meets security requirements
  Future<bool> _checkSecurityRequirements(
    Tool tool,
    DomainContext targetDomain,
  ) async {
    final sourceSecurity = tool.domainContext.securityContext;
    final targetSecurity = targetDomain.securityContext;

    // Check encryption requirements
    if (targetSecurity.encryptionRequirements.required &&
        !sourceSecurity.encryptionRequirements.required) {
      return false;
    }

    // Check authentication requirements
    for (final requirement in targetSecurity.authenticationRequirements) {
      if (!sourceSecurity.authenticationRequirements.contains(requirement)) {
        return false;
      }
    }

    // Check authorization requirements
    for (final requirement in targetSecurity.authorizationRequirements) {
      if (!sourceSecurity.authorizationRequirements.contains(requirement)) {
        return false;
      }
    }

    return true;
  }

  /// Applies domain adaptations to a tool
  Future<Tool> _applyDomainAdaptations(
    Tool tool,
    DomainContext targetDomain,
    DomainConstraints constraints,
    List<AdaptationRule> rules,
  ) async {
    // Create adapted tool with updated properties
    final adaptedTool = tool.copyWith(
      domainContext: targetDomain,
      executionMetadata: tool.executionMetadata.copyWith(
        timeout: _calculateAdaptedTimeout(tool, constraints),
      ),
      performanceMetrics: tool.performanceMetrics.copyWith(
        averageExecutionTime: _calculateAdaptedExecutionTime(tool, constraints),
        memoryUsageMB: _calculateAdaptedMemoryUsage(tool, constraints),
      ),
      mobileOptimizations: tool.mobileOptimizations.copyWith(
        isOptimized: _calculateAdaptedMobileOptimization(tool, targetDomain),
        batteryOptimization:
            targetDomain.mobileContext.batteryOptimizationLevel,
        memoryOptimizations: targetDomain.mobileContext.memoryOptimizations,
      ),
    );

    // Apply adaptation rules
    return _applyAdaptationRules(adaptedTool, rules);
  }

  /// Applies adaptation rules to a tool
  Tool _applyAdaptationRules(Tool tool, List<AdaptationRule> rules) {
    var adaptedTool = tool;

    for (final rule in rules) {
      adaptedTool = rule.apply(adaptedTool);
    }

    return adaptedTool;
  }

  /// Calculates adapted timeout based on constraints
  Duration _calculateAdaptedTimeout(Tool tool, DomainConstraints constraints) {
    final originalTimeout = tool.executionMetadata.timeout;
    final maxTimeout = constraints.maxExecutionTime;

    return originalTimeout > maxTimeout ? maxTimeout : originalTimeout;
  }

  /// Calculates adapted execution time based on constraints
  Duration _calculateAdaptedExecutionTime(
      Tool tool, DomainConstraints constraints) {
    final originalTime = tool.performanceMetrics.averageExecutionTime;
    final maxTime = constraints.maxExecutionTime;

    return originalTime > maxTime ? maxTime : originalTime;
  }

  /// Calculates adapted memory usage based on constraints
  double _calculateAdaptedMemoryUsage(
      Tool tool, DomainConstraints constraints) {
    final originalMemory = tool.performanceMetrics.memoryUsageMB;
    final maxMemory = constraints.maxMemoryUsageMB;

    return originalMemory > maxMemory ? maxMemory : originalMemory;
  }

  /// Calculates adapted mobile optimization based on domain
  bool _calculateAdaptedMobileOptimization(
      Tool tool, DomainContext targetDomain) {
    return targetDomain.mobileContext.requiresMobileOptimization
        ? tool.isMobileOptimized
        : false;
  }

  /// Checks if categories are compatible
  bool _isCategoryCompatible(String sourceCategory, String targetCategory) {
    // Define compatible category mappings
    final compatibleCategories = {
      'general': ['web', 'mobile', 'desktop'],
      'web': ['general', 'mobile'],
      'mobile': ['general', 'web'],
      'desktop': ['general'],
      'healthcare': ['medical', 'research'],
      'finance': ['banking', 'accounting'],
      'iot': ['analytics', 'monitoring'],
    };

    final compatible = compatibleCategories[sourceCategory];
    return compatible?.contains(targetCategory) ?? false;
  }

  /// Checks if versions are compatible
  bool _isVersionCompatible(String sourceVersion, String targetVersion) {
    // Simple semantic version comparison
    final sourceParts = sourceVersion.split('.').map(int.parse).toList();
    final targetParts = targetVersion.split('.').map(int.parse).toList();

    // Major version must match
    if (sourceParts[0] != targetParts[0]) {
      return false;
    }

    // Source version should be >= target version
    for (int i = 0; i < sourceParts.length && i < targetParts.length; i++) {
      if (sourceParts[i] < targetParts[i]) {
        return false;
      }
    }

    return true;
  }

  /// Checks if security levels are compatible
  bool _isSecurityLevelCompatible(String sourceLevel, String targetLevel) {
    // Define security level hierarchy
    final levels = ['low', 'medium', 'high', 'critical'];
    final sourceIndex = levels.indexOf(sourceLevel);
    final targetIndex = levels.indexOf(targetLevel);

    // Source level should be >= target level
    return sourceIndex >= targetIndex && sourceIndex != -1 && targetIndex != -1;
  }

  /// Gets predefined domain configuration
  DomainContext? _getPredefinedDomain(String domainId) {
    switch (domainId) {
      case 'web':
        return DomainContext(
          id: 'web',
          name: 'Web Domain',
          description: 'Web application domain with browser-based interactions',
          category: 'web',
          version: '1.0.0',
          parameters: {
            'required_parameters': ['url', 'user_agent'],
            'validation_rules': {
              'string': ['not_null', 'max_length:2048'],
            },
          },
          securityContext: SecurityContext(
            securityLevel: 'medium',
            authenticationRequirements: ['session'],
            authorizationRequirements: ['csrf_protection'],
            encryptionRequirements: EncryptionRequirements(
              required: true,
              algorithm: 'AES-256',
              encryptAtRest: true,
              encryptInTransit: true,
            ),
            auditRequirements: ['access_logging'],
            privacyRequirements: ['data_minimization'],
          ),
          performanceContext: PerformanceContext(
            maxExecutionTime: Duration(seconds: 30),
            maxMemoryUsageMB: 100.0,
            maxCpuUsagePercent: 50.0,
            maxNetworkBandwidthKBps: 1024.0,
            targets: PerformanceTargets(
              targetExecutionTime: Duration(seconds: 10),
              targetMemoryUsageMB: 50.0,
              targetSuccessRate: 0.95,
              targetAvailability: 0.99,
            ),
          ),
          mobileContext: MobileContext(
            requiresMobileOptimization: false,
            batteryOptimizationLevel: 'low',
            networkOptimizations: ['compression', 'caching'],
            memoryOptimizations: ['lazy_loading'],
            offlineRequirements: OfflineRequirements(
              required: false,
              maxOfflineDuration: Duration(hours: 1),
              syncRequirements: ['delta_sync'],
              cacheRequirements: CacheRequirements(
                maxCacheSizeMB: 50.0,
                evictionPolicy: 'lru',
                ttl: Duration(hours: 24),
              ),
            ),
            backgroundRequirements: BackgroundExecutionRequirements(
              required: false,
              maxExecutionTime: Duration(minutes: 5),
              resourceLimits: ResourceLimits(
                maxMemoryMB: 20.0,
                maxCpuPercent: 10.0,
                maxNetworkMB: 10.0,
              ),
            ),
          ),
        );
      case 'mobile':
        return DomainContext(
          id: 'mobile',
          name: 'Mobile Domain',
          description:
              'Mobile application domain with touch-based interactions',
          category: 'mobile',
          version: '1.0.0',
          parameters: {
            'required_parameters': ['device_id', 'os_version'],
            'validation_rules': {
              'string': ['not_null', 'max_length:256'],
            },
          },
          securityContext: SecurityContext(
            securityLevel: 'high',
            authenticationRequirements: ['biometric', 'device_token'],
            authorizationRequirements: ['app_permissions'],
            encryptionRequirements: EncryptionRequirements(
              required: true,
              algorithm: 'AES-256',
              encryptAtRest: true,
              encryptInTransit: true,
            ),
            auditRequirements: ['access_logging', 'tamper_detection'],
            privacyRequirements: ['data_minimization', 'user_consent'],
          ),
          performanceContext: PerformanceContext(
            maxExecutionTime: Duration(seconds: 10),
            maxMemoryUsageMB: 30.0,
            maxCpuUsagePercent: 30.0,
            maxNetworkBandwidthKBps: 512.0,
            targets: PerformanceTargets(
              targetExecutionTime: Duration(seconds: 3),
              targetMemoryUsageMB: 15.0,
              targetSuccessRate: 0.98,
              targetAvailability: 0.99,
            ),
          ),
          mobileContext: MobileContext(
            requiresMobileOptimization: true,
            batteryOptimizationLevel: 'high',
            networkOptimizations: ['compression', 'caching', 'batching'],
            memoryOptimizations: ['lazy_loading', 'object_pooling'],
            offlineRequirements: OfflineRequirements(
              required: true,
              maxOfflineDuration: Duration(hours: 24),
              syncRequirements: ['delta_sync', 'conflict_resolution'],
              cacheRequirements: CacheRequirements(
                maxCacheSizeMB: 20.0,
                evictionPolicy: 'lru',
                ttl: Duration(hours: 48),
              ),
            ),
            backgroundRequirements: BackgroundExecutionRequirements(
              required: true,
              maxExecutionTime: Duration(minutes: 2),
              resourceLimits: ResourceLimits(
                maxMemoryMB: 10.0,
                maxCpuPercent: 15.0,
                maxNetworkMB: 5.0,
              ),
            ),
          ),
        );
      default:
        return null;
    }
  }

  /// Gets predefined domain constraints
  DomainConstraints? _getPredefinedConstraints(String domainId) {
    switch (domainId) {
      case 'web':
        return DomainConstraints(
          maxExecutionTime: Duration(seconds: 30),
          maxMemoryUsageMB: 100.0,
          maxCpuUsagePercent: 50.0,
          maxNetworkBandwidthKBps: 1024.0,
        );
      case 'mobile':
        return DomainConstraints(
          maxExecutionTime: Duration(seconds: 10),
          maxMemoryUsageMB: 30.0,
          maxCpuUsagePercent: 30.0,
          maxNetworkBandwidthKBps: 512.0,
        );
      default:
        return null;
    }
  }

  /// Gets predefined adaptation rules
  List<AdaptationRule>? _getPredefinedRules(String domainId) {
    switch (domainId) {
      case 'web':
        return [
          AdaptationRule(
            id: 'web_input_adaptation',
            name: 'Web Input Adaptation',
            description: 'Adapts input parameters for web context',
            condition: (tool) => tool.category == 'input',
            action: (tool) => tool.copyWith(
              inputSchema: _adaptWebInputSchema(tool.inputSchema),
            ),
          ),
          AdaptationRule(
            id: 'web_output_adaptation',
            name: 'Web Output Adaptation',
            description: 'Adapts output parameters for web context',
            condition: (tool) => tool.category == 'output',
            action: (tool) => tool.copyWith(
              outputSchema: _adaptWebOutputSchema(tool.outputSchema),
            ),
          ),
        ];
      case 'mobile':
        return [
          AdaptationRule(
            id: 'mobile_input_adaptation',
            name: 'Mobile Input Adaptation',
            description: 'Adapts input parameters for mobile context',
            condition: (tool) => tool.category == 'input',
            action: (tool) => tool.copyWith(
              inputSchema: _adaptMobileInputSchema(tool.inputSchema),
            ),
          ),
          AdaptationRule(
            id: 'mobile_output_adaptation',
            name: 'Mobile Output Adaptation',
            description: 'Adapts output parameters for mobile context',
            condition: (tool) => tool.category == 'output',
            action: (tool) => tool.copyWith(
              outputSchema: _adaptMobileOutputSchema(tool.outputSchema),
            ),
          ),
        ];
      default:
        return null;
    }
  }

  /// Adapts input schema for web context
  Map<String, dynamic> _adaptWebInputSchema(
      Map<String, dynamic> originalSchema) {
    final adaptedSchema = Map<String, dynamic>.from(originalSchema);

    // Add web-specific parameters
    adaptedSchema['user_agent'] = {
      'type': 'string',
      'description': 'User agent string',
      'required': false,
    };

    adaptedSchema['csrf_token'] = {
      'type': 'string',
      'description': 'CSRF protection token',
      'required': false,
    };

    return adaptedSchema;
  }

  /// Adapts output schema for web context
  Map<String, dynamic> _adaptWebOutputSchema(
      Map<String, dynamic> originalSchema) {
    final adaptedSchema = Map<String, dynamic>.from(originalSchema);

    // Add web-specific parameters
    adaptedSchema['html_response'] = {
      'type': 'string',
      'description': 'HTML response content',
      'required': false,
    };

    adaptedSchema['redirect_url'] = {
      'type': 'string',
      'description': 'Redirect URL',
      'required': false,
    };

    return adaptedSchema;
  }

  /// Adapts input schema for mobile context
  Map<String, dynamic> _adaptMobileInputSchema(
      Map<String, dynamic> originalSchema) {
    final adaptedSchema = Map<String, dynamic>.from(originalSchema);

    // Add mobile-specific parameters
    adaptedSchema['touch_gesture'] = {
      'type': 'string',
      'description': 'Touch gesture type',
      'required': false,
    };

    adaptedSchema['device_orientation'] = {
      'type': 'string',
      'description': 'Device orientation',
      'required': false,
    };

    return adaptedSchema;
  }

  /// Adapts output schema for mobile context
  Map<String, dynamic> _adaptMobileOutputSchema(
      Map<String, dynamic> originalSchema) {
    final adaptedSchema = Map<String, dynamic>.from(originalSchema);

    // Add mobile-specific parameters
    adaptedSchema['vibration_pattern'] = {
      'type': 'string',
      'description': 'Vibration pattern',
      'required': false,
    };

    adaptedSchema['notification'] = {
      'type': 'object',
      'description': 'Notification configuration',
      'required': false,
    };

    return adaptedSchema;
  }

  /// Initializes default domains
  void _initializeDefaultDomains() {
    // Preload common domains
    final defaultDomains = ['web', 'mobile'];
    for (final domainId in defaultDomains) {
      _loadDomainConfiguration(domainId);
    }
  }
}

/// Domain constraints for tool execution
class DomainConstraints {
  final Duration maxExecutionTime;
  final double maxMemoryUsageMB;
  final double maxCpuUsagePercent;
  final double maxNetworkBandwidthKBps;

  const DomainConstraints({
    required this.maxExecutionTime,
    required this.maxMemoryUsageMB,
    required this.maxCpuUsagePercent,
    required this.maxNetworkBandwidthKBps,
  });
}

/// Adaptation rule for domain-specific tool modifications
class AdaptationRule {
  final String id;
  final String name;
  final String description;
  final bool Function(Tool) condition;
  final Tool Function(Tool) action;

  const AdaptationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.action,
  });

  /// Applies the rule if the condition is met
  Tool apply(Tool tool) {
    return condition(tool) ? action(tool) : tool;
  }
}

/// Internal metrics tracking for domain context handler
class _ContextHandlerMetrics {
  int _domainLoads = 0;
  int _domainUpdates = 0;
  int _adaptations = 0;
  int _cacheHits = 0;
  int _errors = 0;
  final List<int> _loadTimes = [];
  final List<int> _adaptationTimes = [];

  void recordDomainLoad(int milliseconds) {
    _domainLoads++;
    _loadTimes.add(milliseconds);
  }

  void recordDomainUpdate() => _domainUpdates++;
  void recordAdaptation(int milliseconds) {
    _adaptations++;
    _adaptationTimes.add(milliseconds);
  }

  void recordCacheHit() => _cacheHits++;
  void recordError() => _errors++;

  Map<String, dynamic> toJson() {
    return {
      'domain_loads': _domainLoads,
      'domain_updates': _domainUpdates,
      'adaptations': _adaptations,
      'cache_hits': _cacheHits,
      'errors': _errors,
      'average_load_time_ms': _loadTimes.isEmpty
          ? 0.0
          : _loadTimes.reduce((a, b) => a + b) / _loadTimes.length,
      'average_adaptation_time_ms': _adaptationTimes.isEmpty
          ? 0.0
          : _adaptationTimes.reduce((a, b) => a + b) / _adaptationTimes.length,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}

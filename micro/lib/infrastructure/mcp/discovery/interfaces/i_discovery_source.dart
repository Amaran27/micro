import 'package:equatable/equatable.dart';
import '../models/discovery_models.dart';
import '../../core/models/tool.dart';

/// Interface for tool discovery sources
///
/// Discovery sources are responsible for finding tools from different locations
/// such as local device, network, or MCP servers.
abstract class IDiscoverySource extends Equatable {
  /// Unique identifier for the discovery source
  String get id;

  /// Human-readable name of the discovery source
  String get name;

  /// Type of discovery source
  DiscoverySourceType get type;

  /// Whether the source is currently available
  bool get isAvailable;

  /// Priority of the source (lower number = higher priority)
  int get priority;

  /// Last time the source was successfully accessed
  DateTime? get lastAccessTime;

  /// Number of tools discovered from this source
  int get discoveredToolCount;

  /// Initializes the discovery source
  ///
  /// [config] contains source-specific configuration
  Future<void> initialize(Map<String, dynamic> config);

  /// Discovers tools from this source
  ///
  /// Returns a list of discovered tools with metadata
  /// [timeout] specifies maximum time to wait for discovery
  Future<List<DiscoveredTool>> discoverTools({Duration? timeout});

  /// Validates that a tool from this source is reachable
  ///
  /// [tool] is the tool to validate
  /// Returns true if the tool is reachable and functional
  Future<bool> validateToolReachability(Tool tool);

  /// Gets the current status of the discovery source
  ///
  /// Returns status information including health and performance metrics
  Future<Map<String, dynamic>> getStatus();

  /// Updates the configuration of the discovery source
  ///
  /// [config] contains the new configuration
  Future<void> updateConfiguration(Map<String, dynamic> config);

  /// Performs health check on the discovery source
  ///
  /// Returns true if the source is healthy and functional
  Future<bool> performHealthCheck();

  /// Gets performance metrics for the discovery source
  ///
  /// Returns metrics such as discovery time, success rate, etc.
  Future<Map<String, dynamic>> getPerformanceMetrics();

  /// Clears any caches or temporary data
  ///
  /// Useful for resetting the source or freeing memory
  Future<void> clearCache();

  /// Disposes the discovery source
  ///
  /// Cleans up resources and connections
  Future<void> dispose();

  /// Gets the configuration schema for this source
  ///
  /// Returns a schema describing the required and optional configuration
  Map<String, dynamic> getConfigurationSchema();

  /// Validates the provided configuration
  ///
  /// [config] is the configuration to validate
  /// Returns true if the configuration is valid
  bool validateConfiguration(Map<String, dynamic> config);

  /// Gets the estimated discovery time for this source
  ///
  /// Returns an estimate in milliseconds
  int getEstimatedDiscoveryTime();

  /// Gets the memory usage estimate for this source
  ///
  /// Returns an estimate in MB
  double getEstimatedMemoryUsage();

  /// Gets the battery impact of using this source
  ///
  /// Returns a value from 0.0 (no impact) to 1.0 (high impact)
  double getBatteryImpact();

  /// Checks if this source supports mobile optimization
  ///
  /// Returns true if the source has mobile-specific optimizations
  bool supportsMobileOptimization();

  /// Gets mobile-specific configuration options
  ///
  /// Returns a map of mobile optimization settings
  Map<String, dynamic> getMobileOptimizations();
}

/// Base implementation for discovery sources
///
/// Provides common functionality that can be shared across different source types
abstract class BaseDiscoverySource extends IDiscoverySource {
  final String _id;
  final String _name;
  final DiscoverySourceType _type;
  final int _priority;
  DateTime? _lastAccessTime;
  int _discoveredToolCount;
  Map<String, dynamic> _config;
  bool _isInitialized = false;

  BaseDiscoverySource({
    required String id,
    required String name,
    required DiscoverySourceType type,
    int priority = 100,
  })  : _id = id,
        _name = name,
        _type = type,
        _priority = priority,
        _discoveredToolCount = 0,
        _config = {};

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  DiscoverySourceType get type => _type;

  @override
  int get priority => _priority;

  @override
  DateTime? get lastAccessTime => _lastAccessTime;

  @override
  int get discoveredToolCount => _discoveredToolCount;

  @override
  bool get isAvailable => _isInitialized;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    if (!validateConfiguration(config)) {
      throw ArgumentError('Invalid configuration for discovery source: $name');
    }

    _config = Map<String, dynamic>.from(config);
    await performInitialization(config);
    _isInitialized = true;
    _lastAccessTime = DateTime.now();
  }

  @override
  Future<List<DiscoveredTool>> discoverTools({Duration? timeout}) async {
    if (!_isInitialized) {
      throw StateError('Discovery source not initialized: $name');
    }

    final stopwatch = Stopwatch()..start();
    final discoveredTools = await performDiscovery(timeout);
    stopwatch.stop();

    _discoveredToolCount += discoveredTools.length;
    _lastAccessTime = DateTime.now();

    return discoveredTools
        .map((tool) => tool.copyWith(
              discoveryLatencyMs: stopwatch.elapsedMilliseconds,
            ))
        .toList();
  }

  @override
  Future<bool> validateToolReachability(Tool tool) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      return await performReachabilityValidation(tool);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    return {
      'id': _id,
      'name': _name,
      'type': _type.name,
      'available': _isInitialized,
      'priority': _priority,
      'last_access': _lastAccessTime?.toIso8601String(),
      'discovered_tools': _discoveredToolCount,
      'health': await performHealthCheck(),
      'performance': await getPerformanceMetrics(),
      'mobile_optimized': supportsMobileOptimization(),
      'battery_impact': getBatteryImpact(),
      'estimated_memory_mb': getEstimatedMemoryUsage(),
      'estimated_discovery_time_ms': getEstimatedDiscoveryTime(),
    };
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    if (!validateConfiguration(config)) {
      throw ArgumentError('Invalid configuration for discovery source: $name');
    }

    _config = Map<String, dynamic>.from(config);
    await applyConfigurationUpdate(config);
  }

  @override
  Future<bool> performHealthCheck() async {
    if (!_isInitialized) return false;

    try {
      return await performHealthValidation();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    return {
      'discovery_count': _discoveredToolCount,
      'last_access': _lastAccessTime?.toIso8601String(),
      'average_discovery_time_ms': getEstimatedDiscoveryTime(),
      'memory_usage_mb': getEstimatedMemoryUsage(),
      'battery_impact': getBatteryImpact(),
      'success_rate': await calculateSuccessRate(),
    };
  }

  @override
  Future<void> clearCache() async {
    _discoveredToolCount = 0;
    await performCacheClear();
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    await performDisposal();
  }

  @override
  Map<String, dynamic> getConfigurationSchema() {
    return {
      'type': 'object',
      'properties': {
        'enabled': {
          'type': 'boolean',
          'default': true,
          'description': 'Whether this discovery source is enabled',
        },
        'priority': {
          'type': 'integer',
          'default': 100,
          'description':
              'Priority of this discovery source (lower number = higher priority)',
        },
        'timeout_ms': {
          'type': 'integer',
          'default': 5000,
          'description': 'Timeout for discovery operations in milliseconds',
        },
        'max_retries': {
          'type': 'integer',
          'default': 3,
          'description': 'Maximum number of retry attempts',
        },
      },
      'required': ['enabled'],
    };
  }

  @override
  bool validateConfiguration(Map<String, dynamic> config) {
    return config.containsKey('enabled') &&
        config['enabled'] is bool &&
        (config.containsKey('priority') ? config['priority'] is int : true) &&
        (config.containsKey('timeout_ms')
            ? config['timeout_ms'] is int
            : true) &&
        (config.containsKey('max_retries')
            ? config['max_retries'] is int
            : true);
  }

  @override
  int getEstimatedDiscoveryTime() {
    return _config['timeout_ms'] as int? ?? 5000;
  }

  @override
  double getEstimatedMemoryUsage() {
    return 10.0; // Default estimate
  }

  @override
  double getBatteryImpact() {
    return 0.3; // Default moderate impact
  }

  @override
  bool supportsMobileOptimization() {
    return true; // Default to supporting mobile optimization
  }

  @override
  Map<String, dynamic> getMobileOptimizations() {
    return {
      'battery_optimization': true,
      'network_optimization': true,
      'memory_optimization': true,
      'cache_optimization': true,
    };
  }

  // Abstract methods to be implemented by concrete sources

  /// Performs source-specific initialization
  Future<void> performInitialization(Map<String, dynamic> config);

  /// Performs the actual discovery operation
  Future<List<DiscoveredTool>> performDiscovery(Duration? timeout);

  /// Performs source-specific reachability validation
  Future<bool> performReachabilityValidation(Tool tool);

  /// Performs source-specific health validation
  Future<bool> performHealthValidation();

  /// Applies source-specific configuration updates
  Future<void> applyConfigurationUpdate(Map<String, dynamic> config);

  /// Performs source-specific cache clearing
  Future<void> performCacheClear();

  /// Performs source-specific disposal
  Future<void> performDisposal();

  /// Calculates the success rate for this source
  Future<double> calculateSuccessRate();

  @override
  List<Object?> get props => [
        _id,
        _name,
        _type,
        _priority,
        _isInitialized,
        _discoveredToolCount,
        _lastAccessTime,
      ];
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../core/interfaces/i_universal_mcp_client.dart';
import '../core/models/tool.dart';
import '../core/models/tool_call.dart';
import '../core/models/tool_result.dart';
import '../core/models/tool_capability.dart';
import '../core/exceptions/mcp_exceptions.dart';
import '../../../core/utils/logger.dart';

/// Implementation of the Universal MCP Client
///
/// This is the central component for tool discovery and execution in the MCP ecosystem.
/// It provides a unified interface for interacting with multiple MCP servers and tools
/// with mobile-optimized performance and resource management.
class UniversalMCPClient implements IUniversalMCPClient {
  /// Logger for debugging and monitoring
  final AppLogger _logger;

  /// Cache for tool definitions
  final Map<String, Tool> _toolCache = {};

  /// Cache for tool capabilities
  final Map<String, ToolCapability> _capabilityCache = {};

  /// Connected MCP servers
  final Map<String, McpServerConnection> _servers = {};

  /// Performance metrics collector
  final PerformanceMetricsCollector _metricsCollector;

  /// Mobile optimization manager
  final MobileOptimizationManager _mobileOptimizer;

  /// Configuration settings
  final Map<String, dynamic> _config = {};

  /// Event subscribers
  final List<Function(Map<String, dynamic>)> _subscribers = [];

  /// Execution history
  final List<Map<String, dynamic>> _executionHistory = [];

  /// Background execution flag
  bool _backgroundExecutionEnabled = false;

  /// Mobile optimization level (0.0 to 1.0)
  double _mobileOptimizationLevel = 0.5;

  /// Initialization flag
  bool _isInitialized = false;

  /// Creates a new UniversalMCPClient instance
  UniversalMCPClient({
    AppLogger? logger,
    Map<String, dynamic>? config,
  })  : _logger = logger ?? AppLogger(),
        _metricsCollector = PerformanceMetricsCollector(),
        _mobileOptimizer = MobileOptimizationManager() {
    if (config != null) {
      _config.addAll(config);
    }
  }

  /// Initializes the client with default configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Universal MCP Client');

      // Initialize mobile optimization
      await _mobileOptimizer.initialize(_config);

      // Load configuration
      _loadConfiguration();

      // Connect to default servers if configured
      await _connectToDefaultServers();

      _isInitialized = true;
      _logger.info('Universal MCP Client initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Universal MCP Client', error: e);
      throw McpConfigurationException(
        'Failed to initialize client',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Tool>> discoverAllAvailableTools() async {
    _ensureInitialized();

    try {
      _logger.info('Discovering all available tools');
      final stopwatch = Stopwatch()..start();

      final List<Tool> allTools = [];

      // Check cache first for mobile optimization
      if (_toolCache.isNotEmpty) {
        _logger.debug('Using cached tool definitions');
        allTools.addAll(_toolCache.values);
      } else {
        // Discover from all connected servers
        for (final server in _servers.values) {
          try {
            final serverTools = await server.discoverTools();
            allTools.addAll(serverTools);

            // Cache tools for performance
            for (final tool in serverTools) {
              _toolCache[tool.id] = tool;
            }
          } catch (e) {
            _logger.warning(
                'Failed to discover tools from server ${server.name}',
                error: e);
          }
        }
      }

      // Apply mobile optimization filters
      final optimizedTools = _mobileOptimizer.filterToolsForMobile(allTools);

      stopwatch.stop();
      _metricsCollector.recordToolDiscovery(
        toolCount: optimizedTools.length,
        executionTime: stopwatch.elapsed,
        cacheHit: _toolCache.isNotEmpty,
      );

      _logger.info(
          'Discovered ${optimizedTools.length} tools in ${stopwatch.elapsedMilliseconds}ms');
      return optimizedTools;
    } catch (e) {
      _logger.error('Tool discovery failed', error: e);
      throw McpToolDiscoveryException(
        'Failed to discover tools',
        originalError: e,
      );
    }
  }

  @override
  Future<ToolResult> executeToolWithUniversalAdapter(ToolCall call) async {
    _ensureInitialized();

    try {
      _logger.info('Executing tool: ${call.toolName} (${call.id})');
      final stopwatch = Stopwatch()..start();

      // Validate tool call
      final isValid = await validateToolCall(call);
      if (!isValid) {
        throw McpToolExecutionException(
          'Invalid tool call',
          toolName: call.toolName,
          parameters: call.parameters,
        );
      }

      // Get tool from cache
      final tool = _toolCache[call.toolId];
      if (tool == null) {
        throw McpToolExecutionException(
          'Tool not found: ${call.toolId}',
          toolName: call.toolName,
        );
      }

      // Apply mobile optimizations
      final optimizedCall = await _mobileOptimizer.optimizeToolCall(call, tool);

      // Select appropriate server
      final server = _selectServerForTool(tool);
      if (server == null) {
        throw McpToolExecutionException(
          'No available server for tool: ${tool.name}',
          toolName: tool.name,
        );
      }

      // Execute with retry logic
      final result = await _executeWithRetry(server, optimizedCall);

      // Record execution
      _recordExecution(call, result, stopwatch.elapsed);

      stopwatch.stop();
      _metricsCollector.recordToolExecution(
        toolId: tool.id,
        executionTime: stopwatch.elapsed,
        success: result.isSuccess,
        memoryUsage: result.metrics.memoryUsageMB,
      );

      _logger.info(
          'Tool execution completed: ${call.toolName} in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      _logger.error('Tool execution failed: ${call.toolName}', error: e);

      // Create failure result
      return ToolResult.failure(
        id: const Uuid().v4(),
        toolCallId: call.id,
        error: ToolResultError(
          code: 'EXECUTION_FAILED',
          message: e.toString(),
          type: 'MCP_EXECUTION_ERROR',
          isRetryable: _isRetryableError(e),
        ),
        metadata: ToolResultMetadata(
          toolId: call.toolId,
          toolName: call.toolName,
          serverName: call.serverName,
          executionVersion: '1.0.0',
          executionEnvironment: 'mobile',
          securityContext: call.context.securityContext,
        ),
        metrics: ToolResultMetrics(
          totalExecutionTime: Duration.zero,
          cpuTime: Duration.zero,
          memoryUsageMB: 0.0,
          peakMemoryUsageMB: 0.0,
          networkUsageKB: 0.0,
          diskUsageKB: 0.0,
          batteryConsumptionPercent: 0.0,
        ),
      );
    }
  }

  @override
  Future<void> registerToolCapability(ToolCapability capability) async {
    _ensureInitialized();

    try {
      _logger.info('Registering tool capability: ${capability.name}');

      // Validate capability
      _validateCapability(capability);

      // Cache capability
      _capabilityCache[capability.id] = capability;

      // Notify subscribers
      _notifySubscribers({
        'type': 'capability_registered',
        'capability': capability.toJson(),
      });

      _logger
          .info('Tool capability registered successfully: ${capability.name}');
    } catch (e) {
      _logger.error('Failed to register tool capability', error: e);
      throw McpToolRegistrationException(
        'Failed to register capability: ${capability.name}',
        toolName: capability.name,
        originalError: e,
      );
    }
  }

  @override
  Future<List<ToolCapability>> analyzeToolCapabilities() async {
    _ensureInitialized();

    try {
      _logger.info('Analyzing tool capabilities');

      final capabilities = _capabilityCache.values.toList();

      // Perform analysis
      final analysis = await _performCapabilityAnalysis(capabilities);

      // Record metrics
      _metricsCollector.recordCapabilityAnalysis(
        capabilityCount: capabilities.length,
        analysisTime: Duration.zero,
      );

      _logger.info(
          'Capability analysis completed: ${capabilities.length} capabilities');
      return capabilities;
    } catch (e) {
      _logger.error('Capability analysis failed', error: e);
      throw McpToolRegistrationException(
        'Failed to analyze capabilities',
        originalError: e,
      );
    }
  }

  @override
  Future<Tool?> getToolById(String toolId) async {
    _ensureInitialized();

    // Check cache first
    if (_toolCache.containsKey(toolId)) {
      _metricsCollector.recordCacheHit('tool_by_id');
      return _toolCache[toolId];
    }

    // Try to discover from servers
    for (final server in _servers.values) {
      try {
        final tools = await server.discoverTools();
        for (final tool in tools) {
          _toolCache[tool.id] = tool;
        }

        if (_toolCache.containsKey(toolId)) {
          return _toolCache[toolId];
        }
      } catch (e) {
        _logger.warning('Failed to discover tools from server ${server.name}',
            error: e);
      }
    }

    return null;
  }

  @override
  Future<List<Tool>> getToolsByCategory(String category) async {
    _ensureInitialized();

    final allTools = await discoverAllAvailableTools();
    return allTools.where((tool) => tool.category == category).toList();
  }

  @override
  Future<List<Tool>> getToolsByCapability(String capabilityType) async {
    _ensureInitialized();

    final allTools = await discoverAllAvailableTools();
    return allTools
        .where((tool) => tool.hasCapability(capabilityType))
        .toList();
  }

  @override
  Future<List<Tool>> searchTools(String query) async {
    _ensureInitialized();

    final allTools = await discoverAllAvailableTools();
    final lowerQuery = query.toLowerCase();

    return allTools
        .where((tool) =>
            tool.name.toLowerCase().contains(lowerQuery) ||
            tool.description.toLowerCase().contains(lowerQuery) ||
            tool.category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<bool> validateToolCall(ToolCall call) async {
    _ensureInitialized();

    try {
      // Get tool definition
      final tool = _toolCache[call.toolId];
      if (tool == null) return false;

      // Validate parameters against schema
      if (!_validateParameters(call.parameters, tool.inputSchema)) {
        return false;
      }

      // Check security requirements
      if (!_checkSecurityRequirements(call, tool)) {
        return false;
      }

      // Check resource limits
      if (!_checkResourceLimits(call, tool)) {
        return false;
      }

      // Check mobile constraints
      if (!_checkMobileConstraints(call, tool)) {
        return false;
      }

      return true;
    } catch (e) {
      _logger.error('Tool call validation failed', error: e);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    _ensureInitialized();

    return {
      'client_metrics': _metricsCollector.getMetrics(),
      'mobile_optimization': _mobileOptimizer.getMetrics(),
      'cache_stats': {
        'tool_cache_size': _toolCache.length,
        'capability_cache_size': _capabilityCache.length,
        'cache_hit_rate': _metricsCollector.getCacheHitRate(),
      },
      'server_stats': {
        'connected_servers': _servers.length,
        'server_status': await getServerStatus(),
      },
      'execution_stats': {
        'total_executions': _executionHistory.length,
        'success_rate': _calculateSuccessRate(),
        'average_execution_time': _calculateAverageExecutionTime(),
      },
    };
  }

  @override
  Future<void> clearCache() async {
    _ensureInitialized();

    _logger.info('Clearing all caches');
    _toolCache.clear();
    _capabilityCache.clear();
    _metricsCollector.reset();

    _notifySubscribers({
      'type': 'cache_cleared',
    });
  }

  @override
  Future<void> setMobileOptimizationLevel(double level) async {
    _ensureInitialized();

    if (level < 0.0 || level > 1.0) {
      throw McpConfigurationException(
        'Mobile optimization level must be between 0.0 and 1.0',
        configKey: 'mobile_optimization_level',
        configValue: level,
      );
    }

    _mobileOptimizationLevel = level;
    await _mobileOptimizer.setOptimizationLevel(level);

    _config['mobile_optimization_level'] = level;
    _logger.info('Mobile optimization level set to: $level');
  }

  @override
  Future<void> setBackgroundExecutionEnabled(bool enabled) async {
    _ensureInitialized();

    _backgroundExecutionEnabled = enabled;
    _config['background_execution_enabled'] = enabled;

    _logger.info('Background execution ${enabled ? 'enabled' : 'disabled'}');
  }

  @override
  Future<Map<String, dynamic>> getServerStatus() async {
    _ensureInitialized();

    final status = <String, dynamic>{};

    for (final entry in _servers.entries) {
      final serverName = entry.key;
      final server = entry.value;

      try {
        final serverStatus = await server.getStatus();
        status[serverName] = serverStatus;
      } catch (e) {
        status[serverName] = {
          'status': 'error',
          'error': e.toString(),
          'last_check': DateTime.now().toIso8601String(),
        };
      }
    }

    return status;
  }

  @override
  Future<void> addMcpServer(String serverUrl, String serverName,
      {String? authToken}) async {
    _ensureInitialized();

    try {
      _logger.info('Adding MCP server: $serverName');

      final connection = McpServerConnection(
        url: serverUrl,
        name: serverName,
        authToken: authToken,
        logger: _logger,
      );

      await connection.connect();
      _servers[serverName] = connection;

      _notifySubscribers({
        'type': 'server_added',
        'server_name': serverName,
        'server_url': serverUrl,
      });

      _logger.info('MCP server added successfully: $serverName');
    } catch (e) {
      _logger.error('Failed to add MCP server', error: e);
      throw McpConnectionException(
        'Failed to connect to server: $serverName',
        endpoint: serverUrl,
        originalError: e,
      );
    }
  }

  @override
  Future<void> removeMcpServer(String serverName) async {
    _ensureInitialized();

    try {
      _logger.info('Removing MCP server: $serverName');

      final server = _servers.remove(serverName);
      if (server != null) {
        await server.disconnect();
      }

      _notifySubscribers({
        'type': 'server_removed',
        'server_name': serverName,
      });

      _logger.info('MCP server removed successfully: $serverName');
    } catch (e) {
      _logger.error('Failed to remove MCP server', error: e);
      throw McpConnectionException(
        'Failed to remove server: $serverName',
        serverName: serverName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateMcpServerConfig(
      String serverName, Map<String, dynamic> config) async {
    _ensureInitialized();

    try {
      final server = _servers[serverName];
      if (server == null) {
        throw McpConfigurationException(
          'Server not found: $serverName',
          configKey: 'server_name',
        );
      }

      await server.updateConfiguration(config);

      _notifySubscribers({
        'type': 'server_config_updated',
        'server_name': serverName,
        'config': config,
      });

      _logger.info('Server configuration updated: $serverName');
    } catch (e) {
      _logger.error('Failed to update server configuration', error: e);
      throw McpConfigurationException(
        'Failed to update configuration for server: $serverName',
        configKey: 'server_config',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getToolExecutionHistory(String toolId,
      {int limit = 100}) async {
    _ensureInitialized();

    return _executionHistory
        .where((record) => record['tool_id'] == toolId)
        .take(limit)
        .toList();
  }

  @override
  Future<void> subscribeToUpdates(
      Function(Map<String, dynamic> update) callback) async {
    _ensureInitialized();

    _subscribers.add(callback);
    _logger.info('Added update subscriber');
  }

  @override
  Future<void> unsubscribeFromUpdates(
      Function(Map<String, dynamic> update) callback) async {
    _ensureInitialized();

    _subscribers.remove(callback);
    _logger.info('Removed update subscriber');
  }

  @override
  Future<Map<String, dynamic>> performHealthCheck() async {
    _ensureInitialized();

    final healthStatus = <String, dynamic>{};

    // Check client health
    healthStatus['client'] = {
      'status': 'healthy',
      'initialized': _isInitialized,
      'cache_size': _toolCache.length,
      'memory_usage': await _getCurrentMemoryUsage(),
    };

    // Check server health
    healthStatus['servers'] = await getServerStatus();

    // Check mobile optimization health
    healthStatus['mobile_optimization'] = _mobileOptimizer.getHealthStatus();

    return healthStatus;
  }

  @override
  Future<List<String>> getMobileOptimizationRecommendations() async {
    _ensureInitialized();

    return await _mobileOptimizer.getRecommendations(
      toolCache: _toolCache,
      executionHistory: _executionHistory,
      metrics: _metricsCollector.getMetrics(),
    );
  }

  @override
  Future<String> exportToolRegistry(String format) async {
    _ensureInitialized();

    try {
      final data = {
        'tools': _toolCache.values.map((tool) => tool.toJson()).toList(),
        'capabilities':
            _capabilityCache.values.map((cap) => cap.toJson()).toList(),
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      switch (format.toLowerCase()) {
        case 'json':
          return jsonEncode(data);
        case 'yaml':
          // Simple YAML export (would use a YAML package in production)
          return _convertToYaml(data);
        case 'csv':
          return _convertToCsv(data);
        default:
          throw McpConfigurationException(
            'Unsupported export format: $format',
            configKey: 'export_format',
          );
      }
    } catch (e) {
      _logger.error('Failed to export tool registry', error: e);
      throw McpConfigurationException(
        'Export failed',
        originalError: e,
      );
    }
  }

  @override
  Future<void> importToolRegistry(String data, String format) async {
    _ensureInitialized();

    try {
      Map<String, dynamic> importedData;

      switch (format.toLowerCase()) {
        case 'json':
          importedData = jsonDecode(data) as Map<String, dynamic>;
        case 'yaml':
          // Simple YAML import (would use a YAML package in production)
          importedData = _parseFromYaml(data);
        default:
          throw McpConfigurationException(
            'Unsupported import format: $format',
            configKey: 'import_format',
          );
      }

      // Validate imported data
      _validateImportedData(importedData);

      // Merge with existing registry
      _mergeImportedData(importedData);

      _notifySubscribers({
        'type': 'registry_imported',
        'format': format,
        'tools_count': importedData['tools']?.length ?? 0,
      });

      _logger.info('Tool registry imported successfully');
    } catch (e) {
      _logger.error('Failed to import tool registry', error: e);
      throw McpConfigurationException(
        'Import failed',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getToolUsageAnalytics(String timeRange) async {
    _ensureInitialized();

    final now = DateTime.now();
    DateTime startDate;

    switch (timeRange.toLowerCase()) {
      case 'day':
        startDate = now.subtract(const Duration(days: 1));
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        throw McpConfigurationException(
          'Invalid time range: $timeRange',
          configKey: 'time_range',
        );
    }

    final filteredHistory = _executionHistory.where((record) {
      final timestamp = DateTime.parse(record['timestamp']);
      return timestamp.isAfter(startDate);
    }).toList();

    return {
      'time_range': timeRange,
      'start_date': startDate.toIso8601String(),
      'end_date': now.toIso8601String(),
      'total_executions': filteredHistory.length,
      'most_used_tools': _getMostUsedTools(filteredHistory),
      'success_rate': _calculateSuccessRateForHistory(filteredHistory),
      'average_execution_time':
          _calculateAverageExecutionTimeForHistory(filteredHistory),
      'tool_categories': _getToolCategoryBreakdown(filteredHistory),
    };
  }

  @override
  Future<void> setAutomaticToolUpdates(bool enabled,
      {Duration? checkInterval}) async {
    _ensureInitialized();

    _config['automatic_updates_enabled'] = enabled;
    if (checkInterval != null) {
      _config['automatic_updates_interval'] = checkInterval.inMilliseconds;
    }

    _logger.info('Automatic tool updates ${enabled ? 'enabled' : 'disabled'}');

    // Implementation would set up a timer for periodic updates
    // This is a placeholder for the actual implementation
  }

  @override
  Map<String, dynamic> getCurrentConfiguration() {
    return Map<String, dynamic>.from(_config);
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    _ensureInitialized();

    try {
      // Validate configuration
      _validateConfiguration(config);

      // Update configuration
      _config.addAll(config);

      // Apply configuration changes
      if (config.containsKey('mobile_optimization_level')) {
        await setMobileOptimizationLevel(
            config['mobile_optimization_level'] as double);
      }

      if (config.containsKey('background_execution_enabled')) {
        await setBackgroundExecutionEnabled(
            config['background_execution_enabled'] as bool);
      }

      _notifySubscribers({
        'type': 'configuration_updated',
        'config': config,
      });

      _logger.info('Configuration updated successfully');
    } catch (e) {
      _logger.error('Failed to update configuration', error: e);
      throw McpConfigurationException(
        'Configuration update failed',
        originalError: e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    _logger.info('Disposing Universal MCP Client');

    // Disconnect from all servers
    for (final server in _servers.values) {
      try {
        await server.disconnect();
      } catch (e) {
        _logger.warning('Error disconnecting from server', error: e);
      }
    }
    _servers.clear();

    // Clear caches
    _toolCache.clear();
    _capabilityCache.clear();

    // Clear subscribers
    _subscribers.clear();

    // Reset metrics
    _metricsCollector.reset();

    _isInitialized = false;
    _logger.info('Universal MCP Client disposed');
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw McpConfigurationException(
        'Client not initialized. Call initialize() first.',
      );
    }
  }

  void _loadConfiguration() {
    // Load configuration from persistent storage
    // This is a placeholder for actual implementation
    _config['mobile_optimization_level'] = _mobileOptimizationLevel;
    _config['background_execution_enabled'] = _backgroundExecutionEnabled;
  }

  Future<void> _connectToDefaultServers() async {
    // Connect to default servers if configured
    final defaultServers = _config['default_servers'] as List<dynamic>? ?? [];

    for (final serverConfig in defaultServers) {
      if (serverConfig is Map<String, dynamic>) {
        try {
          await addMcpServer(
            serverConfig['url'] as String,
            serverConfig['name'] as String,
            authToken: serverConfig['auth_token'] as String?,
          );
        } catch (e) {
          _logger.warning('Failed to connect to default server', error: e);
        }
      }
    }
  }

  McpServerConnection? _selectServerForTool(Tool tool) {
    // Select the best server for the tool based on:
    // 1. Server availability
    // 2. Performance metrics
    // 3. Mobile optimization
    // 4. Load balancing

    final availableServers =
        _servers.values.where((server) => server.hasTool(tool.id)).toList();

    if (availableServers.isEmpty) return null;

    // Sort by performance metrics
    availableServers.sort(
        (a, b) => a.getPerformanceScore().compareTo(b.getPerformanceScore()));

    return availableServers.first;
  }

  Future<ToolResult> _executeWithRetry(
      McpServerConnection server, ToolCall call) async {
    int attempts = 0;
    final maxAttempts = call.maxRetries + 1;

    while (attempts < maxAttempts) {
      try {
        return await server.executeTool(call);
      } catch (e) {
        attempts++;

        if (attempts >= maxAttempts || !_isRetryableError(e)) {
          rethrow;
        }

        _logger.warning(
            'Tool execution failed, retrying ($attempts/$maxAttempts)',
            error: e);

        // Exponential backoff for mobile optimization
        final delay = Duration(milliseconds: 100 * (1 << (attempts - 1)));
        await Future.delayed(delay);
      }
    }

    throw McpToolExecutionException(
      'All retry attempts failed',
      toolName: call.toolName,
    );
  }

  void _recordExecution(
      ToolCall call, ToolResult result, Duration executionTime) {
    final record = {
      'tool_id': call.toolId,
      'tool_name': call.toolName,
      'call_id': call.id,
      'success': result.isSuccess,
      'execution_time_ms': executionTime.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      'memory_usage_mb': result.metrics.memoryUsageMB,
      'error_code': result.error?.code,
    };

    _executionHistory.add(record);

    // Limit history size for memory optimization
    if (_executionHistory.length > 1000) {
      _executionHistory.removeRange(0, _executionHistory.length - 1000);
    }
  }

  bool _validateParameters(
      Map<String, dynamic> parameters, Map<String, dynamic> schema) {
    // Validate parameters against the tool's input schema
    // This is a simplified implementation
    try {
      for (final entry in schema.entries) {
        final paramName = entry.key;
        final paramSchema = entry.value as Map<String, dynamic>;

        if (paramSchema['required'] == true &&
            !parameters.containsKey(paramName)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _checkSecurityRequirements(ToolCall call, Tool tool) {
    // Check if the call meets security requirements
    // This is a simplified implementation
    return true;
  }

  bool _checkResourceLimits(ToolCall call, Tool tool) {
    // Check if the call exceeds resource limits
    // This is a simplified implementation
    return true;
  }

  bool _checkMobileConstraints(ToolCall call, Tool tool) {
    // Check mobile-specific constraints
    // This is a simplified implementation
    return true;
  }

  Future<Map<String, dynamic>> _performCapabilityAnalysis(
      List<ToolCapability> capabilities) async {
    // Perform detailed analysis of capabilities
    return {
      'total_capabilities': capabilities.length,
      'capability_types': capabilities.map((cap) => cap.type).toSet().toList(),
      'primary_capabilities': capabilities.where((cap) => cap.isPrimary).length,
      'performance_scores': capabilities
          .map((cap) => cap.performance.mobileOptimizationScore)
          .toList(),
      'security_requirements': capabilities
          .expand((cap) => cap.securityRequirements)
          .toSet()
          .toList(),
    };
  }

  void _validateCapability(ToolCapability capability) {
    // Validate capability definition
    if (capability.id.isEmpty) {
      throw McpToolRegistrationException(
        'Capability ID cannot be empty',
        capability: capability.type,
      );
    }

    if (capability.name.isEmpty) {
      throw McpToolRegistrationException(
        'Capability name cannot be empty',
        capability: capability.type,
      );
    }
  }

  void _notifySubscribers(Map<String, dynamic> update) {
    for (final subscriber in _subscribers) {
      try {
        subscriber(update);
      } catch (e) {
        _logger.warning('Error notifying subscriber', error: e);
      }
    }
  }

  bool _isRetryableError(dynamic error) {
    // Determine if an error is retryable
    if (error is McpException) {
      return error.mcpErrorCode != null;
    }
    return false;
  }

  double _calculateSuccessRate() {
    if (_executionHistory.isEmpty) return 0.0;

    final successful =
        _executionHistory.where((record) => record['success'] as bool).length;
    return successful / _executionHistory.length;
  }

  Duration _calculateAverageExecutionTime() {
    if (_executionHistory.isEmpty) return Duration.zero;

    final totalMs = _executionHistory
        .map((record) => record['execution_time_ms'] as int)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMs ~/ _executionHistory.length);
  }

  Future<double> _getCurrentMemoryUsage() async {
    // Get current memory usage in MB
    // This is a platform-specific implementation
    return 0.0; // Placeholder
  }

  List<Map<String, dynamic>> _getMostUsedTools(
      List<Map<String, dynamic>> history) {
    final toolCounts = <String, int>{};

    for (final record in history) {
      final toolName = record['tool_name'] as String;
      toolCounts[toolName] = (toolCounts[toolName] ?? 0) + 1;
    }

    return toolCounts.entries
        .map((entry) => {
              'tool_name': entry.key,
              'usage_count': entry.value,
            })
        .toList()
      ..sort((a, b) =>
          (b['usage_count'] as int).compareTo(a['usage_count'] as int));
  }

  double _calculateSuccessRateForHistory(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.0;

    final successful =
        history.where((record) => record['success'] as bool).length;
    return successful / history.length;
  }

  Duration _calculateAverageExecutionTimeForHistory(
      List<Map<String, dynamic>> history) {
    if (history.isEmpty) return Duration.zero;

    final totalMs = history
        .map((record) => record['execution_time_ms'] as int)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMs ~/ history.length);
  }

  Map<String, int> _getToolCategoryBreakdown(
      List<Map<String, dynamic>> history) {
    final categoryCounts = <String, int>{};

    for (final record in history) {
      // This would need tool information to get category
      // Simplified implementation
      final category = 'unknown';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return categoryCounts;
  }

  void _validateImportedData(Map<String, dynamic> data) {
    if (!data.containsKey('tools') || !(data['tools'] is List)) {
      throw McpConfigurationException(
        'Invalid import data: missing or invalid tools list',
      );
    }
  }

  void _mergeImportedData(Map<String, dynamic> data) {
    final tools = data['tools'] as List<dynamic>;

    for (final toolData in tools) {
      if (toolData is Map<String, dynamic>) {
        try {
          final tool = Tool.fromJson(toolData as Map<String, dynamic>);
          _toolCache[tool.id] = tool;
        } catch (e) {
          _logger.warning('Failed to import tool', error: e);
        }
      }
    }
  }

  void _validateConfiguration(Map<String, dynamic> config) {
    // Validate configuration parameters
    if (config.containsKey('mobile_optimization_level')) {
      final level = config['mobile_optimization_level'];
      if (level is! double || level < 0.0 || level > 1.0) {
        throw McpConfigurationException(
          'Invalid mobile optimization level',
          configKey: 'mobile_optimization_level',
        );
      }
    }
  }

  String _convertToYaml(Map<String, dynamic> data) {
    // Simple YAML conversion (would use a YAML package in production)
    final buffer = StringBuffer();
    buffer.writeln('tools:');
    buffer.writeln('  # Tools would be listed here in YAML format');
    buffer.writeln('capabilities:');
    buffer.writeln('  # Capabilities would be listed here in YAML format');
    buffer.writeln('exported_at: ${data['exported_at']}');
    buffer.writeln('version: ${data['version']}');
    return buffer.toString();
  }

  String _convertToCsv(Map<String, dynamic> data) {
    // Simple CSV conversion for tools
    final buffer = StringBuffer();
    buffer.writeln('id,name,description,version,category,server_name');

    final tools = data['tools'] as List<dynamic>?;
    if (tools != null) {
      for (final toolData in tools) {
        if (toolData is Map<String, dynamic>) {
          buffer.writeln(
              '${toolData['id']},${toolData['name']},${toolData['description']},${toolData['version']},${toolData['category']},${toolData['serverName']}');
        }
      }
    }

    return buffer.toString();
  }

  Map<String, dynamic> _parseFromYaml(String yamlData) {
    // Simple YAML parsing (would use a YAML package in production)
    return <String, dynamic>{
      'tools': <Map<String, dynamic>>[],
      'capabilities': <Map<String, dynamic>>[],
    };
  }
}

/// Represents a connection to an MCP server
class McpServerConnection {
  final String url;
  final String name;
  final String? authToken;
  final AppLogger logger;

  bool _isConnected = false;
  DateTime _lastPing = DateTime.now();
  Duration _responseTime = Duration.zero;

  McpServerConnection({
    required this.url,
    required this.name,
    this.authToken,
    required this.logger,
  });

  Future<void> connect() async {
    // Connect to the MCP server
    // This is a placeholder for actual implementation
    _isConnected = true;
    _lastPing = DateTime.now();
    logger.info('Connected to MCP server: $name');
  }

  Future<void> disconnect() async {
    // Disconnect from the MCP server
    _isConnected = false;
    logger.info('Disconnected from MCP server: $name');
  }

  Future<List<Tool>> discoverTools() async {
    // Discover tools from the server
    // This is a placeholder for actual implementation
    return [];
  }

  Future<ToolResult> executeTool(ToolCall call) async {
    // Execute a tool on the server
    // This is a placeholder for actual implementation
    throw UnimplementedError('Tool execution not implemented');
  }

  bool hasTool(String toolId) {
    // Check if the server has a specific tool
    // This is a placeholder for actual implementation
    return false;
  }

  Future<Map<String, dynamic>> getStatus() async {
    // Get server status
    return {
      'name': name,
      'url': url,
      'connected': _isConnected,
      'last_ping': _lastPing.toIso8601String(),
      'response_time_ms': _responseTime.inMilliseconds,
    };
  }

  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // Update server configuration
    // This is a placeholder for actual implementation
  }

  double getPerformanceScore() {
    // Calculate performance score for server selection
    // This is a simplified implementation
    return _isConnected ? 1.0 : 0.0;
  }
}

/// Collects performance metrics for the MCP client
class PerformanceMetricsCollector {
  final List<Map<String, dynamic>> _metrics = [];

  void recordToolDiscovery({
    required int toolCount,
    required Duration executionTime,
    required bool cacheHit,
  }) {
    _metrics.add({
      'type': 'tool_discovery',
      'tool_count': toolCount,
      'execution_time_ms': executionTime.inMilliseconds,
      'cache_hit': cacheHit,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void recordToolExecution({
    required String toolId,
    required Duration executionTime,
    required bool success,
    required double memoryUsage,
  }) {
    _metrics.add({
      'type': 'tool_execution',
      'tool_id': toolId,
      'execution_time_ms': executionTime.inMilliseconds,
      'success': success,
      'memory_usage_mb': memoryUsage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void recordCapabilityAnalysis({
    required int capabilityCount,
    required Duration analysisTime,
  }) {
    _metrics.add({
      'type': 'capability_analysis',
      'capability_count': capabilityCount,
      'analysis_time_ms': analysisTime.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void recordCacheHit(String cacheType) {
    _metrics.add({
      'type': 'cache_hit',
      'cache_type': cacheType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> getMetrics() {
    return {
      'total_metrics': _metrics.length,
      'recent_metrics': _metrics.take(100).toList(),
    };
  }

  double getCacheHitRate() {
    final cacheHits = _metrics.where((m) => m['type'] == 'cache_hit').length;
    final totalRequests = _metrics
        .where((m) =>
            m['type'] == 'tool_discovery' || m['type'] == 'tool_execution')
        .length;

    return totalRequests > 0 ? cacheHits / totalRequests : 0.0;
  }

  void reset() {
    _metrics.clear();
  }
}

/// Manages mobile optimization for the MCP client
class MobileOptimizationManager {
  double _optimizationLevel = 0.5;
  final Map<String, dynamic> _metrics = {};

  Future<void> initialize(Map<String, dynamic> config) async {
    _optimizationLevel =
        (config['mobile_optimization_level'] as double?) ?? 0.5;
  }

  Future<void> setOptimizationLevel(double level) async {
    _optimizationLevel = level;
  }

  List<Tool> filterToolsForMobile(List<Tool> tools) {
    // Filter tools based on mobile optimization requirements
    return tools.where((tool) => tool.isMobileOptimized).toList();
  }

  Future<ToolCall> optimizeToolCall(ToolCall call, Tool tool) async {
    // Optimize tool call for mobile execution
    // This is a placeholder for actual implementation
    return call;
  }

  Map<String, dynamic> getMetrics() {
    return {
      'optimization_level': _optimizationLevel,
      'metrics': _metrics,
    };
  }

  Map<String, dynamic> getHealthStatus() {
    return {
      'status': 'healthy',
      'optimization_level': _optimizationLevel,
    };
  }

  Future<List<String>> getRecommendations({
    required Map<String, Tool> toolCache,
    required List<Map<String, dynamic>> executionHistory,
    required Map<String, dynamic> metrics,
  }) async {
    final recommendations = <String>[];

    // Analyze and generate recommendations
    if (_optimizationLevel > 0.7) {
      recommendations
          .add('Consider reducing concurrent tool executions to save battery');
    }

    if (toolCache.length > 100) {
      recommendations
          .add('Consider caching less frequently used tools to save memory');
    }

    return recommendations;
  }
}

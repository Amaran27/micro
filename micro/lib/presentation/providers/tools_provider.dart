import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../infrastructure/mcp/client/universal_mcp_client.dart';
import '../../infrastructure/mcp/core/models/tool.dart';
import '../../infrastructure/mcp/core/models/tool_call.dart' as tool_call;
import '../../infrastructure/mcp/core/models/tool_result.dart';
import '../../core/utils/logger.dart';
import '../providers/autonomous_provider.dart';

/// Tools state management class
class ToolsState {
  final List<Tool> tools;
  final List<Tool> filteredTools;
  final Map<String, Tool> toolCache;
  final Map<String, ToolExecutionStatus> executionStatus;
  final Map<String, ToolResult> executionResults;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Map<String, dynamic> performanceMetrics;
  final List<Map<String, dynamic>> executionHistory;

  const ToolsState({
    this.tools = const [],
    this.filteredTools = const [],
    this.toolCache = const {},
    this.executionStatus = const {},
    this.executionResults = const {},
    this.categories = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.performanceMetrics = const {},
    this.executionHistory = const [],
  });

  ToolsState copyWith({
    List<Tool>? tools,
    List<Tool>? filteredTools,
    Map<String, Tool>? toolCache,
    Map<String, ToolExecutionStatus>? executionStatus,
    Map<String, ToolResult>? executionResults,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    Map<String, dynamic>? performanceMetrics,
    List<Map<String, dynamic>>? executionHistory,
  }) {
    return ToolsState(
      tools: tools ?? this.tools,
      filteredTools: filteredTools ?? this.filteredTools,
      toolCache: toolCache ?? this.toolCache,
      executionStatus: executionStatus ?? this.executionStatus,
      executionResults: executionResults ?? this.executionResults,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      executionHistory: executionHistory ?? this.executionHistory,
    );
  }
}

/// Tool execution status enum
enum ToolExecutionStatus {
  idle,
  preparing,
  executing,
  completed,
  failed,
  cancelled,
}

class ToolsProvider extends Notifier<ToolsState> {
  UniversalMCPClient get _mcpClient => ref.watch(universalMcpClientProvider);
  AppLogger get _logger => ref.watch(loggerProvider);
  AutonomousProvider get _autonomousProvider =>
      ref.watch(autonomousProviderProvider);

  @override
  ToolsState build() {
    // Initialize in build method
    Future.microtask(() => initialize());
    return const ToolsState();
  }

  /// Initialize tools provider
  Future<void> initialize() async {
    _logger.info('Initializing Tools Provider');

    try {
      state = state.copyWith(isLoading: true);

      // Initialize MCP client if not already initialized
      await _mcpClient.initialize();

      // Subscribe to MCP updates
      await _subscribeToMcpUpdates();

      // Discover available tools
      await discoverTools();

      // Get performance metrics
      await _updatePerformanceMetrics();

      state = state.copyWith(isLoading: false);
      _logger.info('Tools Provider initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Tools Provider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize tools: ${e.toString()}',
      );
    }
  }

  /// Discover all available tools
  Future<void> discoverTools() async {
    _logger.info('Discovering tools');

    try {
      state = state.copyWith(isRefreshing: true);

      final tools = await _mcpClient.discoverAllAvailableTools();

      // Extract categories
      final categories = <String>{'All'};
      for (final tool in tools) {
        categories.add(tool.category);
      }

      // Update tool cache
      final toolCache = <String, Tool>{};
      for (final tool in tools) {
        toolCache[tool.id] = tool;
      }

      state = state.copyWith(
        tools: tools,
        filteredTools: tools,
        toolCache: toolCache,
        categories: categories.toList()..sort(),
        isRefreshing: false,
        error: null,
      );

      _logger.info('Discovered ${tools.length} tools');
    } catch (e) {
      _logger.error('Tool discovery failed', error: e);
      state = state.copyWith(
        isRefreshing: false,
        error: 'Failed to discover tools: ${e.toString()}',
      );
    }
  }

  /// Refresh tools
  Future<void> refreshTools() async {
    await _mcpClient.clearCache();
    await discoverTools();
  }

  /// Execute a tool
  Future<void> executeTool({
    required String toolId,
    required Map<String, dynamic> parameters,
    String? capabilityId,
    Duration? timeout,
  }) async {
    _logger.info('Executing tool: $toolId');

    try {
      final tool = getToolById(toolId);
      if (tool == null) {
        throw Exception('Tool not found: $toolId');
      }

      // Update execution status
      state = state.copyWith(
        executionStatus: {
          ...state.executionStatus,
          toolId: ToolExecutionStatus.preparing,
        },
      );

      // Create execution context
      final context = _createExecutionContext(tool);

      // Create tool call
      final toolCall = tool_call.ToolCall(
        id: _generateToolCallId(),
        toolId: toolId,
        toolName: tool.name,
        serverName: tool.serverName,
        capabilityId: capabilityId,
        parameters: parameters,
        context: context,
        timeout: timeout ?? tool.executionMetadata.timeout,
        createdAt: DateTime.now(),
      );

      // Update execution status to executing
      state = state.copyWith(
        executionStatus: {
          ...state.executionStatus,
          toolId: ToolExecutionStatus.executing,
        },
      );

      // Execute tool
      final result = await _mcpClient.executeToolWithUniversalAdapter(toolCall);

      // Update execution status and results
      final newStatus = result.isSuccess
          ? ToolExecutionStatus.completed
          : ToolExecutionStatus.failed;

      state = state.copyWith(
        executionStatus: {
          ...state.executionStatus,
          toolId: newStatus,
        },
        executionResults: {
          ...state.executionResults,
          toolId: result,
        },
      );

      // Add to execution history
      final historyEntry = {
        'tool_id': toolId,
        'tool_name': tool.name,
        'success': result.isSuccess,
        'timestamp': DateTime.now().toIso8601String(),
        'execution_time_ms': result.metrics.totalExecutionTime.inMilliseconds,
        'parameters': parameters,
      };

      final updatedHistory = [historyEntry, ...state.executionHistory];
      if (updatedHistory.length > 100) {
        updatedHistory.removeRange(100, updatedHistory.length);
      }

      state = state.copyWith(executionHistory: updatedHistory);

      _logger.info(
          'Tool execution completed: $toolId, success: ${result.isSuccess}');
    } catch (e) {
      _logger.error('Tool execution failed: $toolId', error: e);

      state = state.copyWith(
        executionStatus: {
          ...state.executionStatus,
          toolId: ToolExecutionStatus.failed,
        },
        error: 'Tool execution failed: ${e.toString()}',
      );
    }
  }

  /// Search tools by query
  void searchTools(String query) {
    _logger.info('Searching tools with query: $query');

    final searchQuery = query.toLowerCase().trim();

    if (searchQuery.isEmpty) {
      state = state.copyWith(
        searchQuery: searchQuery,
        filteredTools: _filterByCategory(state.tools, state.selectedCategory),
      );
      return;
    }

    final filteredTools = state.tools.where((tool) {
      return tool.name.toLowerCase().contains(searchQuery) ||
          tool.description.toLowerCase().contains(searchQuery) ||
          tool.category.toLowerCase().contains(searchQuery);
    }).toList();

    state = state.copyWith(
      searchQuery: searchQuery,
      filteredTools: _filterByCategory(filteredTools, state.selectedCategory),
    );
  }

  /// Filter tools by category
  void filterByCategory(String category) {
    _logger.info('Filtering tools by category: $category');

    state = state.copyWith(
      selectedCategory: category,
      filteredTools: _filterByCategory(state.tools, category),
    );
  }

  /// Get tool by ID
  Tool? getToolById(String toolId) {
    return state.toolCache[toolId];
  }

  /// Cancel tool execution
  Future<void> cancelToolExecution(String toolId) async {
    _logger.info('Cancelling tool execution: $toolId');

    state = state.copyWith(
      executionStatus: {
        ...state.executionStatus,
        toolId: ToolExecutionStatus.cancelled,
      },
    );
  }

  /// Get tool execution history
  Future<List<Map<String, dynamic>>> getToolExecutionHistory(
      String toolId) async {
    try {
      return await _mcpClient.getToolExecutionHistory(toolId);
    } catch (e) {
      _logger.error('Failed to get tool execution history', error: e);
      return [];
    }
  }

  /// Get tool usage analytics
  Future<Map<String, dynamic>> getToolUsageAnalytics(String timeRange) async {
    try {
      return await _mcpClient.getToolUsageAnalytics(timeRange);
    } catch (e) {
      _logger.error('Failed to get tool usage analytics', error: e);
      return {};
    }
  }

  /// Get suggested tools based on autonomous context
  List<Tool> getSuggestedTools() {
    try {
      final context = _autonomousProvider.currentContext;
      if (context == null) return [];

      // Get tools that match current context
      final suggestedTools = <Tool>[];

      for (final tool in state.tools) {
        if (_toolMatchesContext(tool, context)) {
          suggestedTools.add(tool);
        }
      }

      // Sort by relevance and limit to top 5
      suggestedTools.sort((a, b) => _compareToolRelevance(a, b, context));
      return suggestedTools.take(5).toList();
    } catch (e) {
      _logger.error('Failed to get suggested tools', error: e);
      return [];
    }
  }

  /// Update performance metrics
  Future<void> _updatePerformanceMetrics() async {
    try {
      final metrics = await _mcpClient.getPerformanceMetrics();
      state = state.copyWith(performanceMetrics: metrics);
    } catch (e) {
      _logger.error('Failed to update performance metrics', error: e);
    }
  }

  /// Subscribe to MCP updates
  Future<void> _subscribeToMcpUpdates() async {
    await _mcpClient.subscribeToUpdates((update) {
      _handleMcpUpdate(update);
    });
  }

  /// Handle MCP updates
  void _handleMcpUpdate(Map<String, dynamic> update) {
    final type = update['type'] as String?;

    switch (type) {
      case 'tool_discovered':
        _handleToolDiscovered(update);
        break;
      case 'tool_updated':
        _handleToolUpdated(update);
        break;
      case 'tool_removed':
        _handleToolRemoved(update);
        break;
      case 'execution_completed':
        _handleExecutionCompleted(update);
        break;
      default:
        _logger.debug('Unknown MCP update type: $type');
    }
  }

  /// Handle tool discovered update
  void _handleToolDiscovered(Map<String, dynamic> update) {
    // Refresh tools when new tools are discovered
    discoverTools();
  }

  /// Handle tool updated update
  void _handleToolUpdated(Map<String, dynamic> update) {
    // Update specific tool in cache
    final toolData = update['tool'] as Map<String, dynamic>?;
    if (toolData != null) {
      try {
        final tool = Tool.fromJson(toolData);
        final updatedCache = {...state.toolCache};
        updatedCache[tool.id] = tool;

        final updatedTools =
            state.tools.map((t) => t.id == tool.id ? tool : t).toList();

        state = state.copyWith(
          toolCache: updatedCache,
          tools: updatedTools,
          filteredTools: _filterByCategoryAndSearch(updatedTools),
        );
      } catch (e) {
        _logger.error('Failed to parse updated tool', error: e);
      }
    }
  }

  /// Handle tool removed update
  void _handleToolRemoved(Map<String, dynamic> update) {
    final toolId = update['tool_id'] as String?;
    if (toolId != null) {
      final updatedCache = {...state.toolCache}..remove(toolId);
      final updatedTools = state.tools.where((t) => t.id != toolId).toList();

      state = state.copyWith(
        toolCache: updatedCache,
        tools: updatedTools,
        filteredTools: _filterByCategoryAndSearch(updatedTools),
      );
    }
  }

  /// Handle execution completed update
  void _handleExecutionCompleted(Map<String, dynamic> update) {
    final toolId = update['tool_id'] as String?;
    if (toolId != null) {
      state = state.copyWith(
        executionStatus: {
          ...state.executionStatus,
          toolId: ToolExecutionStatus.completed,
        },
      );
    }
  }

  /// Filter tools by category
  List<Tool> _filterByCategory(List<Tool> tools, String category) {
    if (category == 'All') return tools;
    return tools.where((tool) => tool.category == category).toList();
  }

  /// Filter tools by category and search
  List<Tool> _filterByCategoryAndSearch(List<Tool> tools) {
    var filtered = _filterByCategory(tools, state.selectedCategory);

    if (state.searchQuery.isNotEmpty) {
      final searchQuery = state.searchQuery.toLowerCase();
      filtered = filtered.where((tool) {
        return tool.name.toLowerCase().contains(searchQuery) ||
            tool.description.toLowerCase().contains(searchQuery) ||
            tool.category.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  /// Create execution context for tool call
  tool_call.ExecutionContext _createExecutionContext(Tool tool) {
    return tool_call.ExecutionContext(
      userId: 'current_user', // Would get from auth provider
      sessionId: 'current_session', // Would get from session provider
      requestId: _generateRequestId(),
      deviceInfo: tool_call.DeviceInfo(
        deviceType: 'mobile',
        operatingSystem: 'Android', // Would get from device info
        osVersion: '1.0',
        availableMemoryMB: 1000,
        batteryLevel: 0.8,
        isOnBattery: true,
        networkType: 'wifi',
      ),
      networkContext: tool_call.NetworkContext(
        connectionType: 'wifi',
        networkQuality: 'good',
        availableBandwidthKBps: 1000,
        latencyMs: 50,
        isMetered: false,
      ),
      securityContext: {
        'user_permissions': [], // Would get from permissions provider
        'security_level': tool.securityRequirements.securityLevel,
      },
      performanceConstraints: tool_call.PerformanceConstraints(
        maxExecutionTime: tool.executionMetadata.timeout,
        maxMemoryUsageMB: tool.performanceMetrics.memoryUsageMB * 2,
        maxCpuUsagePercent: 80,
        optimizeForBattery: true,
      ),
      mobileContext: tool_call.MobileContext(
        optimizeForMobile: true,
        allowOffline: tool.mobileOptimizations.supportsOffline,
        allowBackgroundExecution:
            tool.mobileOptimizations.supportsBackgroundExecution,
        batteryOptimizationLevel: tool.mobileOptimizations.batteryOptimization,
        memoryOptimizationLevel: 'high',
      ),
    );
  }

  /// Check if tool matches context
  bool _toolMatchesContext(Tool tool, dynamic context) {
    // Simple implementation - would be more sophisticated in real app
    return tool.isMobileOptimized;
  }

  /// Compare tool relevance for sorting
  int _compareToolRelevance(Tool a, Tool b, dynamic context) {
    // Simple implementation - would be more sophisticated in real app
    return a.name.compareTo(b.name);
  }

  /// Generate tool call ID
  String _generateToolCallId() {
    return 'tool_call_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate request ID
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Dispose resources
  void dispose() {
    // No resources to dispose
  }
}

/// Provider for tools state
final toolsProviderProvider = NotifierProvider<ToolsProvider, ToolsState>(() {
  return ToolsProvider();
});

/// Provider for tools state
final toolsStateProvider = Provider<ToolsState>((ref) {
  return ref.watch(toolsProviderProvider);
});

/// Provider for filtered tools
final filteredToolsProvider = Provider<List<Tool>>((ref) {
  return ref.watch(toolsProviderProvider).filteredTools;
});

/// Provider for tool categories
final toolCategoriesProvider = Provider<List<String>>((ref) {
  return ref.watch(toolsProviderProvider).categories;
});

/// Provider for suggested tools
final suggestedToolsProvider = Provider<List<Tool>>((ref) {
  return ref.watch(toolsProviderProvider.notifier).getSuggestedTools();
});

/// Provider for tool execution status
final toolExecutionStatusProvider =
    Provider<Map<String, ToolExecutionStatus>>((ref) {
  return ref.watch(toolsProviderProvider).executionStatus;
});

/// Provider for tool execution results
final toolExecutionResultsProvider = Provider<Map<String, ToolResult>>((ref) {
  return ref.watch(toolsProviderProvider).executionResults;
});

/// Provider for execution parameters
final executionParametersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(toolsProviderProvider).executionHistory;
});

/// Provider for performance metrics
final performanceMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(toolsProviderProvider).performanceMetrics;
});

/// Provider for tool execution history
final toolExecutionHistoryProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(toolsProviderProvider).executionHistory;
});

/// Provider for tools performance metrics
final toolsPerformanceMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(toolsProviderProvider).performanceMetrics;
});

// Placeholder providers that would be implemented elsewhere
final universalMcpClientProvider = Provider<UniversalMCPClient>((ref) {
  throw UnimplementedError('Universal MCP Client provider must be implemented');
});

final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

final autonomousProviderProvider = Provider<AutonomousProvider>((ref) {
  throw UnimplementedError('Autonomous Provider must be implemented');
});

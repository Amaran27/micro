import '../models/tool.dart';
import '../models/tool_call.dart';
import '../models/tool_result.dart';
import '../models/tool_capability.dart';

/// Interface for the Universal MCP Client
///
/// This is the central component for tool discovery and execution in the MCP ecosystem.
/// It provides a unified interface for interacting with multiple MCP servers and tools.
abstract class IUniversalMCPClient {
  /// Discovers all available tools from all connected MCP servers
  ///
  /// Returns a list of all tools that can be executed through this client.
  /// The discovery process includes:
  /// - Connecting to all registered MCP servers
  /// - Retrieving tool definitions
  /// - Validating tool capabilities
  /// - Caching tool metadata for performance
  ///
  /// Throws [McpToolDiscoveryException] if discovery fails
  ///
  /// Mobile optimization considerations:
  /// - Implements caching to reduce network calls
  /// - Limits concurrent connections to save battery
  /// - Uses efficient data structures for memory optimization
  Future<List<Tool>> discoverAllAvailableTools();

  /// Executes a tool call using the universal adapter
  ///
  /// The universal adapter handles:
  /// - Parameter validation and transformation
  /// - Server selection and routing
  /// - Error handling and retry logic
  /// - Performance monitoring
  /// - Mobile optimization (battery, memory, network)
  ///
  /// [call] The tool call to execute
  ///
  /// Returns the result of the tool execution
  ///
  /// Throws [McpToolExecutionException] if execution fails
  /// Throws [McpAdapterException] if adapter fails
  /// Throws [McpResourceLimitException] if resource limits are exceeded
  Future<ToolResult> executeToolWithUniversalAdapter(ToolCall call);

  /// Registers a new tool capability with the client
  ///
  /// This enables the client to:
  /// - Track custom tool capabilities
  /// - Optimize execution based on capability metadata
  /// - Provide capability-based tool discovery
  /// - Handle capability-specific security requirements
  ///
  /// [capability] The capability to register
  ///
  /// Throws [McpToolRegistrationException] if registration fails
  Future<void> registerToolCapability(ToolCapability capability);

  /// Analyzes all registered tool capabilities
  ///
  /// Returns a comprehensive analysis of:
  /// - Available capability types
  /// - Capability usage patterns
  /// - Performance characteristics
  /// - Security requirements
  /// - Mobile optimization opportunities
  ///
  /// The analysis is used for:
  /// - Performance optimization
  /// - Resource allocation
  /// - Security policy enforcement
  /// - Mobile battery optimization
  Future<List<ToolCapability>> analyzeToolCapabilities();

  /// Gets a specific tool by ID
  ///
  /// [toolId] The unique identifier of the tool
  ///
  /// Returns the tool if found, null otherwise
  /// Uses cached data when available for performance
  Future<Tool?> getToolById(String toolId);

  /// Gets tools by category
  ///
  /// [category] The category to filter by
  ///
  /// Returns a list of tools in the specified category
  /// Uses cached data when available for performance
  Future<List<Tool>> getToolsByCategory(String category);

  /// Gets tools by capability type
  ///
  /// [capabilityType] The capability type to filter by
  ///
  /// Returns a list of tools that provide the specified capability
  /// Uses cached data when available for performance
  Future<List<Tool>> getToolsByCapability(String capabilityType);

  /// Searches for tools by name or description
  ///
  /// [query] The search query
  ///
  /// Returns a list of tools matching the query
  /// Implements efficient search algorithms for mobile performance
  Future<List<Tool>> searchTools(String query);

  /// Validates a tool call before execution
  ///
  /// [call] The tool call to validate
  ///
  /// Returns true if the call is valid, false otherwise
  /// Validation includes:
  /// - Parameter validation against tool schema
  /// - Security permission checks
  /// - Resource limit verification
  /// - Mobile constraint validation
  Future<bool> validateToolCall(ToolCall call);

  /// Gets the current performance metrics for the client
  ///
  /// Returns metrics including:
  /// - Execution times
  /// - Memory usage
  /// - Network usage
  /// - Battery consumption
  /// - Cache hit rates
  Future<Map<String, dynamic>> getPerformanceMetrics();

  /// Clears all cached tool data
  ///
  /// This is useful for:
  /// - Forcing refresh of tool definitions
  /// - Freeing memory on resource-constrained devices
  /// - Resolving cache inconsistency issues
  Future<void> clearCache();

  /// Sets performance optimization level for mobile devices
  ///
  /// [level] The optimization level (0.0 to 1.0)
  ///
  /// Higher values prioritize battery life over performance
  /// Lower values prioritize performance over battery life
  Future<void> setMobileOptimizationLevel(double level);

  /// Enables or disables background execution
  ///
  /// [enabled] Whether background execution is enabled
  ///
  /// When enabled, tools can execute in the background
  /// When disabled, all execution is foreground-only
  Future<void> setBackgroundExecutionEnabled(bool enabled);

  /// Gets the current status of all connected MCP servers
  ///
  /// Returns a map of server names to their status
  /// Status includes:
  /// - Connection state
  /// - Last ping time
  /// - Response times
  /// - Error rates
  Future<Map<String, dynamic>> getServerStatus();

  /// Adds a new MCP server to the client
  ///
  /// [serverUrl] The URL of the MCP server
  /// [serverName] A human-readable name for the server
  /// [authToken] Optional authentication token
  ///
  /// Throws [McpConnectionException] if connection fails
  /// Throws [McpAuthenticationException] if authentication fails
  Future<void> addMcpServer(String serverUrl, String serverName,
      {String? authToken});

  /// Removes an MCP server from the client
  ///
  /// [serverName] The name of the server to remove
  ///
  /// Cleans up all resources associated with the server
  Future<void> removeMcpServer(String serverName);

  /// Updates the configuration of an MCP server
  ///
  /// [serverName] The name of the server to update
  /// [config] The new configuration
  ///
  /// Throws [McpConfigurationException] if configuration is invalid
  Future<void> updateMcpServerConfig(
      String serverName, Map<String, dynamic> config);

  /// Gets the execution history for a specific tool
  ///
  /// [toolId] The ID of the tool
  /// [limit] Maximum number of records to return
  ///
  /// Returns a list of past executions with their results
  /// Used for analytics and debugging
  Future<List<Map<String, dynamic>>> getToolExecutionHistory(String toolId,
      {int limit = 100});

  /// Subscribes to real-time updates from MCP servers
  ///
  /// [callback] Function to call when updates are received
  ///
  /// Updates include:
  /// - New tool availability
  /// - Tool capability changes
  /// - Server status changes
  /// - Performance alerts
  Future<void> subscribeToUpdates(
      Function(Map<String, dynamic> update) callback);

  /// Unsubscribes from real-time updates
  ///
  /// [callback] The callback function to remove
  Future<void> unsubscribeFromUpdates(
      Function(Map<String, dynamic> update) callback);

  /// Performs health check on all connected MCP servers
  ///
  /// Returns a map of server names to their health status
  /// Health checks include:
  /// - Connectivity
  /// - Response time
  /// - Resource availability
  /// - Security compliance
  Future<Map<String, dynamic>> performHealthCheck();

  /// Gets recommendations for mobile optimization
  ///
  /// Returns a list of recommendations to improve:
  /// - Battery life
  /// - Memory usage
  /// - Network efficiency
  /// - Execution performance
  Future<List<String>> getMobileOptimizationRecommendations();

  /// Exports the current tool registry
  ///
  /// [format] The export format ('json', 'yaml', 'csv')
  ///
  /// Returns the exported data as a string
  /// Useful for backup and analysis
  Future<String> exportToolRegistry(String format);

  /// Imports tool registry data
  ///
  /// [data] The data to import
  /// [format] The format of the data ('json', 'yaml', 'csv')
  ///
  /// Merges imported data with existing registry
  /// Throws [McpConfigurationException] if data is invalid
  Future<void> importToolRegistry(String data, String format);

  /// Gets analytics data for tool usage
  ///
  /// [timeRange] The time range for analytics (day, week, month, year)
  ///
  /// Returns analytics including:
  /// - Most used tools
  /// - Execution success rates
  /// - Performance trends
  /// - User behavior patterns
  Future<Map<String, dynamic>> getToolUsageAnalytics(String timeRange);

  /// Sets up automatic tool updates
  ///
  /// [enabled] Whether automatic updates are enabled
  /// [checkInterval] How often to check for updates
  ///
  /// When enabled, automatically discovers and updates tool definitions
  Future<void> setAutomaticToolUpdates(bool enabled, {Duration? checkInterval});

  /// Gets the current configuration of the client
  ///
  /// Returns all configuration settings including:
  /// - Server connections
  /// - Performance settings
  /// - Security policies
  /// - Mobile optimizations
  Map<String, dynamic> getCurrentConfiguration();

  /// Updates the configuration of the client
  ///
  /// [config] The new configuration settings
  ///
  /// Validates and applies the new configuration
  /// Throws [McpConfigurationException] if configuration is invalid
  Future<void> updateConfiguration(Map<String, dynamic> config);

  /// Disposes of all resources used by the client
  ///
  /// Should be called when the client is no longer needed
  /// Cleans up:
  /// - Network connections
  /// - Cached data
  /// - Background tasks
  /// - Event subscriptions
  Future<void> dispose();
}

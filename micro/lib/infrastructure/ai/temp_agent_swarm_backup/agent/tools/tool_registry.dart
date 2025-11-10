import '../models/agent_models.dart';

/// Abstract interface for all tools
/// Implementations must be stateless and thread-safe
abstract class AgentTool {
  /// Tool metadata (name, description, capabilities)
  ToolMetadata get metadata;

  /// Execute the tool with given parameters
  /// Returns result that should be JSON-serializable
  Future<dynamic> execute(Map<String, dynamic> parameters);

  /// Check if this tool can handle the given action
  bool canHandle(String action);

  /// Get required permissions for this tool
  List<String> getRequiredPermissions();

  /// Validate parameters before execution
  /// Throw exception if validation fails
  void validateParameters(Map<String, dynamic> parameters);
}

/// Registry for available tools
/// Manages tool discovery, validation, and execution
class ToolRegistry {
  final Map<String, AgentTool> _tools = {};
  final Map<String, List<String>> _capabilityIndex = {};
  final Map<String, List<String>> _domainIndex = {};

  /// Register a new tool
  void register(AgentTool tool) {
    _tools[tool.metadata.name] = tool;

    // Index capabilities
    for (final capability in tool.metadata.capabilities) {
      _capabilityIndex
          .putIfAbsent(capability, () => [])
          .add(tool.metadata.name);
    }

    // Index by domain (derived from tool name pattern)
    final domain = _extractDomain(tool.metadata.name);
    _domainIndex.putIfAbsent(domain, () => []).add(tool.metadata.name);
  }

  /// Unregister a tool
  bool unregister(String toolName) {
    final tool = _tools.remove(toolName);
    if (tool == null) return false;

    // Clean up indices
    for (final capability in tool.metadata.capabilities) {
      _capabilityIndex[capability]?.remove(toolName);
    }

    final domain = _extractDomain(toolName);
    _domainIndex[domain]?.remove(toolName);

    return true;
  }

  /// Get tool by name
  AgentTool? getTool(String toolName) => _tools[toolName];

  /// Find tools with specific capability
  List<AgentTool> findByCapability(String capability) {
    return (_capabilityIndex[capability] ?? [])
        .map((name) => _tools[name]!)
        .toList();
  }

  /// Find tools in a specific domain
  List<AgentTool> findByDomain(String domain) {
    return (_domainIndex[domain] ?? []).map((name) => _tools[name]!).toList();
  }

  /// Get all available tools
  List<AgentTool> getAllTools() => _tools.values.toList();

  /// Get all tool metadata (useful for agent planning)
  List<ToolMetadata> getAllMetadata() =>
      _tools.values.map((t) => t.metadata).toList();

  /// Find tools that can handle the given action
  List<AgentTool> findByAction(String action) {
    return _tools.values.where((tool) => tool.canHandle(action)).toList();
  }

  /// Execute a tool by name
  /// Validates parameters before execution
  Future<dynamic> executeTool(
    String toolName,
    Map<String, dynamic> parameters,
  ) async {
    final tool = _tools[toolName];
    if (tool == null) {
      throw ToolNotFoundException('Tool not found: $toolName');
    }

    try {
      tool.validateParameters(parameters);
      return await tool.execute(parameters);
    } catch (e) {
      throw ToolExecutionException(
        'Failed to execute tool $toolName: $e',
        toolName,
        e,
      );
    }
  }

  /// Get capabilities provided by all registered tools
  Set<String> getAllCapabilities() => _capabilityIndex.keys.toSet();

  /// Get all domains with registered tools
  Set<String> getAllDomains() => _domainIndex.keys.toSet();

  /// Check if tool is registered
  bool hasToolWithName(String toolName) => _tools.containsKey(toolName);

  /// Check if capability is available
  bool hasCapability(String capability) =>
      _capabilityIndex.containsKey(capability) &&
      _capabilityIndex[capability]!.isNotEmpty;

  /// Check if all required tools are available
  bool hasAllTools(List<String> toolNames) =>
      toolNames.every((name) => _tools.containsKey(name));

  /// Check if all required capabilities are available
  bool hasAllCapabilities(List<String> capabilities) =>
      capabilities.every((cap) => hasCapability(cap));

  /// Get number of registered tools
  int get toolCount => _tools.length;

  /// Clear all registered tools (useful for testing)
  void clear() {
    _tools.clear();
    _capabilityIndex.clear();
    _domainIndex.clear();
  }

  /// Extract domain from tool name (e.g., "ui_validation" -> "ui")
  static String _extractDomain(String toolName) {
    final parts = toolName.split('_');
    return parts.isNotEmpty ? parts.first : 'general';
  }
}

/// Exception thrown when tool is not found
class ToolNotFoundException implements Exception {
  final String message;

  ToolNotFoundException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown during tool execution
class ToolExecutionException implements Exception {
  final String message;
  final String toolName;
  final Object? originalError;

  ToolExecutionException(this.message, this.toolName, this.originalError);

  @override
  String toString() => message;
}

/// Extension for easier tool lookup by capability
extension ToolRegistryCapabilityExt on ToolRegistry {
  /// Fluent API for finding tools by multiple capabilities
  List<AgentTool> findByCapabilities(List<String> capabilities) {
    if (capabilities.isEmpty) return [];

    final toolsByCapability =
        capabilities.map((cap) => findByCapability(cap).toSet()).toList();

    // Return tools that have at least one of the capabilities
    return toolsByCapability
        .reduce((acc, current) => acc.union(current))
        .toList();
  }
}

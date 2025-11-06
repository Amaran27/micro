import 'package:langchain/langchain.dart';
import '../mcp/mcp_service.dart';
import '../mcp/models/mcp_models.dart';

/// Adapter that wraps MCP tools as LangChain Tool objects
/// This allows agents to use MCP tools seamlessly through the LangChain interface
class MCPToolAdapter extends Tool {
  final MCPService mcpService;
  final String serverId;
  final MCPTool mcpTool;

  MCPToolAdapter({
    required this.mcpService,
    required this.serverId,
    required this.mcpTool,
  }) : super(
          name: mcpTool.name,
          description: mcpTool.description,
        );

  @override
  Future<String> invoke(ToolInput input) async {
    try {
      // Extract parameters from LangChain input
      final parameters = _extractParameters(input);

      // Call MCP tool
      final result = await mcpService.callTool(
        serverId: serverId,
        toolName: mcpTool.name,
        parameters: parameters,
      );

      // Return result as string
      if (result.success) {
        return _formatSuccess(result);
      } else {
        return _formatError(result);
      }
    } catch (e) {
      return 'Error executing tool ${mcpTool.name}: $e';
    }
  }

  /// Extract parameters from LangChain ToolInput
  Map<String, dynamic> _extractParameters(ToolInput input) {
    // LangChain passes input as a string or map
    if (input is Map) {
      return Map<String, dynamic>.from(input);
    } else if (input is String) {
      // Try to parse as single argument
      return {'input': input};
    }
    return {};
  }

  /// Format successful result
  String _formatSuccess(MCPToolResult result) {
    if (result.content is String) {
      return result.content as String;
    } else if (result.content is Map) {
      // Pretty format JSON result
      return (result.content as Map).entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    } else {
      return result.content.toString();
    }
  }

  /// Format error result
  String _formatError(MCPToolResult result) {
    return 'Error: ${result.error ?? "Unknown error"}';
  }
}

/// Factory for creating LangChain tools from MCP servers
class MCPToolFactory {
  final MCPService mcpService;

  MCPToolFactory(this.mcpService);

  /// Get all available tools from connected MCP servers
  Future<List<Tool>> getAllTools() async {
    final tools = <Tool>[];
    
    for (final serverId in mcpService.getAllServerIds()) {
      try {
        final serverTools = await getToolsForServer(serverId);
        tools.addAll(serverTools);
      } catch (e) {
        print('Error getting tools for server $serverId: $e');
      }
    }
    
    return tools;
  }

  /// Get tools for a specific server
  Future<List<Tool>> getToolsForServer(String serverId) async {
    final serverTools = <Tool>[];
    
    try {
      final mcpTools = await mcpService.getServerTools(serverId);
      
      for (final mcpTool in mcpTools) {
        serverTools.add(MCPToolAdapter(
          mcpService: mcpService,
          serverId: serverId,
          mcpTool: mcpTool,
        ));
      }
    } catch (e) {
      print('Error creating tools for server $serverId: $e');
    }
    
    return serverTools;
  }

  /// Get tools from enabled servers based on user settings
  Future<List<Tool>> getEnabledTools(List<String> enabledServerIds) async {
    final tools = <Tool>[];
    
    for (final serverId in enabledServerIds) {
      try {
        final serverTools = await getToolsForServer(serverId);
        tools.addAll(serverTools);
      } catch (e) {
        print('Error getting tools for enabled server $serverId: $e');
      }
    }
    
    return tools;
  }

  /// Get specific tools by name from any connected server
  Future<List<Tool>> getToolsByName(List<String> toolNames) async {
    final allTools = await getAllTools();
    return allTools.where((tool) => toolNames.contains(tool.name)).toList();
  }
}

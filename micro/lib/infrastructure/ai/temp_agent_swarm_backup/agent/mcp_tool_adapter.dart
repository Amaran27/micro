import 'package:langchain/langchain.dart';
import 'package:langchain_core/tools.dart';
import '../mcp/mcp_service.dart';
import '../mcp/models/mcp_models.dart';
import 'tools/builtin_tools_manager.dart';

/// Adapter that wraps MCP tools as LangChain Tool objects
/// This allows agents to use MCP tools seamlessly through the LangChain interface
final class MCPToolAdapter extends Tool<Map<String, dynamic>, ToolOptions, String> {
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
          inputJsonSchema: mcpTool.inputSchema,
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) {
    return json;
  }

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    try {
      // Call MCP tool
      final result = await mcpService.callTool(
        serverId: serverId,
        toolName: mcpTool.name,
        parameters: input,
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

/// Factory for creating LangChain tools from MCP servers AND built-in tools
class MCPToolFactory {
  final MCPService mcpService;
  final BuiltInToolsManager _builtInTools = BuiltInToolsManager();
  bool _initialized = false;

  MCPToolFactory(this.mcpService);

  /// Initialize the factory (registers built-in tools)
  Future<void> initialize() async {
    if (_initialized) return;
    await _builtInTools.initialize();
    _initialized = true;
    print('MCPToolFactory initialized with ${_builtInTools.toolCount} built-in tools');
  }

  /// Get all available tools (built-in + MCP servers)
  Future<List<Tool<Object, ToolOptions, Object>>> getAllTools() async {
    if (!_initialized) await initialize();
    
    final tools = <Tool<Object, ToolOptions, Object>>[];
    
    // Add built-in tools first
    tools.addAll(_builtInTools.getAllTools());
    print('Added ${_builtInTools.toolCount} built-in tools');
    
    // Then add MCP server tools
    for (final serverId in mcpService.getAllServerIds()) {
      try {
        final serverTools = await getToolsForServer(serverId);
        tools.addAll(serverTools);
      } catch (e) {
        print('Error getting tools for server $serverId: $e');
      }
    }
    
    print('Total tools available: ${tools.length}');
    return tools;
  }

  /// Get tools for a specific server
  Future<List<Tool<Object, ToolOptions, Object>>> getToolsForServer(String serverId) async {
    final serverTools = <Tool<Object, ToolOptions, Object>>[];
    
    try {
      final mcpTools = mcpService.getServerTools(serverId);
      
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
  Future<List<Tool<Object, ToolOptions, Object>>> getEnabledTools(List<String> enabledServerIds) async {
    final tools = <Tool<Object, ToolOptions, Object>>[];
    
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
  Future<List<Tool<Object, ToolOptions, Object>>> getToolsByName(List<String> toolNames) async {
    final allTools = await getAllTools();
    return allTools.where((tool) => toolNames.contains(tool.name)).toList();
  }
}

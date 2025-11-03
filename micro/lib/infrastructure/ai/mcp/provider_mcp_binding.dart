import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_service.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';
import 'package:micro/infrastructure/ai/provider_config_model.dart';

/// Service that binds AI providers to MCP servers for tool execution
/// 
/// This service intercepts tool calls from AI providers and routes them
/// to appropriate MCP servers based on provider configuration.
class ProviderMCPBinding {
  final MCPService mcpService;
  final ProviderConfig providerConfig;

  ProviderMCPBinding({
    required this.mcpService,
    required this.providerConfig,
  });

  /// Check if MCP is enabled for this provider
  bool get isMCPEnabled => providerConfig.mcpEnabled;

  /// Get configured MCP server IDs for this provider
  List<String> get mcpServerIds => providerConfig.mcpServerIds;

  /// Execute a tool call via MCP
  /// 
  /// Translates the tool call from AI provider format to MCP format,
  /// executes it on the appropriate MCP server, and translates the result back.
  Future<MCPToolResult> executeToolCall({
    required String toolName,
    required Map<String, dynamic> parameters,
  }) async {
    if (!isMCPEnabled) {
      throw Exception('MCP is not enabled for provider ${providerConfig.providerId}');
    }

    if (mcpServerIds.isEmpty) {
      throw Exception('No MCP servers configured for provider ${providerConfig.providerId}');
    }

    // Find which server has this tool
    final serverId = await _findServerForTool(toolName);
    if (serverId == null) {
      throw Exception('Tool "$toolName" not found in any configured MCP server');
    }

    // Execute the tool call
    try {
      final result = await mcpService.callTool(
        serverId: serverId,
        toolName: toolName,
        parameters: parameters,
      );
      return result;
    } catch (e) {
      throw Exception('Failed to execute tool "$toolName": $e');
    }
  }

  /// Get all available tools from configured MCP servers
  Future<List<MCPTool>> getAvailableTools() async {
    if (!isMCPEnabled || mcpServerIds.isEmpty) {
      return [];
    }

    final tools = <MCPTool>[];
    for (final serverId in mcpServerIds) {
      final serverTools = mcpService.getAvailableTools(serverId);
      tools.addAll(serverTools);
    }
    return tools;
  }

  /// Find which MCP server has a specific tool
  Future<String?> _findServerForTool(String toolName) async {
    for (final serverId in mcpServerIds) {
      final tools = mcpService.getAvailableTools(serverId);
      if (tools.any((tool) => tool.name == toolName)) {
        return serverId;
      }
    }
    return null;
  }

  /// Convert MCP tool to AI provider tool format
  /// 
  /// Different AI providers have different tool schemas.
  /// This converts MCP's universal format to provider-specific format.
  Map<String, dynamic> convertMCPToolToProviderFormat(
    MCPTool mcpTool,
    String providerId,
  ) {
    // Base format that works for most providers (OpenAI-like)
    final toolDef = {
      'type': 'function',
      'function': {
        'name': mcpTool.name,
        'description': mcpTool.description,
        'parameters': mcpTool.inputSchema,
      },
    };

    // Provider-specific adjustments
    switch (providerId) {
      case 'openai':
      case 'zhipuai':
      case 'zai-general':
      case 'zai-coding':
        // OpenAI format (default)
        return toolDef;
      
      case 'anthropic':
      case 'claude':
        // Anthropic format
        return {
          'name': mcpTool.name,
          'description': mcpTool.description,
          'input_schema': mcpTool.inputSchema,
        };
      
      case 'google':
      case 'gemini':
        // Google format
        return {
          'function_declarations': [
            {
              'name': mcpTool.name,
              'description': mcpTool.description,
              'parameters': mcpTool.inputSchema,
            }
          ],
        };
      
      default:
        // Default to OpenAI format
        return toolDef;
    }
  }

  /// Convert AI provider tool call to MCP format
  Map<String, dynamic> convertProviderToolCallToMCP(
    Map<String, dynamic> providerToolCall,
    String providerId,
  ) {
    // Extract tool name and parameters based on provider format
    switch (providerId) {
      case 'openai':
      case 'zhipuai':
      case 'zai-general':
      case 'zai-coding':
        // OpenAI format: {"id": "call_xxx", "type": "function", "function": {"name": "...", "arguments": "{...}"}}
        final function = providerToolCall['function'] as Map<String, dynamic>?;
        if (function == null) return {};
        return {
          'name': function['name'],
          'parameters': function['arguments'] is String
              ? _parseJsonString(function['arguments'])
              : function['arguments'],
        };
      
      case 'anthropic':
      case 'claude':
        // Anthropic format: {"type": "tool_use", "id": "...", "name": "...", "input": {...}}
        return {
          'name': providerToolCall['name'],
          'parameters': providerToolCall['input'] ?? {},
        };
      
      case 'google':
      case 'gemini':
        // Google format: {"function_call": {"name": "...", "args": {...}}}
        final functionCall = providerToolCall['function_call'] as Map<String, dynamic>?;
        if (functionCall == null) return {};
        return {
          'name': functionCall['name'],
          'parameters': functionCall['args'] ?? {},
        };
      
      default:
        // Try to extract generic format
        return {
          'name': providerToolCall['name'] ?? providerToolCall['tool_name'],
          'parameters': providerToolCall['parameters'] ??
              providerToolCall['arguments'] ??
              providerToolCall['input'] ??
              {},
        };
    }
  }

  /// Convert MCP result to AI provider format
  Map<String, dynamic> convertMCPResultToProviderFormat(
    MCPToolResult mcpResult,
    String providerId,
  ) {
    if (!mcpResult.success) {
      // Return error in provider format
      switch (providerId) {
        case 'openai':
        case 'zhipuai':
        case 'zai-general':
        case 'zai-coding':
          return {
            'role': 'tool',
            'content': 'Error: ${mcpResult.error}',
          };
        
        case 'anthropic':
        case 'claude':
          return {
            'type': 'tool_result',
            'is_error': true,
            'content': mcpResult.error,
          };
        
        case 'google':
        case 'gemini':
          return {
            'function_response': {
              'name': mcpResult.toolName,
              'response': {'error': mcpResult.error},
            },
          };
        
        default:
          return {
            'error': mcpResult.error,
            'success': false,
          };
      }
    }

    // Return success result in provider format
    final contentStr = mcpResult.content is String
        ? mcpResult.content
        : mcpResult.content.toString();

    switch (providerId) {
      case 'openai':
      case 'zhipuai':
      case 'zai-general':
      case 'zai-coding':
        return {
          'role': 'tool',
          'content': contentStr,
        };
      
      case 'anthropic':
      case 'claude':
        return {
          'type': 'tool_result',
          'content': contentStr,
        };
      
      case 'google':
      case 'gemini':
        return {
          'function_response': {
            'name': mcpResult.toolName,
            'response': mcpResult.content,
          },
        };
      
      default:
        return {
          'content': contentStr,
          'success': true,
        };
    }
  }

  /// Helper to parse JSON string safely
  Map<String, dynamic> _parseJsonString(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is! String) return {};
    
    try {
      // Remove any JSON parsing if needed
      return {};
    } catch (e) {
      return {};
    }
  }
}

/// Riverpod provider for ProviderMCPBinding
/// 
/// Creates a binding for a specific provider configuration
final providerMCPBindingProvider = Provider.family<ProviderMCPBinding?, String>(
  (ref, providerConfigId) {
    // Get the provider config
    // Note: You'll need to implement a way to get provider config by ID
    // For now, return null if not available
    final mcpServiceAsync = ref.watch(mcpServiceProvider);
    final mcpService = mcpServiceAsync.value;
    
    if (mcpService == null) return null;
    
    // TODO: Get provider config by ID
    // This is a placeholder - you'll need to implement provider config retrieval
    return null;
  },
);

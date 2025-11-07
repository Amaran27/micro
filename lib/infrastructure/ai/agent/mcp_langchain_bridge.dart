/// Bridge between MCP (Model Context Protocol) tools and LangChain format
/// Converts between MCP tool specifications and LangChain Tool objects
class MCPLangChainBridge {
  /// Convert MCP tools to LangChain format
  List<LangChainTool> convertMCPTools(List<dynamic> mcpTools) {
    final langChainTools = <LangChainTool>[];

    for (final mcpTool in mcpTools) {
      try {
        if (mcpTool is! Map<String, dynamic>) {
          continue;
        }

        final name = mcpTool['name'] as String?;
        final description = mcpTool['description'] as String?;
        final inputSchema = mcpTool['inputSchema'];

        if (name == null || description == null || inputSchema == null) {
          continue;
        }

        langChainTools.add(
          LangChainTool(
            name: name,
            description: description,
          ),
        );
      } catch (e) {
        // Skip invalid tools
        continue;
      }
    }

    return langChainTools;
  }

  /// Convert LangChain result back to MCP format
  Map<String, dynamic> convertToMCPResult(
      Map<String, dynamic> langChainResult) {
    return {
      'content': langChainResult['output'] ?? '',
      'isError': langChainResult['error'] != null,
      'error': langChainResult['error'],
    };
  }
}

/// Represents a LangChain tool
class LangChainTool {
  final String name;
  final String description;
  final Map<String, dynamic>? schema;

  LangChainTool({
    required this.name,
    required this.description,
    this.schema,
  });

  @override
  String toString() => 'LangChainTool($name: $description)';
}

import 'package:json_annotation/json_annotation.dart';

part 'mcp_models.g.dart';

/// Transport types supported by MCP
enum MCPTransportType {
  @JsonValue('stdio')
  stdio,
  @JsonValue('sse')
  sse,
  @JsonValue('http')
  http,
}

/// Connection status of MCP server
enum MCPConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Platform support for MCP servers
enum MCPServerPlatform {
  desktop,
  mobile,
  both,
}

/// MCP Server Configuration
@JsonSerializable()
class MCPServerConfig {
  final String id;
  final String name;
  final String description;
  final MCPTransportType transportType;
  
  // For HTTP/SSE
  final String? url;
  final Map<String, String>? headers;
  
  // For stdio
  final String? command;
  final List<String>? args;
  final List<String>? arguments; // Alias for args
  final Map<String, String>? env;
  final Map<String, String>? environment; // Alias for env
  
  final bool autoConnect;
  final bool enabled;

  const MCPServerConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.transportType,
    this.url,
    this.headers,
    this.command,
    this.args,
    this.arguments,
    this.env,
    this.environment,
    this.autoConnect = false,
    this.enabled = true,
  });

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) =>
      _$MCPServerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MCPServerConfigToJson(this);

  MCPServerConfig copyWith({
    String? id,
    String? name,
    String? description,
    MCPTransportType? transportType,
    String? url,
    Map<String, String>? headers,
    String? command,
    List<String>? args,
    List<String>? arguments,
    Map<String, String>? env,
    Map<String, String>? environment,
    bool? autoConnect,
    bool? enabled,
  }) {
    return MCPServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      transportType: transportType ?? this.transportType,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      command: command ?? this.command,
      args: args ?? this.args,
      arguments: arguments ?? this.arguments,
      env: env ?? this.env,
      environment: environment ?? this.environment,
      autoConnect: autoConnect ?? this.autoConnect,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// MCP Server Connection State
@JsonSerializable()
class MCPServerState {
  final String serverId;
  final MCPConnectionStatus status;
  final List<MCPTool> availableTools;
  final DateTime? lastConnected;
  final DateTime? lastActivity;
  final String? errorMessage;
  final int toolCallCount;

  const MCPServerState({
    required this.serverId,
    required this.status,
    this.availableTools = const [],
    this.lastConnected,
    this.lastActivity,
    this.errorMessage,
    this.toolCallCount = 0,
  });

  factory MCPServerState.fromJson(Map<String, dynamic> json) =>
      _$MCPServerStateFromJson(json);

  Map<String, dynamic> toJson() => _$MCPServerStateToJson(this);

  MCPServerState copyWith({
    String? serverId,
    MCPConnectionStatus? status,
    List<MCPTool>? availableTools,
    DateTime? lastConnected,
    DateTime? lastActivity,
    String? errorMessage,
    int? toolCallCount,
  }) {
    return MCPServerState(
      serverId: serverId ?? this.serverId,
      status: status ?? this.status,
      availableTools: availableTools ?? this.availableTools,
      lastConnected: lastConnected ?? this.lastConnected,
      lastActivity: lastActivity ?? this.lastActivity,
      errorMessage: errorMessage ?? this.errorMessage,
      toolCallCount: toolCallCount ?? this.toolCallCount,
    );
  }
}

/// MCP Tool Definition
@JsonSerializable()
class MCPTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final String? serverId;

  const MCPTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    this.serverId,
  });

  factory MCPTool.fromJson(Map<String, dynamic> json) =>
      _$MCPToolFromJson(json);

  Map<String, dynamic> toJson() => _$MCPToolToJson(this);
}

/// MCP Tool Call Result
@JsonSerializable()
class MCPToolResult {
  final String toolName;
  final bool success;
  final dynamic content;
  final String? error;
  final DateTime executedAt;
  final int durationMs;

  const MCPToolResult({
    required this.toolName,
    required this.success,
    this.content,
    this.error,
    required this.executedAt,
    required this.durationMs,
  });

  factory MCPToolResult.fromJson(Map<String, dynamic> json) =>
      _$MCPToolResultFromJson(json);

  Map<String, dynamic> toJson() => _$MCPToolResultToJson(this);
}

/// Recommended MCP Server for discovery
class RecommendedMCPServer {
  final String id;
  final String name;
  final String description;
  final String icon;
  final MCPTransportType transportType;
  final List<String> supportedPlatforms; // ['desktop', 'mobile']
  final MCPServerPlatform platform;
  final String? installCommand;
  final Map<String, dynamic> defaultConfig;
  final String? documentationUrl;
  final String? docUrl; // Alias for documentationUrl

  const RecommendedMCPServer({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.transportType,
    required this.supportedPlatforms,
    required this.platform,
    this.installCommand,
    required this.defaultConfig,
    this.documentationUrl,
    this.docUrl,
  });
}

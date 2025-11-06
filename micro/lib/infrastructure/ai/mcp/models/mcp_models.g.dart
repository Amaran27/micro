// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MCPServerConfig _$MCPServerConfigFromJson(Map<String, dynamic> json) =>
    MCPServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      transportType:
          $enumDecode(_$MCPTransportTypeEnumMap, json['transportType']),
      url: json['url'] as String?,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      command: json['command'] as String?,
      args: (json['args'] as List<dynamic>?)?.map((e) => e as String).toList(),
      arguments: (json['arguments'] as List<dynamic>?)?.map((e) => e as String).toList(),
      env: (json['env'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      environment: (json['environment'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      autoConnect: json['autoConnect'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$MCPServerConfigToJson(MCPServerConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'transportType': _$MCPTransportTypeEnumMap[instance.transportType]!,
      'url': instance.url,
      'headers': instance.headers,
      'command': instance.command,
      'args': instance.args,
      'arguments': instance.arguments,
      'env': instance.env,
      'environment': instance.environment,
      'autoConnect': instance.autoConnect,
      'enabled': instance.enabled,
    };

const _$MCPTransportTypeEnumMap = {
  MCPTransportType.stdio: 'stdio',
  MCPTransportType.sse: 'sse',
  MCPTransportType.http: 'http',
};

MCPServerState _$MCPServerStateFromJson(Map<String, dynamic> json) =>
    MCPServerState(
      serverId: json['serverId'] as String,
      status: $enumDecode(_$MCPConnectionStatusEnumMap, json['status']),
      availableTools: (json['availableTools'] as List<dynamic>?)
              ?.map((e) => MCPTool.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastConnected: json['lastConnected'] == null
          ? null
          : DateTime.parse(json['lastConnected'] as String),
      lastActivity: json['lastActivity'] == null
          ? null
          : DateTime.parse(json['lastActivity'] as String),
      errorMessage: json['errorMessage'] as String?,
      toolCallCount: json['toolCallCount'] as int? ?? 0,
    );

Map<String, dynamic> _$MCPServerStateToJson(MCPServerState instance) =>
    <String, dynamic>{
      'serverId': instance.serverId,
      'status': _$MCPConnectionStatusEnumMap[instance.status]!,
      'availableTools': instance.availableTools,
      'lastConnected': instance.lastConnected?.toIso8601String(),
      'lastActivity': instance.lastActivity?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'toolCallCount': instance.toolCallCount,
    };

const _$MCPConnectionStatusEnumMap = {
  MCPConnectionStatus.disconnected: 'disconnected',
  MCPConnectionStatus.connecting: 'connecting',
  MCPConnectionStatus.connected: 'connected',
  MCPConnectionStatus.error: 'error',
};

MCPTool _$MCPToolFromJson(Map<String, dynamic> json) => MCPTool(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema: json['inputSchema'] as Map<String, dynamic>,
      serverId: json['serverId'] as String?,
    );

Map<String, dynamic> _$MCPToolToJson(MCPTool instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'inputSchema': instance.inputSchema,
      'serverId': instance.serverId,
    };

MCPToolResult _$MCPToolResultFromJson(Map<String, dynamic> json) =>
    MCPToolResult(
      toolName: json['toolName'] as String,
      success: json['success'] as bool,
      content: json['content'],
      error: json['error'] as String?,
      executedAt: DateTime.parse(json['executedAt'] as String),
      durationMs: json['durationMs'] as int,
    );

Map<String, dynamic> _$MCPToolResultToJson(MCPToolResult instance) =>
    <String, dynamic>{
      'toolName': instance.toolName,
      'success': instance.success,
      'content': instance.content,
      'error': instance.error,
      'executedAt': instance.executedAt.toIso8601String(),
      'durationMs': instance.durationMs,
    };

import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'models/mcp_models.dart';

/// MCP Service for managing MCP server connections and operations
class MCPService {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  static const String _storageKey = 'mcp_servers';
  
  final Map<String, MCPServerState> _serverStates = {};
  final Map<String, MCPServerConfig> _serverConfigs = {};
  final Map<String, Process?> _stdioProcesses = {};
  final Map<String, WebSocketChannel?> _sseChannels = {};
  final Map<String, StreamController<MCPServerState>> _stateControllers = {};
  
  int _requestId = 1;

  MCPService({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio();

  /// Initialize the service and load configurations
  Future<void> initialize() async {
    await _loadConfigurations();
  }

  /// Load server configurations from secure storage
  Future<void> _loadConfigurations() async {
    try {
      final jsonString = await _storage.read(key: _storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        for (final item in jsonList) {
          final config = MCPServerConfig.fromJson(item);
          _serverConfigs[config.id] = config;
          _serverStates[config.id] = MCPServerState(
            serverId: config.id,
            status: MCPConnectionStatus.disconnected,
          );
        }
      }
    } catch (e) {
      // Log error but don't throw - allow service to start with empty config
      print('Error loading MCP configurations: $e');
    }
  }

  /// Save server configurations to secure storage
  Future<void> _saveConfigurations() async {
    try {
      final configs = _serverConfigs.values.toList();
      final jsonString = json.encode(configs.map((c) => c.toJson()).toList());
      await _storage.write(key: _storageKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save MCP configurations: $e');
    }
  }

  /// Get all server configurations
  List<MCPServerConfig> getServerConfigs() {
    return _serverConfigs.values.toList();
  }

  /// Get all server states
  List<MCPServerState> getServerStates() {
    return _serverStates.values.toList();
  }

  /// Get state for a specific server
  MCPServerState? getServerState(String serverId) {
    return _serverStates[serverId];
  }

  /// Get configuration for a specific server
  MCPServerConfig? getServerConfig(String serverId) {
    return _serverConfigs[serverId];
  }

  /// Add a new MCP server
  Future<void> addServer(MCPServerConfig config) async {
    // Validate configuration
    _validateConfig(config);
    
    _serverConfigs[config.id] = config;
    _serverStates[config.id] = MCPServerState(
      serverId: config.id,
      status: MCPConnectionStatus.disconnected,
    );
    
    await _saveConfigurations();
    
    // Auto-connect if enabled
    if (config.autoConnect) {
      await connectServer(config.id);
    }
  }

  /// Update an existing MCP server configuration
  Future<void> updateServer(MCPServerConfig config) async {
    if (!_serverConfigs.containsKey(config.id)) {
      throw Exception('Server ${config.id} not found');
    }
    
    _validateConfig(config);
    
    // Disconnect if connected
    if (_serverStates[config.id]?.status == MCPConnectionStatus.connected) {
      await disconnectServer(config.id);
    }
    
    _serverConfigs[config.id] = config;
    await _saveConfigurations();
    
    // Reconnect if enabled
    if (config.autoConnect) {
      await connectServer(config.id);
    }
  }

  /// Remove an MCP server
  Future<void> removeServer(String serverId) async {
    // Disconnect if connected
    if (_serverStates[serverId]?.status == MCPConnectionStatus.connected) {
      await disconnectServer(serverId);
    }
    
    _serverConfigs.remove(serverId);
    _serverStates.remove(serverId);
    await _saveConfigurations();
  }

  /// Connect to an MCP server
  Future<void> connectServer(String serverId) async {
    final config = _serverConfigs[serverId];
    if (config == null) {
      throw Exception('Server $serverId not found');
    }

    // Update state to connecting
    _updateServerState(serverId, (state) => state.copyWith(
      status: MCPConnectionStatus.connecting,
    ));

    try {
      // Validate platform support for stdio
      if (config.transportType == MCPTransportType.stdio) {
        if (Platform.isAndroid || Platform.isIOS) {
          throw Exception(
            'stdio transport is not supported on mobile platforms. '
            'Please use HTTP or SSE transport instead.'
          );
        }
      }

      // Connect based on transport type
      List<MCPTool> tools;
      switch (config.transportType) {
        case MCPTransportType.stdio:
          tools = await _connectStdio(serverId, config);
          break;
        case MCPTransportType.http:
          tools = await _connectHTTP(serverId, config);
          break;
        case MCPTransportType.sse:
          tools = await _connectSSE(serverId, config);
          break;
      }
      
      _updateServerState(serverId, (state) => state.copyWith(
        status: MCPConnectionStatus.connected,
        lastConnected: DateTime.now(),
        lastActivity: DateTime.now(),
        availableTools: tools,
        errorMessage: null,
      ));
    } catch (e) {
      _updateServerState(serverId, (state) => state.copyWith(
        status: MCPConnectionStatus.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  /// Disconnect from an MCP server
  Future<void> disconnectServer(String serverId) async {
    final state = _serverStates[serverId];
    if (state == null) {
      throw Exception('Server $serverId not found');
    }

    final config = _serverConfigs[serverId];
    if (config == null) return;

    // Close connections based on transport type
    switch (config.transportType) {
      case MCPTransportType.stdio:
        _stdioProcesses[serverId]?.kill();
        _stdioProcesses.remove(serverId);
        break;
      case MCPTransportType.sse:
        _sseChannels[serverId]?.sink.close();
        _sseChannels.remove(serverId);
        break;
      case MCPTransportType.http:
        // HTTP is stateless, nothing to close
        break;
    }
    
    _updateServerState(serverId, (state) => state.copyWith(
      status: MCPConnectionStatus.disconnected,
      errorMessage: null,
    ));
  }

  /// Test connection to an MCP server
  Future<bool> testConnection(MCPServerConfig config) async {
    try {
      _validateConfig(config);
      
      // Platform check for stdio
      if (config.transportType == MCPTransportType.stdio) {
        if (Platform.isAndroid || Platform.isIOS) {
          throw Exception('stdio not supported on mobile');
        }
      }
      
      // Try to initialize connection based on transport
      switch (config.transportType) {
        case MCPTransportType.http:
          await _sendJSONRPC(
            url: config.url!,
            method: 'initialize',
            params: {
              'protocolVersion': '2024-11-05',
              'capabilities': {'tools': {}},
              'clientInfo': {'name': 'Micro', 'version': '1.0.0'},
            },
            headers: config.headers,
          );
          return true;
        case MCPTransportType.sse:
        case MCPTransportType.stdio:
          // For SSE/stdio, just validate config - full test would require connection
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Call a tool on an MCP server
  Future<MCPToolResult> callTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> parameters,
  }) async {
    final state = _serverStates[serverId];
    if (state == null) {
      throw Exception('Server $serverId not found');
    }

    if (state.status != MCPConnectionStatus.connected) {
      throw Exception('Server $serverId is not connected');
    }

    // Use actual implementation
    final result = await _callToolImpl(
      serverId: serverId,
      toolName: toolName,
      parameters: parameters,
    );
    
    // Update activity time and tool call count
    _updateServerState(serverId, (state) => state.copyWith(
      lastActivity: DateTime.now(),
      toolCallCount: state.toolCallCount + 1,
    ));
    
    return result;
  }

  /// Get available tools from a server
  List<MCPTool> getAvailableTools(String serverId) {
    final state = _serverStates[serverId];
    return state?.availableTools ?? [];
  }

  /// Alias for getAvailableTools
  Future<List<MCPTool>> getServerTools(String serverId) async {
    return getAvailableTools(serverId);
  }

  /// Get all server IDs
  List<String> getAllServerIds() {
    return _serverConfigs.keys.toList();
  }

  /// Get all available tools from all connected servers
  List<MCPTool> getAllAvailableTools() {
    final tools = <MCPTool>[];
    for (final state in _serverStates.values) {
      if (state.status == MCPConnectionStatus.connected) {
        tools.addAll(state.availableTools);
      }
    }
    return tools;
  }

  /// Validate server configuration
  void _validateConfig(MCPServerConfig config) {
    if (config.name.isEmpty) {
      throw Exception('Server name cannot be empty');
    }

    switch (config.transportType) {
      case MCPTransportType.stdio:
        if (config.command == null || config.command!.isEmpty) {
          throw Exception('Command is required for stdio transport');
        }
        break;
      case MCPTransportType.http:
      case MCPTransportType.sse:
        if (config.url == null || config.url!.isEmpty) {
          throw Exception('URL is required for HTTP/SSE transport');
        }
        // Basic URL validation
        try {
          final uri = Uri.parse(config.url!);
          if (!uri.hasScheme || (!uri.hasAuthority && uri.scheme != 'file')) {
            throw Exception('Invalid URL format');
          }
        } catch (e) {
          throw Exception('Invalid URL: $e');
        }
        break;
    }
  }

  /// Update server state
  void _updateServerState(
    String serverId,
    MCPServerState Function(MCPServerState) update,
  ) {
    final currentState = _serverStates[serverId];
    if (currentState != null) {
      _serverStates[serverId] = update(currentState);
      // Notify listeners if controller exists
      _stateControllers[serverId]?.add(_serverStates[serverId]!);
    }
  }

  /// Get state stream for a server
  Stream<MCPServerState> getServerStateStream(String serverId) {
    if (!_stateControllers.containsKey(serverId)) {
      _stateControllers[serverId] = StreamController<MCPServerState>.broadcast();
    }
    return _stateControllers[serverId]!.stream;
  }

  // ========== TRANSPORT IMPLEMENTATIONS ==========

  /// Connect via HTTP transport
  Future<List<MCPTool>> _connectHTTP(String serverId, MCPServerConfig config) async {
    try {
      // Step 1: Initialize connection
      final initResponse = await _sendJSONRPC(
        url: config.url!,
        method: 'initialize',
        params: {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'tools': {},
          },
          'clientInfo': {
            'name': 'Micro',
            'version': '1.0.0',
          },
        },
        headers: config.headers,
      );

      // Step 2: List available tools
      final toolsResponse = await _sendJSONRPC(
        url: config.url!,
        method: 'tools/list',
        params: {},
        headers: config.headers,
      );

      // Parse tools
      final tools = <MCPTool>[];
      if (toolsResponse['tools'] != null) {
        for (final toolData in toolsResponse['tools']) {
          tools.add(MCPTool(
            name: toolData['name'] as String,
            description: toolData['description'] as String? ?? '',
            inputSchema: toolData['inputSchema'] as Map<String, dynamic>? ?? {},
            serverId: serverId,
          ));
        }
      }

      return tools;
    } catch (e) {
      throw Exception('HTTP connection failed: $e');
    }
  }

  /// Connect via SSE transport
  Future<List<MCPTool>> _connectSSE(String serverId, MCPServerConfig config) async {
    try {
      // SSE uses WebSocket for bi-directional communication
      final uri = Uri.parse(config.url!.replaceFirst('http', 'ws'));
      final channel = WebSocketChannel.connect(uri);
      _sseChannels[serverId] = channel;

      // Send initialize message
      channel.sink.add(json.encode({
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {'tools': {}},
          'clientInfo': {'name': 'Micro', 'version': '1.0.0'},
        },
      }));

      // Wait for initialize response
      final initData = await channel.stream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('SSE initialize timeout'),
      );
      
      // Request tools list
      channel.sink.add(json.encode({
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': 'tools/list',
        'params': {},
      }));

      // Wait for tools response
      final toolsData = await channel.stream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('SSE tools/list timeout'),
      );

      final toolsResponse = json.decode(toolsData as String);
      final tools = <MCPTool>[];
      
      if (toolsResponse['result'] != null && toolsResponse['result']['tools'] != null) {
        for (final toolData in toolsResponse['result']['tools']) {
          tools.add(MCPTool(
            name: toolData['name'] as String,
            description: toolData['description'] as String? ?? '',
            inputSchema: toolData['inputSchema'] as Map<String, dynamic>? ?? {},
            serverId: serverId,
          ));
        }
      }

      return tools;
    } catch (e) {
      _sseChannels[serverId]?.sink.close();
      _sseChannels.remove(serverId);
      throw Exception('SSE connection failed: $e');
    }
  }

  /// Connect via stdio transport (desktop only)
  Future<List<MCPTool>> _connectStdio(String serverId, MCPServerConfig config) async {
    try {
      // Start process
      final process = await Process.start(
        config.command!,
        config.arguments ?? [],
        environment: config.environment,
      );
      _stdioProcesses[serverId] = process;

      // Send initialize
      final initRequest = json.encode({
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {'tools': {}},
          'clientInfo': {'name': 'Micro', 'version': '1.0.0'},
        },
      });
      process.stdin.writeln(initRequest);

      // Read initialize response
      final initLine = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 10));
      
      // Request tools
      final toolsRequest = json.encode({
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': 'tools/list',
        'params': {},
      });
      process.stdin.writeln(toolsRequest);

      // Read tools response
      final toolsLine = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 10));

      final toolsResponse = json.decode(toolsLine);
      final tools = <MCPTool>[];
      
      if (toolsResponse['result'] != null && toolsResponse['result']['tools'] != null) {
        for (final toolData in toolsResponse['result']['tools']) {
          tools.add(MCPTool(
            name: toolData['name'] as String,
            description: toolData['description'] as String? ?? '',
            inputSchema: toolData['inputSchema'] as Map<String, dynamic>? ?? {},
            serverId: serverId,
          ));
        }
      }

      return tools;
    } catch (e) {
      _stdioProcesses[serverId]?.kill();
      _stdioProcesses.remove(serverId);
      throw Exception('stdio connection failed: $e');
    }
  }

  /// Send JSON-RPC request over HTTP
  Future<Map<String, dynamic>> _sendJSONRPC({
    required String url,
    required String method,
    required Map<String, dynamic> params,
    Map<String, String>? headers,
  }) async {
    try {
      final request = {
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': method,
        'params': params,
      };

      final response = await _dio.post(
        url,
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
          responseType: ResponseType.json,
        ),
      ).timeout(const Duration(seconds: 30));

      if (response.data is! Map) {
        throw Exception('Invalid response format');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['error'] != null) {
        final error = data['error'];
        throw Exception('MCP Error: ${error['message'] ?? 'Unknown error'}');
      }

      return data['result'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Call tool with actual implementation
  Future<MCPToolResult> _callToolImpl({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> parameters,
  }) async {
    final config = _serverConfigs[serverId];
    if (config == null) {
      throw Exception('Server $serverId not found');
    }

    final startTime = DateTime.now();
    
    try {
      Map<String, dynamic> result;

      switch (config.transportType) {
        case MCPTransportType.http:
          result = await _sendJSONRPC(
            url: config.url!,
            method: 'tools/call',
            params: {
              'name': toolName,
              'arguments': parameters,
            },
            headers: config.headers,
          );
          break;

        case MCPTransportType.sse:
          final channel = _sseChannels[serverId];
          if (channel == null) {
            throw Exception('SSE channel not connected');
          }
          
          channel.sink.add(json.encode({
            'jsonrpc': '2.0',
            'id': _requestId++,
            'method': 'tools/call',
            'params': {'name': toolName, 'arguments': parameters},
          }));

          final response = await channel.stream.first.timeout(
            const Duration(seconds: 60),
          );
          
          final data = json.decode(response as String);
          result = data['result'] as Map<String, dynamic>? ?? {};
          break;

        case MCPTransportType.stdio:
          final process = _stdioProcesses[serverId];
          if (process == null) {
            throw Exception('stdio process not running');
          }

          process.stdin.writeln(json.encode({
            'jsonrpc': '2.0',
            'id': _requestId++,
            'method': 'tools/call',
            'params': {'name': toolName, 'arguments': parameters},
          }));

          final line = await process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first
              .timeout(const Duration(seconds: 60));

          final data = json.decode(line);
          result = data['result'] as Map<String, dynamic>? ?? {};
          break;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      return MCPToolResult(
        toolName: toolName,
        success: true,
        content: result,
        executedAt: endTime,
        durationMs: duration,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      return MCPToolResult(
        toolName: toolName,
        success: false,
        error: e.toString(),
        executedAt: endTime,
        durationMs: duration,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    // Disconnect all servers
    for (final serverId in _serverConfigs.keys.toList()) {
      try {
        disconnectServer(serverId);
      } catch (e) {
        // Log but don't throw during disposal
        print('Error disconnecting server $serverId: $e');
      }
    }
    
    // Close all state controllers
    for (final controller in _stateControllers.values) {
      controller.close();
    }
    
    _serverConfigs.clear();
    _serverStates.clear();
    _stdioProcesses.clear();
    _sseChannels.clear();
    _stateControllers.clear();
  }
}

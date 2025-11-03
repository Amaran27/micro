import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'models/mcp_models.dart';

/// MCP Service for managing MCP server connections and operations
class MCPService {
  final FlutterSecureStorage _storage;
  static const String _storageKey = 'mcp_servers';
  
  final Map<String, MCPServerState> _serverStates = {};
  final Map<String, MCPServerConfig> _serverConfigs = {};

  MCPService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

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

      // TODO: Implement actual connection logic based on transport type
      // For now, simulate successful connection
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock available tools for demonstration
      final mockTools = <MCPTool>[];
      
      _updateServerState(serverId, (state) => state.copyWith(
        status: MCPConnectionStatus.connected,
        lastConnected: DateTime.now(),
        lastActivity: DateTime.now(),
        availableTools: mockTools,
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

    // TODO: Implement actual disconnection logic
    
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
      
      // TODO: Implement actual connection test
      await Future.delayed(const Duration(seconds: 1));
      return true;
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

    final startTime = DateTime.now();
    
    try {
      // TODO: Implement actual tool call logic
      // For now, simulate a tool call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      // Update activity time and tool call count
      _updateServerState(serverId, (state) => state.copyWith(
        lastActivity: DateTime.now(),
        toolCallCount: state.toolCallCount + 1,
      ));
      
      return MCPToolResult(
        toolName: toolName,
        success: true,
        content: {'result': 'Tool executed successfully'},
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

  /// Get available tools from a server
  List<MCPTool> getAvailableTools(String serverId) {
    final state = _serverStates[serverId];
    return state?.availableTools ?? [];
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
    }
  }

  /// Dispose resources
  void dispose() {
    // Disconnect all servers
    for (final serverId in _serverConfigs.keys) {
      disconnectServer(serverId);
    }
    _serverConfigs.clear();
    _serverStates.clear();
  }
}

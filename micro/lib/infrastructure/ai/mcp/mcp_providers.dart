import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_service.dart';
import 'models/mcp_models.dart';

/// Notifier for MCPService
class MCPServiceNotifier extends AsyncNotifier<MCPService> {
  @override
  Future<MCPService> build() async {
    final service = MCPService();
    await service.initialize();
    return service;
  }
}

/// Provider for MCPService
final mcpServiceProvider = AsyncNotifierProvider<MCPServiceNotifier, MCPService>(
  MCPServiceNotifier.new,
);

/// Provider for list of MCP server configurations
final mcpServerConfigsProvider = FutureProvider<List<MCPServerConfig>>((ref) async {
  final serviceAsync = ref.watch(mcpServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  return service.getServerConfigs();
});

/// Provider for list of MCP server states
final mcpServerStatesProvider = StreamProvider<List<MCPServerState>>((ref) async* {
  final serviceAsync = ref.watch(mcpServiceProvider);
  final service = serviceAsync.value;
  
  if (service == null) {
    yield [];
    return;
  }

  // Initial state
  yield service.getServerStates();
  
  // Update periodically (every 2 seconds)
  // In production, this should be event-driven
  await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
    yield service.getServerStates();
  }
});

/// Provider for a specific server state
final mcpServerStateProvider = Provider.family<MCPServerState?, String>((ref, serverId) {
  final statesAsync = ref.watch(mcpServerStatesProvider);
  final states = statesAsync.value ?? [];
  
  try {
    return states.firstWhere((state) => state.serverId == serverId);
  } catch (e) {
    return null;
  }
});

/// Provider for connected MCP servers
final connectedMCPServersProvider = Provider<List<MCPServerState>>((ref) {
  final statesAsync = ref.watch(mcpServerStatesProvider);
  final states = statesAsync.value ?? [];
  return states.where((s) => s.status == MCPConnectionStatus.connected).toList();
});

/// Provider for all available MCP tools from all connected servers
final allMCPToolsProvider = FutureProvider<List<MCPTool>>((ref) async {
  final serviceAsync = ref.watch(mcpServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  return service.getAllAvailableTools();
});

/// Provider for tools from a specific server
final mcpServerToolsProvider = Provider.family<List<MCPTool>, String>((ref, serverId) {
  final serviceAsync = ref.watch(mcpServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  return service.getAvailableTools(serverId);
});

/// Notifier for MCP operations (connect, disconnect, etc.)
class MCPOperationsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Connect to a server
  Future<void> connectServer(String serverId) async {
    state = const AsyncValue.loading();
    
    try {
      final serviceAsync = ref.read(mcpServiceProvider);
      final service = serviceAsync.value;
      
      if (service == null) {
        throw Exception('MCP service not initialized');
      }
      
      await service.connectServer(serverId);
      state = const AsyncValue.data(null);
      
      // Refresh server states
      ref.invalidate(mcpServerStatesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Disconnect from a server
  Future<void> disconnectServer(String serverId) async {
    state = const AsyncValue.loading();
    
    try {
      final serviceAsync = ref.read(mcpServiceProvider);
      final service = serviceAsync.value;
      
      if (service == null) {
        throw Exception('MCP service not initialized');
      }
      
      await service.disconnectServer(serverId);
      state = const AsyncValue.data(null);
      
      // Refresh server states
      ref.invalidate(mcpServerStatesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add a new server
  Future<void> addServer(MCPServerConfig config) async {
    state = const AsyncValue.loading();
    
    try {
      final serviceAsync = ref.read(mcpServiceProvider);
      final service = serviceAsync.value;
      
      if (service == null) {
        throw Exception('MCP service not initialized');
      }
      
      await service.addServer(config);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      ref.invalidate(mcpServerConfigsProvider);
      ref.invalidate(mcpServerStatesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update a server
  Future<void> updateServer(MCPServerConfig config) async {
    state = const AsyncValue.loading();
    
    try {
      final serviceAsync = ref.read(mcpServiceProvider);
      final service = serviceAsync.value;
      
      if (service == null) {
        throw Exception('MCP service not initialized');
      }
      
      await service.updateServer(config);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      ref.invalidate(mcpServerConfigsProvider);
      ref.invalidate(mcpServerStatesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Remove a server
  Future<void> removeServer(String serverId) async {
    state = const AsyncValue.loading();
    
    try {
      final serviceAsync = ref.read(mcpServiceProvider);
      final service = serviceAsync.value;
      
      if (service == null) {
        throw Exception('MCP service not initialized');
      }
      
      await service.removeServer(serverId);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      ref.invalidate(mcpServerConfigsProvider);
      ref.invalidate(mcpServerStatesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Test connection to a server
  Future<bool> testConnection(MCPServerConfig config) async {
    try {
      final serviceAsync = ref.read(mcpServiceProvider);
      final service = serviceAsync.value;
      
      if (service == null) {
        throw Exception('MCP service not initialized');
      }
      
      return await service.testConnection(config);
    } catch (e) {
      return false;
    }
  }
}

/// Provider for MCP operations
final mcpOperationsProvider = NotifierProvider<MCPOperationsNotifier, AsyncValue<void>>(
  MCPOperationsNotifier.new,
);

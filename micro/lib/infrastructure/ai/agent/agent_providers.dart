import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'agent_service.dart';
import 'agent_types.dart' as agent_types;

/// Notifier for AgentService
class AgentServiceNotifier extends AsyncNotifier<AgentService> {
  @override
  Future<AgentService> build() async {
    final service = AgentService();
    await service.initialize();
    return service;
  }
}

/// Provider for AgentService
final agentServiceProvider =
    AsyncNotifierProvider<AgentServiceNotifier, AgentService>(
  AgentServiceNotifier.new,
);

/// Notifier for agent status
class AgentStatusNotifier extends StreamNotifier<agent_types.AgentStatus> {
  @override
  Stream<agent_types.AgentStatus> build() async* {
    final serviceAsync = ref.watch(agentServiceProvider);
    final service = serviceAsync.value;
    if (service != null) {
      await service.initialize();
    }
    // This is a simplified version - you'd want to implement proper status monitoring
    yield agent_types.AgentStatus.idle;
  }
}

/// Provider for default agent status
final defaultAgentStatusProvider =
    StreamNotifierProvider<AgentStatusNotifier, agent_types.AgentStatus>(
  AgentStatusNotifier.new,
);

/// Provider for agent execution history
final agentHistoryProvider =
    FutureProvider<List<agent_types.AgentExecution>>((ref) async {
  final serviceAsync = ref.watch(agentServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  return service.getExecutionHistory();
});

/// Provider for available tools
final availableToolsProvider = FutureProvider<List<dynamic>>((ref) async {
  final serviceAsync = ref.watch(agentServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  return await service.getAvailableTools();
});

/// Provider for tools by category
final toolsByCategoryProvider =
    FutureProvider<Map<String, List<dynamic>>>((ref) async {
  final serviceAsync = ref.watch(agentServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return {};
  return await service.getToolsByCategory();
});

/// Provider for agent capabilities
final agentCapabilitiesProvider =
    FutureProvider<List<agent_types.AgentCapability>>((ref) async {
  final serviceAsync = ref.watch(agentServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  return service.getAgentCapabilities();
});

/// State notifier for agent execution
class AgentExecutionNotifier extends AsyncNotifier<agent_types.AgentResult?> {
  @override
  agent_types.AgentResult? build() => null;

  /// Execute a goal
  Future<void> executeGoal({
    required String goal,
    String? agentId,
    String? context,
    Map<String, dynamic>? parameters,
  }) async {
    state = const AsyncValue.loading();

    try {
      final serviceAsync = ref.read(agentServiceProvider);
      final service = serviceAsync.value;
      if (service == null) {
        state = AsyncValue.error(
            'Agent service not initialized', StackTrace.current);
        return;
      }

      final result = await service.executeGoal(
        goal: goal,
        agentId: agentId,
        context: context,
        parameters: parameters,
      );

      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Cancel current execution
  Future<void> cancel() async {
    try {
      final serviceAsync = ref.read(agentServiceProvider);
      final service = serviceAsync.value;
      if (service != null) {
        await service.cancelExecution();
      }
      state = const AsyncValue.data(null);
    } catch (e) {
      // Ignore cancel errors
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for agent execution
final agentExecutionProvider =
    AsyncNotifierProvider<AgentExecutionNotifier, agent_types.AgentResult?>(
  AgentExecutionNotifier.new,
);

/// Async notifier for agent management
class AgentManagementNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {
      'agents': <String>[],
      'activeAgent': 'default',
      'status': 'initialized',
    };
  }

  /// Initialize agent management
  Future<void> initialize() async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(agentServiceProvider).value;
      if (service == null) return;
      final agents = service.listAgents();

      state = AsyncValue.data({
        'agents': agents,
        'activeAgent': 'default',
        'status': 'initialized',
      });
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create new agent
  Future<String> createAgent({
    String? name,
    String model = 'gpt-4',
    double temperature = 0.7,
    int maxSteps = 10,
    bool enableMemory = true,
    bool enableReasoning = true,
    List<String>? preferredTools,
  }) async {
    try {
      final service = ref.read(agentServiceProvider).value;
      if (service == null) return '';
      final agentId = await service.createAgent(
        name: name,
        model: model,
        temperature: temperature,
        maxSteps: maxSteps,
        enableMemory: enableMemory,
        enableReasoning: enableReasoning,
        preferredTools: preferredTools,
      );

      // Update state
      if (state case AsyncData(:final value)) {
        final currentState = Map<String, dynamic>.from(value);
        final agents = List<String>.from(currentState['agents'] ?? []);
        agents.add(agentId);

        state = AsyncValue.data({
          ...currentState,
          'agents': agents,
          'lastCreatedAgent': agentId,
        });
      }

      return agentId;
    } catch (e) {
      rethrow;
    }
  }

  /// Create specialized agent
  Future<String> createSpecializedAgent({
    required String specialization,
    String? model,
    List<String>? requiredTools,
  }) async {
    try {
      final service = ref.read(agentServiceProvider).value;
      if (service == null) return '';
      final agentId = await service.createSpecializedAgent(
        specialization: specialization,
        model: model,
        requiredTools: requiredTools,
      );

      // Update state
      if (state case AsyncData(:final value)) {
        final currentState = Map<String, dynamic>.from(value);
        final agents = List<String>.from(currentState['agents'] ?? []);
        agents.add(agentId);

        state = AsyncValue.data({
          ...currentState,
          'agents': agents,
          'lastCreatedAgent': agentId,
          'specialized_agents': {
            ...currentState['specialized_agents'] as Map<String, dynamic>? ??
                {},
            agentId: specialization,
          },
        });
      }

      return agentId;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove agent
  Future<void> removeAgent(String agentId) async {
    try {
      final service = ref.read(agentServiceProvider).value;
      if (service == null) return;
      await service.removeAgent(agentId);

      // Update state
      if (state case AsyncData(:final value)) {
        final currentState = Map<String, dynamic>.from(value);
        final agents = List<String>.from(currentState['agents'] ?? []);
        agents.remove(agentId);

        state = AsyncValue.data({
          ...currentState,
          'agents': agents,
          'lastRemovedAgent': agentId,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Set active agent
  void setActiveAgent(String agentId) {
    if (state case AsyncData(:final value)) {
      state = AsyncValue.data({
        ...value,
        'activeAgent': agentId,
      });
    }
  }

  /// Get agent statistics
  Future<Map<String, dynamic>> getAgentStatistics({String? agentId}) async {
    final service = ref.read(agentServiceProvider).value;
    if (service == null) return {};
    final memoryStats = service.getMemoryStatistics(agentId: agentId);
    final history = service.getExecutionHistory(agentId: agentId);

    return {
      'memory_statistics': memoryStats,
      'execution_count': history.length,
      'success_rate': history.isEmpty
          ? 0
          : history.where((e) => e.result.success).length / history.length,
      'average_steps': history.isEmpty
          ? 0
          : history.map((e) => e.result.steps.length).reduce((a, b) => a + b) /
              history.length,
    };
  }

  /// Search memories
  Future<List<agent_types.AgentMemoryEntry>> searchMemories({
    required String query,
    String? agentId,
    int limit = 10,
    List<agent_types.AgentMemoryType>? types,
  }) async {
    final service = ref.read(agentServiceProvider).value;
    if (service == null) return [];
    return await service.searchMemories(
      query: query,
      agentId: agentId,
      limit: limit,
      types: types,
    );
  }

  /// Add custom memory
  Future<void> addMemory({
    required agent_types.AgentMemoryType type,
    required String content,
    required Map<String, dynamic> metadata,
    String? agentId,
    double relevance = 1.0,
  }) async {
    final service = ref.read(agentServiceProvider).value;
    if (service == null) return;
    await service.addMemory(
      type: type,
      content: content,
      metadata: metadata,
      agentId: agentId,
      relevance: relevance,
    );
  }

  /// Execute collaborative task
  Future<Map<String, agent_types.AgentResult>> executeCollaborativeTask({
    required String goal,
    required List<String> agentIds,
    Map<String, dynamic>? sharedContext,
  }) async {
    final service = ref.read(agentServiceProvider).value;
    if (service == null) return {};
    return await service.executeCollaborativeTask(
      goal: goal,
      agentIds: agentIds,
      sharedContext: sharedContext,
    );
  }

  /// Refresh agent list
  Future<void> refresh() async {
    try {
      final service = ref.read(agentServiceProvider).value;
      if (service == null) return;
      final agents = service.listAgents();

      state = AsyncValue.data({
        ...state.asData?.value ?? {},
        'agents': agents,
        'status': 'refreshed',
      });
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for agent management
final agentManagementProvider =
    AsyncNotifierProvider<AgentManagementNotifier, Map<String, dynamic>>(
  AgentManagementNotifier.new,
);

/// Provider for real-time agent steps
final agentStepsProvider =
    StreamProvider.family<List<agent_types.AgentStep>, String>(
        (ref, agentId) async* {
  final service = ref.watch(agentServiceProvider).value;
  if (service == null) return;

  // Accumulate steps in a list and yield when available
  final steps = <agent_types.AgentStep>[];
  await for (final step in service.getStepStream(agentId: agentId)) {
    steps.add(step);
    yield steps;
  }
});

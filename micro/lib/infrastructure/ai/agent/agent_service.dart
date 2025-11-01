import 'package:langchain/langchain.dart' as langchain;
import 'agent_types.dart' as agent_types;
import 'autonomous_agent.dart';
import 'agent_memory.dart';

/// Service that manages autonomous agents
class AgentService {
  final Map<String, AutonomousAgentImpl> _agents = {};
  final Map<String, AgentMemorySystem> _memorySystems = {};
  // MCP bridges will be added when langchain_openai becomes available
  final Map<String, dynamic> _bridges = {};

  AgentService();

  /// Initialize agent service
  Future<void> initialize() async {
    // Create default memory system
    final defaultMemory = AgentMemorySystem();
    _memorySystems['default'] = defaultMemory;

    // Note: MCP bridge and tools will be integrated when langchain_openai is available
    // For now, create default agent without MCP tools

    // Create default agent
    final model = await _createDefaultModel();
    final tools = <langchain.Tool>[]; // Empty tools for now

    final defaultAgent = AutonomousAgentImpl(
      model: model,
      tools: tools,
      config: agent_types.AgentConfig(
        model: 'gpt-4',
        maxSteps: 10,
        enableMemory: true,
        enableReasoning: true,
      ),
      memory: defaultMemory,
    );

    _agents['default'] = defaultAgent;
  }

  /// Create an agent with custom configuration
  Future<String> createAgent({
    String? name,
    String model = 'gpt-4',
    double temperature = 0.7,
    int maxSteps = 10,
    bool enableMemory = true,
    bool enableReasoning = true,
    List<String>? preferredTools,
    String? memoryId,
  }) async {
    final agentId = name ?? _generateAgentId();

    // Get or create memory system
    final memorySystem =
        memoryId != null && _memorySystems.containsKey(memoryId)
            ? _memorySystems[memoryId]!
            : AgentMemorySystem();

    // Create model
    final chatModel = await _createModel(model, temperature);

    // Tools will be integrated when langchain_openai becomes available
    final tools = <langchain.Tool>[];
    final toolNames = preferredTools ?? <String>[];

    // Create agent
    final agent = AutonomousAgentImpl(
      model: chatModel,
      tools: tools,
      config: agent_types.AgentConfig(
        model: model,
        temperature: temperature,
        maxSteps: maxSteps,
        enableMemory: enableMemory,
        enableReasoning: enableReasoning,
        availableTools: toolNames,
      ),
      memory: memorySystem,
    );

    _agents[agentId] = agent;
    _memorySystems[agentId] = memorySystem;

    return agentId;
  }

  /// Execute a goal with an agent
  Future<agent_types.AgentResult> executeGoal({
    required String goal,
    String? agentId,
    String? context,
    Map<String, dynamic>? parameters,
  }) async {
    final agent = _getAgent(agentId ?? 'default');
    return await agent.execute(
      goal: goal,
      context: context,
      parameters: parameters,
    );
  }

  /// Get agent status
  agent_types.AgentStatus getAgentStatus({String? agentId}) {
    final agent = _getAgent(agentId ?? 'default');
    return agent.status;
  }

  /// Get agent execution history
  List<agent_types.AgentExecution> getExecutionHistory({String? agentId}) {
    final agent = _getAgent(agentId ?? 'default');
    return agent.executionHistory;
  }

  /// Cancel agent execution
  Future<void> cancelExecution({String? agentId}) async {
    final agent = _getAgent(agentId ?? 'default');
    await agent.cancel();
  }

  /// Get agent capabilities
  List<agent_types.AgentCapability> getAgentCapabilities({String? agentId}) {
    final agent = _getAgent(agentId ?? 'default');
    return agent.capabilities;
  }

  /// Get agent step stream for real-time monitoring
  Stream<agent_types.AgentStep> getStepStream({String? agentId}) {
    final agent = _getAgent(agentId ?? 'default');
    return agent.stepStream;
  }

  /// Get available tools
  Future<List<dynamic>> getAvailableTools({String? agentId}) async {
    // Tools integration pending when langchain_openai is available
    return <dynamic>[];
  }

  /// Get tools by category
  Future<Map<String, List<dynamic>>> getToolsByCategory(
      {String? agentId}) async {
    // Tools integration pending when langchain_openai is available
    return <String, List<dynamic>>{};
  }

  /// Search agent memories
  Future<List<agent_types.AgentMemoryEntry>> searchMemories({
    required String query,
    String? agentId,
    int limit = 10,
    List<agent_types.AgentMemoryType>? types,
  }) async {
    final memorySystem = agentId != null && _memorySystems.containsKey(agentId)
        ? _memorySystems[agentId]!
        : _memorySystems['default']!;

    return await memorySystem.findRelevantMemories(
      query,
      limit: limit,
      types: types,
    );
  }

  /// Get agent memory statistics
  Map<String, dynamic> getMemoryStatistics({String? agentId}) {
    final memorySystem = agentId != null && _memorySystems.containsKey(agentId)
        ? _memorySystems[agentId]!
        : _memorySystems['default']!;

    return memorySystem.getStatistics();
  }

  /// Add custom memory entry
  Future<void> addMemory({
    required agent_types.AgentMemoryType type,
    required String content,
    required Map<String, dynamic> metadata,
    String? agentId,
    double relevance = 1.0,
  }) async {
    final memorySystem = agentId != null && _memorySystems.containsKey(agentId)
        ? _memorySystems[agentId]!
        : _memorySystems['default']!;

    await memorySystem.addMemory(
      type: type,
      content: content,
      metadata: metadata,
      relevance: relevance,
    );
  }

  /// List all agents
  List<String> listAgents() => _agents.keys.toList();

  /// Remove an agent
  Future<void> removeAgent(String agentId) async {
    final agent = _agents[agentId];
    if (agent != null) {
      await agent.cancel();
      agent.dispose();
      _agents.remove(agentId);
      _memorySystems.remove(agentId);
    }
  }

  /// Create specialized agent for specific tasks
  Future<String> createSpecializedAgent({
    required String specialization,
    String? model,
    List<String>? requiredTools,
    agent_types.AgentConfig? customConfig,
  }) async {
    final agentId =
        'specialized_${specialization.toLowerCase().replaceAll(' ', '_')}';

    // Create specialized memory
    final memory = AgentMemorySystem(
      maxMemories: 500,
      relevanceThreshold: 0.3,
    );

    // Create specialized model
    final chatModel = await _createModel(model ?? 'gpt-4', 0.5);

    // Tools integration pending when langchain_openai is available
    final tools = <langchain.Tool>[];

    // Create specialized config
    final config = customConfig ??
        agent_types.AgentConfig(
          model: model ?? 'gpt-4',
          temperature: 0.5,
          maxSteps: 8,
          enableMemory: true,
          enableReasoning: true,
          customParameters: {
            'specialization': specialization,
            'focus_area': specialization,
          },
        );

    final agent = AutonomousAgentImpl(
      model: chatModel,
      tools: tools,
      config: config,
      memory: memory,
    );

    _agents[agentId] = agent;
    _memorySystems[agentId] = memory;

    // Add initial memory about specialization
    await memory.addMemory(
      type: agent_types.AgentMemoryType.semantic,
      content: 'Specialized agent for: $specialization',
      metadata: {
        'specialization': specialization,
        'created_at': DateTime.now().toIso8601String(),
        'agent_type': 'specialized',
      },
      relevance: 1.0,
    );

    return agentId;
  }

  /// Execute collaborative multi-agent task
  Future<Map<String, agent_types.AgentResult>> executeCollaborativeTask({
    required String goal,
    required List<String> agentIds,
    Map<String, dynamic>? sharedContext,
  }) async {
    final results = <String, agent_types.AgentResult>{};

    for (final agentId in agentIds) {
      if (_agents.containsKey(agentId)) {
        final agent = _agents[agentId]!;

        // Add collaborative context
        final context = sharedContext != null
            ? 'Collaborative context: ${sharedContext.toString()}'
            : null;

        try {
          final result = await agent.execute(
            goal: goal,
            context: context,
            parameters: {
              'collaborative_mode': true,
              'participant_agents': agentIds,
            },
          );

          results[agentId] = result;

          // Share results with other agents
          if (sharedContext != null) {
            sharedContext[agentId] = {
              'result': result.result,
              'success': result.success,
              'steps_count': result.steps.length,
            };
          }
        } catch (e) {
          results[agentId] = agent_types.AgentResult(
            result: 'Collaborative execution failed: ${e.toString()}',
            success: false,
            steps: [],
            error: e.toString(),
          );
        }
      }
    }

    return results;
  }

  /// Get agent by ID
  AutonomousAgentImpl _getAgent(String agentId) {
    final agent = _agents[agentId];
    if (agent == null) {
      throw Exception('Agent not found: $agentId');
    }
    return agent;
  }

  /// Create default chat model
  Future<langchain.BaseChatModel> _createDefaultModel() async {
    return await _createModel('gpt-4', 0.7);
  }

  /// Create chat model with specified parameters
  /// NOTE: This currently returns a placeholder and needs langchain_openai package
  /// to be added to pubspec.yaml for actual functionality
  Future<langchain.BaseChatModel> _createModel(
      String model, double temperature) async {
    throw UnimplementedError(
        'Chat model creation requires langchain_openai package. '
        'Please add langchain_openai to pubspec.yaml dependencies.');
  }

  /// Generate unique agent ID
  String _generateAgentId() {
    return 'agent_${DateTime.now().millisecondsSinceEpoch}_${_agents.length}';
  }

  /// Shutdown service and cleanup
  Future<void> shutdown() async {
    for (final agent in _agents.values) {
      await agent.cancel();
      agent.dispose();
    }

    _agents.clear();
    _memorySystems.clear();
    _bridges.clear();
  }
}

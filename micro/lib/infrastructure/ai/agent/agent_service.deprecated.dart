import 'package:langchain/langchain.dart' as langchain;
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'agent_types.dart' as agent_types;
import 'autonomous_agent.dart';
import 'agent_memory.dart';
import '../mcp/mcp_service.dart';
import 'mcp_tool_adapter.dart';
import 'swarm/swarm_orchestrator.dart';
import 'tools/tool_registry.dart';
import 'tools/mock_tools.dart';
import '../swarm_settings_service.dart';
import 'plan_execute_agent.dart';

/// Service that manages autonomous agents with MCP tool integration
class AgentService {
  final Map<String, AutonomousAgentImpl> _agents = {};
  final Map<String, AgentMemorySystem> _memorySystems = {};
  final MCPService? _mcpService;
  final MCPToolFactory? _toolFactory;
  final ToolRegistry _toolRegistry = ToolRegistry();
  final SwarmSettingsService _swarmSettings = SwarmSettingsService();

  AgentService({MCPService? mcpService})
      : _mcpService = mcpService,
        _toolFactory = mcpService != null ? MCPToolFactory(mcpService) : null;

  /// Initialize agent service
  Future<void> initialize() async {
    // Register mock tools for swarm
    for (final tool in getAllMockTools()) {
      _toolRegistry.register(tool);
    }
    print(
        'AgentService: Registered ${_toolRegistry.toolCount} mock tools for swarm');

    // Initialize tool factory if available
    if (_toolFactory != null) {
      await _toolFactory!.initialize();
      print('AgentService: Tool factory initialized');
    }

    // Create default memory system
    final defaultMemory = AgentMemorySystem();
    _memorySystems['default'] = defaultMemory;

    // Get tools (built-in + MCP)
    final tools = _toolFactory != null
        ? await _toolFactory!.getAllTools()
        : <langchain.Tool>[];

    print('AgentService: Loaded ${tools.length} tools for default agent');

    // Create default agent
    final model = await _createDefaultModel();

    final defaultAgent = AutonomousAgentImpl(
      model: model,
      tools: tools,
      config: agent_types.AgentConfig(
        model: 'gpt-4',
        maxSteps: 10,
        enableMemory: true,
        enableReasoning: true,
        availableTools: tools.map((t) => t.name).toList(),
      ),
      memory: defaultMemory,
    );

    _agents['default'] = defaultAgent;
    print('AgentService: Default agent created with ${tools.length} tools');
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
    List<String>? mcpServerIds,
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

    // Get MCP tools if available
    final tools = await _getTools(
      serverIds: mcpServerIds,
      toolNames: preferredTools,
    );

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
        availableTools: tools.map((t) => t.name).toList(),
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
    if (_toolFactory == null) {
      return <dynamic>[];
    }

    try {
      final tools = await _toolFactory!.getAllTools();
      return tools
          .map((tool) => {
                'name': tool.name,
                'description': tool.description,
              })
          .toList();
    } catch (e) {
      print('Error getting available tools: $e');
      return <dynamic>[];
    }
  }

  /// Get tools by category
  Future<Map<String, List<dynamic>>> getToolsByCategory(
      {String? agentId}) async {
    if (_mcpService == null) {
      return <String, List<dynamic>>{};
    }

    try {
      final categorized = <String, List<dynamic>>{};

      for (final serverId in _mcpService!.getAllServerIds()) {
        final tools = _mcpService!.getServerTools(serverId);
        final serverConfig = _mcpService!.getServerConfig(serverId);

        categorized[serverConfig?.name ?? serverId] = tools
            .map((tool) => {
                  'name': tool.name,
                  'description': tool.description,
                  'server': serverId,
                })
            .toList();
      }

      return categorized;
    } catch (e) {
      print('Error getting tools by category: $e');
      return <String, List<dynamic>>{};
    }
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
    List<String>? mcpServerIds,
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

    // Get MCP tools
    final tools = await _getTools(
      serverIds: mcpServerIds,
      toolNames: requiredTools,
    );

    // Create specialized config
    final config = customConfig ??
        agent_types.AgentConfig(
          model: model ?? 'gpt-4',
          temperature: 0.5,
          maxSteps: 8,
          enableMemory: true,
          enableReasoning: true,
          availableTools: tools.map((t) => t.name).toList(),
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
  Future<langchain.BaseChatModel> _createModel(
      String model, double temperature) async {
    // Support multiple providers based on model name
    if (model.contains('gpt')) {
      return ChatOpenAI(
        apiKey: '', // Will be set from provider config
        defaultOptions: ChatOpenAIOptions(
          model: model,
          temperature: temperature,
        ),
      );
    } else if (model.contains('gemini')) {
      return ChatGoogleGenerativeAI(
        apiKey: '', // Will be set from provider config
        defaultOptions: ChatGoogleGenerativeAIOptions(
          model: model,
          temperature: temperature,
        ),
      );
    } else if (model.contains('claude')) {
      return ChatAnthropic(
        apiKey: '', // Will be set from provider config
        defaultOptions: ChatAnthropicOptions(
          model: model,
          temperature: temperature,
        ),
      );
    } else {
      // Default to OpenAI compatible
      return ChatOpenAI(
        apiKey: '',
        defaultOptions: ChatOpenAIOptions(
          model: model,
          temperature: temperature,
        ),
      );
    }
  }

  /// Get tools based on server IDs or tool names
  Future<List<langchain.Tool>> _getTools({
    List<String>? serverIds,
    List<String>? toolNames,
  }) async {
    if (_toolFactory == null) {
      return <langchain.Tool>[];
    }

    try {
      if (serverIds != null && serverIds.isNotEmpty) {
        // Get tools from specific servers
        return await _toolFactory!.getEnabledTools(serverIds);
      } else if (toolNames != null && toolNames.isNotEmpty) {
        // Get specific tools by name
        return await _toolFactory!.getToolsByName(toolNames);
      } else {
        // Get all available tools
        return await _toolFactory!.getAllTools();
      }
    } catch (e) {
      print('Error getting tools: $e');
      return <langchain.Tool>[];
    }
  }

  /// Generate unique agent ID
  String _generateAgentId() {
    return 'agent_${DateTime.now().millisecondsSinceEpoch}_${_agents.length}';
  }

  /// Execute a goal using swarm intelligence
  Future<SwarmResult> executeSwarmGoal({
    required String goal,
    required langchain.BaseChatModel languageModel,
    Map<String, dynamic>? context,
    List<String>? constraints,
    int? maxSpecialists,
  }) async {
    print('AgentService: Executing swarm goal');

    // Wrap BaseChatModel in a LanguageModel adapter
    final wrappedModel = _ChatModelAdapter(languageModel);

    final orchestrator = SwarmOrchestrator(
      languageModel: wrappedModel,
      toolRegistry: _toolRegistry,
      maxSpecialists: maxSpecialists,
      useTOONCompression: true,
    );

    final result = await orchestrator.execute(
      goal,
      context: context,
      constraints: constraints,
    );

    print(
        'AgentService: Swarm execution completed - ${result.totalSpecialistsUsed} specialists used');
    return result;
  }

  /// Get swarm settings
  Future<int> getMaxSpecialists() async {
    return await _swarmSettings.getMaxSpecialists();
  }

  /// Set swarm settings
  Future<void> setMaxSpecialists(int value) async {
    await _swarmSettings.setMaxSpecialists(value);
  }

  /// Shutdown service and cleanup
  Future<void> shutdown() async {
    for (final agent in _agents.values) {
      await agent.cancel();
      agent.dispose();
    }

    _agents.clear();
    _memorySystems.clear();
    _toolRegistry.clear();
  }
}

/// Adapter to wrap langchain.BaseChatModel as LanguageModel
class _ChatModelAdapter implements LanguageModel {
  final langchain.BaseChatModel _chatModel;

  _ChatModelAdapter(this._chatModel);

  @override
  Future<dynamic> invoke(String input) async {
    final message = langchain.ChatMessage.human(
      langchain.ChatMessageContent.text(input),
    );
    final response = await _chatModel.invoke(
      langchain.PromptValue.chat([message]),
    );
    return response.output.content;
  }
}

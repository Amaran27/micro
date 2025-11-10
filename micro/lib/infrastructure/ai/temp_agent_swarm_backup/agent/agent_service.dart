import 'dart:async';
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart' as lc_community;
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'agent_types.dart' as agent_types;
import 'agent_memory.dart';
import '../mcp/mcp_service.dart';
import 'mcp_tool_adapter.dart';
import 'swarm/swarm_orchestrator.dart';
import 'tools/tool_registry.dart';
import '../../../features/swarm/tools/mobile_tools_simple.dart';
import '../swarm_settings_service.dart';
import 'plan_execute_agent.dart' show LanguageModel;

/// Refactored AgentService using LangChain's built-in ToolsAgent + AgentExecutor
///
/// This replaces custom PlanExecuteAgent and AutonomousAgentImpl with
/// the official LangChain agent implementation pattern.
class AgentService {
  final Map<String, _LangChainAgentWrapper> _agents = {};
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
    // Register real mobile tools for swarm
    final mobileTools = [
      CameraTool(),
      ContactsTool(),
      SmsTool(),
      PhoneTool(),
      GpsTool(),
      DeviceInfoTool(),
      BatteryTool(),
      AppLauncherTool(),
      NotificationTool(),
      CalendarTool(),
    ];
    for (final tool in mobileTools) {
      _toolRegistry.register(tool);
    }
    print(
        'AgentService: Registered ${_toolRegistry.toolCount} real mobile tools for swarm');

    // Initialize tool factory if available
    if (_toolFactory != null) {
      await _toolFactory.initialize();
      print('AgentService: Tool factory initialized');
    }

    // Create default memory system
    final defaultMemory = AgentMemorySystem();
    _memorySystems['default'] = defaultMemory;

    // Get tools (built-in + MCP)
    final tools = await _getAllLangChainTools();

    print('AgentService: Loaded ${tools.length} tools for default agent');

    // Create default agent using LangChain's ToolsAgent
    final model = await _createDefaultModel();

    final agent = ToolsAgent.fromLLMAndTools(
      llm: model,
      tools: tools,
      memory: ConversationBufferMemory(returnMessages: true),
    );

    final executor = AgentExecutor(
      agent: agent,
      maxIterations: 10,
      returnIntermediateSteps: true,
    );

    _agents['default'] = _LangChainAgentWrapper(
      agent: agent,
      executor: executor,
      model: model,
      tools: tools,
      memory: defaultMemory,
      config: agent_types.AgentConfig(
        model: 'gpt-4',
        maxSteps: 10,
        enableMemory: true,
        enableReasoning: true,
        availableTools: tools.map((t) => t.name).toList(),
      ),
    );

    print(
        'AgentService: Default LangChain agent created with ${tools.length} tools');
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

    // Get tools
    final tools = await _getFilteredTools(
      serverIds: mcpServerIds,
      toolNames: preferredTools,
    );

    // Create LangChain agent
    final memory =
        enableMemory ? ConversationBufferMemory(returnMessages: true) : null;

    final agent = ToolsAgent.fromLLMAndTools(
      llm: chatModel,
      tools: tools,
      memory: memory,
    );

    final executor = AgentExecutor(
      agent: agent,
      maxIterations: maxSteps,
      returnIntermediateSteps: true,
    );

    _agents[agentId] = _LangChainAgentWrapper(
      agent: agent,
      executor: executor,
      model: chatModel,
      tools: tools,
      memory: memorySystem,
      config: agent_types.AgentConfig(
        model: model,
        temperature: temperature,
        maxSteps: maxSteps,
        enableMemory: enableMemory,
        enableReasoning: enableReasoning,
        availableTools: tools.map((t) => t.name).toList(),
      ),
    );

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
    final wrapper = _getAgentWrapper(agentId ?? 'default');

    try {
      wrapper.setStatus(agent_types.AgentStatus.executing);

      final startTime = DateTime.now();
      final steps = <agent_types.AgentStep>[];

      // Execute using AgentExecutor
      final input = context != null ? '$goal\nContext: $context' : goal;
      final ChainValues result =
          await wrapper.executor.run(input) as ChainValues;

      // Extract steps from intermediate results if available
      final intermediateSteps = wrapper.executor.returnIntermediateSteps &&
              result.containsKey('intermediate_steps')
          ? (result['intermediate_steps'] as List<dynamic>?) ?? []
          : <dynamic>[];

      // Convert LangChain steps to our format
      for (var i = 0; i < intermediateSteps.length; i++) {
        final step = intermediateSteps[i];
        steps.add(agent_types.AgentStep(
          stepId: 'step_$i',
          description: step.action.log ?? 'Tool: ${step.action.tool}',
          type: agent_types.AgentStepType.toolExecution,
          timestamp: DateTime.now(),
          duration: Duration.zero,
          output: {'result': step.observation},
          input: step.action.toolInput as Map<String, dynamic>?,
        ));
      }

      final endTime = DateTime.now();
      wrapper.setStatus(agent_types.AgentStatus.idle);

      // Save to memory
      await wrapper.memory.addMemory(
        type: agent_types.AgentMemoryType.episodic,
        content: 'Goal: $goal\nResult: ${result.toString()}',
        metadata: {
          'goal': goal,
          'result': result.toString(),
          'steps_count': steps.length,
          'duration_ms': endTime.difference(startTime).inMilliseconds,
        },
        relevance: 1.0,
      );

      final outputString = (result['output'] as String?) ?? result.toString();

      return agent_types.AgentResult(
        result: outputString,
        success: true,
        steps: steps,
        metadata: {
          'reasoning': 'Executed using LangChain ToolsAgent',
          'toolsUsed': steps
              .where((s) => s.type == agent_types.AgentStepType.toolExecution)
              .map((s) => s.input?['tool'] as String? ?? 'unknown')
              .toSet()
              .toList(),
        },
      );
    } catch (e) {
      wrapper.setStatus(agent_types.AgentStatus.failed);

      return agent_types.AgentResult(
        result: 'Execution failed',
        success: false,
        steps: [],
        error: e.toString(),
      );
    }
  }

  /// Get agent status
  agent_types.AgentStatus getAgentStatus({String? agentId}) {
    final wrapper = _getAgentWrapper(agentId ?? 'default');
    return wrapper.status;
  }

  /// Get agent execution history
  List<agent_types.AgentExecution> getExecutionHistory({String? agentId}) {
    final wrapper = _getAgentWrapper(agentId ?? 'default');
    return wrapper.executionHistory;
  }

  /// Cancel agent execution
  Future<void> cancelExecution({String? agentId}) async {
    final wrapper = _getAgentWrapper(agentId ?? 'default');
    wrapper.setStatus(agent_types.AgentStatus.idle);
  }

  /// Get agent capabilities
  List<agent_types.AgentCapability> getAgentCapabilities({String? agentId}) {
    final wrapper = _getAgentWrapper(agentId ?? 'default');
    return [
      agent_types.AgentCapability(
        name: 'Tool Calling',
        description: 'Execute tools via LangChain ToolsAgent',
        inputTypes: ['string'],
        outputTypes: ['string'],
        parameters: {'enabled': true},
      ),
      agent_types.AgentCapability(
        name: 'Memory',
        description: 'Conversation buffer memory',
        inputTypes: ['string'],
        outputTypes: ['string'],
        parameters: {'enabled': wrapper.config.enableMemory},
      ),
      agent_types.AgentCapability(
        name: 'Multi-step Reasoning',
        description: 'Plan and execute complex tasks',
        inputTypes: ['string'],
        outputTypes: ['string'],
        parameters: {'enabled': wrapper.config.enableReasoning},
      ),
    ];
  }

  /// Get agent step stream for real-time monitoring
  Stream<agent_types.AgentStep> getStepStream({String? agentId}) {
    final wrapper = _getAgentWrapper(agentId ?? 'default');
    return wrapper.stepStream;
  }

  /// Get available tools
  Future<List<dynamic>> getAvailableTools({String? agentId}) async {
    if (_toolFactory == null) {
      return <dynamic>[];
    }

    try {
      final tools = await _toolFactory.getAllTools();
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
    _agents.remove(agentId);
    _memorySystems.remove(agentId);
  }

  /// Get tools by category (for compatibility)
  Future<Map<String, List<dynamic>>> getToolsByCategory(
      {String? agentId}) async {
    final categorized = <String, List<dynamic>>{};
    final tools = await getAvailableTools(agentId: agentId);
    categorized['general'] = tools;
    return categorized;
  }

  /// Create specialized agent (for compatibility)
  Future<String> createSpecializedAgent({
    required String specialization,
    String? model,
    List<String>? requiredTools,
  }) async {
    return await createAgent(
      name: 'specialized_$specialization',
      model: model ?? 'gpt-4',
      preferredTools: requiredTools,
    );
  }

  /// Execute collaborative task (for compatibility)
  Future<Map<String, agent_types.AgentResult>> executeCollaborativeTask({
    required String goal,
    required List<String> agentIds,
  }) async {
    final results = <String, agent_types.AgentResult>{};
    for (final agentId in agentIds) {
      try {
        final result = await executeGoal(goal: goal, agentId: agentId);
        results[agentId] = result;
      } catch (e) {
        results[agentId] = agent_types.AgentResult(
          result: '',
          success: false,
          steps: [],
          error: e.toString(),
        );
      }
    }
    return results;
  }

  /// Execute a goal using swarm intelligence
  Future<SwarmResult> executeSwarmGoal({
    required String goal,
    BaseChatModel? languageModel,
    Map<String, dynamic>? context,
    List<String>? constraints,
    int? maxSpecialists,
  }) async {
    print('AgentService: Executing swarm goal with LangChain agents');

    final model = languageModel ?? await _createDefaultModel();
    final wrappedModel = _ChatModelAdapter(model);

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

  // Helper properties for tests
  bool get hasDefaultAgent => _agents.containsKey('default');
  int get agentCount => _agents.length;
  bool get mcpToolsAvailable => _toolFactory != null;
  int get toolCount => _toolRegistry.toolCount;

  _LangChainAgentWrapper? getAgent(String agentId) => _agents[agentId];

  /// Get agent wrapper by ID
  _LangChainAgentWrapper _getAgentWrapper(String agentId) {
    final wrapper = _agents[agentId];
    if (wrapper == null) {
      throw Exception('Agent not found: $agentId');
    }
    return wrapper;
  }

  /// Create default chat model
  Future<BaseChatModel> _createDefaultModel() async {
    return await _createModel('gpt-4', 0.7);
  }

  /// Create chat model with specified parameters
  Future<BaseChatModel> _createModel(String model, double temperature) async {
    // Support multiple providers based on model name
    if (model.contains('gpt') || model.contains('o1')) {
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

  /// Get all LangChain tools (built-in + MCP wrapped)
  Future<List<Tool>> _getAllLangChainTools() async {
    final tools = <Tool>[
      lc_community.CalculatorTool(), // Built-in LangChain tool
    ];

    // Add MCP tools if available
    if (_toolFactory != null) {
      try {
        final mcpTools = await _toolFactory.getAllTools();
        tools.addAll(mcpTools);
      } catch (e) {
        print('Error loading MCP tools: $e');
      }
    }

    return tools;
  }

  /// Get filtered tools based on criteria
  Future<List<Tool>> _getFilteredTools({
    List<String>? serverIds,
    List<String>? toolNames,
  }) async {
    final allTools = await _getAllLangChainTools();

    if (toolNames != null && toolNames.isNotEmpty) {
      return allTools.where((tool) => toolNames.contains(tool.name)).toList();
    }

    return allTools;
  }

  /// Generate unique agent ID
  String _generateAgentId() {
    return 'agent_${DateTime.now().millisecondsSinceEpoch}_${_agents.length}';
  }

  /// Shutdown service and cleanup
  Future<void> shutdown() async {
    _agents.clear();
    _memorySystems.clear();
    _toolRegistry.clear();
  }
}

/// Wrapper around LangChain's ToolsAgent + AgentExecutor
class _LangChainAgentWrapper {
  final ToolsAgent agent;
  final AgentExecutor executor;
  final BaseChatModel model;
  final List<Tool> tools;
  final AgentMemorySystem memory;
  final agent_types.AgentConfig config;

  agent_types.AgentStatus _status = agent_types.AgentStatus.idle;
  final List<agent_types.AgentExecution> _executionHistory = [];
  final _stepController = StreamController<agent_types.AgentStep>.broadcast();

  _LangChainAgentWrapper({
    required this.agent,
    required this.executor,
    required this.model,
    required this.tools,
    required this.memory,
    required this.config,
  });

  agent_types.AgentStatus get status => _status;
  List<agent_types.AgentExecution> get executionHistory => _executionHistory;
  Stream<agent_types.AgentStep> get stepStream => _stepController.stream;

  void setStatus(agent_types.AgentStatus newStatus) {
    _status = newStatus;
  }

  void dispose() {
    _stepController.close();
  }
}

/// Adapter to wrap BaseChatModel as LanguageModel for swarm
class _ChatModelAdapter implements LanguageModel {
  final BaseChatModel _chatModel;

  _ChatModelAdapter(this._chatModel);

  @override
  Future<dynamic> invoke(String input) async {
    final message = ChatMessage.human(
      ChatMessageContent.text(input),
    );
    final response = await _chatModel.invoke(
      PromptValue.chat([message]),
    );
    return response.output.content;
  }
}

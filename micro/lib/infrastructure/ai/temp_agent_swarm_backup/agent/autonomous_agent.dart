import 'dart:async';
import 'dart:math';
import 'package:langchain/langchain.dart' as langchain;
import 'agent_types.dart' as agent_types;
import 'agent_memory.dart';

/// Main autonomous agent implementation
class AutonomousAgentImpl implements agent_types.AutonomousAgent {
  final langchain.BaseChatModel _model;
  final List<langchain.Tool> _tools;
  final agent_types.AgentConfig _config;
  final AgentMemorySystem _memory;

  agent_types.AgentStatus _status = agent_types.AgentStatus.idle;
  final List<agent_types.AgentExecution> _executionHistory = [];
  final StreamController<agent_types.AgentStep> _stepStream =
      StreamController.broadcast();
  final List<agent_types.ToolExecutionRequest> _pendingRequests = [];

  AutonomousAgentImpl({
    required langchain.BaseChatModel model,
    required List<langchain.Tool> tools,
    required agent_types.AgentConfig config,
    required AgentMemorySystem memory,
  })  : _model = model,
        _tools = tools,
        _config = config,
        _memory = memory;

  @override
  Future<agent_types.AgentResult> execute({
    required String goal,
    String? context,
    Map<String, dynamic>? parameters,
  }) async {
    final executionId = _generateExecutionId();
    final startTime = DateTime.now();
    _status = agent_types.AgentStatus.planning;

    final steps = <agent_types.AgentStep>[];

    try {
      // Step 1: Plan the approach
      _stepStream.add(agent_types.AgentStep(
        stepId: _generateStepId(),
        description: 'Planning approach for goal: $goal',
        type: agent_types.AgentStepType.planning,
        timestamp: DateTime.now(),
        duration: Duration.zero,
        input: {'goal': goal, 'context': context},
      ));

      final plan = await _createPlan(goal, context);
      steps.add(plan);

      // Step 2: Execute the plan
      _status = agent_types.AgentStatus.executing;
      final executionSteps = await _executePlan(plan, goal);
      steps.addAll(executionSteps);

      // Step 3: Reflect and finalize
      _status = agent_types.AgentStatus.reasoning;
      final reflection = await _reflectOnExecution(goal, steps);
      steps.add(reflection);

      // Store in memory if enabled
      if (_config.enableMemory) {
        await _memory.storeExecution(
          executionId: executionId,
          goal: goal,
          steps: steps,
          result: reflection.output?['result'] ?? 'Task completed',
        );
      }

      final result = agent_types.AgentResult(
        result: reflection.output?['result'] ?? 'Task completed',
        success: true,
        steps: steps,
        metadata: {
          'executionId': executionId,
          'totalDuration': DateTime.now().difference(startTime),
          'stepsCount': steps.length,
        },
      );

      _executionHistory.add(agent_types.AgentExecution(
        executionId: executionId,
        goal: goal,
        result: result,
        startTime: startTime,
        endTime: DateTime.now(),
        status: agent_types.AgentStatus.completed,
      ));

      _status = agent_types.AgentStatus.idle;
      return result;
    } catch (e, stackTrace) {
      _status = agent_types.AgentStatus.failed;

      final errorStep = agent_types.AgentStep(
        stepId: _generateStepId(),
        description: 'Execution failed: ${e.toString()}',
        type: agent_types.AgentStepType.errorRecovery,
        timestamp: DateTime.now(),
        duration: Duration.zero,
        error: e.toString(),
        input: {'goal': goal, 'stackTrace': stackTrace.toString()},
      );

      steps.add(errorStep);

      final result = agent_types.AgentResult(
        result: 'Execution failed: ${e.toString()}',
        success: false,
        steps: steps,
        error: e.toString(),
        metadata: {
          'executionId': executionId,
          'totalDuration': DateTime.now().difference(startTime),
          'error': e.toString(),
        },
      );

      _executionHistory.add(agent_types.AgentExecution(
        executionId: executionId,
        goal: goal,
        result: result,
        startTime: startTime,
        endTime: DateTime.now(),
        status: agent_types.AgentStatus.failed,
      ));

      _status = agent_types.AgentStatus.idle;
      return result;
    }
  }

  @override
  agent_types.AgentStatus get status => _status;

  @override
  List<agent_types.AgentExecution> get executionHistory =>
      List.unmodifiable(_executionHistory);

  @override
  Future<void> cancel() async {
    if (_status != agent_types.AgentStatus.idle &&
        _status != agent_types.AgentStatus.completed) {
      _status = agent_types.AgentStatus.cancelled;
      // Clear pending requests
      _pendingRequests.clear();
    }
  }

  @override
  List<agent_types.AgentCapability> get capabilities => [
        agent_types.AgentCapability(
          name: 'planning',
          description: 'Can plan complex multi-step tasks',
        ),
        agent_types.AgentCapability(
          name: 'reasoning',
          description: 'Can reason about problems and solutions',
        ),
        agent_types.AgentCapability(
          name: 'tool_execution',
          description: 'Can execute various tools to accomplish tasks',
          parameters: {
            'availableTools': _tools.map((t) => t.name).toList(),
          },
        ),
        agent_types.AgentCapability(
          name: 'memory',
          description: 'Can remember and learn from past executions',
          parameters: {
            'memoryEnabled': _config.enableMemory,
            'memoryTypes': [
              agent_types.AgentMemoryType.conversation.name,
              agent_types.AgentMemoryType.episodic.name,
            ],
          },
        ),
      ];

  /// Stream of agent steps for real-time monitoring
  Stream<agent_types.AgentStep> get stepStream => _stepStream.stream;

  /// Create a plan for the given goal
  Future<agent_types.AgentStep> _createPlan(
      String goal, String? context) async {
    final prompt = langchain.ChatPromptTemplate.fromTemplates([
      (langchain.ChatMessageType.system, _getPlanningPrompt()),
      (
        langchain.ChatMessageType.human,
        'Goal: $goal\n\nContext: ${context ?? "No additional context provided"}'
      ),
    ]);

    final chain = prompt
        .pipe(_model)
        .pipe(const langchain.StringOutputParser<langchain.ChatResult>());
    final planResult = await chain.invoke({});

    return agent_types.AgentStep(
      stepId: _generateStepId(),
      description: 'Created execution plan',
      type: agent_types.AgentStepType.planning,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 2),
      input: {'goal': goal, 'context': context},
      output: {'plan': planResult},
    );
  }

  /// Execute the plan
  Future<List<agent_types.AgentStep>> _executePlan(
      agent_types.AgentStep planStep, String goal) async {
    final steps = <agent_types.AgentStep>[];
    final plan = planStep.output?['plan'] as String? ?? '';

    // Parse plan into actionable steps
    final actionItems = _parsePlanActions(plan);

    for (final action in actionItems) {
      if (_status != agent_types.AgentStatus.executing) break;

      final step = await _executeAction(action, goal);
      steps.add(step);

      // Emit step for real-time monitoring
      _stepStream.add(step);

      // Add delay between steps for stability
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return steps;
  }

  /// Execute a single action
  Future<agent_types.AgentStep> _executeAction(
      Map<String, dynamic> action, String goal) async {
    final startTime = DateTime.now();
    final actionType = action['type'] as String;

    try {
      switch (actionType) {
        case 'tool':
          final toolName = action['tool'] as String;
          final parameters = action['parameters'] as Map<String, dynamic>;

          final toolResult = await _executeTool(toolName, parameters);

          return agent_types.AgentStep(
            stepId: _generateStepId(),
            description: 'Executed tool: $toolName',
            type: agent_types.AgentStepType.toolExecution,
            timestamp: DateTime.now(),
            duration: DateTime.now().difference(startTime),
            input: {'tool': toolName, 'parameters': parameters},
            output: {'result': toolResult},
          );

        case 'reasoning':
          final reasoningPrompt = action['prompt'] as String;

          final reasoning = await _performReasoning(reasoningPrompt, goal);

          return agent_types.AgentStep(
            stepId: _generateStepId(),
            description: 'Performed reasoning step',
            type: agent_types.AgentStepType.reasoning,
            timestamp: DateTime.now(),
            duration: DateTime.now().difference(startTime),
            input: {'prompt': reasoningPrompt},
            output: {'reasoning': reasoning},
          );

        default:
          return agent_types.AgentStep(
            stepId: _generateStepId(),
            description: 'Unknown action type: $actionType',
            type: agent_types.AgentStepType.errorRecovery,
            timestamp: DateTime.now(),
            duration: DateTime.now().difference(startTime),
            error: 'Unknown action type: $actionType',
            input: action,
          );
      }
    } catch (e) {
      return agent_types.AgentStep(
        stepId: _generateStepId(),
        description: 'Action execution failed: ${e.toString()}',
        type: agent_types.AgentStepType.errorRecovery,
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
        input: action,
      );
    }
  }

  /// Execute a tool
  Future<dynamic> _executeTool(
      String toolName, Map<String, dynamic> parameters) async {
    // For now, return a placeholder result
    // TODO: Implement proper tool execution through MCP bridge
    return {
      'success': true,
      'result': 'Tool $toolName executed with parameters: $parameters',
    };
  }

  /// Perform reasoning
  Future<String> _performReasoning(String prompt, String goal) async {
    final reasoningPrompt = langchain.ChatPromptTemplate.fromTemplates([
      (
        langchain.ChatMessageType.system,
        'You are a reasoning assistant. Analyze the following and provide logical reasoning.'
      ),
      (
        langchain.ChatMessageType.human,
        'Goal: $goal\n\nReasoning prompt: $prompt'
      ),
    ]);

    final chain = reasoningPrompt
        .pipe(_model)
        .pipe(const langchain.StringOutputParser<langchain.ChatResult>());
    return (await chain.invoke({})).toString();
  }

  /// Reflect on execution results
  Future<agent_types.AgentStep> _reflectOnExecution(
      String goal, List<agent_types.AgentStep> steps) async {
    final startTime = DateTime.now();

    // Get relevant memories if enabled
    String memoryContext = '';
    if (_config.enableMemory) {
      memoryContext = await _memory.getRelevantContext(goal);
    }

    final executionSummary = steps
        .where((s) =>
            s.type != agent_types.AgentStepType.planning &&
            s.type != agent_types.AgentStepType.reflection)
        .map((s) =>
            '${s.description}: ${s.output?['result'] ?? s.error ?? 'No output'}')
        .join('\n');

    final reflectionPrompt = langchain.ChatPromptTemplate.fromTemplates([
      (langchain.ChatMessageType.system, _getReflectionPrompt()),
      (
        langchain.ChatMessageType.human,
        '''
Goal: $goal
Execution Summary:
$executionSummary

Memory Context:
$memoryContext

Provide a final reflection on the execution and the result.'''
      ),
    ]);

    final chain = reflectionPrompt
        .pipe(_model)
        .pipe(const langchain.StringOutputParser<langchain.ChatResult>());
    final reflection = await chain.invoke({});

    return agent_types.AgentStep(
      stepId: _generateStepId(),
      description: 'Final reflection on execution',
      type: agent_types.AgentStepType.reflection,
      timestamp: DateTime.now(),
      duration: DateTime.now().difference(startTime),
      input: {'goal': goal, 'executionSummary': executionSummary},
      output: {'result': reflection},
    );
  }

  /// Parse plan into actionable items
  List<Map<String, dynamic>> _parsePlanActions(String plan) {
    // Simple parsing for now - can be enhanced with more sophisticated parsing
    final actions = <Map<String, dynamic>>[];
    final lines = plan.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- Tool:')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          final toolName = parts[1].trim();
          actions.add({
            'type': 'tool',
            'tool': toolName,
            'parameters': {}, // Default empty parameters
          });
        }
      } else if (trimmed.startsWith('- Reasoning:')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          final reasoningPrompt = parts.sublist(1).join(':').trim();
          actions.add({
            'type': 'reasoning',
            'prompt': reasoningPrompt,
          });
        }
      }
    }

    return actions;
  }

  /// Get planning system prompt
  String _getPlanningPrompt() {
    return '''
You are an autonomous agent planner. Given a goal, create a step-by-step plan to accomplish it.

Available tools:
${_tools.map((t) => '- ${t.name}: ${t.description}').join('\n')}

For each step, use one of these formats:
- Tool: [tool_name] - Execute the specified tool
- Reasoning: [prompt] - Perform reasoning about the problem

Create a detailed plan with up to ${_config.maxSteps} steps. Be specific about what each step should accomplish.
''';
  }

  /// Get reflection system prompt
  String _getReflectionPrompt() {
    return '''
You are an autonomous agent reflection engine. Review the execution and provide:
1. A summary of what was accomplished
2. Any insights or learnings from the execution
3. The final result or conclusion

Be concise but thorough in your reflection.
''';
  }

  /// Generate unique execution ID
  String _generateExecutionId() {
    return 'exec_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Generate unique step ID
  String _generateStepId() {
    return 'step_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Dispose resources
  void dispose() {
    _stepStream.close();
  }
}

import 'package:logger/logger.dart';

import 'models/agent_models.dart';
import 'plan_execute_agent.dart';
import 'tools/tool_registry.dart';

/// Factory for dynamically creating agents
///
/// This factory:
/// 1. Analyzes incoming tasks to understand their complexity and requirements
/// 2. Selects appropriate tools based on task analysis
/// 3. Creates and configures PlanExecuteAgent instances
/// 4. Decides whether task should run locally or remotely
/// 5. Provides execution context (local/remote hybrid)
class AgentFactory {
  final LanguageModel model;
  final ToolRegistry toolRegistry;
  final Logger logger;
  final bool enableRemoteDelegation;

  AgentFactory({
    required this.model,
    required this.toolRegistry,
    required this.logger,
    this.enableRemoteDelegation = true,
  });

  /// Analyze a task to determine its requirements
  Future<TaskAnalysis> analyzeTask(String taskDescription) async {
    logger.d('Analyzing task: $taskDescription');

    // Build analysis prompt
    final availableCapabilities =
        toolRegistry.getAllCapabilities().toList().join(', ');

    final analysisPrompt = '''Analyze this task and determine:
1. Estimated complexity (1-10)
2. Required capabilities from available set: $availableCapabilities
3. Whether it should run on remote server or local device
4. Brief reasoning

Task: $taskDescription

Respond in this JSON format:
{
  "complexity": <number 1-10>,
  "requiredCapabilities": ["capability1", "capability2"],
  "shouldRunRemotely": <true|false>,
  "reasoning": "<explanation>"
}''';

    try {
      final response = await model.invoke(analysisPrompt);
      final analysis = _parseTaskAnalysis(response.content, taskDescription);
      return analysis;
    } catch (e) {
      logger.e('Task analysis failed: $e');
      // Return conservative default analysis
      return TaskAnalysis(
        taskDescription: taskDescription,
        estimatedComplexity: 5,
        requiredCapabilities: [],
        shouldRunRemotely: false,
        reasoning: 'Analysis failed, using defaults',
      );
    }
  }

  /// Create an agent for the given task
  ///
  /// Returns null if the required tools are not available
  PlanExecuteAgent? createAgent(
    String taskDescription, {
    Duration? stepTimeout,
    int? maxReplanAttempts,
  }) {
    logger.d('Creating agent for task: $taskDescription');

    // Analyze task
    // NOTE: In production, this would be async, but we'd need to redesign this method
    // For now, we create agent optimistically and let plan creation handle capability validation

    return PlanExecuteAgent(
      model: model,
      toolRegistry: toolRegistry,
      logger: logger,
      stepTimeout: stepTimeout ?? const Duration(minutes: 5),
      maxReplanAttempts: maxReplanAttempts ?? 3,
    );
  }

  /// Create an agent async with full analysis
  ///
  /// This is the recommended method that performs full task analysis before
  /// creating the agent
  Future<PlanExecuteAgent?> createAgentAsync(
    String taskDescription, {
    Duration? stepTimeout,
    int? maxReplanAttempts,
  }) async {
    logger.d('Creating agent (async) for task: $taskDescription');

    // Analyze task
    final analysis = await analyzeTask(taskDescription);
    logger.d(
      'Task analysis: complexity=${analysis.estimatedComplexity}, '
      'remote=${analysis.shouldRunRemotely}',
    );

    // Check if required capabilities are available
    if (!toolRegistry.hasAllCapabilities(analysis.requiredCapabilities)) {
      logger.w(
        'Required capabilities not available. Required: '
        '${analysis.requiredCapabilities}, '
        'Available: ${toolRegistry.getAllCapabilities()}',
      );
      return null;
    }

    // Create agent
    final agent = PlanExecuteAgent(
      model: model,
      toolRegistry: toolRegistry,
      logger: logger,
      stepTimeout: stepTimeout ?? const Duration(minutes: 5),
      maxReplanAttempts: maxReplanAttempts ?? 3,
    );

    logger.d('Agent created successfully');
    return agent;
  }

  /// Create multiple specialized agents for complex tasks
  ///
  /// For tasks that require multiple domains of expertise, this creates
  /// a team of specialized agents that can work together
  Future<List<PlanExecuteAgent>> createAgentTeam(
    String mainTaskDescription,
    List<String> subtasks,
  ) async {
    logger.d('Creating agent team for ${subtasks.length} subtasks');

    final agents = <PlanExecuteAgent>[];

    for (final subtask in subtasks) {
      final agent = await createAgentAsync(subtask);
      if (agent != null) {
        agents.add(agent);
      } else {
        logger.w('Could not create agent for subtask: $subtask');
      }
    }

    logger.d('Agent team created with ${agents.length} agents');
    return agents;
  }

  /// Estimate task complexity without creating an agent
  ///
  /// Useful for deciding whether to execute locally or delegate to remote
  Future<int> estimateComplexity(String taskDescription) async {
    final analysis = await analyzeTask(taskDescription);
    return analysis.estimatedComplexity;
  }

  /// Determine if task should run remotely
  ///
  /// Used by mobile app to decide between local execution and remote delegation
  Future<bool> shouldExecuteRemotely(String taskDescription) async {
    if (!enableRemoteDelegation) return false;

    try {
      final analysis = await analyzeTask(taskDescription);
      return analysis.shouldRunRemotely;
    } catch (e) {
      logger.e('Could not determine execution context: $e');
      return false;
    }
  }

  /// Get planning context for an agent
  ///
  /// This provides all information needed for the agent's planning phase
  PlanningContext getPlanningContext(String taskDescription) {
    return PlanningContext(
      taskDescription: taskDescription,
      availableTools: toolRegistry.getAllMetadata(),
      availablePermissions: _getAvailablePermissions(),
      environmentInfo: _getEnvironmentInfo(),
    );
  }

  /// Parse task analysis from LLM response
  TaskAnalysis _parseTaskAnalysis(
    String response,
    String originalTask,
  ) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      // Parse JSON - would use json.decode in production with proper error handling
      // For now, using simple pattern matching as fallback

      final jsonStr = jsonMatch.group(0)!;

      // Extract complexity
      int complexity = 5;
      final complexityMatch =
          RegExp(r'"complexity"\s*:\s*(\d+)').firstMatch(jsonStr);
      if (complexityMatch != null) {
        complexity = int.parse(complexityMatch.group(1)!);
      }

      // Extract remote flag
      bool remote = false;
      if (jsonStr.contains('"shouldRunRemotely": true')) {
        remote = true;
      }

      // Extract required capabilities
      final List<String> capabilities = [];
      final capMatch =
          RegExp(r'"requiredCapabilities"\s*:\s*\[(.*?)\]').firstMatch(jsonStr);
      if (capMatch != null) {
        final capStr = capMatch.group(1)!;
        final caps = capStr.split(',');
        for (final cap in caps) {
          final cleaned = cap.trim().replaceAll('"', '');
          if (cleaned.isNotEmpty) {
            capabilities.add(cleaned);
          }
        }
      }

      return TaskAnalysis(
        taskDescription: originalTask,
        estimatedComplexity: complexity,
        requiredCapabilities: capabilities,
        shouldRunRemotely: remote && enableRemoteDelegation,
        reasoning: 'Task analysis complete',
      );
    } catch (e) {
      logger.w('Failed to parse task analysis: $e');
      return TaskAnalysis(
        taskDescription: originalTask,
        estimatedComplexity: 5,
        requiredCapabilities: [],
        shouldRunRemotely: false,
        reasoning: 'Parse failed: $e',
      );
    }
  }

  /// Get available permissions for context
  List<String> _getAvailablePermissions() {
    // In production, this would check actual device permissions
    return [
      'camera',
      'microphone',
      'location',
      'contacts',
      'calendar',
      'files',
      'sensors',
    ];
  }

  /// Get environment information for planning context
  Map<String, dynamic> _getEnvironmentInfo() {
    return {
      'platform': 'flutter',
      'toolCount': toolRegistry.toolCount,
      'availableCapabilities': toolRegistry.getAllCapabilities().toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

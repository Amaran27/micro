import 'dart:convert' as json;

import 'package:logger/logger.dart';

import 'models/agent_models.dart';
import 'tools/tool_registry.dart';

/// Base interface for language models used by agents
abstract class LanguageModel {
  Future<dynamic> invoke(String input);
}

/// Standard ChatModel interface from LangChain
abstract class ChatModel {
  Future<dynamic> call(List<dynamic> messages);
}

/// Core agent that implements the Plan-Execute-Verify-Replan pattern
///
/// This agent works with a ChatModel (LLM) and a ToolRegistry to:
/// 1. PLAN: Create a structured plan from the task description
/// 2. EXECUTE: Run steps sequentially, calling tools as needed
/// 3. VERIFY: Check if each step completed successfully
/// 4. REPLAN: Adjust the plan if verification fails
///
/// This pattern is efficient for mobile environments and provides
/// clear progress tracking and recovery mechanisms.
class PlanExecuteAgent {
  final LanguageModel model;
  final ToolRegistry toolRegistry;
  final Logger logger;

  /// Maximum number of replanning attempts
  final int maxReplanAttempts;

  /// Timeout for each step execution
  final Duration stepTimeout;

  PlanExecuteAgent({
    required this.model,
    required this.toolRegistry,
    required this.logger,
    this.maxReplanAttempts = 3,
    this.stepTimeout = const Duration(minutes: 5),
  });

  /// Execute a task end-to-end: Plan -> Execute -> Verify -> (optionally Replan)
  Future<AgentResult> executeTask(String taskDescription) async {
    logger.i('Starting task execution: $taskDescription');

    try {
      // Step 1: Create initial plan
      final plan = await _createPlan(taskDescription);
      logger.d('Plan created with ${plan.steps.length} steps');

      // Step 2: Execute plan steps
      final results = await _executePlan(plan);

      // Step 3: Verify results
      final verifications = await _verifyResults(plan, results);

      // Step 4: Check if replanning is needed
      var currentPlan = plan;
      var currentResults = results;
      var currentVerifications = verifications;
      var replannedCount = 0;

      while (_needsReplanning(currentVerifications) &&
          replannedCount < maxReplanAttempts) {
        logger.w('Replanning needed (attempt ${replannedCount + 1})');

        // Replan based on failures
        currentPlan = await _replan(currentPlan, currentVerifications);
        replannedCount++;

        // Re-execute and re-verify
        currentResults = await _executePlan(currentPlan);
        currentVerifications =
            await _verifyResults(currentPlan, currentResults);
      }

      // Return final result
      return _buildAgentResult(
          currentPlan, currentResults, currentVerifications);
    } catch (e, st) {
      logger.e('Task execution failed', error: e, stackTrace: st);
      return AgentResult(
        planId: 'unknown',
        finalStatus: ExecutionStatus.failed,
        result: null,
        error: 'Task execution failed: $e',
        completedAt: DateTime.now(),
      );
    }
  }

  /// Step 1: Create an initial plan from task description
  Future<AgentPlan> _createPlan(String taskDescription) async {
    logger.d('Creating plan for task: $taskDescription');

    // Prepare available tools info for the LLM
    final availableTools = toolRegistry.getAllMetadata();
    final toolsJson = availableTools
        .map((t) => {
              'name': t.name,
              'description': t.description,
              'capabilities': t.capabilities,
            })
        .toList();

    // Create prompt for planning
    final planningPrompt = _buildPlanningPrompt(taskDescription, toolsJson);

    // Call LLM to create plan
    final response = await model.invoke(planningPrompt);

    // Parse response into PlanStep objects
    final steps = _parsePlanFromResponse(response.content);

    return AgentPlan(
      id: _generateId('plan'),
      taskDescription: taskDescription,
      steps: steps,
      status: ExecutionStatus.planning,
      createdAt: DateTime.now(),
    );
  }

  /// Step 2: Execute plan steps sequentially
  Future<List<StepResult>> _executePlan(AgentPlan plan) async {
    logger.d('Executing plan with ${plan.steps.length} steps');

    final results = <StepResult>[];
    final updatedPlan = plan.copyWith(
      status: ExecutionStatus.executing,
      startedAt: DateTime.now(),
    );

    for (final step in updatedPlan.steps) {
      try {
        logger.d('Executing step: ${step.id}');

        final startTime = DateTime.now();
        final result = await _executeStep(step);
        final duration = DateTime.now().difference(startTime);

        results.add(
          StepResult(
            stepId: step.id,
            status: ExecutionStatus.completed,
            result: result,
            executedAt: DateTime.now(),
            durationMilliseconds: duration.inMilliseconds,
          ),
        );
      } catch (e) {
        logger.e('Step execution failed: $e');
        results.add(
          StepResult(
            stepId: step.id,
            status: ExecutionStatus.failed,
            result: null,
            error: e.toString(),
            executedAt: DateTime.now(),
          ),
        );
        // Continue executing remaining steps for better error reporting
      }
    }

    return results;
  }

  /// Execute a single step
  Future<dynamic> _executeStep(PlanStep step) async {
    // Get the tool needed for this step
    final tool = toolRegistry.getTool(step.toolName ?? step.action);
    if (tool == null) {
      throw ToolNotFoundException(
        'Tool not found for step: ${step.id}',
      );
    }

    // Execute tool with timeout
    try {
      final result = await tool.execute(step.parameters).timeout(
        stepTimeout,
        onTimeout: () {
          throw Exception(
            'Step execution timeout after ${stepTimeout.inSeconds}s',
          );
        },
      );
      return result;
    } catch (e) {
      logger.e('Tool execution error for ${tool.metadata.name}: $e');
      rethrow;
    }
  }

  /// Step 3: Verify execution results
  Future<List<Verification>> _verifyResults(
    AgentPlan plan,
    List<StepResult> results,
  ) async {
    logger.d('Verifying ${results.length} step results');

    final verifications = <Verification>[];

    for (int i = 0; i < plan.steps.length && i < results.length; i++) {
      final step = plan.steps[i];
      final result = results[i];

      // Check if step was successful
      if (result.status == ExecutionStatus.completed) {
        verifications.add(
          Verification(
            stepId: step.id,
            result: VerificationResult.success,
            reasoning: 'Step completed successfully',
            evidence: {'result': result.result},
          ),
        );
      } else {
        // For failed steps, try to determine if they can be retried
        verifications.add(
          Verification(
            stepId: step.id,
            result: VerificationResult.failed,
            reasoning: 'Step failed: ${result.error}',
            issues: [result.error ?? 'Unknown error'],
          ),
        );
      }
    }

    return verifications;
  }

  /// Step 4: Replan based on failures
  Future<AgentPlan> _replan(
    AgentPlan failedPlan,
    List<Verification> verifications,
  ) async {
    logger.d('Replanning after failures');

    // Build information about what failed
    final failureInfo = verifications
        .where((v) => v.result != VerificationResult.success)
        .map((v) => '${v.stepId}: ${v.reasoning}')
        .join('\n');

    // Create replanning prompt
    final replanPrompt = _buildReplanningPrompt(
      failedPlan.taskDescription,
      failedPlan.steps,
      failureInfo,
    );

    // Call LLM to create new plan
    final response = await model.invoke(replanPrompt);
    final newSteps = _parsePlanFromResponse(response.content);

    return failedPlan.copyWith(
      steps: newSteps,
      replannedCount: failedPlan.replannedCount + 1,
      status: ExecutionStatus.replanning,
    );
  }

  /// Build the final agent result
  AgentResult _buildAgentResult(
    AgentPlan plan,
    List<StepResult> results,
    List<Verification> verifications,
  ) {
    final allSuccessful =
        verifications.every((v) => v.result == VerificationResult.success);

    final stepsCompleted =
        results.where((r) => r.status == ExecutionStatus.completed).length;
    final stepsFailed =
        results.where((r) => r.status == ExecutionStatus.failed).length;

    final totalDuration = plan.completedAt != null && plan.startedAt != null
        ? plan.completedAt!.difference(plan.startedAt!).inSeconds
        : 0;

    return AgentResult(
      planId: plan.id,
      finalStatus:
          allSuccessful ? ExecutionStatus.completed : ExecutionStatus.failed,
      result: allSuccessful ? _aggregateResults(results) : null,
      error: allSuccessful ? null : 'Some steps failed',
      completedAt: DateTime.now(),
      totalDurationSeconds: totalDuration,
      stepsCompleted: stepsCompleted,
      stepsFailed: stepsFailed,
      metadata: {
        'replannedCount': plan.replannedCount,
        'stepCount': plan.steps.length,
      },
    );
  }

  /// Check if replanning is needed
  bool _needsReplanning(List<Verification> verifications) {
    return verifications.any(
      (v) =>
          v.result == VerificationResult.failed ||
          v.result == VerificationResult.needsReplanning,
    );
  }

  /// Aggregate results from all steps
  dynamic _aggregateResults(List<StepResult> results) {
    if (results.isEmpty) return null;

    // For single step, return its result
    if (results.length == 1) return results.first.result;

    // For multiple steps, return as list
    return results.map((r) => r.result).toList();
  }

  /// Build planning prompt for LLM
  String _buildPlanningPrompt(
    String taskDescription,
    List<Map<String, dynamic>> availableTools,
  ) {
    final toolsDescription = availableTools
        .map((t) => '- ${t['name']}: ${t['description']}')
        .join('\n');

    return '''You are an autonomous agent planner. Create a detailed plan to accomplish the following task.

Task: $taskDescription

Available Tools:
$toolsDescription

Create a step-by-step plan. For each step, specify:
1. Step ID (e.g., step_1, step_2)
2. Description of what the step does
3. Which tool to use
4. Parameters for the tool

Format your response as a JSON array of steps.''';
  }

  /// Build replanning prompt for LLM
  String _buildReplanningPrompt(
    String taskDescription,
    List<PlanStep> originalSteps,
    String failureInfo,
  ) {
    final stepsDescription =
        originalSteps.map((s) => '- ${s.id}: ${s.description}').join('\n');

    return '''The original plan for the task had failures. Please create a revised plan.

Original Task: $taskDescription

Original Plan:
$stepsDescription

Failures Encountered:
$failureInfo

Create a new, revised step-by-step plan that avoids the previous failures.
Format your response as a JSON array of steps.''';
  }

  /// Parse LLM response into plan steps
  List<PlanStep> _parsePlanFromResponse(String response) {
    // Extract JSON from response
    final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
    if (jsonMatch == null) {
      logger.w('No JSON found in response, using fallback parsing');
      return _createFallbackPlan();
    }

    try {
      final jsonStr = jsonMatch.group(0)!;
      // Parse JSON - json.decode requires dart:convert import
      final dynamic decoded = json.jsonDecode(jsonStr);
      final List<dynamic> jsonList = (decoded as List<dynamic>?) ?? [];

      final steps = <PlanStep>[];
      for (int i = 0; i < jsonList.length; i++) {
        final stepJson = jsonList[i] as Map<String, dynamic>;
        steps.add(
          PlanStep(
            id: stepJson['id'] as String? ?? 'step_$i',
            description: stepJson['description'] as String? ?? '',
            action: stepJson['action'] as String? ?? stepJson['tool'] ?? '',
            parameters: stepJson['parameters'] as Map<String, dynamic>? ?? {},
            requiredTools: [stepJson['tool'] as String? ?? ''],
            estimatedDurationSeconds: stepJson['duration'] as int? ?? 60,
            toolName: stepJson['tool'] as String?,
          ),
        );
      }
      return steps;
    } catch (e) {
      logger.e('Failed to parse plan from response: $e');
      return _createFallbackPlan();
    }
  }

  /// Create a fallback plan when parsing fails
  List<PlanStep> _createFallbackPlan() {
    return [
      PlanStep(
        id: 'step_1',
        description: 'Default step',
        action: 'default',
        parameters: {},
        requiredTools: const [],
        estimatedDurationSeconds: 60,
      ),
    ];
  }

  /// Generate unique ID
  static String _generateId(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Extension to make PlanStep copyable
extension PlanStepCopy on PlanStep {
  PlanStep copyWith({
    String? id,
    String? description,
    String? action,
    Map<String, dynamic>? parameters,
    List<String>? requiredTools,
    int? estimatedDurationSeconds,
    ExecutionStatus? status,
    List<String>? dependencies,
    int? sequenceNumber,
    String? toolName,
  }) {
    return PlanStep(
      id: id ?? this.id,
      description: description ?? this.description,
      action: action ?? this.action,
      parameters: parameters ?? this.parameters,
      requiredTools: requiredTools ?? this.requiredTools,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
      status: status ?? this.status,
      dependencies: dependencies ?? this.dependencies,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      toolName: toolName ?? this.toolName,
    );
  }
}

/// Extension to make AgentPlan copyable
extension AgentPlanCopy on AgentPlan {
  AgentPlan copyWith({
    String? id,
    String? taskDescription,
    List<PlanStep>? steps,
    ExecutionStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<Verification>? verifications,
    List<StepResult>? results,
    int? replannedCount,
    String? finalReasoning,
  }) {
    return AgentPlan(
      id: id ?? this.id,
      taskDescription: taskDescription ?? this.taskDescription,
      steps: steps ?? this.steps,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      verifications: verifications ?? this.verifications,
      results: results ?? this.results,
      replannedCount: replannedCount ?? this.replannedCount,
      finalReasoning: finalReasoning ?? this.finalReasoning,
    );
  }
}

import '../../models/autonomous/autonomous_action.dart';
import '../../models/autonomous/context_analysis.dart';

/// Interface for proactive behavior engine
/// Defines the contract for scheduling and executing autonomous proactive actions
abstract class IProactiveBehaviorEngine {
  /// Initialize the proactive behavior engine
  Future<void> initialize();

  /// Schedule a proactive action for execution
  /// Returns true if successfully scheduled, false otherwise
  Future<bool> scheduleProactiveAction({
    required AutonomousAction action,
    Duration? delay,
    String? cronExpression,
    Map<String, dynamic>? context,
  });

  /// Cancel a scheduled proactive action
  /// Returns true if successfully cancelled, false otherwise
  Future<bool> cancelProactiveAction(String actionId);

  /// Get all currently scheduled proactive actions
  Future<List<AutonomousAction>> getScheduledActions();

  /// Get current resource usage statistics
  Future<Map<String, dynamic>> getResourceUsage();

  /// Update engine configuration
  Future<void> updateConfiguration({
    bool? notificationsEnabled,
    bool? resourceMonitoringEnabled,
    Duration? maxExecutionDuration,
    int? maxDailyActions,
    Duration? notificationTimeout,
  });

  /// Schedule proactive action based on AI analysis
  /// Called by AI context analyzer when it detects patterns that suggest proactive actions
  Future<bool> scheduleAIRecommendedAction({
    required AutonomousAction action,
    required String aiReasoning,
    required double confidenceScore,
    Duration? suggestedDelay,
    String? suggestedCronExpression,
    Map<String, dynamic>? aiContext,
  });

  /// Get AI-driven proactive action recommendations
  /// Returns actions that could be scheduled based on current context patterns
  Future<List<Map<String, dynamic>>> getAIActionRecommendations({
    required ContextAnalysis context,
    required String userId,
  });

  /// Update AI consent settings
  Future<void> updateAIConsent(bool enabled);
}

import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import 'permissions_provider.dart';
import '../../domain/models/autonomous/context_analysis.dart';
import '../../domain/models/autonomous/user_intent.dart';
import '../../domain/models/autonomous/autonomous_action.dart';
import '../../infrastructure/autonomous/context_analyzer.dart';
import '../../infrastructure/autonomous/intent_recognizer.dart';
import '../../infrastructure/autonomous/decision_engine.dart';
import '../../infrastructure/autonomous/proactive_behavior_engine.dart';
import '../../infrastructure/permissions/services/store_compliant_permissions_manager.dart';
import '../../core/utils/logger.dart';
import '../../features/chat/presentation/providers/chat_provider.dart'; // Import aiProviderConfigProvider

/// Provider for the autonomous decision framework
/// Connects the autonomous components to Riverpod state management
class AutonomousProvider {
  final StoreCompliantContextAnalyzer _contextAnalyzer;
  final StoreCompliantIntentRecognizer _intentRecognizer;
  final StoreCompliantDecisionEngine _decisionEngine;
  final StoreCompliantProactiveBehaviorEngine _proactiveBehaviorEngine;
  final StoreCompliantPermissionsManager _permissionsManager;
  final AppLogger _logger;

  // State management
  ContextAnalysis? _currentContextAnalysis;
  UserIntent? _currentUserIntent;
  AutonomousAction? _currentAutonomousAction;
  bool _isAutonomousEnabled = false;
  bool _isInitialized = false;

  AutonomousProvider({
    required StoreCompliantContextAnalyzer contextAnalyzer,
    required StoreCompliantIntentRecognizer intentRecognizer,
    required StoreCompliantDecisionEngine decisionEngine,
    required StoreCompliantProactiveBehaviorEngine proactiveBehaviorEngine,
    required StoreCompliantPermissionsManager permissionsManager,
    AppLogger? logger,
  })  : _contextAnalyzer = contextAnalyzer,
        _intentRecognizer = intentRecognizer,
        _decisionEngine = decisionEngine,
        _proactiveBehaviorEngine = proactiveBehaviorEngine,
        _permissionsManager = permissionsManager,
        _logger = logger ?? AppLogger();

  /// Initialize the autonomous framework
  Future<void> initialize() async {
    _logger.info('Initializing Autonomous Provider');

    try {
      // Initialize all components
      await _contextAnalyzer.initialize();
      await _intentRecognizer.initialize();
      await _decisionEngine.initialize();
      await _proactiveBehaviorEngine.initialize();

      // Update initialization state
      _isInitialized = true;

      _logger.info('Autonomous Provider initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Autonomous Provider', error: e);
    }
  }

  /// Enable or disable autonomous operations
  Future<void> setAutonomousEnabled(bool enabled) async {
    _logger.info('Setting autonomous enabled: $enabled');

    try {
      // Update state
      _isAutonomousEnabled = enabled;

      // In a real implementation, this would persist the setting
      // For now, we'll just log the change
    } catch (e) {
      _logger.error('Failed to set autonomous enabled', error: e);
    }
  }

  /// Analyze context for autonomous decision making
  Future<ContextAnalysis> analyzeContext({
    Map<String, dynamic>? contextData,
    String? userId,
  }) async {
    _logger.info('Analyzing context for user: ${userId ?? 'anonymous'}');

    try {
      // Analyze context
      final analysis = await _contextAnalyzer.analyzeContext(
        contextData: contextData,
        userId: userId,
      );

      // Update state
      _currentContextAnalysis = analysis;

      return analysis;
    } catch (e) {
      _logger.error('Context analysis failed', error: e);

      // Return a failure analysis
      return ContextAnalysis.failure(
        id: 'context-analysis-failure',
        contextData: contextData ?? {},
        requiredPermissions: [],
        grantedPermissions: [],
        deniedPermissions: [],
        confidenceScore: 0.0,
        complianceIssues: ['Context analysis failed: ${e.toString()}'],
      );
    }
  }

  /// Recognize user intent from input
  Future<IntentRecognitionResult> recognizeIntent({
    required String input,
    ContextAnalysis? contextAnalysis,
    String? userId,
  }) async {
    _logger.info('Recognizing intent for input: "$input"');

    try {
      // Get current context if not provided
      final context = contextAnalysis ?? _currentContextAnalysis;

      // Recognize intent
      final result = await _intentRecognizer.recognizeIntent(
        input: input,
        contextAnalysis: context,
        userId: userId,
      );

      // Update state
      _currentUserIntent = result.intent;

      return result;
    } catch (e) {
      _logger.error('Intent recognition failed', error: e);

      // Return a failure result
      return IntentRecognitionResult.failure(
        intent: UserIntent.failure(
          id: 'intent-recognition-failure',
          originalInput: input,
          confidenceScore: 0.0,
          complianceIssues: ['Intent recognition failed: ${e.toString()}'],
          userId: userId,
        ),
        biasWarnings: ['Intent recognition failed'],
      );
    }
  }

  /// Generate autonomous action based on intent and context
  Future<AutonomousAction> generateAction({
    required UserIntent intent,
    required ContextAnalysis context,
    String? userId,
  }) async {
    _logger.info('Generating action for intent: ${intent.intentType}');

    try {
      // Generate action
      final action = await _decisionEngine.generateAction(
        intent: intent,
        context: context,
        userId: userId,
      );

      // Update state
      _currentAutonomousAction = action;

      return action;
    } catch (e) {
      _logger.error('Action generation failed', error: e);

      // Return a failure action
      return AutonomousAction.create(
        id: 'action-generation-failure',
        actionType: ActionType.unknown,
        description: 'Action generation failed',
        parameters: {},
        requiredPermissions: [],
        riskLevel: ActionRiskLevel.critical,
        userId: userId,
      ).block(reason: 'Action generation failed: ${e.toString()}');
    }
  }

  /// Execute an autonomous action
  Future<ActionExecutionResult> executeAction({
    required AutonomousAction action,
    bool requireUserApproval = false,
  }) async {
    _logger.info('Executing action: ${action.id}');

    try {
      // Execute action
      final result = await _decisionEngine.executeAction(
        action: action,
        requireUserApproval: requireUserApproval,
      );

      // Update state
      _currentAutonomousAction = result.action;

      return result;
    } catch (e) {
      _logger.error('Action execution failed', error: e);

      // Return a failure result
      return ActionExecutionResult.failure(
        action: action,
        resourceUsage: {},
        warnings: ['Action execution failed: ${e.toString()}'],
      );
    }
  }

  /// Request user approval for an action
  Future<bool> requestUserApproval({
    required AutonomousAction action,
    String? justification,
  }) async {
    _logger.info('Requesting user approval for action: ${action.id}');

    try {
      // Request approval
      final approved = await _decisionEngine.requestUserApproval(
        action: action,
        justification: justification,
      );

      // Update state if approved
      if (approved) {
        final approvedAction = action.approve();
        _currentAutonomousAction = approvedAction;
      }

      return approved;
    } catch (e) {
      _logger.error('User approval request failed', error: e);
      return false;
    }
  }

  /// Get current context analysis
  ContextAnalysis? get currentContext => _currentContextAnalysis;

  /// Get last recognized intent
  UserIntent? get lastIntent => _currentUserIntent;

  /// Get last generated action
  AutonomousAction? get lastAction => _currentAutonomousAction;

  /// Check if autonomous operations are enabled
  bool get isAutonomousEnabled => _isAutonomousEnabled;

  /// Check if the framework is initialized
  bool get isInitialized => _isInitialized;

  /// Get proactive behavior engine
  StoreCompliantProactiveBehaviorEngine get proactiveBehaviorEngine =>
      _proactiveBehaviorEngine;

  /// Schedule a proactive action
  Future<bool> scheduleProactiveAction({
    required AutonomousAction action,
    Duration? delay,
    String? cronExpression,
    Map<String, dynamic>? context,
  }) async {
    _logger.info('Scheduling proactive action: ${action.id}');

    try {
      return await _proactiveBehaviorEngine.scheduleProactiveAction(
        action: action,
        delay: delay,
        cronExpression: cronExpression,
        context: context,
      );
    } catch (e) {
      _logger.error('Failed to schedule proactive action', error: e);
      return false;
    }
  }

  /// Cancel a scheduled proactive action
  Future<bool> cancelProactiveAction(String actionId) async {
    _logger.info('Cancelling proactive action: $actionId');

    try {
      return await _proactiveBehaviorEngine.cancelProactiveAction(actionId);
    } catch (e) {
      _logger.error('Failed to cancel proactive action', error: e);
      return false;
    }
  }

  /// Get scheduled proactive actions
  Future<List<AutonomousAction>> getScheduledProactiveActions() async {
    try {
      return await _proactiveBehaviorEngine.getScheduledActions();
    } catch (e) {
      _logger.error('Failed to get scheduled proactive actions', error: e);
      return [];
    }
  }

  /// Get proactive behavior resource usage
  Future<Map<String, dynamic>> getProactiveResourceUsage() async {
    try {
      return await _proactiveBehaviorEngine.getResourceUsage();
    } catch (e) {
      _logger.error('Failed to get proactive resource usage', error: e);
      return {};
    }
  }

  /// Schedule AI-recommended proactive action
  Future<bool> scheduleAIRecommendedAction({
    required AutonomousAction action,
    required String aiReasoning,
    required double confidenceScore,
    Duration? suggestedDelay,
    String? suggestedCronExpression,
    Map<String, dynamic>? aiContext,
  }) async {
    _logger.info('Scheduling AI-recommended proactive action: ${action.id}');

    try {
      return await _proactiveBehaviorEngine.scheduleAIRecommendedAction(
        action: action,
        aiReasoning: aiReasoning,
        confidenceScore: confidenceScore,
        suggestedDelay: suggestedDelay,
        suggestedCronExpression: suggestedCronExpression,
        aiContext: aiContext,
      );
    } catch (e) {
      _logger.error('Failed to schedule AI-recommended proactive action',
          error: e);
      return false;
    }
  }

  /// Get AI-driven proactive action recommendations
  Future<List<Map<String, dynamic>>> getAIActionRecommendations({
    required ContextAnalysis context,
    required String userId,
  }) async {
    try {
      return await _proactiveBehaviorEngine.getAIActionRecommendations(
        context: context,
        userId: userId,
      );
    } catch (e) {
      _logger.error('Failed to get AI action recommendations', error: e);
      return [];
    }
  }

  /// Update AI consent for proactive behavior
  Future<void> updateAIConsent(bool enabled) async {
    try {
      await _proactiveBehaviorEngine.updateAIConsent(enabled);
    } catch (e) {
      _logger.error('Failed to update AI consent', error: e);
    }
  }

  /// Get executing actions
  List<AutonomousAction> get executingActions {
    return _decisionEngine
        .getActiveActions()
        .where((action) => action.status == ActionStatus.executing)
        .toList();
  }

  /// Get action by ID
  AutonomousAction? getActionById(String id) {
    return _decisionEngine.getActionById(id);
  }

  /// Cancel an action
  Future<bool> cancelAction(String id) async {
    _logger.info('Cancelling action: $id');

    try {
      // Get action
      final action = _decisionEngine.getActionById(id);
      if (action == null) {
        _logger.warning('Action not found: $id');
        return false;
      }

      // Cancel action
      final cancelledAction = action.cancel();

      // Update state if this was the last action
      if (_currentAutonomousAction?.id == id) {
        _currentAutonomousAction = cancelledAction;
      }

      return true;
    } catch (e) {
      _logger.error('Action cancellation failed', error: e);
      return false;
    }
  }

  /// Approve an action
  Future<bool> approveAction(String id) async {
    _logger.info('Approving action: $id');

    try {
      // Get action
      final action = _decisionEngine.getActionById(id);
      if (action == null) {
        _logger.warning('Action not found: $id');
        return false;
      }

      // Approve action
      final approvedAction = action.approve();

      // Update state if this was the last action
      if (_currentAutonomousAction?.id == id) {
        _currentAutonomousAction = approvedAction;
      }

      return true;
    } catch (e) {
      _logger.error('Action approval failed', error: e);
      return false;
    }
  }

  /// Get compliance report for autonomous operations
  Future<Map<String, dynamic>> getComplianceReport() async {
    _logger.info('Generating compliance report');

    try {
      // Get reports from each component
      final contextStats = _contextAnalyzer.getStatistics();
      final intentStats = _intentRecognizer.getStatistics();
      final actionStats = _decisionEngine.getStatistics();

      // Get permissions compliance report
      final permissionsReport =
          await _permissionsManager.generateComplianceReport();

      return {
        'contextAnalysis': contextStats,
        'intentRecognition': intentStats,
        'actionExecution': actionStats,
        'permissions': permissionsReport,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.error('Failed to generate compliance report', error: e);
      return {
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get audit log for autonomous operations
  Future<List<Map<String, dynamic>>> getAuditLog({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    _logger.info('Getting audit log');

    try {
      // Get audit logs from each component
      // final contextLogs = await _contextAnalyzer.getAuditLog(
      //   startDate: startDate,
      //   endDate: endDate,
      //   limit: limit,
      // );
      // final intentLogs = await _intentRecognizer.getAuditLog(
      //   startDate: startDate,
      //   endDate: endDate,
      //   limit: limit,
      // );
      // final actionLogs = await _decisionEngine.getAuditLog(
      //   startDate: startDate,
      //   endDate: endDate,
      //   limit: limit,
      // );

      // Combine and sort all logs
      final allLogs = <Map<String, dynamic>>[];
      // allLogs.addAll(contextLogs);
      // allLogs.addAll(intentLogs);
      // allLogs.addAll(actionLogs);

      // Sort by timestamp (newest first)
      allLogs.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      // Apply date filters
      var filteredLogs = allLogs;
      if (startDate != null) {
        filteredLogs = filteredLogs
            .where((log) =>
                DateTime.parse(log['timestamp'] as String).isAfter(startDate))
            .toList();
      }

      if (endDate != null) {
        filteredLogs = filteredLogs
            .where((log) =>
                DateTime.parse(log['timestamp'] as String).isBefore(endDate))
            .toList();
      }

      // Apply limit
      if (limit != null && filteredLogs.length > limit) {
        filteredLogs = filteredLogs.take(limit).toList();
      }

      return filteredLogs;
    } catch (e) {
      _logger.error('Failed to get audit log', error: e);
      return [];
    }
  }

  /// Export audit data
  Future<String> exportAuditData({
    String format = 'json',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _logger.info('Exporting audit data in format: $format');

    try {
      // Get audit logs
      final logs = await getAuditLog(
        startDate: startDate,
        endDate: endDate,
      );

      // Convert to requested format
      switch (format.toLowerCase()) {
        case 'json':
          return _exportAsJson(logs);
        case 'csv':
          return _exportAsCsv(logs);
        default:
          throw ArgumentError('Unsupported export format: $format');
      }
    } catch (e) {
      _logger.error('Failed to export audit data', error: e);
      return 'Export failed: ${e.toString()}';
    }
  }

  /// Clear audit log
  Future<void> clearAuditLog() async {
    _logger.info('Clearing audit log');

    try {
      // Clear audit logs from each component
      // await _contextAnalyzer.clearAuditLog();
      // await _intentRecognizer.clearAuditLog();
      // await _decisionEngine.clearAuditLog();

      _logger.info('Audit log cleared');
    } catch (e) {
      _logger.error('Failed to clear audit log', error: e);
    }
  }

  /// Get resource usage statistics
  Future<Map<String, dynamic>> getResourceUsageStats() async {
    _logger.info('Getting resource usage statistics');

    try {
      // Get resource usage from decision engine
      return _decisionEngine.getCurrentResourceUsage();
    } catch (e) {
      _logger.error('Failed to get resource usage statistics', error: e);
      return {};
    }
  }

  /// Get autonomous operation statistics
  Future<Map<String, dynamic>> getOperationStats() async {
    _logger.info('Getting autonomous operation statistics');

    try {
      // Get statistics from each component
      final contextStats = _contextAnalyzer.getStatistics();
      final intentStats = _intentRecognizer.getStatistics();
      final actionStats = _decisionEngine.getStatistics();

      return {
        'contextAnalysis': contextStats,
        'intentRecognition': intentStats,
        'actionExecution': actionStats,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.error('Failed to get operation statistics', error: e);
      return {
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Reset the autonomous framework
  Future<void> reset() async {
    _logger.info('Resetting autonomous framework');

    try {
      // Reset each component
      _contextAnalyzer.clearCache();
      _intentRecognizer.clearCache();
      _decisionEngine.clearCache();

      // Clear states
      _currentContextAnalysis = null;
      _currentUserIntent = null;
      _currentAutonomousAction = null;

      _logger.info('Autonomous framework reset');
    } catch (e) {
      _logger.error('Failed to reset autonomous framework', error: e);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.info('Disposing Autonomous Provider');

    try {
      // Dispose each component
      // await _contextAnalyzer.dispose();
      // await _intentRecognizer.dispose();
      // await _decisionEngine.dispose();

      _logger.info('Autonomous Provider disposed');
    } catch (e) {
      _logger.error('Failed to dispose Autonomous Provider', error: e);
    }
  }

  // Private helper methods

  /// Export audit logs as JSON
  String _exportAsJson(List<Map<String, dynamic>> logs) {
    // Convert logs to JSON format
    final auditData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRecords': logs.length,
      'records': logs,
    };

    return jsonEncode(auditData);
  }

  /// Export audit logs as CSV
  String _exportAsCsv(List<Map<String, dynamic>> logs) {
    // Convert logs to CSV format
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln(
      'timestamp,component,type,id,userId,status,riskLevel,result,errorMessage',
    );

    // CSV rows
    for (final log in logs) {
      buffer.writeln(
        '${log['timestamp']},'
        '${log['component'] ?? ''},'
        '${log['type'] ?? ''},'
        '${log['id'] ?? ''},'
        '${log['userId'] ?? ''},'
        '${log['status'] ?? ''},'
        '${log['riskLevel'] ?? ''},'
        '${log['result'] ?? ''},'
        '"${(log['errorMessage'] ?? '').replaceAll('"', '""')}"',
      );
    }

    return buffer.toString();
  }
}

/// Provider for the autonomous decision framework
final autonomousProviderProvider = Provider<AutonomousProvider>((ref) {
  // Get dependencies
  final permissionsManager = ref.watch(permissionsManagerProvider);
  final aiProviderConfig = ref.watch(aiProviderConfigProvider);

  return AutonomousProvider(
    contextAnalyzer: StoreCompliantContextAnalyzer(
      permissionsManager: permissionsManager,
    ),
    intentRecognizer: StoreCompliantIntentRecognizer(
      permissionsManager: permissionsManager,
      aiProviderConfig: aiProviderConfig,
    ),
    decisionEngine: StoreCompliantDecisionEngine(
      permissionsManager: permissionsManager,
    ),
    proactiveBehaviorEngine: StoreCompliantProactiveBehaviorEngine(
      permissionsManager: permissionsManager,
    ),
    permissionsManager: permissionsManager,
  );
});

/// Provider for autonomous framework state
final contextAnalysisProvider = Provider<ContextAnalysis?>((ref) => null);
final userIntentProvider = Provider<UserIntent?>((ref) => null);
final autonomousActionProvider = Provider<AutonomousAction?>((ref) => null);
final autonomousEnabledProvider = Provider<bool>((ref) => false);
final autonomousInitializedProvider = Provider<bool>((ref) => false);

/// Provider for autonomous framework statistics
final autonomousStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(autonomousProviderProvider);
  return await provider.getOperationStats();
});

/// Provider for autonomous framework compliance report
final autonomousComplianceProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(autonomousProviderProvider);
  return await provider.getComplianceReport();
});

/// Provider for autonomous framework audit log
final autonomousAuditLogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final provider = ref.watch(autonomousProviderProvider);
  return await provider.getAuditLog();
});

/// Provider for autonomous framework resource usage
final autonomousResourceUsageProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(autonomousProviderProvider);
  return await provider.getResourceUsageStats();
});

/// Provider for proactive behavior engine
final proactiveBehaviorEngineProvider =
    Provider<StoreCompliantProactiveBehaviorEngine>((ref) {
  final provider = ref.watch(autonomousProviderProvider);
  return provider.proactiveBehaviorEngine;
});

/// Provider for scheduled proactive actions
final scheduledProactiveActionsProvider =
    FutureProvider<List<AutonomousAction>>((ref) async {
  final provider = ref.watch(autonomousProviderProvider);
  return await provider.getScheduledProactiveActions();
});

/// Provider for proactive behavior resource usage
final proactiveResourceUsageProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(autonomousProviderProvider);
  return await provider.getProactiveResourceUsage();
});

/// Provider for AI action recommendations
final aiActionRecommendationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>(
        (ref, params) async {
  final provider = ref.watch(autonomousProviderProvider);
  final context = params['context'] as ContextAnalysis;
  final userId = params['userId'] as String;
  return await provider.getAIActionRecommendations(
    context: context,
    userId: userId,
  );
});

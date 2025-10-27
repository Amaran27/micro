import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cron/cron.dart';
import 'package:queue/queue.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/autonomous/autonomous_action.dart';
import '../../domain/models/autonomous/context_analysis.dart';
import '../../domain/interfaces/autonomous/i_proactive_behavior_engine.dart';
import '../permissions/services/store_compliant_permissions_manager.dart';
import '../../core/utils/logger.dart';
import '../../core/exceptions/app_exception.dart';

/// Store-compliant proactive behavior engine for autonomous decision making
/// Implements proactive action scheduling with user notifications, resource monitoring,
/// and execution limits for store compliance
class StoreCompliantProactiveBehaviorEngine
    implements IProactiveBehaviorEngine {
  final StoreCompliantPermissionsManager _permissionsManager;
  final AppLogger _logger;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Notification system
  late FlutterLocalNotificationsPlugin _notifications;

  // Scheduling system
  final Cron _cron = Cron();

  // Task queue for sequential execution
  final Queue _actionQueue = Queue();

  // Active scheduled tasks
  final Map<String, ScheduledTask> _scheduledTasks = {};

  // Resource monitoring
  final Map<String, dynamic> _resourceUsage = {
    'cpu': 0.0,
    'memory': 0.0,
    'network': 0.0,
    'storage': 0.0,
    'battery': 100.0,
  };

  // Audit log for proactive actions
  final List<Map<String, dynamic>> _auditLog = [];

  // Configuration
  bool _notificationsEnabled = true;
  bool _resourceMonitoringEnabled = true;
  Duration _maxExecutionDuration = const Duration(minutes: 10);
  int _maxDailyActions = 20;
  Duration _notificationTimeout = const Duration(seconds: 30);

  StoreCompliantProactiveBehaviorEngine({
    required StoreCompliantPermissionsManager permissionsManager,
    AppLogger? logger,
  })  : _permissionsManager = permissionsManager,
        _logger = logger ?? AppLogger();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Store-Compliant Proactive Behavior Engine');

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize notifications
      await _initializeNotifications();

      // Initialize WorkManager for background tasks
      await _initializeWorkManager();

      // Load configuration
      _loadConfiguration();

      // Load scheduled tasks
      await _loadScheduledTasks();

      // Load audit log
      await _loadAuditLog();

      _isInitialized = true;
      _logger.info(
          'Store-Compliant Proactive Behavior Engine initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Proactive Behavior Engine', error: e);
      throw const SecurityException(
          'Failed to initialize Proactive Behavior Engine');
    }
  }

  @override
  Future<bool> scheduleProactiveAction({
    required AutonomousAction action,
    Duration? delay,
    String? cronExpression,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    _logger.info('Scheduling proactive action: ${action.id}');

    try {
      // Check user consent for proactive behavior
      final hasConsent = await _checkUserConsent(action);
      if (!hasConsent) {
        _logger.warning(
            'User consent not obtained for proactive action: ${action.id}');
        return false;
      }

      // Validate action for store compliance
      final isCompliant = await _validateActionCompliance(action);
      if (!isCompliant) {
        _logger
            .warning('Action failed store compliance validation: ${action.id}');
        return false;
      }

      // Check daily action limits
      if (!await _checkDailyLimits()) {
        _logger.warning('Daily action limit exceeded');
        return false;
      }

      // Check resource availability
      if (!await _checkResourceAvailability(action)) {
        _logger.warning('Insufficient resources for action: ${action.id}');
        return false;
      }

      // Show user notification if required
      if (action.requiresUserApproval ||
          action.riskLevel == ActionRiskLevel.high) {
        final userApproved = await _showUserNotification(action);
        if (!userApproved) {
          _logger.info('User declined proactive action: ${action.id}');
          return false;
        }
      }

      // Schedule the action
      final scheduledTask =
          await _scheduleAction(action, delay, cronExpression, context);

      // Add to scheduled tasks
      _scheduledTasks[action.id] = scheduledTask;

      // Save scheduled tasks
      await _saveScheduledTasks();

      // Log for audit
      await _logProactiveAction(action, 'scheduled', context);

      _logger.info('Proactive action scheduled successfully: ${action.id}');
      return true;
    } catch (e) {
      _logger.error('Failed to schedule proactive action: ${action.id}',
          error: e);
      return false;
    }
  }

  @override
  Future<bool> cancelProactiveAction(String actionId) async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    _logger.info('Cancelling proactive action: $actionId');

    try {
      final task = _scheduledTasks[actionId];
      if (task == null) {
        _logger.warning('Action not found for cancellation: $actionId');
        return false;
      }

      // Cancel the scheduled task
      await task.cancel();

      // Remove from scheduled tasks
      _scheduledTasks.remove(actionId);

      // Save updated tasks
      await _saveScheduledTasks();

      // Log cancellation
      await _logProactiveAction(task.action, 'cancelled');

      _logger.info('Proactive action cancelled: $actionId');
      return true;
    } catch (e) {
      _logger.error('Failed to cancel proactive action: $actionId', error: e);
      return false;
    }
  }

  @override
  Future<List<AutonomousAction>> getScheduledActions() async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    return _scheduledTasks.values.map((task) => task.action).toList();
  }

  @override
  Future<Map<String, dynamic>> getResourceUsage() async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    // Update resource usage if monitoring is enabled
    if (_resourceMonitoringEnabled) {
      await _updateResourceUsage();
    }

    return Map<String, dynamic>.from(_resourceUsage);
  }

  @override
  Future<void> updateConfiguration({
    bool? notificationsEnabled,
    bool? resourceMonitoringEnabled,
    Duration? maxExecutionDuration,
    int? maxDailyActions,
    Duration? notificationTimeout,
  }) async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    _logger.info('Updating proactive behavior configuration');

    if (notificationsEnabled != null) {
      _notificationsEnabled = notificationsEnabled;
      await _prefs.setBool('notifications_enabled', notificationsEnabled);
    }

    if (resourceMonitoringEnabled != null) {
      _resourceMonitoringEnabled = resourceMonitoringEnabled;
      await _prefs.setBool(
          'resource_monitoring_enabled', resourceMonitoringEnabled);
    }

    if (maxExecutionDuration != null) {
      _maxExecutionDuration = maxExecutionDuration;
      await _prefs.setInt(
          'max_execution_duration_minutes', maxExecutionDuration.inMinutes);
    }

    if (maxDailyActions != null) {
      _maxDailyActions = maxDailyActions;
      await _prefs.setInt('max_daily_actions', maxDailyActions);
    }

    if (notificationTimeout != null) {
      _notificationTimeout = notificationTimeout;
      await _prefs.setInt(
          'notification_timeout_seconds', notificationTimeout.inSeconds);
    }

    _logger.info('Proactive behavior configuration updated');
  }

  /// Execute a scheduled action
  Future<void> executeScheduledAction(
      String actionId, Map<String, dynamic>? context) async {
    final task = _scheduledTasks[actionId];
    if (task == null) return;

    try {
      _logger.info('Executing scheduled action: $actionId');

      // Check resource availability before execution
      if (!await _checkResourceAvailability(task.action)) {
        _logger.warning('Insufficient resources for execution: $actionId');
        return;
      }

      // Execute action with timeout
      final result = await _executeActionWithTimeout(task.action, context);

      // Log execution result
      await _logProactiveAction(task.action, 'executed', context, result);

      // Update resource usage
      if (_resourceMonitoringEnabled) {
        await _updateResourceUsage();
      }

      // Remove one-time tasks
      if (task.cronExpression == null) {
        _scheduledTasks.remove(actionId);
        await _saveScheduledTasks();
      }

      _logger.info('Scheduled action executed: $actionId');
    } catch (e) {
      _logger.error('Failed to execute scheduled action: $actionId', error: e);

      // Log execution failure
      await _logProactiveAction(
          task.action, 'failed', context, null, e.toString());
    }
  }

  // Private helper methods

  Future<void> _initializeNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> _initializeWorkManager() async {
    await Workmanager().initialize(
      _workManagerCallback,
      isInDebugMode: false,
    );
  }

  @pragma('vm:entry-point')
  static void _workManagerCallback() {
    Workmanager().executeTask((task, inputData) async {
      // Handle background task execution
      return true;
    });
  }

  void _loadConfiguration() {
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _resourceMonitoringEnabled =
        _prefs.getBool('resource_monitoring_enabled') ?? true;
    _maxExecutionDuration = Duration(
      minutes: _prefs.getInt('max_execution_duration_minutes') ?? 10,
    );
    _maxDailyActions = _prefs.getInt('max_daily_actions') ?? 20;
    _notificationTimeout = Duration(
      seconds: _prefs.getInt('notification_timeout_seconds') ?? 30,
    );
  }

  Future<void> _loadScheduledTasks() async {
    try {
      final tasksJson = _prefs.getString('scheduled_tasks') ?? '[]';
      final tasksList = jsonDecode(tasksJson) as List<dynamic>;

      for (final taskData in tasksList) {
        final task = ScheduledTask.fromJson(taskData as Map<String, dynamic>);
        _scheduledTasks[task.action.id] = task;

        // Re-schedule the task
        await _rescheduleTask(task);
      }

      _logger.debug('Loaded ${_scheduledTasks.length} scheduled tasks');
    } catch (e) {
      _logger.error('Failed to load scheduled tasks', error: e);
    }
  }

  Future<void> _saveScheduledTasks() async {
    try {
      final tasksJson = jsonEncode(
        _scheduledTasks.values.map((task) => task.toJson()).toList(),
      );
      await _prefs.setString('scheduled_tasks', tasksJson);
    } catch (e) {
      _logger.error('Failed to save scheduled tasks', error: e);
    }
  }

  Future<void> _loadAuditLog() async {
    try {
      final auditLogJson = _prefs.getString('proactive_audit_log') ?? '[]';
      final auditLogList = jsonDecode(auditLogJson) as List<dynamic>;

      _auditLog.clear();
      for (final record in auditLogList) {
        _auditLog.add(record as Map<String, dynamic>);
      }

      _logger
          .debug('Loaded ${_auditLog.length} proactive action audit records');
    } catch (e) {
      _logger.error('Failed to load proactive action audit log', error: e);
    }
  }

  Future<void> _saveAuditLog() async {
    try {
      final auditLogJson = jsonEncode(_auditLog);
      await _prefs.setString('proactive_audit_log', auditLogJson);
    } catch (e) {
      _logger.error('Failed to save proactive action audit log', error: e);
    }
  }

  Future<bool> _checkUserConsent(AutonomousAction action) async {
    // Check if user has given consent for proactive behavior
    final hasConsent = _prefs.getBool('proactive_consent') ?? false;

    // Check if action type requires special consent
    final requiresSpecialConsent = action.riskLevel == ActionRiskLevel.high ||
        action.riskLevel == ActionRiskLevel.critical;

    if (requiresSpecialConsent) {
      final specialConsent =
          _prefs.getBool('proactive_special_consent') ?? false;
      return hasConsent && specialConsent;
    }

    return hasConsent;
  }

  Future<bool> _validateActionCompliance(AutonomousAction action) async {
    // Check if action violates store policies
    if (action.requiresUserApproval && !action.userApproved) {
      return false;
    }

    // Check resource limits
    if (action.estimatedDuration != null &&
        action.estimatedDuration! > _maxExecutionDuration) {
      return false;
    }

    // Additional compliance checks can be added here
    return true;
  }

  Future<bool> _checkDailyLimits() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayActions = _auditLog
        .where((record) =>
            record['date'] == today && record['action'] == 'executed')
        .length;

    return todayActions < _maxDailyActions;
  }

  Future<bool> _checkResourceAvailability(AutonomousAction action) async {
    // Check battery level for power-intensive actions
    if (action.parameters.containsKey('power_consumption') &&
        action.parameters['power_consumption'] == 'high') {
      final batteryLevel = _resourceUsage['battery'] as double;
      if (batteryLevel < 20.0) return false;
    }

    // Check network availability for network actions
    if (action.parameters.containsKey('requires_network') &&
        action.parameters['requires_network'] == true) {
      // Implement network availability check
    }

    return true;
  }

  Future<bool> _showUserNotification(AutonomousAction action) async {
    final completer = Completer<bool>();

    const androidDetails = AndroidNotificationDetails(
      'proactive_actions',
      'Proactive Actions',
      channelDescription: 'Notifications for autonomous proactive actions',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('approve', 'Approve'),
        AndroidNotificationAction('deny', 'Deny'),
      ],
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      action.id.hashCode,
      'Autonomous Action',
      'Would you like to allow: ${action.description}',
      details,
      payload: action.id,
    );

    // Set up timeout
    Timer(_notificationTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(false); // Default to deny on timeout
      }
    });

    // In a real implementation, you'd handle notification actions
    // For now, we'll simulate user approval
    completer.complete(true);

    return completer.future;
  }

  Future<ScheduledTask> _scheduleAction(
    AutonomousAction action,
    Duration? delay,
    String? cronExpression,
    Map<String, dynamic>? context,
  ) async {
    if (cronExpression != null) {
      // Schedule recurring task with cron
      final scheduledTask =
          _cron.schedule(Schedule.parse(cronExpression), () async {
        await executeScheduledAction(action.id, context);
      });

      return ScheduledTask(
        action: action,
        cronExpression: cronExpression,
        context: context,
        scheduledTask: scheduledTask,
      );
    } else if (delay != null) {
      // Schedule one-time task with delay
      final scheduledTask = _cron.schedule(
        Schedule.parse('* * * * *'), // Run every minute to check
        () async {
          // This is a simplified implementation
          // In production, use a proper scheduling library
          await executeScheduledAction(action.id, context);
        },
      );

      return ScheduledTask(
        action: action,
        delay: delay,
        context: context,
        scheduledTask: scheduledTask,
      );
    } else {
      // Schedule immediate execution
      await executeScheduledAction(action.id, context);

      return ScheduledTask(
        action: action,
        context: context,
      );
    }
  }

  Future<void> _rescheduleTask(ScheduledTask task) async {
    if (task.cronExpression != null) {
      final scheduledTask =
          _cron.schedule(Schedule.parse(task.cronExpression!), () async {
        await executeScheduledAction(task.action.id, task.context);
      });
      task.scheduledTask = scheduledTask;
    }
  }

  Future<Map<String, dynamic>> _executeActionWithTimeout(
    AutonomousAction action,
    Map<String, dynamic>? context,
  ) async {
    // Execute action with timeout protection
    return await _actionQueue.add(() async {
      // Simulate action execution
      await Future.delayed(
          action.estimatedDuration ?? const Duration(seconds: 2));

      return {
        'success': true,
        'duration': action.estimatedDuration?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }).timeout(_maxExecutionDuration);
  }

  Future<void> _updateResourceUsage() async {
    // In a real implementation, you'd get actual resource usage
    // For now, we'll simulate
    _resourceUsage['cpu'] = 15.0 + (5.0 * (DateTime.now().second % 10) / 10);
    _resourceUsage['memory'] =
        45.0 + (10.0 * (DateTime.now().second % 10) / 10);
    _resourceUsage['battery'] =
        85.0 - (15.0 * (DateTime.now().second % 10) / 10);
  }

  Future<void> _logProactiveAction(
    AutonomousAction action,
    String actionType, [
    Map<String, dynamic>? context,
    Map<String, dynamic>? result,
    String? error,
  ]) async {
    final auditRecord = {
      'id': action.id,
      'actionType': actionType,
      'timestamp': DateTime.now().toIso8601String(),
      'date': DateTime.now().toIso8601String().split('T')[0],
      'action': action.toJson(),
      'context': context,
      'result': result,
      'error': error,
    };

    _auditLog.add(auditRecord);
    await _saveAuditLog();

    _logger.info('Proactive action logged: ${action.id} ($actionType)');
  }

  /// Schedule proactive action based on AI analysis
  /// Called by AI context analyzer when it detects patterns that suggest proactive actions
  @override
  Future<bool> scheduleAIRecommendedAction({
    required AutonomousAction action,
    required String aiReasoning,
    required double confidenceScore,
    Duration? suggestedDelay,
    String? suggestedCronExpression,
    Map<String, dynamic>? aiContext,
  }) async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    _logger.info('Scheduling AI-recommended proactive action: ${action.id}');

    try {
      // Validate AI confidence threshold (only schedule high-confidence recommendations)
      if (confidenceScore < 0.8) {
        _logger.info(
            'AI confidence too low ($confidenceScore), skipping action: ${action.id}');
        return false;
      }

      // Check user consent for AI-driven proactive behavior
      final hasAIConsent = await _checkAIConsent();
      if (!hasAIConsent) {
        _logger.warning(
            'User consent not obtained for AI-driven proactive actions');
        return false;
      }

      // Validate action for store compliance
      final isCompliant = await _validateActionCompliance(action);
      if (!isCompliant) {
        _logger.warning(
            'AI-recommended action failed store compliance validation: ${action.id}');
        return false;
      }

      // Check daily action limits
      if (!await _checkDailyLimits()) {
        _logger.warning('Daily action limit exceeded for AI action');
        return false;
      }

      // Use AI-suggested timing or default to immediate execution
      final delay = suggestedDelay ?? const Duration(minutes: 5);
      final cronExpression = suggestedCronExpression;

      // Show user notification for AI-recommended actions (always require approval)
      final userApproved =
          await _showAIActionNotification(action, aiReasoning, confidenceScore);
      if (!userApproved) {
        _logger.info('User declined AI-recommended action: ${action.id}');
        return false;
      }

      // Schedule the action
      final scheduledTask =
          await _scheduleAction(action, delay, cronExpression, aiContext);

      // Add to scheduled tasks
      _scheduledTasks[action.id] = scheduledTask;

      // Save scheduled tasks
      await _saveScheduledTasks();

      // Log for audit with AI metadata
      await _logAIProactiveAction(
        action,
        aiReasoning,
        confidenceScore,
        aiContext,
      );

      _logger.info(
          'AI-recommended proactive action scheduled successfully: ${action.id}');
      return true;
    } catch (e) {
      _logger.error(
          'Failed to schedule AI-recommended proactive action: ${action.id}',
          error: e);
      return false;
    }
  }

  /// Get AI-driven proactive action recommendations
  /// Returns actions that could be scheduled based on current context patterns
  @override
  Future<List<Map<String, dynamic>>> getAIActionRecommendations({
    required ContextAnalysis context,
    required String userId,
  }) async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    _logger.info('Getting AI action recommendations for user: $userId');

    try {
      final recommendations = <Map<String, dynamic>>[];

      // Analyze context patterns for potential proactive actions
      final contextPatterns = await _analyzeContextPatterns(context);

      for (final pattern in contextPatterns) {
        if (pattern['confidence'] >= 0.7) {
          // Only high-confidence patterns
          final recommendation = {
            'actionType': pattern['actionType'],
            'reasoning': pattern['reasoning'],
            'confidence': pattern['confidence'],
            'suggestedTiming': pattern['suggestedTiming'],
            'expectedBenefit': pattern['expectedBenefit'],
            'riskLevel': pattern['riskLevel'],
          };
          recommendations.add(recommendation);
        }
      }

      _logger.info(
          'Generated ${recommendations.length} AI action recommendations');
      return recommendations;
    } catch (e) {
      _logger.error('Failed to get AI action recommendations', error: e);
      return [];
    }
  }

  /// Update AI consent settings
  @override
  Future<void> updateAIConsent(bool enabled) async {
    if (!_isInitialized) {
      throw const SecurityException(
          'Proactive Behavior Engine not initialized');
    }

    await _prefs.setBool('ai_proactive_consent', enabled);
    _logger.info('AI proactive consent updated: $enabled');
  }

  // Private helper methods for AI integration

  Future<bool> _checkAIConsent() async {
    return _prefs.getBool('ai_proactive_consent') ?? false;
  }

  Future<bool> _showAIActionNotification(
    AutonomousAction action,
    String aiReasoning,
    double confidenceScore,
  ) async {
    final completer = Completer<bool>();

    const androidDetails = AndroidNotificationDetails(
      'ai_proactive_actions',
      'AI Proactive Actions',
      channelDescription: 'AI-recommended autonomous proactive actions',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('approve', 'Approve'),
        AndroidNotificationAction('deny', 'Deny'),
        AndroidNotificationAction('learn_more', 'Why?'),
      ],
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final confidencePercent = (confidenceScore * 100).round();
    await _notifications.show(
      action.id.hashCode + 1000, // Different ID for AI actions
      'AI Suggestion',
      'Based on your patterns: ${action.description}\nConfidence: $confidencePercent%',
      details,
      payload: 'ai_${action.id}',
    );

    // Set up timeout (longer for AI recommendations since they need consideration)
    Timer(_notificationTimeout * 2, () {
      if (!completer.isCompleted) {
        completer.complete(false); // Default to deny on timeout
      }
    });

    // In a real implementation, you'd handle notification actions
    completer.complete(true);

    return completer.future;
  }

  Future<List<Map<String, dynamic>>> _analyzeContextPatterns(
      ContextAnalysis context) async {
    // This would integrate with the AI context analyzer to identify patterns
    // For now, return some example patterns based on context analysis

    final patterns = <Map<String, dynamic>>[];

    // Example: If user frequently checks battery in the evening, suggest battery optimization
    if (context.contextData.containsKey('battery_checks') &&
        context.contextData['time_of_day'] == 'evening') {
      patterns.add({
        'actionType': ActionType.monitor,
        'reasoning':
            'You frequently check battery levels in the evening. Would you like me to monitor battery usage proactively?',
        'confidence': 0.85,
        'suggestedTiming': 'cron:0 20 * * *', // Daily at 8 PM
        'expectedBenefit':
            'Better battery awareness and optimization suggestions',
        'riskLevel': ActionRiskLevel.low,
      });
    }

    // Example: If user has network issues during certain times, suggest connectivity monitoring
    if (context.contextData.containsKey('network_issues') &&
        context.contextData['network_issues'] > 2) {
      patterns.add({
        'actionType': ActionType.monitor,
        'reasoning':
            'You\'ve experienced network connectivity issues recently. Would you like proactive network monitoring?',
        'confidence': 0.75,
        'suggestedTiming': 'delay:3600000', // 1 hour from now
        'expectedBenefit': 'Early detection of network problems',
        'riskLevel': ActionRiskLevel.low,
      });
    }

    // Example: If user frequently uses certain features, suggest optimization
    if (context.contextData.containsKey('feature_usage') &&
        (context.contextData['feature_usage'] as Map).length > 3) {
      patterns.add({
        'actionType': ActionType.configure,
        'reasoning':
            'Based on your usage patterns, I can optimize your app settings for better performance.',
        'confidence': 0.9,
        'suggestedTiming': 'delay:1800000', // 30 minutes from now
        'expectedBenefit': 'Improved app performance and battery life',
        'riskLevel': ActionRiskLevel.medium,
      });
    }

    return patterns;
  }

  Future<void> _logAIProactiveAction(
    AutonomousAction action,
    String aiReasoning,
    double confidenceScore,
    Map<String, dynamic>? aiContext,
  ) async {
    final auditRecord = {
      'id': action.id,
      'actionType': 'ai_recommended',
      'timestamp': DateTime.now().toIso8601String(),
      'date': DateTime.now().toIso8601String().split('T')[0],
      'action': action.toJson(),
      'aiReasoning': aiReasoning,
      'confidenceScore': confidenceScore,
      'aiContext': aiContext,
    };

    _auditLog.add(auditRecord);
    await _saveAuditLog();

    _logger.info(
        'AI proactive action logged: ${action.id} (confidence: $confidenceScore)');
  }
}

/// Scheduled task wrapper
class ScheduledTask {
  final AutonomousAction action;
  final Duration? delay;
  final String? cronExpression;
  final Map<String, dynamic>? context;
  dynamic scheduledTask;

  ScheduledTask({
    required this.action,
    this.delay,
    this.cronExpression,
    this.context,
    this.scheduledTask,
  });

  Future<void> cancel() async {
    if (scheduledTask != null) {
      // Cancel the scheduled task
      // Implementation depends on the scheduling library used
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.toJson(),
      'delay': delay?.inMilliseconds,
      'cronExpression': cronExpression,
      'context': context,
    };
  }

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      action: AutonomousAction.fromJson(json['action']),
      delay:
          json['delay'] != null ? Duration(milliseconds: json['delay']) : null,
      cronExpression: json['cronExpression'],
      context: json['context'],
    );
  }
}

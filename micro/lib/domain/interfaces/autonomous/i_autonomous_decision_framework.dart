import '../../models/autonomous/context_analysis.dart';
import '../../models/autonomous/user_intent.dart';
import '../../models/autonomous/autonomous_action.dart';
import '../../../infrastructure/permissions/models/permission_type.dart';

/// Interface for the autonomous decision framework
/// This defines the contract for autonomous decision-making components
abstract class IAutonomousDecisionFramework {
  /// Initialize the autonomous decision framework
  Future<void> initialize();

  /// Check if the framework is initialized
  bool get isInitialized;

  /// Enable or disable autonomous operations
  Future<void> setAutonomousEnabled(bool enabled);

  /// Check if autonomous operations are enabled
  bool get isAutonomousEnabled;

  /// Analyze context for autonomous decision making
  Future<ContextAnalysis> analyzeContext({
    Map<String, dynamic>? contextData,
    String? userId,
  });

  /// Recognize user intent from input
  Future<IntentRecognitionResult> recognizeIntent({
    required String input,
    ContextAnalysis? contextAnalysis,
    String? userId,
  });

  /// Generate autonomous action based on intent and context
  Future<AutonomousAction> generateAction({
    required UserIntent intent,
    required ContextAnalysis context,
    String? userId,
  });

  /// Execute an autonomous action
  Future<ActionExecutionResult> executeAction({
    required AutonomousAction action,
    bool requireUserApproval = false,
  });

  /// Request user approval for an action
  Future<bool> requestUserApproval({
    required AutonomousAction action,
    String? justification,
  });

  /// Get the current context analysis
  ContextAnalysis? get currentContext;

  /// Get the last recognized intent
  UserIntent? get lastIntent;

  /// Get the last generated action
  AutonomousAction? get lastAction;

  /// Get all pending actions
  List<AutonomousAction> get pendingActions;

  /// Get all executing actions
  List<AutonomousAction> get executingActions;

  /// Get action by ID
  AutonomousAction? getActionById(String id);

  /// Cancel an action
  Future<bool> cancelAction(String id);

  /// Approve an action
  Future<bool> approveAction(String id);

  /// Get compliance report for autonomous operations
  Future<Map<String, dynamic>> getComplianceReport();

  /// Get audit log for autonomous operations
  Future<List<Map<String, dynamic>>> getAuditLog({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Clear audit log
  Future<void> clearAuditLog();

  /// Export audit data
  Future<String> exportAuditData({
    String format = 'json',
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get resource usage statistics
  Future<Map<String, dynamic>> getResourceUsageStats();

  /// Get autonomous operation statistics
  Future<Map<String, dynamic>> getOperationStats();

  /// Reset the autonomous framework
  Future<void> reset();

  /// Dispose resources
  Future<void> dispose();
}

/// Interface for context analysis
abstract class IContextAnalyzer {
  /// Initialize the context analyzer
  Future<void> initialize();

  /// Analyze context with user consent checking
  Future<ContextAnalysis> analyzeContext({
    Map<String, dynamic>? contextData,
    String? userId,
  });

  /// Check if user consent is required for context collection
  Future<bool> requiresUserConsent({
    required Map<String, dynamic> contextData,
    String? userId,
  });

  /// Apply data minimization to context data
  Map<String, dynamic> applyDataMinimization({
    required Map<String, dynamic> rawData,
    List<String> allowedFields = const [],
  });

  /// Anonymize sensitive data in context
  Map<String, dynamic> anonymizeData({
    required Map<String, dynamic> data,
    List<String> sensitiveFields = const [],
  });

  /// Get required permissions for context analysis
  List<PermissionType> getRequiredPermissions({
    Map<String, dynamic>? contextData,
  });

  /// Check if context analysis is compliant with store policies
  bool isContextCompliant({
    required Map<String, dynamic> contextData,
    required List<PermissionType> permissions,
  });

  /// Log context analysis for audit
  Future<void> logContextAnalysis({
    required ContextAnalysis analysis,
    Map<String, dynamic>? metadata,
  });
}

/// Interface for intent recognition
abstract class IIntentRecognizer {
  /// Initialize the intent recognizer
  Future<void> initialize();

  /// Recognize user intent from input
  Future<IntentRecognitionResult> recognizeIntent({
    required String input,
    ContextAnalysis? contextAnalysis,
    String? userId,
  });

  /// Check if user has opted out of intent recognition
  Future<bool> hasUserOptedOut(String? userId);

  /// Test intent recognition for bias
  Map<String, double> testForBias({
    required String input,
    required UserIntent intent,
  });

  /// Get confidence score for intent recognition
  double getConfidenceScore({
    required String input,
    required UserIntent intent,
  });

  /// Validate intent against store policies
  IntentPolicyValidation validateIntentPolicy({
    required UserIntent intent,
  });

  /// Get required permissions for intent execution
  List<PermissionType> getRequiredPermissions({
    required UserIntent intent,
  });

  /// Log intent recognition for audit
  Future<void> logIntentRecognition({
    required IntentRecognitionResult result,
    Map<String, dynamic>? metadata,
  });
}

/// Interface for decision engine
abstract class IDecisionEngine {
  /// Initialize the decision engine
  Future<void> initialize();

  /// Generate autonomous action based on intent and context
  Future<AutonomousAction> generateAction({
    required UserIntent intent,
    required ContextAnalysis context,
    String? userId,
  });

  /// Assess risk level for an action
  ActionRiskLevel assessRiskLevel({
    required UserIntent intent,
    required ContextAnalysis context,
    required ActionType actionType,
    Map<String, dynamic>? parameters,
  });

  /// Check if action requires user approval
  bool requiresUserApproval({
    required AutonomousAction action,
  });

  /// Monitor resource usage during action execution
  Map<String, dynamic> monitorResourceUsage({
    required AutonomousAction action,
  });

  /// Check if action is within execution limits
  bool isWithinExecutionLimits({
    required AutonomousAction action,
    Map<String, dynamic>? resourceUsage,
  });

  /// Validate action against store policies
  bool isActionCompliant({
    required AutonomousAction action,
    required ContextAnalysis context,
  });

  /// Log action execution for audit
  Future<void> logActionExecution({
    required ActionExecutionResult result,
    Map<String, dynamic>? metadata,
  });

  /// Get execution limits for action type
  Map<String, dynamic> getExecutionLimits({
    required ActionType actionType,
  });

  /// Check if action can be executed
  bool canExecuteAction({
    required AutonomousAction action,
    required ContextAnalysis context,
  });
}

/// Interface for autonomous framework configuration
abstract class IAutonomousFrameworkConfig {
  /// Get autonomous operations enabled status
  bool get autonomousEnabled;

  /// Set autonomous operations enabled status
  Future<void> setAutonomousEnabled(bool enabled);

  /// Get user consent requirements
  bool get requiresUserConsent;

  /// Set user consent requirements
  Future<void> setRequiresUserConsent(bool required);

  /// Get data minimization enabled status
  bool get dataMinimizationEnabled;

  /// Set data minimization enabled status
  Future<void> setDataMinimizationEnabled(bool enabled);

  /// Get bias testing enabled status
  bool get biasTestingEnabled;

  /// Set bias testing enabled status
  Future<void> setBiasTestingEnabled(bool enabled);

  /// Get audit logging enabled status
  bool get auditLoggingEnabled;

  /// Set audit logging enabled status
  Future<void> setAuditLoggingEnabled(bool enabled);

  /// Get resource monitoring enabled status
  bool get resourceMonitoringEnabled;

  /// Set resource monitoring enabled status
  Future<void> setResourceMonitoringEnabled(bool enabled);

  /// Get confidence threshold for autonomous operations
  double get confidenceThreshold;

  /// Set confidence threshold for autonomous operations
  Future<void> setConfidenceThreshold(double threshold);

  /// Get risk level threshold for user approval
  ActionRiskLevel get riskApprovalThreshold;

  /// Set risk level threshold for user approval
  Future<void> setRiskApprovalThreshold(ActionRiskLevel threshold);

  /// Get maximum execution duration for actions
  Duration get maxExecutionDuration;

  /// Set maximum execution duration for actions
  Future<void> setMaxExecutionDuration(Duration duration);

  /// Get maximum daily actions
  int get maxDailyActions;

  /// Set maximum daily actions
  Future<void> setMaxDailyActions(int maxActions);

  /// Get all configuration settings
  Map<String, dynamic> getAllSettings();

  /// Update configuration settings
  Future<void> updateSettings(Map<String, dynamic> settings);

  /// Reset configuration to defaults
  Future<void> resetToDefaults();
}

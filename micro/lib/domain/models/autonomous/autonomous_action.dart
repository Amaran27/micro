import '../../../infrastructure/permissions/models/permission_type.dart';

/// Action types for autonomous operations
enum ActionType {
  /// Execute a tool or command
  execute,

  /// Navigate to a location
  navigate,

  /// Send a notification
  notify,

  /// Collect data
  collect,

  /// Analyze data
  analyze,

  /// Store data
  store,

  /// Retrieve data
  retrieve,

  /// Configure settings
  configure,

  /// Communicate with external service
  communicate,

  /// Monitor system state
  monitor,

  /// Request user input
  requestInput,

  /// Display information
  display,

  /// Create new content or items
  creation,

  /// Unknown action type
  unknown,
}

/// Action risk levels for autonomous operations
enum ActionRiskLevel {
  /// No risk - safe to execute autonomously
  none,

  /// Low risk - minimal impact
  low,

  /// Medium risk - requires user notification
  medium,

  /// High risk - requires user approval
  high,

  /// Critical risk - requires explicit user consent
  critical,
}

/// Action execution status
enum ActionStatus {
  /// Action is pending execution
  pending,

  /// Action is currently executing
  executing,

  /// Action completed successfully
  completed,

  /// Action failed during execution
  failed,

  /// Action was cancelled
  cancelled,

  /// Action was blocked by policy
  blocked,

  /// Action requires user approval
  requiresApproval,
}

/// Autonomous action representation
class AutonomousAction {
  final String id;
  final DateTime timestamp;
  final ActionType actionType;
  final String description;
  final Map<String, dynamic> parameters;
  final List<PermissionType> requiredPermissions;
  final ActionRiskLevel riskLevel;
  final ActionStatus status;
  final String? result;
  final String? errorMessage;
  final DateTime? executionStartTime;
  final DateTime? executionEndTime;
  final Duration? executionDuration;
  final Duration? estimatedDuration;
  final bool isCompliant;
  final List<String> complianceIssues;
  final bool requiresUserApproval;
  final bool userApproved;
  final String? userId;
  final Map<String, dynamic> auditData;

  const AutonomousAction({
    required this.id,
    required this.timestamp,
    required this.actionType,
    required this.description,
    required this.parameters,
    required this.requiredPermissions,
    required this.riskLevel,
    required this.status,
    this.result,
    this.errorMessage,
    this.executionStartTime,
    this.executionEndTime,
    this.executionDuration,
    this.estimatedDuration,
    required this.isCompliant,
    this.complianceIssues = const [],
    this.requiresUserApproval = false,
    this.userApproved = false,
    this.userId,
    this.auditData = const {},
  });

  /// Create a new autonomous action
  factory AutonomousAction.create({
    required String id,
    required ActionType actionType,
    required String description,
    required Map<String, dynamic> parameters,
    required List<PermissionType> requiredPermissions,
    required ActionRiskLevel riskLevel,
    String? userId,
    Duration? estimatedDuration,
  }) {
    final hasProhibitedPermissions = requiredPermissions.any(
      (p) => p.isProhibitedForAutonomous,
    );
    final isCompliant = !hasProhibitedPermissions;
    final requiresUserApproval =
        riskLevel.index >= ActionRiskLevel.high.index ||
            hasProhibitedPermissions;

    final complianceIssues = <String>[];
    if (hasProhibitedPermissions) {
      complianceIssues.add(
        'Prohibited permissions required: ${requiredPermissions.where((p) => p.isProhibitedForAutonomous).map((p) => p.displayName).join(', ')}',
      );
    }

    return AutonomousAction(
      id: id,
      timestamp: DateTime.now(),
      actionType: actionType,
      description: description,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      riskLevel: riskLevel,
      status: ActionStatus.pending,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      requiresUserApproval: requiresUserApproval,
      userApproved: false,
      userId: userId,
      estimatedDuration: estimatedDuration,
      auditData: {
        'createdAt': DateTime.now().toIso8601String(),
        'riskLevel': riskLevel.name,
        'requiresUserApproval': requiresUserApproval,
      },
    );
  }

  /// Create a completed action
  factory AutonomousAction.completed({
    required AutonomousAction action,
    required String result,
    DateTime? executionEndTime,
  }) {
    final endTime = executionEndTime ?? DateTime.now();
    final duration = action.executionStartTime != null
        ? endTime.difference(action.executionStartTime!)
        : null;

    return AutonomousAction(
      id: action.id,
      timestamp: action.timestamp,
      actionType: action.actionType,
      description: action.description,
      parameters: action.parameters,
      requiredPermissions: action.requiredPermissions,
      riskLevel: action.riskLevel,
      status: ActionStatus.completed,
      result: result,
      executionStartTime: action.executionStartTime,
      executionEndTime: endTime,
      executionDuration: duration,
      estimatedDuration: action.estimatedDuration,
      isCompliant: action.isCompliant,
      complianceIssues: action.complianceIssues,
      requiresUserApproval: action.requiresUserApproval,
      userApproved: action.userApproved,
      userId: action.userId,
      auditData: {
        ...action.auditData,
        'completedAt': endTime.toIso8601String(),
        'executionDuration': duration?.inMilliseconds,
      },
    );
  }

  /// Create a failed action
  factory AutonomousAction.failed({
    required AutonomousAction action,
    required String errorMessage,
    DateTime? executionEndTime,
  }) {
    final endTime = executionEndTime ?? DateTime.now();
    final duration = action.executionStartTime != null
        ? endTime.difference(action.executionStartTime!)
        : null;

    return AutonomousAction(
      id: action.id,
      timestamp: action.timestamp,
      actionType: action.actionType,
      description: action.description,
      parameters: action.parameters,
      requiredPermissions: action.requiredPermissions,
      riskLevel: action.riskLevel,
      status: ActionStatus.failed,
      errorMessage: errorMessage,
      executionStartTime: action.executionStartTime,
      executionEndTime: endTime,
      executionDuration: duration,
      estimatedDuration: action.estimatedDuration,
      isCompliant: action.isCompliant,
      complianceIssues: action.complianceIssues,
      requiresUserApproval: action.requiresUserApproval,
      userApproved: action.userApproved,
      userId: action.userId,
      auditData: {
        ...action.auditData,
        'failedAt': endTime.toIso8601String(),
        'executionDuration': duration?.inMilliseconds,
        'errorMessage': errorMessage,
      },
    );
  }

  /// Start execution of the action
  AutonomousAction startExecution() {
    return AutonomousAction(
      id: id,
      timestamp: timestamp,
      actionType: actionType,
      description: description,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      riskLevel: riskLevel,
      status: ActionStatus.executing,
      executionStartTime: DateTime.now(),
      estimatedDuration: estimatedDuration,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
      auditData: {
        ...auditData,
        'executionStartedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Approve the action for execution
  AutonomousAction approve() {
    return AutonomousAction(
      id: id,
      timestamp: timestamp,
      actionType: actionType,
      description: description,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      riskLevel: riskLevel,
      status:
          requiresUserApproval ? ActionStatus.pending : ActionStatus.executing,
      executionStartTime: requiresUserApproval ? null : DateTime.now(),
      estimatedDuration: estimatedDuration,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      requiresUserApproval: requiresUserApproval,
      userApproved: true,
      userId: userId,
      auditData: {
        ...auditData,
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedBy': userId,
      },
    );
  }

  /// Cancel the action
  AutonomousAction cancel() {
    return AutonomousAction(
      id: id,
      timestamp: timestamp,
      actionType: actionType,
      description: description,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      riskLevel: riskLevel,
      status: ActionStatus.cancelled,
      executionEndTime: DateTime.now(),
      estimatedDuration: estimatedDuration,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
      auditData: {
        ...auditData,
        'cancelledAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Block the action due to policy violations
  AutonomousAction block({String? reason}) {
    return AutonomousAction(
      id: id,
      timestamp: timestamp,
      actionType: actionType,
      description: description,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      riskLevel: riskLevel,
      status: ActionStatus.blocked,
      errorMessage: reason ?? 'Action blocked by policy',
      executionEndTime: DateTime.now(),
      estimatedDuration: estimatedDuration,
      isCompliant: false,
      complianceIssues: [...complianceIssues, if (reason != null) reason],
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
      auditData: {
        ...auditData,
        'blockedAt': DateTime.now().toIso8601String(),
        'blockReason': reason,
      },
    );
  }

  /// Check if action can be executed
  bool get canExecute => isCompliant && (!requiresUserApproval || userApproved);

  /// Check if action is completed
  bool get isCompleted => status == ActionStatus.completed;

  /// Check if action failed
  bool get isFailed => status == ActionStatus.failed;

  /// Check if action is active (pending or executing)
  bool get isActive =>
      [ActionStatus.pending, ActionStatus.executing].contains(status);

  /// Check if action requires approval
  bool get needsApproval => requiresUserApproval && !userApproved;

  /// Get prohibited permissions
  List<PermissionType> get prohibitedPermissions {
    return requiredPermissions
        .where((p) => p.isProhibitedForAutonomous)
        .toList();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'actionType': actionType.name,
      'description': description,
      'parameters': parameters,
      'requiredPermissions': requiredPermissions.map((p) => p.name).toList(),
      'riskLevel': riskLevel.name,
      'status': status.name,
      'result': result,
      'errorMessage': errorMessage,
      'executionStartTime': executionStartTime?.toIso8601String(),
      'executionEndTime': executionEndTime?.toIso8601String(),
      'executionDuration': executionDuration?.inMilliseconds,
      'estimatedDuration': estimatedDuration?.inMilliseconds,
      'isCompliant': isCompliant,
      'complianceIssues': complianceIssues,
      'requiresUserApproval': requiresUserApproval,
      'userApproved': userApproved,
      'userId': userId,
      'auditData': auditData,
    };
  }

  /// Create from JSON
  factory AutonomousAction.fromJson(Map<String, dynamic> json) {
    return AutonomousAction(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      actionType: ActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => ActionType.unknown,
      ),
      description: json['description'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((p) => PermissionType.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PermissionType.networkAccess,
              ))
          .toList(),
      riskLevel: ActionRiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => ActionRiskLevel.medium,
      ),
      status: ActionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ActionStatus.pending,
      ),
      result: json['result'],
      errorMessage: json['errorMessage'],
      executionStartTime: json['executionStartTime'] != null
          ? DateTime.parse(json['executionStartTime'])
          : null,
      executionEndTime: json['executionEndTime'] != null
          ? DateTime.parse(json['executionEndTime'])
          : null,
      executionDuration: json['executionDuration'] != null
          ? Duration(milliseconds: json['executionDuration'])
          : null,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(milliseconds: json['estimatedDuration'])
          : null,
      isCompliant: json['isCompliant'] ?? false,
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
      requiresUserApproval: json['requiresUserApproval'] ?? false,
      userApproved: json['userApproved'] ?? false,
      userId: json['userId'],
      auditData: Map<String, dynamic>.from(json['auditData'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'AutonomousAction(id: $id, actionType: $actionType, riskLevel: $riskLevel, status: $status, isCompliant: $isCompliant)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AutonomousAction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Action execution result with resource monitoring
class ActionExecutionResult {
  final AutonomousAction action;
  final Map<String, dynamic> resourceUsage;
  final List<String> warnings;
  final bool withinResourceLimits;

  const ActionExecutionResult({
    required this.action,
    this.resourceUsage = const {},
    this.warnings = const [],
    this.withinResourceLimits = true,
  });

  /// Create a successful execution result
  factory ActionExecutionResult.success({
    required AutonomousAction action,
    required Map<String, dynamic> resourceUsage,
    List<String> warnings = const [],
  }) {
    return ActionExecutionResult(
      action: action,
      resourceUsage: resourceUsage,
      warnings: warnings,
      withinResourceLimits: true,
    );
  }

  /// Create a failed execution result
  factory ActionExecutionResult.failure({
    required AutonomousAction action,
    required Map<String, dynamic> resourceUsage,
    required List<String> warnings,
  }) {
    return ActionExecutionResult(
      action: action,
      resourceUsage: resourceUsage,
      warnings: warnings,
      withinResourceLimits: false,
    );
  }

  /// Check if execution was successful
  bool get isSuccess => action.isCompleted && withinResourceLimits;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'action': action.toJson(),
      'resourceUsage': resourceUsage,
      'warnings': warnings,
      'withinResourceLimits': withinResourceLimits,
    };
  }

  /// Create from JSON
  factory ActionExecutionResult.fromJson(Map<String, dynamic> json) {
    return ActionExecutionResult(
      action: AutonomousAction.fromJson(json['action']),
      resourceUsage: Map<String, dynamic>.from(json['resourceUsage'] ?? {}),
      warnings: List<String>.from(json['warnings'] ?? []),
      withinResourceLimits: json['withinResourceLimits'] ?? true,
    );
  }
}

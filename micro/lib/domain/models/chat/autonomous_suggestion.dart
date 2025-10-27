import '../autonomous/autonomous_action.dart';
import '../autonomous/user_intent.dart';

/// Suggestion types for autonomous actions
enum SuggestionType {
  /// Suggest a tool to execute
  tool,

  /// Suggest an action to take
  action,

  /// Suggest information to provide
  information,

  /// Suggest a question to ask
  question,

  /// Suggest a configuration change
  configuration,

  /// Suggest navigation
  navigation,

  /// General suggestion
  general,
}

/// Suggestion priority levels
enum SuggestionPriority {
  /// Low priority suggestion
  low,

  /// Medium priority suggestion
  medium,

  /// High priority suggestion
  high,

  /// Critical priority suggestion
  critical,
}

/// Autonomous suggestion model
class AutonomousSuggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionType type;
  final SuggestionPriority priority;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final Map<String, dynamic> parameters;
  final List<String> requiredPermissions;
  final bool isCompliant;
  final List<String> complianceIssues;
  final UserIntent? relatedIntent;
  final AutonomousAction? suggestedAction;
  final String? userId;
  final Map<String, dynamic> metadata;
  final bool isAccepted;
  final bool isRejected;
  final bool isExpired;
  final String? rejectionReason;

  const AutonomousSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.expiresAt,
    this.parameters = const {},
    this.requiredPermissions = const [],
    this.isCompliant = true,
    this.complianceIssues = const [],
    this.relatedIntent,
    this.suggestedAction,
    this.userId,
    this.metadata = const {},
    this.isAccepted = false,
    this.isRejected = false,
    this.isExpired = false,
    this.rejectionReason,
  });

  /// Create a tool suggestion
  factory AutonomousSuggestion.tool({
    required String id,
    required String title,
    required String description,
    required String toolId,
    required Map<String, dynamic> toolParameters,
    SuggestionPriority priority = SuggestionPriority.medium,
    List<String> requiredPermissions = const [],
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.tool,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      parameters: {
        'toolId': toolId,
        'toolParameters': toolParameters,
      },
      requiredPermissions: requiredPermissions,
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create an action suggestion
  factory AutonomousSuggestion.action({
    required String id,
    required String title,
    required String description,
    required ActionType actionType,
    required Map<String, dynamic> actionParameters,
    SuggestionPriority priority = SuggestionPriority.medium,
    List<String> requiredPermissions = const [],
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.action,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      parameters: {
        'actionType': actionType.name,
        'actionParameters': actionParameters,
      },
      requiredPermissions: requiredPermissions,
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create an information suggestion
  factory AutonomousSuggestion.information({
    required String id,
    required String title,
    required String description,
    required String information,
    SuggestionPriority priority = SuggestionPriority.low,
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.information,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      parameters: {
        'information': information,
      },
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create a question suggestion
  factory AutonomousSuggestion.question({
    required String id,
    required String title,
    required String description,
    required String question,
    SuggestionPriority priority = SuggestionPriority.medium,
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.question,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      parameters: {
        'question': question,
      },
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create a configuration suggestion
  factory AutonomousSuggestion.configuration({
    required String id,
    required String title,
    required String description,
    required String configurationKey,
    required dynamic configurationValue,
    SuggestionPriority priority = SuggestionPriority.low,
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.configuration,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      parameters: {
        'configurationKey': configurationKey,
        'configurationValue': configurationValue,
      },
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create a navigation suggestion
  factory AutonomousSuggestion.navigation({
    required String id,
    required String title,
    required String description,
    required String destination,
    SuggestionPriority priority = SuggestionPriority.medium,
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.navigation,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      parameters: {
        'destination': destination,
      },
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create a general suggestion
  factory AutonomousSuggestion.general({
    required String id,
    required String title,
    required String description,
    SuggestionPriority priority = SuggestionPriority.low,
    DateTime? expiresAt,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: SuggestionType.general,
      priority: priority,
      timestamp: DateTime.now(),
      expiresAt: expiresAt,
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Accept the suggestion
  AutonomousSuggestion accept() {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      timestamp: timestamp,
      expiresAt: expiresAt,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      relatedIntent: relatedIntent,
      suggestedAction: suggestedAction,
      userId: userId,
      metadata: metadata,
      isAccepted: true,
      isRejected: false,
      isExpired: isExpired,
      rejectionReason: rejectionReason,
    );
  }

  /// Reject the suggestion
  AutonomousSuggestion reject(String reason) {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      timestamp: timestamp,
      expiresAt: expiresAt,
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      relatedIntent: relatedIntent,
      suggestedAction: suggestedAction,
      userId: userId,
      metadata: metadata,
      isAccepted: false,
      isRejected: true,
      isExpired: isExpired,
      rejectionReason: reason,
    );
  }

  /// Mark suggestion as expired
  AutonomousSuggestion expire() {
    return AutonomousSuggestion(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      timestamp: timestamp,
      expiresAt: DateTime.now(),
      parameters: parameters,
      requiredPermissions: requiredPermissions,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      relatedIntent: relatedIntent,
      suggestedAction: suggestedAction,
      userId: userId,
      metadata: metadata,
      isAccepted: isAccepted,
      isRejected: isRejected,
      isExpired: true,
      rejectionReason: rejectionReason,
    );
  }

  /// Check if suggestion is accepted
  bool get isAcceptedOrRejected => isAccepted || isRejected;

  /// Check if suggestion is still valid
  bool get isValid => !isExpired && !isAcceptedOrRejected;

  /// Check if suggestion is expired
  bool get isExpiredNow =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if suggestion is high priority
  bool get isHighPriority =>
      priority == SuggestionPriority.high ||
      priority == SuggestionPriority.critical;

  /// Check if suggestion requires permissions
  bool get requiresPermissions => requiredPermissions.isNotEmpty;

  /// Check if suggestion has compliance issues
  bool get hasComplianceIssues => complianceIssues.isNotEmpty;

  /// Get tool ID if this is a tool suggestion
  String? get toolId =>
      type == SuggestionType.tool ? parameters['toolId'] : null;

  /// Get tool parameters if this is a tool suggestion
  Map<String, dynamic>? get toolParameters =>
      type == SuggestionType.tool ? parameters['toolParameters'] : null;

  /// Get action type if this is an action suggestion
  ActionType? get actionType => type == SuggestionType.action
      ? ActionType.values.firstWhere(
          (e) => e.name == parameters['actionType'],
          orElse: () => ActionType.unknown,
        )
      : null;

  /// Get action parameters if this is an action suggestion
  Map<String, dynamic>? get actionParameters =>
      type == SuggestionType.action ? parameters['actionParameters'] : null;

  /// Get information if this is an information suggestion
  String? get information =>
      type == SuggestionType.information ? parameters['information'] : null;

  /// Get question if this is a question suggestion
  String? get question =>
      type == SuggestionType.question ? parameters['question'] : null;

  /// Get configuration key if this is a configuration suggestion
  String? get configurationKey => type == SuggestionType.configuration
      ? parameters['configurationKey']
      : null;

  /// Get configuration value if this is a configuration suggestion
  dynamic get configurationValue => type == SuggestionType.configuration
      ? parameters['configurationValue']
      : null;

  /// Get destination if this is a navigation suggestion
  String? get destination =>
      type == SuggestionType.navigation ? parameters['destination'] : null;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'parameters': parameters,
      'requiredPermissions': requiredPermissions,
      'isCompliant': isCompliant,
      'complianceIssues': complianceIssues,
      'relatedIntent': relatedIntent?.toJson(),
      'suggestedAction': suggestedAction?.toJson(),
      'userId': userId,
      'metadata': metadata,
      'isAccepted': isAccepted,
      'isRejected': isRejected,
      'isExpired': isExpired,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create from JSON
  factory AutonomousSuggestion.fromJson(Map<String, dynamic> json) {
    return AutonomousSuggestion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: SuggestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SuggestionType.general,
      ),
      priority: SuggestionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => SuggestionPriority.medium,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      requiredPermissions: List<String>.from(json['requiredPermissions'] ?? []),
      isCompliant: json['isCompliant'] ?? true,
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
      relatedIntent: json['relatedIntent'] != null
          ? UserIntent.fromJson(json['relatedIntent'])
          : null,
      suggestedAction: json['suggestedAction'] != null
          ? AutonomousAction.fromJson(json['suggestedAction'])
          : null,
      userId: json['userId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isAccepted: json['isAccepted'] ?? false,
      isRejected: json['isRejected'] ?? false,
      isExpired: json['isExpired'] ?? false,
      rejectionReason: json['rejectionReason'],
    );
  }

  @override
  String toString() {
    return 'AutonomousSuggestion(id: $id, type: $type, priority: $priority, isAccepted: $isAccepted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AutonomousSuggestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

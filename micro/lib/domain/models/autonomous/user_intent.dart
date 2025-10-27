import '../../../infrastructure/permissions/models/permission_type.dart';

/// User intent types for autonomous decision making
enum IntentType {
  /// User wants to perform a specific action
  action,

  /// User is asking a question
  query,

  /// User wants to configure something
  configuration,

  /// User is providing feedback
  feedback,

  /// User wants to navigate somewhere
  navigation,

  /// User wants to communicate
  communication,

  /// User wants to analyze something
  analysis,

  /// User wants to create something
  creation,

  /// User wants to monitor something
  monitoring,

  /// User intent is unclear
  unknown,
}

/// Intent confidence levels
enum IntentConfidence {
  /// Very low confidence (0.0-0.2)
  veryLow,

  /// Low confidence (0.2-0.4)
  low,

  /// Medium confidence (0.4-0.6)
  medium,

  /// High confidence (0.6-0.8)
  high,

  /// Very high confidence (0.8-1.0)
  veryHigh,
}

/// User intent recognition result
class UserIntent {
  final String id;
  final DateTime timestamp;
  final String originalInput;
  final IntentType intentType;
  final String? specificIntent;
  final Map<String, dynamic> parameters;
  final double confidenceScore;
  final IntentConfidence confidenceLevel;
  final List<PermissionType> requiredPermissions;
  final bool isCompliant;
  final List<String> complianceIssues;
  final bool requiresUserApproval;
  final String? userId;

  const UserIntent({
    required this.id,
    required this.timestamp,
    required this.originalInput,
    required this.intentType,
    this.specificIntent,
    required this.parameters,
    required this.confidenceScore,
    required this.confidenceLevel,
    required this.requiredPermissions,
    required this.isCompliant,
    this.complianceIssues = const [],
    this.requiresUserApproval = false,
    this.userId,
  });

  /// Create a successful intent recognition
  factory UserIntent.success({
    required String id,
    required String originalInput,
    required IntentType intentType,
    String? specificIntent,
    required Map<String, dynamic> parameters,
    required double confidenceScore,
    required List<PermissionType> requiredPermissions,
    String? userId,
  }) {
    final confidenceLevel = _getConfidenceLevel(confidenceScore);
    final hasProhibitedPermissions = requiredPermissions.any(
      (p) => p.isProhibitedForAutonomous,
    );
    final isCompliant = !hasProhibitedPermissions;
    final requiresUserApproval =
        confidenceScore < 0.7 || hasProhibitedPermissions;

    final complianceIssues = <String>[];
    if (hasProhibitedPermissions) {
      complianceIssues.add(
        'Prohibited permissions required: ${requiredPermissions.where((p) => p.isProhibitedForAutonomous).map((p) => p.displayName).join(', ')}',
      );
    }

    return UserIntent(
      id: id,
      timestamp: DateTime.now(),
      originalInput: originalInput,
      intentType: intentType,
      specificIntent: specificIntent,
      parameters: parameters,
      confidenceScore: confidenceScore,
      confidenceLevel: confidenceLevel,
      requiredPermissions: requiredPermissions,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      requiresUserApproval: requiresUserApproval,
      userId: userId,
    );
  }

  /// Create a failed intent recognition
  factory UserIntent.failure({
    required String id,
    required String originalInput,
    required double confidenceScore,
    required List<String> complianceIssues,
    String? userId,
  }) {
    return UserIntent(
      id: id,
      timestamp: DateTime.now(),
      originalInput: originalInput,
      intentType: IntentType.unknown,
      parameters: {},
      confidenceScore: confidenceScore,
      confidenceLevel: _getConfidenceLevel(confidenceScore),
      requiredPermissions: [],
      isCompliant: false,
      complianceIssues: complianceIssues,
      requiresUserApproval: true,
      userId: userId,
    );
  }

  /// Get confidence level from score
  static IntentConfidence _getConfidenceLevel(double score) {
    if (score < 0.2) return IntentConfidence.veryLow;
    if (score < 0.4) return IntentConfidence.low;
    if (score < 0.6) return IntentConfidence.medium;
    if (score < 0.8) return IntentConfidence.high;
    return IntentConfidence.veryHigh;
  }

  /// Check if intent recognition is successful
  bool get isSuccess => isCompliant && confidenceScore >= 0.5;

  /// Check if intent recognition has high confidence
  bool get hasHighConfidence => confidenceScore >= 0.7;

  /// Check if intent recognition requires user approval
  bool get needsUserApproval => requiresUserApproval || !isCompliant;

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
      'originalInput': originalInput,
      'intentType': intentType.name,
      'specificIntent': specificIntent,
      'parameters': parameters,
      'confidenceScore': confidenceScore,
      'confidenceLevel': confidenceLevel.name,
      'requiredPermissions': requiredPermissions.map((p) => p.name).toList(),
      'isCompliant': isCompliant,
      'complianceIssues': complianceIssues,
      'requiresUserApproval': requiresUserApproval,
      'userId': userId,
    };
  }

  /// Create from JSON
  factory UserIntent.fromJson(Map<String, dynamic> json) {
    return UserIntent(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      originalInput: json['originalInput'],
      intentType: IntentType.values.firstWhere(
        (e) => e.name == json['intentType'],
        orElse: () => IntentType.unknown,
      ),
      specificIntent: json['specificIntent'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      confidenceLevel: IntentConfidence.values.firstWhere(
        (e) => e.name == json['confidenceLevel'],
        orElse: () => IntentConfidence.low,
      ),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((p) => PermissionType.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PermissionType.networkAccess,
              ))
          .toList(),
      isCompliant: json['isCompliant'] ?? false,
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
      requiresUserApproval: json['requiresUserApproval'] ?? false,
      userId: json['userId'],
    );
  }

  @override
  String toString() {
    return 'UserIntent(id: $id, intentType: $intentType, confidenceScore: $confidenceScore, isCompliant: $isCompliant)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserIntent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Intent recognition result with bias testing
class IntentRecognitionResult {
  final UserIntent intent;
  final Map<String, double> biasScores;
  final List<String> biasWarnings;
  final bool isBiasTested;
  final bool passesBiasTest;

  const IntentRecognitionResult({
    required this.intent,
    this.biasScores = const {},
    this.biasWarnings = const [],
    this.isBiasTested = false,
    this.passesBiasTest = true,
  });

  /// Create a successful intent recognition result
  factory IntentRecognitionResult.success({
    required UserIntent intent,
    required Map<String, double> biasScores,
    required List<String> biasWarnings,
  }) {
    final passesBiasTest = biasScores.values.every((score) => score < 0.3);

    return IntentRecognitionResult(
      intent: intent,
      biasScores: biasScores,
      biasWarnings: biasWarnings,
      isBiasTested: true,
      passesBiasTest: passesBiasTest,
    );
  }

  /// Create a failed intent recognition result
  factory IntentRecognitionResult.failure({
    required UserIntent intent,
    required List<String> biasWarnings,
  }) {
    return IntentRecognitionResult(
      intent: intent,
      biasWarnings: biasWarnings,
      isBiasTested: true,
      passesBiasTest: false,
    );
  }

  /// Check if intent recognition is successful
  bool get isSuccess => intent.isSuccess && passesBiasTest;

  /// Check if intent recognition requires user approval
  bool get requiresUserApproval =>
      intent.requiresUserApproval || !passesBiasTest;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'intent': intent.toJson(),
      'biasScores': biasScores,
      'biasWarnings': biasWarnings,
      'isBiasTested': isBiasTested,
      'passesBiasTest': passesBiasTest,
    };
  }

  /// Create from JSON
  factory IntentRecognitionResult.fromJson(Map<String, dynamic> json) {
    return IntentRecognitionResult(
      intent: UserIntent.fromJson(json['intent']),
      biasScores: Map<String, double>.from(json['biasScores'] ?? {}),
      biasWarnings: List<String>.from(json['biasWarnings'] ?? []),
      isBiasTested: json['isBiasTested'] ?? false,
      passesBiasTest: json['passesBiasTest'] ?? true,
    );
  }
}

/// Intent policy validation result
class IntentPolicyValidation {
  final bool isValid;
  final List<String> violations;
  final List<String> warnings;
  final Map<String, dynamic> policyRequirements;

  const IntentPolicyValidation({
    required this.isValid,
    this.violations = const [],
    this.warnings = const [],
    this.policyRequirements = const {},
  });

  /// Create a valid policy validation
  factory IntentPolicyValidation.valid({
    Map<String, dynamic> policyRequirements = const {},
  }) {
    return IntentPolicyValidation(
      isValid: true,
      policyRequirements: policyRequirements,
    );
  }

  /// Create an invalid policy validation
  factory IntentPolicyValidation.invalid({
    required List<String> violations,
    List<String> warnings = const [],
    Map<String, dynamic> policyRequirements = const {},
  }) {
    return IntentPolicyValidation(
      isValid: false,
      violations: violations,
      warnings: warnings,
      policyRequirements: policyRequirements,
    );
  }

  /// Check if validation has critical violations
  bool get hasCriticalViolations => violations.isNotEmpty;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'violations': violations,
      'warnings': warnings,
      'policyRequirements': policyRequirements,
    };
  }

  /// Create from JSON
  factory IntentPolicyValidation.fromJson(Map<String, dynamic> json) {
    return IntentPolicyValidation(
      isValid: json['isValid'] ?? false,
      violations: List<String>.from(json['violations'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      policyRequirements:
          Map<String, dynamic>.from(json['policyRequirements'] ?? {}),
    );
  }
}

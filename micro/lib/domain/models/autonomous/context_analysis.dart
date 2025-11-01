import '../../../infrastructure/permissions/models/permission_type.dart';

/// Context analysis result for autonomous decision making
class ContextAnalysis {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> contextData;
  final List<PermissionType> requiredPermissions;
  final List<PermissionType> grantedPermissions;
  final List<PermissionType> deniedPermissions;
  final double confidenceScore;
  final bool isCompliant;
  final List<String> complianceIssues;
  final Map<String, dynamic> anonymizedData;
  final String? userId;

  const ContextAnalysis({
    required this.id,
    required this.timestamp,
    required this.contextData,
    required this.requiredPermissions,
    required this.grantedPermissions,
    required this.deniedPermissions,
    required this.confidenceScore,
    required this.isCompliant,
    this.complianceIssues = const [],
    this.anonymizedData = const {},
    this.userId,
  });

  /// Create a successful context analysis
  factory ContextAnalysis.success({
    required String id,
    required Map<String, dynamic> contextData,
    required List<PermissionType> requiredPermissions,
    required List<PermissionType> grantedPermissions,
    required List<PermissionType> deniedPermissions,
    required double confidenceScore,
    required Map<String, dynamic> anonymizedData,
    String? userId,
  }) {
    final allPermissions = requiredPermissions.toSet();
    final grantedSet = grantedPermissions.toSet();

    // Check if all required permissions are granted
    final missingPermissions = allPermissions.difference(grantedSet);
    final hasProhibitedPermissions = deniedPermissions.any(
      (p) => p.isProhibitedForAutonomous,
    );

    final isCompliant = missingPermissions.isEmpty && !hasProhibitedPermissions;
    final complianceIssues = <String>[];

    if (missingPermissions.isNotEmpty) {
      complianceIssues.add(
        'Missing required permissions: ${missingPermissions.map((p) => p.displayName).join(', ')}',
      );
    }

    if (hasProhibitedPermissions) {
      complianceIssues.add(
        'Prohibited permissions requested: ${deniedPermissions.where((p) => p.isProhibitedForAutonomous).map((p) => p.displayName).join(', ')}',
      );
    }

    return ContextAnalysis(
      id: id,
      timestamp: DateTime.now(),
      contextData: contextData,
      requiredPermissions: requiredPermissions,
      grantedPermissions: grantedPermissions,
      deniedPermissions: deniedPermissions,
      confidenceScore: confidenceScore,
      isCompliant: isCompliant,
      complianceIssues: complianceIssues,
      anonymizedData: anonymizedData,
      userId: userId,
    );
  }

  /// Create a failed context analysis
  factory ContextAnalysis.failure({
    required String id,
    required Map<String, dynamic> contextData,
    required List<PermissionType> requiredPermissions,
    required List<PermissionType> grantedPermissions,
    required List<PermissionType> deniedPermissions,
    required double confidenceScore,
    required List<String> complianceIssues,
    Map<String, dynamic> anonymizedData = const {},
    String? userId,
  }) {
    return ContextAnalysis(
      id: id,
      timestamp: DateTime.now(),
      contextData: contextData,
      requiredPermissions: requiredPermissions,
      grantedPermissions: grantedPermissions,
      deniedPermissions: deniedPermissions,
      confidenceScore: confidenceScore,
      isCompliant: false,
      complianceIssues: complianceIssues,
      anonymizedData: anonymizedData,
      userId: userId,
    );
  }

  /// Check if context analysis is successful
  bool get isSuccess => isCompliant && confidenceScore >= 0.7;

  /// Check if context analysis has high confidence
  bool get hasHighConfidence => confidenceScore >= 0.8;

  /// Check if context analysis requires user approval
  bool get requiresUserApproval => !isCompliant || confidenceScore < 0.7;

  /// Get missing permissions
  List<PermissionType> get missingPermissions {
    final requiredSet = requiredPermissions.toSet();
    final grantedSet = grantedPermissions.toSet();
    return requiredSet.difference(grantedSet).toList();
  }

  /// Get prohibited permissions
  List<PermissionType> get prohibitedPermissions {
    return deniedPermissions.where((p) => p.isProhibitedForAutonomous).toList();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'contextData': contextData,
      'requiredPermissions': requiredPermissions.map((p) => p.name).toList(),
      'grantedPermissions': grantedPermissions.map((p) => p.name).toList(),
      'deniedPermissions': deniedPermissions.map((p) => p.name).toList(),
      'confidenceScore': confidenceScore,
      'isCompliant': isCompliant,
      'complianceIssues': complianceIssues,
      'anonymizedData': anonymizedData,
      'userId': userId,
    };
  }

  /// Create from JSON
  factory ContextAnalysis.fromJson(Map<String, dynamic> json) {
    return ContextAnalysis(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      contextData: Map<String, dynamic>.from(json['contextData'] ?? {}),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((p) => PermissionType.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PermissionType.networkAccess,
              ))
          .toList(),
      grantedPermissions: (json['grantedPermissions'] as List<dynamic>)
          .map((p) => PermissionType.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PermissionType.networkAccess,
              ))
          .toList(),
      deniedPermissions: (json['deniedPermissions'] as List<dynamic>)
          .map((p) => PermissionType.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PermissionType.networkAccess,
              ))
          .toList(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      isCompliant: json['isCompliant'] ?? false,
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
      anonymizedData: Map<String, dynamic>.from(json['anonymizedData'] ?? {}),
      userId: json['userId'],
    );
  }

  @override
  String toString() {
    return 'ContextAnalysis(id: $id, isCompliant: $isCompliant, confidenceScore: $confidenceScore, requiredPermissions: ${requiredPermissions.length}, grantedPermissions: ${grantedPermissions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextAnalysis && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Context data collection result
class ContextDataCollection {
  final Map<String, dynamic> rawData;
  final Map<String, dynamic> anonymizedData;
  final List<PermissionType> requiredPermissions;
  final List<String> dataMinimizationApplied;
  final bool isCompliant;
  final List<String> complianceIssues;

  const ContextDataCollection({
    required this.rawData,
    required this.anonymizedData,
    required this.requiredPermissions,
    this.dataMinimizationApplied = const [],
    this.isCompliant = true,
    this.complianceIssues = const [],
  });

  /// Create a successful context data collection
  factory ContextDataCollection.success({
    required Map<String, dynamic> rawData,
    required Map<String, dynamic> anonymizedData,
    required List<PermissionType> requiredPermissions,
    required List<String> dataMinimizationApplied,
  }) {
    return ContextDataCollection(
      rawData: rawData,
      anonymizedData: anonymizedData,
      requiredPermissions: requiredPermissions,
      dataMinimizationApplied: dataMinimizationApplied,
      isCompliant: true,
    );
  }

  /// Create a failed context data collection
  factory ContextDataCollection.failure({
    required Map<String, dynamic> rawData,
    required List<PermissionType> requiredPermissions,
    required List<String> complianceIssues,
  }) {
    return ContextDataCollection(
      rawData: rawData,
      anonymizedData: {},
      requiredPermissions: requiredPermissions,
      isCompliant: false,
      complianceIssues: complianceIssues,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'rawData': rawData,
      'anonymizedData': anonymizedData,
      'requiredPermissions': requiredPermissions.map((p) => p.name).toList(),
      'dataMinimizationApplied': dataMinimizationApplied,
      'isCompliant': isCompliant,
      'complianceIssues': complianceIssues,
    };
  }

  /// Create from JSON
  factory ContextDataCollection.fromJson(Map<String, dynamic> json) {
    return ContextDataCollection(
      rawData: Map<String, dynamic>.from(json['rawData'] ?? {}),
      anonymizedData: Map<String, dynamic>.from(json['anonymizedData'] ?? {}),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((p) => PermissionType.values.firstWhere(
                (e) => e.name == p,
                orElse: () => PermissionType.networkAccess,
              ))
          .toList(),
      dataMinimizationApplied:
          List<String>.from(json['dataMinimizationApplied'] ?? []),
      isCompliant: json['isCompliant'] ?? true,
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
    );
  }
}

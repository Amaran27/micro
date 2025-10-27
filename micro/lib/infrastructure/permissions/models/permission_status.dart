import 'permission_type.dart';

/// Permission status enumeration for tracking permission states
enum PermissionStatus {
  /// Permission has been granted by the user
  granted,

  /// Permission has been denied by the user
  denied,

  /// Permission has been permanently denied (user selected "Don't ask again")
  permanentlyDenied,

  /// Permission is restricted by system settings or parental controls
  restricted,

  /// Permission is not applicable to this device/platform
  notApplicable,

  /// Permission status is currently being determined
  determining,

  /// Permission request has been deferred (user can decide later)
  deferred,
}

/// Extension methods for PermissionStatus enum
extension PermissionStatusExtension on PermissionStatus {
  /// Get human-readable display name
  String get displayName {
    switch (this) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.notApplicable:
        return 'Not Applicable';
      case PermissionStatus.determining:
        return 'Determining';
      case PermissionStatus.deferred:
        return 'Deferred';
    }
  }

  /// Check if permission is effectively granted for use
  bool get isGranted => this == PermissionStatus.granted;

  /// Check if permission is denied (including permanently)
  bool get isDenied => [
        PermissionStatus.denied,
        PermissionStatus.permanentlyDenied,
      ].contains(this);

  /// Check if permission can be requested again
  bool get canRequest => ![
        PermissionStatus.permanentlyDenied,
        PermissionStatus.restricted,
      ].contains(this);

  /// Check if user should be directed to settings
  bool get shouldOpenSettings => [
        PermissionStatus.permanentlyDenied,
        PermissionStatus.restricted,
      ].contains(this);

  /// Get appropriate user guidance message
  String get userGuidance {
    switch (this) {
      case PermissionStatus.granted:
        return 'Permission has been granted. You can use this feature now.';
      case PermissionStatus.denied:
        return 'Permission was denied. You can request it again when needed.';
      case PermissionStatus.permanentlyDenied:
        return 'Permission was permanently denied. Please enable it in app settings.';
      case PermissionStatus.restricted:
        return 'Permission is restricted by system settings. Please check your device settings.';
      case PermissionStatus.notApplicable:
        return 'This permission is not applicable to your device.';
      case PermissionStatus.determining:
        return 'Checking permission status...';
      case PermissionStatus.deferred:
        return 'You can decide about this permission later when using the feature.';
    }
  }
}

/// Permission request result with additional context
class PermissionRequestResult {
  final PermissionType permissionType;
  final PermissionStatus status;
  final DateTime timestamp;
  final String? justification;
  final bool wasJustificationShown;
  final Map<String, dynamic>? context;
  final String? errorMessage;

  const PermissionRequestResult({
    required this.permissionType,
    required this.status,
    required this.timestamp,
    this.justification,
    this.wasJustificationShown = false,
    this.context,
    this.errorMessage,
  });

  /// Create a successful result
  factory PermissionRequestResult.granted(
    PermissionType permissionType, {
    String? justification,
    bool wasJustificationShown = false,
    Map<String, dynamic>? context,
  }) {
    return PermissionRequestResult(
      permissionType: permissionType,
      status: PermissionStatus.granted,
      timestamp: DateTime.now(),
      justification: justification,
      wasJustificationShown: wasJustificationShown,
      context: context,
    );
  }

  /// Create a denied result
  factory PermissionRequestResult.denied(
    PermissionType permissionType, {
    String? justification,
    bool wasJustificationShown = false,
    bool permanentlyDenied = false,
    Map<String, dynamic>? context,
    String? errorMessage,
  }) {
    return PermissionRequestResult(
      permissionType: permissionType,
      status: permanentlyDenied
          ? PermissionStatus.permanentlyDenied
          : PermissionStatus.denied,
      timestamp: DateTime.now(),
      justification: justification,
      wasJustificationShown: wasJustificationShown,
      context: context,
      errorMessage: errorMessage,
    );
  }

  /// Create a restricted result
  factory PermissionRequestResult.restricted(
    PermissionType permissionType, {
    String? justification,
    Map<String, dynamic>? context,
  }) {
    return PermissionRequestResult(
      permissionType: permissionType,
      status: PermissionStatus.restricted,
      timestamp: DateTime.now(),
      justification: justification,
      wasJustificationShown: justification != null,
      context: context,
    );
  }

  /// Check if request was successful
  bool get isSuccess => status.isGranted;

  /// Check if request failed
  bool get isFailure => status.isDenied;

  /// Check if user should be directed to settings
  bool get shouldOpenSettings => status.shouldOpenSettings;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'permissionType': permissionType.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'justification': justification,
      'wasJustificationShown': wasJustificationShown,
      'context': context,
    };
  }

  /// Create from JSON
  factory PermissionRequestResult.fromJson(Map<String, dynamic> json) {
    return PermissionRequestResult(
      permissionType: PermissionType.values.firstWhere(
        (p) => p.name == json['permissionType'],
        orElse: () => PermissionType.networkAccess,
      ),
      status: PermissionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PermissionStatus.denied,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      justification: json['justification'],
      wasJustificationShown: json['wasJustificationShown'] ?? false,
      context: json['context'],
    );
  }
}

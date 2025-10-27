import 'dart:async';
import '../models/permission_type.dart';
import '../models/permission_status.dart';
import '../../../core/utils/logger.dart';

/// Runtime permission requester
/// Handles runtime permission requests on mobile platforms
class RuntimePermissionRequester {
  final AppLogger _logger;
  final Map<PermissionType, PermissionStatus> _permissionStates = {};

  RuntimePermissionRequester({AppLogger? logger})
      : _logger = logger ?? AppLogger();

  /// Initialize the permission requester
  Future<void> initialize() async {
    _logger.info('Initializing Runtime Permission Requester');

    // Initialize all permission states to denied
    for (final permissionType in PermissionType.values) {
      _permissionStates[permissionType] = PermissionStatus.denied;
    }
  }

  /// Check if a permission should be requested
  bool shouldRequestPermission(PermissionType permissionType) {
    // Default implementation - always return true for testing
    return true;
  }

  /// Request a permission
  Future<PermissionRequestResult> requestPermission(
    PermissionType permissionType, {
    String? customJustification,
    Map<String, dynamic>? context,
    bool forceJustification = false,
  }) async {
    _logger.info('Requesting permission: ${permissionType.displayName}');

    // Simulate permission request - in real app would use platform APIs
    await Future.delayed(const Duration(milliseconds: 500));

    // For testing, always grant the permission
    final status = PermissionStatus.granted;
    _permissionStates[permissionType] = status;

    _logger.info('Permission ${permissionType.displayName} granted');

    return PermissionRequestResult.granted(
      permissionType,
      justification: customJustification ?? 'Permission granted for testing',
      context: context,
    );
  }

  /// Check if a permission is granted
  Future<bool> isPermissionGranted(PermissionType permissionType) async {
    final status = _permissionStates[permissionType] ?? PermissionStatus.denied;
    return status.isGranted;
  }

  /// Get permission status
  PermissionStatus? getPermissionStatus(PermissionType permissionType) {
    return _permissionStates[permissionType];
  }

  /// Open app settings
  Future<bool> openAppSettings(PermissionType permissionType) async {
    _logger.info('Opening app settings for ${permissionType.displayName}');

    // In a real app, this would open the device settings
    // For testing, just return true
    return true;
  }

  /// Get request statistics
  Map<PermissionType, PermissionRequestStats> getRequestStats() {
    // Return empty stats for testing
    return {};
  }

  /// Reset tracking
  void resetTracking() {
    _logger.info('Resetting permission tracking');
    _permissionStates.clear();
  }
}

/// Result of a permission request - use the one from permission_status.dart instead
/// This class is deprecated, use PermissionRequestResult from permission_status.dart
@Deprecated('Use PermissionRequestResult from permission_status.dart')
class RuntimePermissionRequestResult {
  final PermissionType permissionType;
  final PermissionStatus status;
  final String? justification;
  final Map<String, dynamic>? context;
  final String? errorMessage;

  RuntimePermissionRequestResult({
    required this.permissionType,
    required this.status,
    this.justification,
    this.context,
    this.errorMessage,
  });

  /// Create a granted result
  factory RuntimePermissionRequestResult.granted(
    PermissionType permissionType,
    String? justification,
    Map<String, dynamic>? context,
  ) {
    return RuntimePermissionRequestResult(
      permissionType: permissionType,
      status: PermissionStatus.granted,
      justification: justification,
      context: context,
    );
  }

  /// Create a denied result
  factory RuntimePermissionRequestResult.denied(
    PermissionType permissionType,
    String? justification,
    Map<String, dynamic>? context,
    String? errorMessage,
  ) {
    return RuntimePermissionRequestResult(
      permissionType: permissionType,
      status: PermissionStatus.denied,
      justification: justification,
      context: context,
      errorMessage: errorMessage,
    );
  }
}

/// Statistics for permission requests
class PermissionRequestStats {
  final int totalRequests;
  final int grantedRequests;
  final int deniedRequests;
  final DateTime? lastRequested;

  PermissionRequestStats({
    required this.totalRequests,
    required this.grantedRequests,
    required this.deniedRequests,
    this.lastRequested,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'grantedRequests': grantedRequests,
      'deniedRequests': deniedRequests,
      'lastRequested': lastRequested?.toIso8601String(),
    };
  }
}

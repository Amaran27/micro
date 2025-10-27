import 'dart:async';
import '../models/permission_type.dart';
import '../models/permission_status.dart';
import '../models/store_policy.dart';
import 'store_policy_validator.dart';
import 'runtime_permission_requester.dart';
import 'permission_auditor.dart';
import '../../../core/utils/logger.dart';

/// Main coordinator for store-compliant permissions management
/// Integrates policy validation, runtime requests, and audit logging
class StoreCompliantPermissionsManager {
  final StorePolicyValidator _policyValidator;
  final RuntimePermissionRequester _requester;
  final PermissionAuditor _auditor;
  final AppLogger _logger;

  // Cache for permission states
  final Map<PermissionType, PermissionStatus> _permissionStates = {};

  // Stream controllers for permission state changes
  final Map<PermissionType, StreamController<PermissionStatus>> _controllers =
      {};

  StoreCompliantPermissionsManager({
    required StorePolicyValidator policyValidator,
    required RuntimePermissionRequester requester,
    required PermissionAuditor auditor,
    AppLogger? logger,
  })  : _policyValidator = policyValidator,
        _requester = requester,
        _auditor = auditor,
        _logger = logger ?? AppLogger();

  /// Initialize the permissions manager
  Future<void> initialize() async {
    _logger.info('Initializing Store-Compliant Permissions Manager');

    // Load cached permission states
    await _loadPermissionStates();

    // Initialize audit system
    await _auditor.clearAuditLog();

    _logger.info('Store-Compliant Permissions Manager initialized');
  }

  /// Request a permission with full store compliance
  Future<PermissionRequestResult> requestPermission(
    PermissionType permissionType, {
    String? customJustification,
    Map<String, dynamic>? context,
    bool forceJustification = false,
  }) async {
    _logger.info('Requesting permission: ${permissionType.displayName}');

    // Check if permission should be requested
    if (!_requester.shouldRequestPermission(permissionType)) {
      _logger
          .debug('Permission request skipped: ${permissionType.displayName}');
      return PermissionRequestResult.denied(
        permissionType,
        justification: 'Permission request not allowed at this time',
        context: context,
      );
    }

    // Request the permission
    final result = await _requester.requestPermission(
      permissionType,
      customJustification: customJustification,
      context: context,
      forceJustification: forceJustification,
    );

    // Update cached state
    _permissionStates[permissionType] = result.status;

    // Log for audit
    await _auditor.logPermissionRequest(result);

    return result;
  }

  /// Request multiple permissions
  Future<List<PermissionRequestResult>> requestPermissions(
    List<PermissionType> permissionTypes, {
    Map<String, String>? customJustifications,
    Map<PermissionType, Map<String, dynamic>>? contexts,
  }) async {
    _logger.info('Requesting ${permissionTypes.length} permissions');

    final results = <PermissionRequestResult>[];

    for (final permissionType in permissionTypes) {
      final result = await requestPermission(
        permissionType,
        customJustification: customJustifications?[permissionType.name],
        context: contexts?[permissionType],
      );
      results.add(result);
    }

    return results;
  }

  /// Check if permission is granted
  Future<bool> isPermissionGranted(PermissionType permissionType) async {
    final cachedStatus = _permissionStates[permissionType];
    if (cachedStatus != null) {
      return cachedStatus.isGranted;
    }

    // Check with runtime requester
    return await _requester.isPermissionGranted(permissionType);
  }

  /// Get permission status
  PermissionStatus? getPermissionStatus(PermissionType permissionType) {
    return _permissionStates[permissionType];
  }

  /// Open app settings for a permission
  Future<bool> openAppSettings(PermissionType permissionType) async {
    _logger.info('Opening app settings for ${permissionType.displayName}');
    return await _requester.openAppSettings(permissionType);
  }

  /// Get policy details for a permission
  StorePolicyDetails getPolicyDetails(PermissionType permissionType) {
    return _policyValidator.getPolicyDetails(permissionType);
  }

  /// Check if permission requires user interaction
  bool requiresUserInteraction(PermissionType permissionType) {
    return _policyValidator.requiresUserInteraction(permissionType);
  }

  /// Check if permission requires special justification
  bool requiresSpecialJustification(PermissionType permissionType) {
    return _policyValidator.requiresSpecialJustification(permissionType);
  }

  /// Get user guidance for a permission
  String? getUserGuidance(PermissionType permissionType) {
    return _policyValidator.getUserGuidance(permissionType);
  }

  /// Get requirements for a permission
  List<String> getPermissionRequirements(PermissionType permissionType) {
    return _policyValidator.getPermissionRequirements(permissionType);
  }

  /// Get usage statistics for a permission
  PermissionRequestStats? getPermissionUsageStats(
      PermissionType permissionType) {
    return _requester.getRequestStats()[permissionType];
  }

  /// Get all usage statistics
  Map<PermissionType, PermissionRequestStats> getAllUsageStats() {
    return _requester.getRequestStats();
  }

  /// Generate compliance report
  Future<ComplianceReport> generateComplianceReport() async {
    _logger.info('Generating compliance report');
    return await _auditor.generateComplianceReport();
  }

  /// Get permission audit log
  Future<List<PermissionAuditRecord>> getPermissionAuditLog({
    PermissionType? permissionType,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (permissionType == null) {
      return await _auditor.getFullAuditLog(
        limit: limit ?? 100,
        startDate: startDate,
        endDate: endDate,
      );
    }
    return await _auditor.getPermissionAuditLog(
      permissionType,
      limit: limit ?? 100,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get full audit log
  Future<List<PermissionAuditRecord>> getFullAuditLog({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _auditor.getFullAuditLog(
      limit: limit ?? 100,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Export audit data
  Future<String> exportAuditData({
    AuditExportFormat format = AuditExportFormat.json,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _auditor.exportAuditData(
      format: format,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Clear audit log
  Future<void> clearAuditLog() async {
    _logger.info('Clearing permission audit log');
    await _auditor.clearAuditLog();
  }

  /// Listen to permission state changes
  Stream<PermissionStatus> listenToPermissionChanges(
      PermissionType permissionType) {
    // Create stream controller if it doesn't exist
    _controllers.putIfAbsent(
      permissionType,
      () => StreamController<PermissionStatus>.broadcast(),
    );

    // Return the stream
    return _controllers[permissionType]!.stream;
  }

  /// Validate overall compliance
  Future<ComplianceReport> validateOverallCompliance() async {
    _logger.info('Validating overall compliance');

    // Get all permission types that might be used
    final allPermissionTypes = PermissionType.values;

    // Generate report
    final report =
        _policyValidator.validatePermissionsCompliance(allPermissionTypes);

    _logger.info('Overall compliance validation completed');
    return report;
  }

  /// Reset permission tracking
  Future<void> resetTracking() async {
    _logger.info('Resetting permission tracking');

    // Clear caches
    _permissionStates.clear();

    // Reset requesters and auditors
    _requester.resetTracking();
    await _auditor.clearAuditLog();
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.info('Disposing Store-Compliant Permissions Manager');

    // Close all stream controllers
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();

    // Clear caches
    _permissionStates.clear();
  }

  /// Load permission states from cache
  Future<void> _loadPermissionStates() async {
    // This would typically load from persistent storage
    // For now, we'll initialize with default values
    for (final permissionType in PermissionType.values) {
      _permissionStates[permissionType] = PermissionStatus.denied;
    }
  }

  /// Save permission states to cache
  Future<void> _savePermissionStates() async {
    // This would typically save to persistent storage
    // For now, we'll just log
    _logger.debug('Saving permission states: $_permissionStates');
  }

  /// Handle permission state change
  void _onPermissionStateChanged(
    PermissionType permissionType,
    PermissionStatus oldStatus,
    PermissionStatus newStatus,
  ) {
    _logger.debug(
      'Permission state changed: ${permissionType.displayName} ${oldStatus.name} -> ${newStatus.name}',
    );

    // Update cache
    _permissionStates[permissionType] = newStatus;

    // Save to persistent storage
    _savePermissionStates();
  }

  /// Get platform-specific compliance notes
  List<String> getPlatformComplianceNotes() {
    return _policyValidator.getPlatformComplianceNotes();
  }

  /// Check if background execution is compliant
  bool isBackgroundExecutionCompliant(
    PermissionType permissionType,
    Duration executionDuration,
  ) {
    return _policyValidator.isBackgroundExecutionCompliant(
      permissionType,
      executionDuration,
    );
  }

  /// Check if request context is compliant
  bool isRequestContextCompliant(
    PermissionType permissionType,
    Map<String, dynamic> context,
  ) {
    return _policyValidator.isRequestContextCompliant(permissionType, context);
  }

  /// Get permission limits
  Map<String, dynamic>? getPermissionLimits(PermissionType permissionType) {
    return _policyValidator.getPermissionLimits(permissionType);
  }

  /// Check if permission requires audit logging
  bool requiresAuditLogging(PermissionType permissionType) {
    return _policyValidator.requiresAuditLogging(permissionType);
  }

  /// Get compliance summary for a specific permission
  Future<Map<String, dynamic>> getComplianceSummary(
      PermissionType permissionType) async {
    final policyDetails = getPolicyDetails(permissionType);
    final usageStats = getPermissionUsageStats(permissionType);
    final auditLogs =
        await getPermissionAuditLog(permissionType: permissionType, limit: 10);

    return {
      'permissionType': permissionType.name,
      'displayName': permissionType.displayName,
      'policy': policyDetails.policy.name,
      'isAllowed': policyDetails.isAllowed,
      'isRestricted': policyDetails.isRestricted,
      'isProhibited': policyDetails.isProhibited,
      'requiresUserInteraction': policyDetails.requiresUserInteraction,
      'requirements': policyDetails.requirements,
      'userGuidance': policyDetails.userGuidance,
      'limits': policyDetails.limits,
      'currentStatus': getPermissionStatus(permissionType)?.name,
      'usageStats': usageStats != null
          ? Map<String, dynamic>.from(usageStats.toJson())
          : null,
      'recentRequests': auditLogs.map((r) => r.toJson()).toList(),
      'platformComplianceNotes': getPlatformComplianceNotes(),
    };
  }

  /// Get overall compliance status
  Future<Map<String, dynamic>> getOverallComplianceStatus() async {
    final report = await validateOverallCompliance();

    return {
      'isFullyCompliant': report.isFullyCompliant,
      'hasCriticalViolations': report.hasCriticalViolations,
      'summary': report.summary,
      'violations': report.violations.map((v) => v.toJson()).toList(),
      'warnings': report.warnings,
      'compliantPermissions':
          report.compliantPermissions.map((p) => p.name).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import '../../lib/infrastructure/permissions/models/permission_type.dart';
import '../../lib/infrastructure/permissions/models/permission_status.dart';
import '../../lib/infrastructure/permissions/models/store_policy.dart';
import '../../lib/infrastructure/permissions/services/store_policy_validator.dart';
import '../../lib/infrastructure/permissions/services/runtime_permission_requester.dart';
import '../../lib/infrastructure/permissions/services/permission_auditor.dart';
import '../../lib/infrastructure/permissions/services/store_compliant_permissions_manager.dart';
import '../../lib/presentation/providers/permissions_provider.dart';

/// Tests for store-compliant permissions management system
void main() {
  group('Store-Compliant Permissions Management', () {
    testWidgetsFlutterBinding();

    // Test store policy validator
    group('Store Policy Validator', () {
      final validator = StorePolicyValidator();

      test('should allow location permission', () {
        final result =
            validator.isPermissionAllowedForAutonomous(PermissionType.location);
        expect(result, isTrue);
      });

      test('should prohibit contacts permission', () {
        final result =
            validator.isPermissionAllowedForAutonomous(PermissionType.contacts);
        expect(result, isFalse);
      });

      test('should require user interaction for camera', () {
        final result = validator.requiresUserInteraction(PermissionType.camera);
        expect(result, isTrue);
      });

      test('should get policy details', () {
        final details = validator.getPolicyDetails(PermissionType.location);
        expect(details.policy, StorePolicy.allowed);
        expect(details.requirements, isNotEmpty);
        expect(details.userGuidance, isNotNull);
      });
    });

    // Test runtime permission requester
    group('Runtime Permission Requester', () {
      final mockPolicyValidator = MockStorePolicyValidator();
      final mockAuditor = MockPermissionAuditor();
      final requester = RuntimePermissionRequester(
        policyValidator: mockPolicyValidator,
        requester: RuntimePermissionRequester(
          policyValidator: mockPolicyValidator,
          requester: RuntimePermissionRequester(
            policyValidator: mockPolicyValidator,
          ),
        ),
        auditor: mockAuditor,
      );

      test('should request permission when allowed', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.location))
            .thenReturn(true);

        when(requester.isPermissionGranted(PermissionType.location))
            .thenReturn(false);

        final result =
            await requester.requestPermission(PermissionType.location);
        expect(result.status, PermissionStatus.granted);
        expect(result.isSuccess, isTrue);
        verify(mockAuditor.logPermissionRequest(result));
      });

      test('should not request permission when prohibited', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.contacts))
            .thenReturn(false);

        final result =
            await requester.requestPermission(PermissionType.contacts);
        expect(result.status, PermissionStatus.denied);
        expect(result.isFailure, isTrue);
        expect(result.justification,
            'Permission not allowed for autonomous operations');
        verify(mockAuditor.logPermissionRequest(result));
      });

      test('should show justification when required', () async {
        when(mockPolicyValidator
                .requiresSpecialJustification(PermissionType.camera))
            .thenReturn(true);

        when(requester.requestPermission(PermissionType.camera))
            .thenReturn(PermissionRequestResult.granted(
          PermissionType.camera,
          wasJustificationShown: true,
        ));

        verify(mockAuditor.logPermissionRequest(captured));
        expect(captured.wasJustificationShown, isTrue);
      });

      test('should handle permanent denial', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.location))
            .thenReturn(true);

        when(requester.requestPermission(PermissionType.location))
            .thenReturn(PermissionRequestResult.denied(
          PermissionType.location,
          permanentlyDenied: true,
        ));

        final result =
            await requester.requestPermission(PermissionType.location);
        expect(result.status, PermissionStatus.permanentlyDenied);
        expect(result.shouldOpenSettings, isTrue);
        verify(mockAuditor.logPermissionRequest(result));
      });
    });

    // Test permission auditor
    group('Permission Auditor', () {
      final mockAuditor = MockPermissionAuditor();

      test('should log permission request', () async {
        final result = PermissionRequestResult.granted(
          PermissionType.location,
          status: PermissionStatus.granted,
          justification: 'Test justification',
          wasJustificationShown: true,
        );

        await mockAuditor.logPermissionRequest(result);

        final auditLog = await mockAuditor.getPermissionAuditLog();
        expect(auditLog.length, 1);
        expect(auditLog.first.permissionType, PermissionType.location);
        expect(auditLog.first.status, PermissionStatus.granted);
        expect(auditLog.first.justification, 'Test justification');
        expect(auditLog.first.wasJustificationShown, isTrue);
      });

      test('should generate compliance report', () async {
        final report = await mockAuditor.generateComplianceReport();

        expect(report.isFullyCompliant, isTrue);
        expect(report.summary, contains('Some permissions require attention'));
        expect(report.violations.length, 0);
        expect(report.warnings.length, greaterThan(0));
      });
    });

    // Test store compliant permissions manager
    group('Store Compliant Permissions Manager', () {
      final mockPolicyValidator = MockStorePolicyValidator();
      final mockAuditor = MockPermissionAuditor();
      final manager = StoreCompliantPermissionsManager(
        policyValidator: mockPolicyValidator,
        requester: RuntimePermissionRequester(
          policyValidator: mockPolicyValidator,
          requester: RuntimePermissionRequester(
            policyValidator: mockPolicyValidator,
          ),
        ),
        auditor: mockAuditor,
      );

      test('should initialize', () async {
        await manager.initialize();
        verify(mockAuditor.clearAuditLog());
      });

      test('should request permission', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.location))
            .thenReturn(true);

        final result = await manager.requestPermission(PermissionType.location);
        expect(result.status, PermissionStatus.granted);
        expect(result.isSuccess, isTrue);
        verify(mockAuditor.logPermissionRequest(result));
      });

      test('should check permission status', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.location))
            .thenReturn(true);

        when(manager.isPermissionGranted(PermissionType.location))
            .thenReturn(true);

        final isGranted = manager.isPermissionGranted(PermissionType.location);
        expect(isGranted, isTrue);
      });

      test('should get policy details', () async {
        final details = manager.getPolicyDetails(PermissionType.location);
        expect(details.policy, StorePolicy.allowed);
        expect(details.requirements, isNotEmpty);
        expect(details.userGuidance, isNotNull);
      });

      test('should validate overall compliance', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.location))
            .thenReturn(true);

        final report = await manager.validateOverallCompliance();
        expect(report.isFullyCompliant, isTrue);
        expect(report.violations.length, 0);
        expect(report.warnings.length, greaterThan(0));
      });

      test('should generate compliance summary', () async {
        when(mockPolicyValidator
                .isPermissionAllowedForAutonomous(PermissionType.location))
            .thenReturn(true);

        final summary =
            await manager.getComplianceSummary(PermissionType.location);
        expect(summary['permissionType'], PermissionType.location.name);
        expect(summary['displayName'], PermissionType.location.displayName);
        expect(summary['policy'], StorePolicy.allowed.name);
        expect(summary['isAllowed'], isTrue);
        expect(summary['requirements'], isNotEmpty);
        expect(summary['userGuidance'], isNotNull);
      });
    });
  });
}

/// Mock store policy validator for testing
class MockStorePolicyValidator extends Mock implements StorePolicyValidator {
  @override
  bool isPermissionAllowedForAutonomous(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.location:
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage:
      case PermissionType.notifications:
      case PermissionType.networkAccess:
      case PermissionType.deviceInfo:
        return true;
      case PermissionType.contacts:
      case PermissionType.sms:
      case PermissionType.callLog:
        return false;
      default:
        return true;
    }
  }

  @override
  bool requiresUserInteraction(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.camera:
      case PermissionType.microphone:
        return true;
      case PermissionType.location:
      case PermissionType.calendar:
      case PermissionType.photos:
        return true;
      default:
        return false;
    }
  }

  @override
  bool requiresSpecialJustification(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.location:
        return true;
      case PermissionType.calendar:
      case PermissionType.photos:
        return true;
      default:
        return false;
    }
  }

  @override
  StorePolicyDetails getPolicyDetails(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.location:
        return StorePolicyDetails.allowed(
          requirements: ['Foreground justification required'],
          userGuidance: 'Location is used only when explicitly requested',
        );
      case PermissionType.camera:
        return StorePolicyDetails.requiresJustification(
          requirements: ['Active user interaction required'],
          userGuidance: 'Camera is used only when you actively take photos',
        );
      case PermissionType.contacts:
        return StorePolicyDetails.prohibited(
          justification:
              'Contacts access is prohibited for autonomous operations',
          userGuidance:
              'This permission cannot be used for autonomous operations',
        );
      default:
        return StorePolicyDetails.allowed(
          requirements: ['Runtime permission request required'],
          userGuidance: 'Permission is requested when needed',
        );
    }
  }
}

/// Mock permission auditor for testing
class MockPermissionAuditor extends Mock implements PermissionAuditor {
  final List<PermissionAuditRecord> _auditLog = [];

  @override
  Future<void> logPermissionRequest(PermissionRequestResult result) async {
    _auditLog.add(result);
  }

  @override
  Future<List<PermissionAuditRecord>> getPermissionAuditLog({
    PermissionType? permissionType,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var filteredLogs = _auditLog;

    if (permissionType != null) {
      filteredLogs = filteredLogs
          .where((record) => record.permissionType == permissionType)
          .toList();
    }

    // Apply date filters
    if (startDate != null) {
      filteredLogs = filteredLogs
          .where((record) => record.timestamp.isAfter(startDate))
          .toList();
    }

    if (endDate != null) {
      filteredLogs = filteredLogs
          .where((record) => record.timestamp.isBefore(endDate))
          .toList();
    }

    // Apply limit
    if (filteredLogs.length > limit) {
      filteredLogs = filteredLogs.take(limit).toList();
    }

    // Sort by timestamp (newest first)
    filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return filteredLogs;
  }

  @override
  Future<void> clearAuditLog() async {
    _auditLog.clear();
  }

  @override
  Future<ComplianceReport> generateComplianceReport() async {
    return ComplianceReport(
      isFullyCompliant: true,
      summary: 'All permissions are compliant',
      violations: [],
      warnings: [],
      compliantPermissions: PermissionType.values
          .where((p) =>
              p != PermissionType.contacts &&
              p != PermissionType.sms &&
              p != PermissionType.callLog)
          .toList(),
    );
  }
}

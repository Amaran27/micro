import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/permissions/services/store_compliant_permissions_manager.dart';
import '../../infrastructure/permissions/models/permission_type.dart';
import '../../infrastructure/permissions/models/permission_status.dart';

/// Provider for permissions manager
final permissionsManagerProvider =
    Provider<StoreCompliantPermissionsManager>((ref) {
  throw UnimplementedError(
      'Permissions Manager provider must be overridden in main.dart');
});

/// Provider for permission state
final permissionStateProvider =
    Provider.family<PermissionStatus?, PermissionType>((ref, permissionType) {
  final permissionsManager = ref.watch(permissionsManagerProvider);
  return permissionsManager.getPermissionStatus(permissionType);
});

/// Provider for compliance report
final complianceReportProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final permissionsManager = ref.watch(permissionsManagerProvider);
  return await permissionsManager.getOverallComplianceStatus();
});

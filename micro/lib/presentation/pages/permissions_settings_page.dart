import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permissions_provider.dart';
import '../../infrastructure/permissions/models/permission_type.dart';

/// Settings page for managing permissions
class PermissionsSettingsPage extends ConsumerWidget {
  const PermissionsSettingsPage({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
      ),
      body: ListView(
            children: [
              // Permission type settings
              ...PermissionType.values
                  .where((permissionType) => !permissionType.isProhibitedForAutonomous)
                  .map((permissionType) {
                final currentStatus = ref.watch(
                  permissionStateProvider.select(permissionType),
                );
                
                final policyDetails = ref.watch(
                  permissionsManagerProvider.select(
                    (manager) => manager.getPolicyDetails(permissionType),
                  ),
                );
                
                return ListTile(
                  leading: Icon(
                    _getPermissionIcon(permissionType),
                    color: currentStatus.isGranted 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  title: Text(permissionType.displayName),
                  subtitle: Text(
                    currentStatus.displayName,
                    style: TextStyle(
                      color: currentStatus.isGranted 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                  trailing: Switch(
                    value: currentStatus.isGranted,
                    onChanged: (value) {
                      if (value) {
                        ref.read(permissionsManagerProvider).requestPermission(
                          permissionType,
                          customJustification: 'Enable from settings',
                        );
                      } else {
                        // For now, we'll just log the denial
                        // In a real implementation, this would open settings
                        ref.read(permissionsManagerProvider).openAppSettings(permissionType);
                      }
                    },
                  ),
                  onTap: () {
                    // Show permission details
                    _showPermissionDetails(context, permissionType, policyDetails);
                  },
                );
              }),
              
              const Divider(),
              
              // Overall compliance status
              Consumer(
                builder: (context, ref) {
                  final report = ref.watch(complianceReportProvider);
                  
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Compliance Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            report.summary,
                            style: TextStyle(
                              color: report.isFullyCompliant 
                                  ? Colors.green 
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Compliance issues
                          if (!report.isFullyCompliant) ...[
                            ExpansionTile(
                              title: const Text('Compliance Issues'),
                              children: [
                                ...report.violations.map((violation) => ListTile(
                                  leading: const Icon(Icons.error, color: Colors.red),
                                  title: Text(violation.permissionType.displayName),
                                  subtitle: Text(violation.violation),
                                )).toList(),
                              ],
                            ),
                          ],
                          
                          // Compliance warnings
                          if (report.warnings.isNotEmpty) ...[
                            ExpansionTile(
                              title: const Text('Compliance Warnings'),
                              children: [
                                ...report.warnings.map((warning) => ListTile(
                                  leading: const Icon(Icons.warning, color: Colors.orange),
                                  title: Text(warning.permissionType.displayName),
                                  subtitle: Text(warning.warning),
                                )).toList(),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
  }
  }

  /// Show permission details dialog
  void _showPermissionDetails(
    BuildContext context,
    PermissionType permissionType,
    StorePolicyDetails policyDetails,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Permission icon
              Icon(
                _getPermissionIcon(permissionType),
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            
              const SizedBox(height: 16),
              
              // Permission name
              Text(
                permissionType.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            
              const SizedBox(height: 8),
              
              // Policy details
              Text(
                'Policy: ${policyDetails.policy.name}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 8),
              
              // Requirements list
              if (policyDetails.requirements.isNotEmpty) {
                Text(
                  'Requirements:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 8),
                
                ...policyDetails.requirements.map((requirement) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                            Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                      
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: Text(
                          requirement,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              }
            
              // User guidance
              if (policyDetails.userGuidance != null) {
                Text(
                  'Guidance:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  policyDetails.userGuidance!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              },
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Get appropriate icon for permission type
  IconData _getPermissionIcon(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.camera:
        return Icons.camera_alt;
      case PermissionType.microphone:
        return Icons.mic;
      case PermissionType.storage:
        return Icons.storage;
      case PermissionType.notifications:
        return Icons.notifications;
      case PermissionType.contacts:
        return Icons.contacts;
      case PermissionType.calendar:
        return Icons.calendar_today;
      case PermissionType.photos:
        return Icons.photo_library;
      case PermissionType.sms:
        return Icons.sms;
      case PermissionType.callLog:
        return Icons.call;
      case PermissionType.backgroundProcessing:
        return Icons.access_time;
      case PermissionType.networkAccess:
        return Icons.wifi;
      case PermissionType.deviceInfo:
        return Icons.devices;
      default:
        return Icons.settings;
    }
  }
}
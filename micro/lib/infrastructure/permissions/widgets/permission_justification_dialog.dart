import 'package:flutter/material.dart';
import '../models/permission_type.dart';
import '../models/store_policy.dart';
import 'store_policy_validator.dart';

/// Callback for permission justification result
typedef VoidCallback = void Function(bool);

/// Dialog for showing permission justification to users
class PermissionJustificationDialog extends StatelessWidget {
  final PermissionType permissionType;
  final StorePolicyDetails policyDetails;
  final String? customJustification;
  final VoidCallback onResult;

  const PermissionJustificationDialog({
    super.key,
    Key? key,
    required this.permissionType,
    required this.policyDetails,
    this.customJustification,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permission Required'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission icon
            Icon(
              _getPermissionIcon(),
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

            // Why permission is needed
            Text(
              'Why this permission is needed:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 8),

            // Justification text
            Text(
              customJustification ?? permissionType.autonomousDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 16),

            // Policy details
            if (policyDetails.isRestricted ||
                policyDetails.requiresUserInteraction)
              {
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Special Requirements Apply',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (policyDetails.isRestricted) ...[
                        Text(
                          'This permission is restricted by store policies',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (policyDetails.requiresUserInteraction) ...[
                        Text(
                          'User interaction is required',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (policyDetails.requirements.isNotEmpty) ...[
                        Text(
                          'Requirements:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        ...policyDetails.requirements
                            .map((requirement) => Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ],
                  ),
                )
              },

            const SizedBox(height: 24),

            // User guidance
            if (policyDetails.userGuidance != null)
              {
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Guidance:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        policyDetails.userGuidance!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              },
          ],
        ),
      ),
      actions: [
        // Deny button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onResult(false);
          },
          child: const Text('Deny'),
        ),

        // Allow button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onResult(true);
          },
          child: const Text('Allow'),
        ),
      ],
    );
  }

  /// Get appropriate icon for permission type
  IconData _getPermissionIcon() {
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
    }
  }

  /// Show permission justification dialog
  static Future<bool> show({
    required BuildContext context,
    required PermissionType permissionType,
    required StorePolicyDetails policyDetails,
    String? customJustification,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PermissionJustificationDialog(
        permissionType: permissionType,
        policyDetails: policyDetails,
        customJustification: customJustification,
        onResult: (granted) {
          if (granted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: 'Permission granted',
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: 'Permission denied',
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );

    return result ?? false;
  }
}

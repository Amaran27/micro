# Store-Compliant Permissions Management System

This directory contains the implementation of a store-compliant permissions management system for the Micro Flutter app. The system ensures that all autonomous operations comply with Google Play Store and iOS App Store policies while maintaining a transparent user experience.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Runtime Permission Requester                │
│                     Store Policy Validator                    │
│                     Permission Auditor                        │
│                     Store-Compliant Permissions Manager           │
│                     Permission Justification Dialog              │
│                     Permissions Provider                      │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Permission Models (`models/`)

- **PermissionType**: Enum defining all permission types used by the app
- **PermissionStatus**: Enum defining permission states and request results
- **StorePolicy**: Enum defining store compliance policies
- **StorePolicyDetails**: Class containing policy details and requirements

### 2. Permission Services (`services/`)

- **StorePolicyValidator**: Validates permissions against store policies
- **RuntimePermissionRequester**: Handles runtime permission requests with store compliance
- **PermissionAuditor**: Audits permission usage for compliance reporting

### 3. Permission UI Widgets (`widgets/`)

- **PermissionJustificationDialog**: Dialog for showing permission justification to users

### 4. Presentation Layer (`presentation/providers/`)

- **PermissionsProvider**: Riverpod providers for permission state and management

## Key Features

### Store Compliance Validation

- Validates each permission against Google Play Store and iOS App Store policies
- Identifies prohibited permissions for autonomous operations
- Provides requirements and user guidance for each permission
- Supports platform-specific compliance rules

### Runtime Permission Requests

- Implements store-compliant permission request flow
- Shows justification dialog when required
- Handles permission denial with appropriate user guidance
- Tracks request frequency and context

### Permission Auditing

- Logs all permission requests and usage statistics
- Generates compliance reports
- Identifies potential policy violations
- Provides audit trail for store submission

### Background Execution Compliance

- Enforces store-specific background execution limits
- Monitors resource usage
- Provides user notifications for background work
- Implements automatic cleanup for expired permissions

## Store Policy Implementation

The system implements comprehensive store policies:

### Google Play Store Policies

- **Location**: Restricted with foreground justification
- **Camera**: Restricted with active user interaction
- **Microphone**: Restricted with active user interaction
- **Background Processing**: Limited to 10 minutes per task, 20 tasks daily
- **Contacts/SMS/Call Log**: Prohibited for autonomous operations
- **Storage**: Allowed with proper scope limitation
- **Notifications**: Allowed with user control
- **Network Access**: Allowed with data minimization
- **Device Info**: Allowed with anonymization
- **Calendar/Photos**: Restricted with explicit user consent

### iOS App Store Policies

- **Location**: Restricted with foreground justification
- **Background Processing**: Limited to approved background modes
- **Contacts/SMS/Call Log**: Prohibited for autonomous operations
- **Storage**: Allowed with proper scope limitation
- **Notifications**: Allowed with user control
- **Network Access**: Allowed with data minimization
- **Device Info**: Allowed with anonymization
- **Calendar/Photos**: Restricted with explicit user consent

## Integration with Flutter App

The permissions system integrates with the Flutter app through Riverpod providers:

1. **Initialization**: Permissions manager is initialized during app startup
2. **State Management**: Permission states are managed in providers and cached for performance
3. **UI Integration**: Permission settings page provides comprehensive permission management
4. **Onboarding**: Permissions setup is integrated into the onboarding flow
5. **Testing**: Comprehensive test suite validates all components

## Usage Example

```dart
// Request a permission
final result = await ref.read(permissionsManagerProvider).requestPermission(
  PermissionType.location,
  customJustification: 'Enable location-aware assistance',
);

// Check if permission is granted
final isGranted = ref.read(permissionsManagerProvider).isPermissionGranted(PermissionType.location);

// Get policy details
final policy = ref.read(permissionsManagerProvider).getPolicyDetails(PermissionType.location);

// Generate compliance report
final report = await ref.read(permissionsManagerProvider).generateComplianceReport();
```

## Testing

Run the test suite with:
```bash
flutter test test/permissions_test.dart
```

## Store Submission Preparation

The system provides comprehensive audit logs and compliance reports that can be exported for store submission:

- Permission request logs with justifications
- Usage statistics for each permission
- Compliance reports with violation details
- Policy compliance validation results

## Benefits

1. **Store Compliance**: Ensures the app will be approved by Google Play Store and iOS App Store
2. **User Trust**: Transparent permission management builds user trust
3. **Risk Mitigation**: Identifies and prevents policy violations
4. **Audit Trail**: Provides complete audit trail for store reviews
5. **Flexibility**: Easy to update policies as store requirements change
6. **Performance**: Optimized permission requests with caching and batching
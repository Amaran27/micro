/// Permission types used by the autonomous agent system
/// Each permission has specific store compliance requirements
enum PermissionType {
  /// Location access (GPS, network-based)
  /// Store Policy: Restricted - requires foreground justification and runtime request
  location,

  /// Camera access for visual context analysis
  /// Store Policy: Restricted - requires active user interaction
  camera,

  /// Microphone access for audio context analysis
  /// Store Policy: Restricted - requires active user interaction
  microphone,

  /// File system access for local data storage
  /// Store Policy: Allowed with proper scope limitation
  storage,

  /// Push notifications for user communication
  /// Store Policy: Allowed with user control
  notifications,

  /// Background processing for autonomous operations
  /// Store Policy: Restricted - limited to 10 minutes per task, 20 tasks daily
  backgroundProcessing,

  /// Network access for tool discovery and execution
  /// Store Policy: Allowed with data minimization
  networkAccess,

  /// Device information for optimization
  /// Store Policy: Allowed with anonymization
  deviceInfo,

  /// Contacts access (PROHIBITED for autonomous agents)
  /// Store Policy: Prohibited for autonomous operations without explicit user interaction
  contacts,

  /// SMS access (PROHIBITED for autonomous agents)
  /// Store Policy: Prohibited for autonomous operations
  sms,

  /// Call log access (PROHIBITED for autonomous agents)
  /// Store Policy: Prohibited for autonomous operations
  callLog,

  /// Calendar access for context planning
  /// Store Policy: Restricted - requires explicit user consent
  calendar,

  /// Photos access for context analysis
  /// Store Policy: Restricted - requires explicit user consent
  photos,
}

/// Extension methods for PermissionType enum
extension PermissionTypeExtension on PermissionType {
  /// Get human-readable display name
  String get displayName {
    switch (this) {
      case PermissionType.location:
        return 'Location';
      case PermissionType.camera:
        return 'Camera';
      case PermissionType.microphone:
        return 'Microphone';
      case PermissionType.storage:
        return 'Storage';
      case PermissionType.notifications:
        return 'Notifications';
      case PermissionType.backgroundProcessing:
        return 'Background Processing';
      case PermissionType.networkAccess:
        return 'Network Access';
      case PermissionType.deviceInfo:
        return 'Device Information';
      case PermissionType.contacts:
        return 'Contacts';
      case PermissionType.sms:
        return 'SMS';
      case PermissionType.callLog:
        return 'Call Log';
      case PermissionType.calendar:
        return 'Calendar';
      case PermissionType.photos:
        return 'Photos';
    }
  }

  /// Get description of why permission is needed for autonomous operations
  String get autonomousDescription {
    switch (this) {
      case PermissionType.location:
        return 'To provide location-aware assistance and optimize performance based on your context';
      case PermissionType.camera:
        return 'To analyze visual context and provide relevant assistance';
      case PermissionType.microphone:
        return 'To analyze audio context and respond to voice commands';
      case PermissionType.storage:
        return 'To store learning data and optimize performance';
      case PermissionType.notifications:
        return 'To notify you of important autonomous actions and opportunities';
      case PermissionType.backgroundProcessing:
        return 'To perform proactive analysis and prepare assistance when needed';
      case PermissionType.networkAccess:
        return 'To discover and execute tools that enhance your experience';
      case PermissionType.deviceInfo:
        return 'To optimize performance and adapt to your device capabilities';
      case PermissionType.contacts:
        return 'To enhance communication assistance (requires explicit approval)';
      case PermissionType.sms:
        return 'To assist with messaging (requires explicit approval)';
      case PermissionType.callLog:
        return 'To enhance communication assistance (requires explicit approval)';
      case PermissionType.calendar:
        return 'To provide proactive assistance based on your schedule';
      case PermissionType.photos:
        return 'To analyze visual context and memories for relevant assistance';
    }
  }

  /// Check if permission is prohibited for autonomous operations
  bool get isProhibitedForAutonomous {
    return [
      PermissionType.contacts,
      PermissionType.sms,
      PermissionType.callLog,
    ].contains(this);
  }

  /// Check if permission requires special justification
  bool get requiresSpecialJustification {
    return [
      PermissionType.location,
      PermissionType.camera,
      PermissionType.microphone,
      PermissionType.backgroundProcessing,
      PermissionType.calendar,
      PermissionType.photos,
    ].contains(this);
  }

  /// Check if permission has background execution limits
  bool get hasBackgroundLimits {
    return [
      PermissionType.backgroundProcessing,
      PermissionType.location,
      PermissionType.microphone,
    ].contains(this);
  }
}

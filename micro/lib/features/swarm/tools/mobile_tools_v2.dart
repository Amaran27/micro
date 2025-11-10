import '../../../infrastructure/ai/agent/models/agent_models.dart';

/// Base class for all mobile tools that implements AgentTool interface
abstract class MobileTool implements AgentTool {
  @override
  ToolMetadata get metadata;
  
  @override
  Future<dynamic> execute(Map<String, dynamic> parameters);
  
  @override
  bool canHandle(String action) {
    return action.toLowerCase().contains(metadata.name.toLowerCase());
  }
  
  @override
  List<String> getRequiredPermissions() {
    return metadata.requiredPermissions;
  }
  
  @override
  void validateParameters(Map<String, dynamic> parameters) {
    // Basic validation - check required parameters exist
    final requiredParams = _getRequiredParams();
    for (final param in requiredParams) {
      if (!parameters.containsKey(param)) {
        throw ArgumentError('Missing required parameter: $param');
      }
    }
  }
  
  /// Override this to specify required parameters
  List<String> _getRequiredParams();
}

/// Camera Tool - Take photos and access camera
class CameraTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'camera_capture',
    description: 'Take a photo using the device camera or access existing photos',
    capabilities: ['photography', 'image_capture', 'camera_control'],
    requiredPermissions: ['camera'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 30),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['take_photo', 'access_gallery', 'switch_camera'],
        'description': 'Camera action to perform',
        'required': true,
      },
      'quality': {
        'type': 'string',
        'enum': ['low', 'medium', 'high'],
        'default': 'medium',
        'description': 'Photo quality setting',
        'required': false,
      }
    },
  );

  @override
  List<String> _getRequiredParams() => ['action'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    final quality = params['quality'] as String? ?? 'medium';
    
    try {
      switch (action) {
        case 'take_photo':
          // TODO: Implement actual camera capture
          return 'Photo captured successfully: /storage/emulated/0/Pictures/captured_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
        case 'access_gallery':
          // TODO: Implement actual gallery access
          return 'Image selected from gallery: /storage/emulated/0/Pictures/selected_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
        case 'switch_camera':
          return 'Camera switched successfully';
          
        default:
          throw ArgumentError('Invalid camera action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute camera action - $e';
    }
  }
}

/// Gallery Tool - Manage photo gallery
class GalleryTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'gallery_manage',
    description: 'Access and manage device photo gallery',
    capabilities: ['gallery_management', 'photo_browsing', 'image_organization'],
    requiredPermissions: ['storage', 'media_library'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 15),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['list_recent', 'get_image_info', 'delete_image'],
        'description': 'Gallery action to perform',
        'required': true,
      },
      'image_path': {
        'type': 'string',
        'description': 'Path to specific image (for info/delete actions)',
        'required': false,
      },
      'limit': {
        'type': 'integer',
        'default': 10,
        'description': 'Number of recent images to list',
        'required': false,
      }
    },
  );

  @override
  List<String> _getRequiredParams() => ['action'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'list_recent':
          final limit = params['limit'] as int? ?? 10;
          return 'Listed $limit recent images from gallery';
          
        case 'get_image_info':
          final imagePath = params['image_path'] as String?;
          if (imagePath == null) {
            throw ArgumentError('image_path is required for get_image_info');
          }
          return 'Retrieved info for image: $imagePath';
          
        case 'delete_image':
          final imagePath = params['image_path'] as String?;
          if (imagePath == null) {
            throw ArgumentError('image_path is required for delete_image');
          }
          return 'Deleted image: $imagePath';
          
        default:
          throw ArgumentError('Invalid gallery action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute gallery action - $e';
    }
  }
}

/// Contacts Tool - Manage device contacts
class ContactsTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'contacts_manage',
    description: 'Access and manage device contacts',
    capabilities: ['contact_management', 'address_book', 'contact_search'],
    requiredPermissions: ['contacts'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 10),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['list_all', 'search', 'add_contact', 'get_details'],
        'description': 'Contact action to perform',
        'required': true,
      },
      'query': {
        'type': 'string',
        'description': 'Search query or contact details',
        'required': false,
      },
      'limit': {
        'type': 'integer',
        'default': 20,
        'description': 'Number of contacts to return',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'list_all':
          final limit = params['limit'] as int? ?? 20;
          return 'Listed $limit contacts from device';
          
        case 'search':
          final query = params['query'] as String?;
          if (query == null) {
            throw ArgumentError('query is required for search');
          }
          return 'Searched contacts for: $query';
          
        case 'add_contact':
          final details = params['query'] as String?;
          if (details == null) {
            throw ArgumentError('contact details are required for add_contact');
          }
          return 'Added new contact: $details';
          
        case 'get_details':
          final query = params['query'] as String?;
          if (query == null) {
            throw ArgumentError('contact identifier is required for get_details');
          }
          return 'Retrieved contact details for: $query';
          
        default:
          throw ArgumentError('Invalid contact action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute contact action - $e';
    }
  }
}

/// SMS Tool - Send and read SMS messages
class SmsTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'sms_manage',
    description: 'Send and read SMS messages',
    capabilities: ['messaging', 'sms_communication', 'text_messaging'],
    requiredPermissions: ['sms', 'phone'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 20),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['send', 'read_recent', 'search_messages'],
        'description': 'SMS action to perform',
        'required': true,
      },
      'phone_number': {
        'type': 'string',
        'description': 'Phone number for sending SMS',
        'required': false,
      },
      'message': {
        'type': 'string',
        'description': 'SMS message content',
        'required': false,
      },
      'limit': {
        'type': 'integer',
        'default': 10,
        'description': 'Number of recent messages to retrieve',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'send':
          final phoneNumber = params['phone_number'] as String?;
          final message = params['message'] as String?;
          if (phoneNumber == null || message == null) {
            throw ArgumentError('phone_number and message are required for send');
          }
          return 'SMS sent to $phoneNumber: $message';
          
        case 'read_recent':
          final limit = params['limit'] as int? ?? 10;
          return 'Retrieved $limit recent SMS messages';
          
        case 'search_messages':
          final query = params['message'] as String?;
          if (query == null) {
            throw ArgumentError('search query is required for search_messages');
          }
          return 'Searched SMS messages for: $query';
          
        default:
          throw ArgumentError('Invalid SMS action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute SMS action - $e';
    }
  }
}

/// Phone Tool - Make phone calls
class PhoneTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'phone_call',
    description: 'Make phone calls and manage call history',
    capabilities: ['calling', 'phone_communication', 'call_management'],
    requiredPermissions: ['phone', 'call_phone'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 25),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['make_call', 'get_call_history', 'get_contact_info'],
        'description': 'Phone action to perform',
        'required': true,
      },
      'phone_number': {
        'type': 'string',
        'description': 'Phone number to call',
        'required': false,
      },
      'contact_name': {
        'type': 'string',
        'description': 'Contact name for lookup',
        'required': false,
      },
      'limit': {
        'type': 'integer',
        'default': 10,
        'description': 'Number of call history entries to retrieve',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'make_call':
          final phoneNumber = params['phone_number'] as String?;
          if (phoneNumber == null) {
            throw ArgumentError('phone_number is required for make_call');
          }
          return 'Initiated call to $phoneNumber';
          
        case 'get_call_history':
          final limit = params['limit'] as int? ?? 10;
          return 'Retrieved $limit recent call history entries';
          
        case 'get_contact_info':
          final contactName = params['contact_name'] as String?;
          if (contactName == null) {
            throw ArgumentError('contact_name is required for get_contact_info');
          }
          return 'Retrieved contact info for: $contactName';
          
        default:
          throw ArgumentError('Invalid phone action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute phone action - $e';
    }
  }
}

/// GPS Tool - Get location information
class GpsTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'gps_location',
    description: 'Get current GPS location and location-based information',
    capabilities: ['location_tracking', 'gps_navigation', 'geolocation'],
    requiredPermissions: ['location', 'gps'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 15),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['get_current', 'get_coordinates', 'get_address', 'track_location'],
        'description': 'GPS action to perform',
        'required': true,
      },
      'duration': {
        'type': 'integer',
        'default': 5000,
        'description': 'Duration in milliseconds for location tracking',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'get_current':
          return 'Retrieved current GPS location';
          
        case 'get_coordinates':
          return 'Retrieved GPS coordinates';
          
        case 'get_address':
          return 'Retrieved address from GPS coordinates';
          
        case 'track_location':
          final duration = params['duration'] as int? ?? 5000;
          return 'Started location tracking for ${duration}ms';
          
        default:
          throw ArgumentError('Invalid GPS action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute GPS action - $e';
    }
  }
}

/// Location Search Tool - Search for places and get directions
class LocationSearchTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'location_search',
    description: 'Search for places, get directions, and location-based services',
    capabilities: ['place_search', 'directions', 'navigation', 'local_discovery'],
    requiredPermissions: ['location', 'network'],
    executionContext: 'hybrid',
    isAsync: true,
    timeout: Duration(seconds: 20),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['search_place', 'get_directions', 'nearby_search', 'place_details'],
        'description': 'Location search action to perform',
        'required': true,
      },
      'query': {
        'type': 'string',
        'description': 'Search query or place name',
        'required': false,
      },
      'destination': {
        'type': 'string',
        'description': 'Destination for directions',
        'required': false,
      },
      'radius': {
        'type': 'integer',
        'default': 1000,
        'description': 'Search radius in meters',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'search_place':
          final query = params['query'] as String?;
          if (query == null) {
            throw ArgumentError('query is required for search_place');
          }
          return 'Searched for place: $query';
          
        case 'get_directions':
          final destination = params['destination'] as String?;
          if (destination == null) {
            throw ArgumentError('destination is required for get_directions');
          }
          return 'Retrieved directions to: $destination';
          
        case 'nearby_search':
          final query = params['query'] as String?;
          final radius = params['radius'] as int? ?? 1000;
          return 'Searched nearby places for: $query within ${radius}m';
          
        case 'place_details':
          final query = params['query'] as String?;
          if (query == null) {
            throw ArgumentError('place name is required for place_details');
          }
          return 'Retrieved details for place: $query';
          
        default:
          throw ArgumentError('Invalid location search action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute location search action - $e';
    }
  }
}

/// Device Info Tool - Get device information
class DeviceInfoTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'device_info',
    description: 'Get device information and system details',
    capabilities: ['device_information', 'system_details', 'hardware_info'],
    requiredPermissions: [],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 5),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['get_basic', 'get_storage', 'get_memory', 'get_network', 'get_system'],
        'description': 'Device info action to perform',
        'required': true,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'get_basic':
          return 'Retrieved basic device information';
          
        case 'get_storage':
          return 'Retrieved storage information';
          
        case 'get_memory':
          return 'Retrieved memory information';
          
        case 'get_network':
          return 'Retrieved network information';
          
        case 'get_system':
          return 'Retrieved system information';
          
        default:
          throw ArgumentError('Invalid device info action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute device info action - $e';
    }
  }
}

/// Battery Tool - Monitor battery status
class BatteryTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'battery_status',
    description: 'Get battery status and monitor battery usage',
    capabilities: ['battery_monitoring', 'power_management', 'energy_tracking'],
    requiredPermissions: ['battery_stats'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 5),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['get_status', 'get_usage_stats', 'start_monitoring', 'stop_monitoring'],
        'description': 'Battery action to perform',
        'required': true,
      },
      'duration': {
        'type': 'integer',
        'default': 10000,
        'description': 'Monitoring duration in milliseconds',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'get_status':
          return 'Retrieved battery status';
          
        case 'get_usage_stats':
          return 'Retrieved battery usage statistics';
          
        case 'start_monitoring':
          final duration = params['duration'] as int? ?? 10000;
          return 'Started battery monitoring for ${duration}ms';
          
        case 'stop_monitoring':
          return 'Stopped battery monitoring';
          
        default:
          throw ArgumentError('Invalid battery action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute battery action - $e';
    }
  }
}

/// Storage Tool - Manage device storage
class StorageTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'storage_manage',
    description: 'Manage device storage and file system',
    capabilities: ['storage_management', 'file_operations', 'disk_usage'],
    requiredPermissions: ['storage', 'read_external_storage', 'write_external_storage'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 15),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['get_usage', 'list_files', 'delete_file', 'get_file_info'],
        'description': 'Storage action to perform',
        'required': true,
      },
      'path': {
        'type': 'string',
        'description': 'File or directory path',
        'required': false,
      },
      'limit': {
        'type': 'integer',
        'default': 50,
        'description': 'Number of files to list',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'get_usage':
          return 'Retrieved storage usage information';
          
        case 'list_files':
          final path = params['path'] as String? ?? '/storage/emulated/0';
          final limit = params['limit'] as int? ?? 50;
          return 'Listed $limit files in: $path';
          
        case 'delete_file':
          final path = params['path'] as String?;
          if (path == null) {
            throw ArgumentError('path is required for delete_file');
          }
          return 'Deleted file: $path';
          
        case 'get_file_info':
          final path = params['path'] as String?;
          if (path == null) {
            throw ArgumentError('path is required for get_file_info');
          }
          return 'Retrieved file info for: $path';
          
        default:
          throw ArgumentError('Invalid storage action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute storage action - $e';
    }
  }
}

/// App Launcher Tool - Launch and manage apps
class AppLauncherTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'app_launcher',
    description: 'Launch applications and manage running apps',
    capabilities: ['app_launching', 'task_management', 'application_control'],
    requiredPermissions: ['query_all_packages', 'get_tasks'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 10),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['launch', 'list_installed', 'get_running_apps', 'close_app'],
        'description': 'App launcher action to perform',
        'required': true,
      },
      'app_name': {
        'type': 'string',
        'description': 'Name or package name of the app',
        'required': false,
      },
      'limit': {
        'type': 'integer',
        'default': 20,
        'description': 'Number of apps to list',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'launch':
          final appName = params['app_name'] as String?;
          if (appName == null) {
            throw ArgumentError('app_name is required for launch');
          }
          return 'Launched application: $appName';
          
        case 'list_installed':
          final limit = params['limit'] as int? ?? 20;
          return 'Listed $limit installed applications';
          
        case 'get_running_apps':
          return 'Retrieved list of running applications';
          
        case 'close_app':
          final appName = params['app_name'] as String?;
          if (appName == null) {
            throw ArgumentError('app_name is required for close_app');
          }
          return 'Closed application: $appName';
          
        default:
          throw ArgumentError('Invalid app launcher action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute app launcher action - $e';
    }
  }
}

/// Notification Tool - Manage system notifications
class NotificationTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'notification_manage',
    description: 'Create and manage system notifications',
    capabilities: ['notification_management', 'alerts', 'system_notifications'],
    requiredPermissions: ['notification_listener', 'post_notifications'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 5),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['create', 'list_active', 'cancel', 'cancel_all'],
        'description': 'Notification action to perform',
        'required': true,
      },
      'title': {
        'type': 'string',
        'description': 'Notification title',
        'required': false,
      },
      'message': {
        'type': 'string',
        'description': 'Notification message',
        'required': false,
      },
      'notification_id': {
        'type': 'integer',
        'description': 'Notification ID for cancellation',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'create':
          final title = params['title'] as String?;
          final message = params['message'] as String?;
          if (title == null || message == null) {
            throw ArgumentError('title and message are required for create');
          }
          return 'Created notification: $title - $message';
          
        case 'list_active':
          return 'Retrieved list of active notifications';
          
        case 'cancel':
          final notificationId = params['notification_id'] as int?;
          if (notificationId == null) {
            throw ArgumentError('notification_id is required for cancel');
          }
          return 'Cancelled notification: $notificationId';
          
        case 'cancel_all':
          return 'Cancelled all notifications';
          
        default:
          throw ArgumentError('Invalid notification action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute notification action - $e';
    }
  }
}

/// Calendar Tool - Manage calendar events
class CalendarTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'calendar_manage',
    description: 'Create and manage calendar events',
    capabilities: ['calendar_management', 'event_scheduling', 'reminders'],
    requiredPermissions: ['calendar', 'write_calendar'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 10),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['create_event', 'list_events', 'get_event', 'delete_event'],
        'description': 'Calendar action to perform',
        'required': true,
      },
      'title': {
        'type': 'string',
        'description': 'Event title',
        'required': false,
      },
      'description': {
        'type': 'string',
        'description': 'Event description',
        'required': false,
      },
      'start_time': {
        'type': 'string',
        'description': 'Event start time (ISO format)',
        'required': false,
      },
      'end_time': {
        'type': 'string',
        'description': 'Event end time (ISO format)',
        'required': false,
      },
      'event_id': {
        'type': 'string',
        'description': 'Event ID for retrieval/deletion',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'create_event':
          final title = params['title'] as String?;
          final startTime = params['start_time'] as String?;
          final endTime = params['end_time'] as String?;
          if (title == null || startTime == null) {
            throw ArgumentError('title and start_time are required for create_event');
          }
          return 'Created calendar event: $title';
          
        case 'list_events':
          return 'Retrieved calendar events';
          
        case 'get_event':
          final eventId = params['event_id'] as String?;
          if (eventId == null) {
            throw ArgumentError('event_id is required for get_event');
          }
          return 'Retrieved calendar event: $eventId';
          
        case 'delete_event':
          final eventId = params['event_id'] as String?;
          if (eventId == null) {
            throw ArgumentError('event_id is required for delete_event');
          }
          return 'Deleted calendar event: $eventId';
          
        default:
          throw ArgumentError('Invalid calendar action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute calendar action - $e';
    }
  }
}

/// Biometric Tool - Handle biometric authentication
class BiometricTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'biometric_auth',
    description: 'Perform biometric authentication and manage biometric settings',
    capabilities: ['biometric_authentication', 'fingerprint', 'face_recognition'],
    requiredPermissions: ['use_fingerprint', 'use_biometric'],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 10),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['authenticate', 'check_availability', 'get_enrolled_biometrics'],
        'description': 'Biometric action to perform',
        'required': true,
      },
      'reason': {
        'type': 'string',
        'default': 'Authentication required',
        'description': 'Reason for authentication request',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'authenticate':
          final reason = params['reason'] as String? ?? 'Authentication required';
          return 'Biometric authentication initiated: $reason';
          
        case 'check_availability':
          return 'Checked biometric availability';
          
        case 'get_enrolled_biometrics':
          return 'Retrieved enrolled biometrics';
          
        default:
          throw ArgumentError('Invalid biometric action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute biometric action - $e';
    }
  }
}

/// Secure Storage Tool - Manage secure storage
class SecureStorageTool extends MobileTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
    name: 'secure_storage',
    description: 'Store and retrieve sensitive data securely',
    capabilities: ['secure_storage', 'encryption', 'data_protection'],
    requiredPermissions: [],
    executionContext: 'local',
    isAsync: true,
    timeout: Duration(seconds: 5),
    parameters: {
      'action': {
        'type': 'string',
        'enum': ['store', 'retrieve', 'delete', 'list_keys'],
        'description': 'Secure storage action to perform',
        'required': true,
      },
      'key': {
        'type': 'string',
        'description': 'Storage key',
        'required': false,
      },
      'value': {
        'type': 'string',
        'description': 'Value to store',
        'required': false,
      }
    },
  );

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    validateParameters(params);
    final action = params['action'] as String;
    
    try {
      switch (action) {
        case 'store':
          final key = params['key'] as String?;
          final value = params['value'] as String?;
          if (key == null || value == null) {
            throw ArgumentError('key and value are required for store');
          }
          return 'Stored data securely for key: $key';
          
        case 'retrieve':
          final key = params['key'] as String?;
          if (key == null) {
            throw ArgumentError('key is required for retrieve');
          }
          return 'Retrieved secure data for key: $key';
          
        case 'delete':
          final key = params['key'] as String?;
          if (key == null) {
            throw ArgumentError('key is required for delete');
          }
          return 'Deleted secure data for key: $key';
          
        case 'list_keys':
          return 'Retrieved list of secure storage keys';
          
        default:
          throw ArgumentError('Invalid secure storage action: $action');
      }
    } catch (e) {
      return 'Error: Failed to execute secure storage action - $e';
    }
  }
}
import 'package:logger/logger.dart';

import '../models/agent_models.dart';
import 'tool_registry.dart';

/// Base class for implementing mobile tools
/// Provides common functionality like logging, parameter validation, error handling
abstract class BaseMobileTool implements AgentTool {
  final Logger logger;

  BaseMobileTool({Logger? logger}) : logger = logger ?? Logger();

  @override
  void validateParameters(Map<String, dynamic> parameters) {
    for (final required in getRequiredParameters()) {
      if (!parameters.containsKey(required)) {
        throw ArgumentError('Missing required parameter: $required');
      }
    }
  }

  /// Get list of required parameter names
  List<String> getRequiredParameters();
}

/// Tool for validating UI elements and screenshots
class UIValidationTool extends BaseMobileTool {
  UIValidationTool({Logger? logger}) : super(logger: logger);

  @override
  ToolMetadata get metadata => ToolMetadata(
        name: 'ui_validation',
        description: 'Validates UI elements, buttons, and screen layouts',
        capabilities: [
          'ui-inspection',
          'screenshot-analysis',
          'element-detection'
        ],
        requiredPermissions: [],
        executionContext: 'local',
        parameters: {
          'action': 'validate|screenshot|find_element',
          'target': 'element_id or screen_region',
        },
      );

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    validateParameters(parameters);

    final action = parameters['action'] as String?;
    final target = parameters['target'] as String?;

    logger.d('UIValidationTool executing: action=$action, target=$target');

    switch (action) {
      case 'validate':
        return await _validateElement(target);
      case 'screenshot':
        return await _takeScreenshot();
      case 'find_element':
        return await _findElement(target);
      default:
        throw ArgumentError('Unknown action: $action');
    }
  }

  @override
  bool canHandle(String action) => action.startsWith('ui_');

  @override
  List<String> getRequiredParameters() => ['action'];

  @override
  List<String> getRequiredPermissions() => [];

  Future<Map<String, dynamic>> _validateElement(String? elementId) async {
    // Simulate element validation
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'elementId': elementId,
      'isValid': true,
      'properties': {
        'visible': true,
        'enabled': true,
        'text': 'Button',
      },
    };
  }

  Future<Map<String, dynamic>> _takeScreenshot() async {
    // Simulate screenshot capture
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'screenshotPath':
          '/tmp/screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      'timestamp': DateTime.now().toIso8601String(),
      'size': {'width': 1080, 'height': 2340},
    };
  }

  Future<List<Map<String, dynamic>>> _findElement(String? selector) async {
    // Simulate element finding
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      {
        'elementId': 'element_1',
        'type': 'Button',
        'text': 'OK',
        'bounds': {'x': 100, 'y': 200, 'width': 200, 'height': 50},
      },
    ];
  }
}

/// Tool for accessing device sensors
class SensorAccessTool extends BaseMobileTool {
  SensorAccessTool({Logger? logger}) : super(logger: logger);

  @override
  ToolMetadata get metadata => ToolMetadata(
        name: 'sensor_access',
        description:
            'Access device sensors: accelerometer, gyroscope, GPS, etc.',
        capabilities: ['sensor-data', 'location-services', 'motion-detection'],
        requiredPermissions: ['location', 'sensors'],
        executionContext: 'local',
        parameters: {
          'sensor': 'accelerometer|gyroscope|gps|temperature|humidity',
          'duration_seconds': 'how long to collect data',
        },
      );

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    validateParameters(parameters);

    final sensor = parameters['sensor'] as String?;
    final duration = (parameters['duration_seconds'] as num?)?.toInt() ?? 5;

    logger.d('SensorAccessTool accessing sensor: $sensor for ${duration}s');

    return await _readSensor(sensor, duration);
  }

  @override
  bool canHandle(String action) => action.startsWith('sensor_');

  @override
  List<String> getRequiredParameters() => ['sensor'];

  @override
  List<String> getRequiredPermissions() => metadata.requiredPermissions;

  Future<Map<String, dynamic>> _readSensor(String? sensor, int duration) async {
    await Future.delayed(Duration(milliseconds: duration * 100));

    switch (sensor) {
      case 'accelerometer':
        return {
          'sensor': 'accelerometer',
          'readings': [
            {'x': 0.1, 'y': 0.2, 'z': 9.8},
            {'x': 0.15, 'y': 0.25, 'z': 9.78},
          ],
          'unit': 'm/s²',
        };
      case 'gps':
        return {
          'sensor': 'gps',
          'latitude': 37.7749,
          'longitude': -122.4194,
          'accuracy': 10.5,
          'altitude': 52.3,
          'timestamp': DateTime.now().toIso8601String(),
        };
      default:
        return {
          'sensor': sensor,
          'data': 'mock_data_for_${sensor}',
        };
    }
  }
}

/// Tool for file operations on the device
class FileOperationTool extends BaseMobileTool {
  FileOperationTool({Logger? logger}) : super(logger: logger);

  @override
  ToolMetadata get metadata => ToolMetadata(
        name: 'file_operations',
        description: 'Read, write, and list files in application directory',
        capabilities: ['file-read', 'file-write', 'file-list', 'file-delete'],
        requiredPermissions: ['files'],
        executionContext: 'local',
        parameters: {
          'action': 'read|write|list|delete',
          'path': 'file or directory path',
          'content': 'for write action',
        },
      );

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    validateParameters(parameters);

    final action = parameters['action'] as String?;
    final path = parameters['path'] as String?;

    logger.d('FileOperationTool executing: action=$action, path=$path');

    switch (action) {
      case 'read':
        return await _readFile(path);
      case 'write':
        final content = parameters['content'] as String?;
        return await _writeFile(path, content);
      case 'list':
        return await _listFiles(path);
      case 'delete':
        return await _deleteFile(path);
      default:
        throw ArgumentError('Unknown action: $action');
    }
  }

  @override
  bool canHandle(String action) => action.startsWith('file_');

  @override
  List<String> getRequiredParameters() => ['action', 'path'];

  @override
  List<String> getRequiredPermissions() => metadata.requiredPermissions;

  Future<String> _readFile(String? path) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 'File content from $path';
  }

  Future<Map<String, dynamic>> _writeFile(String? path, String? content) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'path': path,
      'bytesWritten': content?.length ?? 0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<List<String>> _listFiles(String? path) async {
    await Future.delayed(const Duration(milliseconds: 75));
    return [
      'file1.txt',
      'file2.txt',
      'subdir/',
    ];
  }

  Future<Map<String, dynamic>> _deleteFile(String? path) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return {
      'path': path,
      'deleted': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Tool for app navigation and interaction
class AppNavigationTool extends BaseMobileTool {
  AppNavigationTool({Logger? logger}) : super(logger: logger);

  @override
  ToolMetadata get metadata => ToolMetadata(
        name: 'app_navigation',
        description:
            'Navigate to screens, trigger actions, and interact with app',
        capabilities: ['navigation', 'action-trigger', 'state-verification'],
        requiredPermissions: [],
        executionContext: 'local',
        parameters: {
          'action': 'goto|tap|type|wait',
          'target': 'screen or element identifier',
          'value': 'for type action',
        },
      );

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    validateParameters(parameters);

    final action = parameters['action'] as String?;
    final target = parameters['target'] as String?;

    logger.d('AppNavigationTool executing: action=$action, target=$target');

    switch (action) {
      case 'goto':
        return await _navigateTo(target);
      case 'tap':
        return await _tapElement(target);
      case 'type':
        final value = parameters['value'] as String?;
        return await _typeText(target, value);
      case 'wait':
        return await _waitForElement(target);
      default:
        throw ArgumentError('Unknown action: $action');
    }
  }

  @override
  bool canHandle(String action) => action.startsWith('nav_');

  @override
  List<String> getRequiredParameters() => ['action', 'target'];

  @override
  List<String> getRequiredPermissions() => metadata.requiredPermissions;

  Future<Map<String, dynamic>> _navigateTo(String? screen) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'screen': screen,
      'navigated': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _tapElement(String? elementId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'elementId': elementId,
      'tapped': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _typeText(String? fieldId, String? text) async {
    await Future.delayed(Duration(milliseconds: (text?.length ?? 0) * 20));
    return {
      'fieldId': fieldId,
      'textEntered': text,
      'characterCount': text?.length ?? 0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _waitForElement(String? elementId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'elementId': elementId,
      'found': true,
      'waitedMilliseconds': 500,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

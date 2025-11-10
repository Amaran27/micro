import 'dart:io' show Platform, Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:langchain_core/tools.dart';
import 'package:path_provider/path_provider.dart';

/// File System tool - Desktop and Mobile only
final class FileSystemTool extends Tool<Map<String, dynamic>, ToolOptions, String> {
  FileSystemTool()
      : super(
          name: 'filesystem',
          description:
              'List files and directories, read file contents (text files only). Desktop and Mobile only.',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'description': 'Action: "list_temp", "list_docs", "read_file"',
                'enum': ['list_temp', 'list_docs', 'read_file'],
              },
              'path': {
                'type': 'string',
                'description': 'Optional: file path for read_file action',
              },
            },
            'required': ['action'],
          },
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) => json;

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    if (kIsWeb) {
      return 'Error: Filesystem operations not available on web platform';
    }

    final action = input['action'] as String;

    try {
      switch (action) {
        case 'list_temp':
          final tempDir = await getTemporaryDirectory();
          final entities = tempDir.listSync();
          if (entities.isEmpty) {
            return 'Temp directory is empty';
          }
          return 'Temp directory contents (${entities.length} items):\n' +
              entities
                  .take(10)
                  .map((e) => '- ${e.path.split('/').last}')
                  .join('\n') +
              (entities.length > 10 ? '\n... and ${entities.length - 10} more' : '');

        case 'list_docs':
          try {
            final docsDir = await getApplicationDocumentsDirectory();
            final entities = docsDir.listSync();
            if (entities.isEmpty) {
              return 'Documents directory is empty';
            }
            return 'Documents directory contents (${entities.length} items):\n' +
                entities
                    .take(10)
                    .map((e) => '- ${e.path.split('/').last}')
                    .join('\n') +
                (entities.length > 10 ? '\n... and ${entities.length - 10} more' : '');
          } catch (e) {
            return 'Error accessing documents directory: $e';
          }

        case 'read_file':
          final path = input['path'] as String?;
          if (path == null) {
            return 'Error: path parameter required for read_file action';
          }
          final file = File(path);
          if (!await file.exists()) {
            return 'Error: File not found: $path';
          }
          final content = await file.readAsString();
          if (content.length > 500) {
            return content.substring(0, 500) +
                '\n... (showing first 500 characters of ${content.length})';
          }
          return content;

        default:
          return 'Unknown action: $action';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  static bool isAvailable() => !kIsWeb;
}

/// System Info tool - Desktop and Mobile
final class SystemInfoTool extends Tool<Map<String, dynamic>, ToolOptions, String> {
  SystemInfoTool()
      : super(
          name: 'system_info',
          description:
              'Get system information: OS, version, environment variables (limited)',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'info_type': {
                'type': 'string',
                'description': 'Type of info: "os", "env_keys"',
                'enum': ['os', 'env_keys'],
              },
            },
            'required': ['info_type'],
          },
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) => json;

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    if (kIsWeb) {
      return 'Error: System info not available on web platform';
    }

    final infoType = input['info_type'] as String;

    try {
      switch (infoType) {
        case 'os':
          return '''
Operating System: ${Platform.operatingSystem}
OS Version: ${Platform.operatingSystemVersion}
Number of Processors: ${Platform.numberOfProcessors}
Path Separator: ${Platform.pathSeparator}
''';

        case 'env_keys':
          final env = Platform.environment;
          final keys = env.keys.take(10).toList();
          return 'Environment variables (showing first 10 keys):\n' +
              keys.map((k) => '- $k').join('\n');

        default:
          return 'Unknown info type: $infoType';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  static bool isAvailable() => !kIsWeb;
}

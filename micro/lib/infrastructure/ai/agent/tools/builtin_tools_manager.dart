import 'package:langchain_core/tools.dart';
import 'platform_tools.dart';

/// Manages built-in tools and provides them to agents
class BuiltInToolsManager {
  static final BuiltInToolsManager _instance = BuiltInToolsManager._internal();
  factory BuiltInToolsManager() => _instance;
  BuiltInToolsManager._internal();

  final List<Tool<Object, ToolOptions, Object>> _allTools = [];
  bool _initialized = false;

  /// Initialize and register all built-in tools
  Future<void> initialize() async {
    if (_initialized) return;

    // Register universal tools (work on all platforms)
    _allTools.addAll([
      CalculatorTool(),
      DateTimeTool(),
      TextProcessorTool(),
      PlatformInfoTool(),
    ]);

    _initialized = true;
    print('BuiltInToolsManager: Registered ${_allTools.length} built-in tools');
  }

  /// Get all available built-in tools
  List<Tool<Object, ToolOptions, Object>> getAllTools() {
    if (!_initialized) {
      print('Warning: BuiltInToolsManager not initialized, call initialize() first');
      return [];
    }
    return List.unmodifiable(_allTools);
  }

  /// Get tools filtered by platform
  List<Tool<Object, ToolOptions, Object>> getToolsForPlatform() {
    if (!_initialized) {
      print('Warning: BuiltInToolsManager not initialized, call initialize() first');
      return [];
    }

    // For now, all tools work on all platforms
    // In the future, we can filter based on PlatformInfo
    return getAllTools();
  }

  /// Get tool count
  int get toolCount => _allTools.length;

  /// Check if initialized
  bool get isInitialized => _initialized;
}

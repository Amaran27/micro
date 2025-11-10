import 'package:langchain_core/tools.dart';
import 'platform_tools.dart';
import 'native_tools.dart';
import 'search_tools.dart';

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

    // Register search tools (available on all platforms)
    if (WebSearchTool.isAvailable()) {
      _allTools.add(WebSearchTool());
      print('Added WebSearchTool');
    }

    if (KnowledgeBaseTool.isAvailable()) {
      _allTools.add(KnowledgeBaseTool());
      print('Added KnowledgeBaseTool');
    }

    // Register platform-specific tools
    if (FileSystemTool.isAvailable()) {
      _allTools.add(FileSystemTool());
      print('Added FileSystemTool (platform: ${PlatformInfo.platformName})');
    }

    if (SystemInfoTool.isAvailable()) {
      _allTools.add(SystemInfoTool());
      print('Added SystemInfoTool (platform: ${PlatformInfo.platformName})');
    }

    _initialized = true;
    print('BuiltInToolsManager: Registered ${_allTools.length} built-in tools');
    print('Tools available: ${_allTools.map((t) => t.name).join(", ")}');
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

    // Tools are already filtered during initialization
    return getAllTools();
  }

  /// Get tool by name
  Tool<Object, ToolOptions, Object>? getToolByName(String name) {
    return _allTools.firstWhere(
      (tool) => tool.name == name,
      orElse: () => throw Exception('Tool not found: $name'),
    );
  }

  /// Get tool names
  List<String> getToolNames() {
    return _allTools.map((t) => t.name).toList();
  }

  /// Get tool count
  int get toolCount => _allTools.length;

  /// Check if initialized
  bool get isInitialized => _initialized;
}

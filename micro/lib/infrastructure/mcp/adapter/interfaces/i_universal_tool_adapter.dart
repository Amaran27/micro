import '../../core/models/tool.dart';
import '../../core/models/tool_capability.dart';
import '../../core/models/tool_call.dart';
import '../../core/models/tool_result.dart';
import '../../core/models/domain_context.dart';
import '../models/adapter_models.dart';

/// Interface for the Universal Tool Adapter that adapts tools for any domain context
abstract class IUniversalToolAdapter {
  /// Discovers the capabilities of the adapter
  Future<ToolCapability> discoverCapabilities();

  /// Configures the adapter for a specific domain
  Future<void> configureForDomain(String domain);

  /// Executes a tool call with the provided domain context
  Future<ToolResult> executeWithContext(ToolCall call, DomainContext context);

  /// Assesses the security of the adapter
  Future<SecurityAssessment> assessSecurity();

  /// Adapts a tool for a specific domain context
  Future<AdaptationResult> adaptTool(Tool tool, DomainContext targetContext);

  /// Validates if a tool can be adapted to a domain context
  Future<bool> canAdaptTool(Tool tool, DomainContext targetContext);

  /// Gets the current domain configuration
  String? getCurrentDomain();

  /// Gets the performance metrics of the adapter
  Future<AdapterPerformanceMetrics> getPerformanceMetrics();

  /// Resets the adapter to its initial state
  Future<void> reset();

  /// Disposes of the adapter resources
  Future<void> dispose();
}

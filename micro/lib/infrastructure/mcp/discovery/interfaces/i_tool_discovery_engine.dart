import 'package:equatable/equatable.dart';
import '../../core/models/tool.dart';
import '../models/discovery_models.dart';
import 'i_discovery_source.dart';

/// Interface for the Tool Discovery Engine
///
/// This component is responsible for discovering tools from various sources
/// including local device, network, and MCP servers. It provides validation
/// and classification capabilities for discovered tools.
abstract class IToolDiscoveryEngine {
  /// Scans for available tools from all registered sources
  ///
  /// Returns a list of discovered tools with metadata about their source
  /// and discovery process. Implements mobile optimization for fast discovery
  /// (<5 seconds) and efficient resource usage (<30MB memory).
  Future<List<DiscoveredTool>> scanForTools();

  /// Classifies a tool based on its capabilities and characteristics
  ///
  /// Analyzes the tool's metadata, capabilities, and behavior to determine
  /// its classification category and confidence level.
  Future<ToolClassification> classifyTool(Tool tool);

  /// Validates a tool for compatibility and security
  ///
  /// Performs comprehensive validation including:
  /// - Schema validation
  /// - Security requirements check
  /// - Mobile compatibility assessment
  /// - Performance requirements verification
  Future<ToolValidation> validateTool(Tool tool);

  /// Registers a new discovery source
  ///
  /// Adds a new source for tool discovery with its configuration.
  /// Sources can be local device, network, or MCP server based.
  Future<void> registerDiscoverySource(IDiscoverySource source);

  /// Discovers tools from a specific source
  ///
  /// Performs targeted discovery from a single source, useful for
  /// refreshing tools from a specific location or testing new sources.
  Future<List<DiscoveredTool>> discoverFromSource(IDiscoverySource source);

  /// Gets the current discovery configuration
  DiscoveryConfig getConfiguration();

  /// Updates the discovery configuration
  Future<void> updateConfiguration(DiscoveryConfig config);

  /// Gets performance metrics for the discovery engine
  Future<Map<String, dynamic>> getDiscoveryMetrics();

  /// Clears all discovery caches
  Future<void> clearCaches();

  /// Performs health check on the discovery engine
  Future<Map<String, dynamic>> performHealthCheck();
}

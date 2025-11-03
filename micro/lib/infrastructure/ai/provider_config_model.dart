/// Provider Configuration Model
///
/// Manages configuration for individual provider instances
/// Stores API keys, endpoints, custom settings, and model preferences
library;

import 'package:flutter/foundation.dart';

class ProviderConfig {
  final String id; // Unique config ID (provider + index if multiple)
  final String providerId;
  final String apiKey;
  final String? endpoint; // For self-hosted providers
  final String? deploymentId; // For Azure OpenAI
  final bool isEnabled;
  final bool isConfigured; // Verified with API
  final bool testPassed; // Connection test successful
  final List<String> favoriteModels; // Selected models for this provider
  final List<String> customModels; // User-added custom models not in API list
  final Map<String, dynamic>? additionalSettings;
  final DateTime createdAt;
  final DateTime? lastTestedAt;
  
  // MCP Integration Settings
  final bool mcpEnabled; // Enable MCP tool integration for this provider
  final List<String> mcpServerIds; // MCP servers assigned to this provider

  ProviderConfig({
    String? id,
    required this.providerId,
    required this.apiKey,
    this.endpoint,
    this.deploymentId,
    this.isEnabled = true,
    this.isConfigured = false,
    this.testPassed = false,
    this.favoriteModels = const [],
    this.customModels = const [],
    this.additionalSettings,
    DateTime? createdAt,
    this.lastTestedAt,
    this.mcpEnabled = false,
    this.mcpServerIds = const [],
  })  : id = id ?? '$providerId-${DateTime.now().millisecondsSinceEpoch}',
        createdAt = createdAt ?? DateTime.now();

  // Copy with updates
  ProviderConfig copyWith({
    String? id,
    String? providerId,
    String? apiKey,
    String? endpoint,
    String? deploymentId,
    bool? isEnabled,
    bool? isConfigured,
    bool? testPassed,
    List<String>? favoriteModels,
    List<String>? customModels,
    Map<String, dynamic>? additionalSettings,
    DateTime? createdAt,
    DateTime? lastTestedAt,
    bool? mcpEnabled,
    List<String>? mcpServerIds,
  }) {
    return ProviderConfig(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      deploymentId: deploymentId ?? this.deploymentId,
      isEnabled: isEnabled ?? this.isEnabled,
      isConfigured: isConfigured ?? this.isConfigured,
      testPassed: testPassed ?? this.testPassed,
      favoriteModels: favoriteModels ?? this.favoriteModels,
      customModels: customModels ?? this.customModels,
      additionalSettings: additionalSettings ?? this.additionalSettings,
      createdAt: createdAt ?? this.createdAt,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      mcpEnabled: mcpEnabled ?? this.mcpEnabled,
      mcpServerIds: mcpServerIds ?? this.mcpServerIds,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'apiKey': apiKey,
      'endpoint': endpoint,
      'deploymentId': deploymentId,
      'isEnabled': isEnabled,
      'isConfigured': isConfigured,
      'testPassed': testPassed,
      'favoriteModels': favoriteModels,
      'customModels': customModels,
      'additionalSettings': additionalSettings,
      'createdAt': createdAt.toIso8601String(),
      'lastTestedAt': lastTestedAt?.toIso8601String(),
      'mcpEnabled': mcpEnabled,
      'mcpServerIds': mcpServerIds,
    };
  }

  // Create from JSON
  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      apiKey: json['apiKey'] as String,
      endpoint: json['endpoint'] as String?,
      deploymentId: json['deploymentId'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isConfigured: json['isConfigured'] as bool? ?? false,
      testPassed: json['testPassed'] as bool? ?? false,
      favoriteModels: List<String>.from(json['favoriteModels'] as List? ?? []),
      customModels: List<String>.from(json['customModels'] as List? ?? []),
      additionalSettings: json['additionalSettings'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastTestedAt: json['lastTestedAt'] != null
          ? DateTime.parse(json['lastTestedAt'] as String)
          : null,
      mcpEnabled: json['mcpEnabled'] as bool? ?? false,
      mcpServerIds: List<String>.from(json['mcpServerIds'] as List? ?? []),
    );
  }

  @override
  String toString() => 'ProviderConfig(id: $id, providerId: $providerId, '
      'isEnabled: $isEnabled, testPassed: $testPassed, '
      'favoriteModels: $favoriteModels)';
}

// ChangeNotifier for reactive state management
class ProviderConfigNotifier extends ChangeNotifier {
  final Map<String, ProviderConfig> _configs = {};

  Map<String, ProviderConfig> get configs => {..._configs};

  List<ProviderConfig> get allConfigs => _configs.values.toList();

  List<ProviderConfig> getEnabledConfigs() {
    return _configs.values.where((c) => c.isEnabled).toList();
  }

  List<ProviderConfig> getConfigsByProvider(String providerId) {
    return _configs.values.where((c) => c.providerId == providerId).toList();
  }

  ProviderConfig? getConfig(String configId) {
    return _configs[configId];
  }

  void addConfig(ProviderConfig config) {
    _configs[config.id] = config;
    notifyListeners();
  }

  void updateConfig(ProviderConfig config) {
    _configs[config.id] = config;
    notifyListeners();
  }

  void removeConfig(String configId) {
    _configs.remove(configId);
    notifyListeners();
  }

  void toggleConfig(String configId) {
    final config = _configs[configId];
    if (config != null) {
      _configs[configId] = config.copyWith(isEnabled: !config.isEnabled);
      notifyListeners();
    }
  }

  void setFavoriteModels(String configId, List<String> models) {
    final config = _configs[configId];
    if (config != null) {
      _configs[configId] = config.copyWith(favoriteModels: models);
      notifyListeners();
    }
  }

  void addCustomModel(String configId, String modelId) {
    final config = _configs[configId];
    if (config != null) {
      final updatedModels = [...config.customModels];
      if (!updatedModels.contains(modelId)) {
        updatedModels.add(modelId);
        _configs[configId] = config.copyWith(customModels: updatedModels);
        notifyListeners();
      }
    }
  }

  void removeCustomModel(String configId, String modelId) {
    final config = _configs[configId];
    if (config != null) {
      final updatedModels = [...config.customModels];
      updatedModels.remove(modelId);
      _configs[configId] = config.copyWith(customModels: updatedModels);
      notifyListeners();
    }
  }

  void setCustomModels(String configId, List<String> models) {
    final config = _configs[configId];
    if (config != null) {
      _configs[configId] = config.copyWith(customModels: models);
      notifyListeners();
    }
  }

  void markAsConfigured(String configId, bool configured) {
    final config = _configs[configId];
    if (config != null) {
      _configs[configId] = config.copyWith(isConfigured: configured);
      notifyListeners();
    }
  }

  void markTestPassed(String configId, {bool passed = true}) {
    final config = _configs[configId];
    if (config != null) {
      _configs[configId] = config.copyWith(
        testPassed: passed,
        lastTestedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void clear() {
    _configs.clear();
    notifyListeners();
  }

  // Get all favorite models from all enabled providers
  List<String> getAllFavoriteModels() {
    final models = <String>[];
    for (final config in getEnabledConfigs()) {
      models.addAll(config.favoriteModels);
    }
    return models;
  }

  // Get favorite models by provider
  List<String> getFavoriteModelsByProvider(String providerId) {
    final configs = getConfigsByProvider(providerId);
    final models = <String>[];
    for (final config in configs) {
      if (config.isEnabled) {
        models.addAll(config.favoriteModels);
      }
    }
    return models;
  }
}

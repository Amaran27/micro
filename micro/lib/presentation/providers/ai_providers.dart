import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/ai/ai_provider_config.dart';
import '../../infrastructure/ai/model_selection_service.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/autonomous/context_analysis.dart';

/// Provider for logger
final loggerProvider = Provider<AppLogger>((ref) {
  return logger;
});

/// Provider for AI provider configuration
final aiProviderConfigProvider = Provider<AIProviderConfig>((ref) {
  return AIProviderConfig();
});

/// Provider for ModelSelectionService
final modelSelectionServiceProvider = Provider<ModelSelectionService>((ref) {
  final service = ModelSelectionService();
  // Initialize the service when first accessed
  ref.onDispose(() {
    // Cleanup if needed
  });
  return service;
});

/// Provider for initialized ModelSelectionService
final initializedModelSelectionServiceProvider =
    FutureProvider<ModelSelectionService>((ref) async {
  final service = ref.watch(modelSelectionServiceProvider);
  await service.initialize();
  await service.fetchAvailableModels();
  return service;
});

/// Provider for favorite models across all providers
final favoriteModelsProvider = Provider<Map<String, List<String>>>((ref) {
  final serviceAsync = ref.watch(initializedModelSelectionServiceProvider);
  return serviceAsync.when(
    data: (service) {
      final favorites = <String, List<String>>{};
      // Get all provider IDs from constants
      for (final providerId in [
        'openai',
        'google',
        'claude',
        'azure',
        'cohere',
        'mistral'
      ]) {
        favorites[providerId] = service.getFavoriteModels(providerId);
      }
      return favorites;
    },
    loading: () => <String, List<String>>{},
    error: (_, __) => <String, List<String>>{},
  );
});

/// Provider for active models across all providers
final activeModelsProvider = Provider<Map<String, String>>((ref) {
  final serviceAsync = ref.watch(initializedModelSelectionServiceProvider);
  return serviceAsync.when(
    data: (service) => service.getAllActiveModels(),
    loading: () => <String, String>{},
    error: (_, __) => <String, String>{},
  );
});

/// Provider for current selected model
final currentSelectedModelProvider = Provider<String?>((ref) {
  final serviceAsync = ref.watch(initializedModelSelectionServiceProvider);
  final favorites = ref.watch(favoriteModelsProvider);

  return serviceAsync.when(
    data: (service) {
      // Get the first available active model
      final activeModels = service.getAllActiveModels();
      if (activeModels.isNotEmpty) {
        return activeModels.values.first;
      }

      // Fall back to first favorite model
      for (final providerId in ['openai', 'google', 'claude']) {
        final providerFavorites = favorites[providerId] ?? [];
        if (providerFavorites.isNotEmpty) {
          return providerFavorites.first;
        }
      }

      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for available models
final availableModelsProvider = Provider<List<String>>((ref) {
  final aiConfig = ref.watch(aiProviderConfigProvider);
  return aiConfig.getProviderStatus().keys.toList();
});

/// Provider for current model info
final currentModelProvider = Provider<Map<String, dynamic>>((ref) {
  final aiConfig = ref.watch(aiProviderConfigProvider);
  return aiConfig.getProviderStatus();
});

/// Provider for LLM state
final llmStateProvider = Provider<Map<String, dynamic>>((ref) {
  final aiConfig = ref.watch(aiProviderConfigProvider);
  return aiConfig.getProviderStatus();
});

/// Provider for context analysis results
final contextAnalysisProvider =
    FutureProvider.family<ContextAnalysis, String?>((ref, userId) async {
  // Example context data - in real implementation this would come from context analyzer
  final contextData = {
    'timestamp': DateTime.now().toIso8601String(),
    'deviceType': 'mobile',
    'appVersion': '1.0.0',
    'language': 'en',
    'timezone': DateTime.now().timeZoneName,
    'batteryLevel': 85,
    'networkType': 'wifi',
    'userPreferences': {
      'preferredTaskType': 'chat',
      'allowBackgroundProcessing': true,
      'maxResponseLength': 4000,
    },
  };

  // Return a basic context analysis - in real implementation this would be analyzed
  return ContextAnalysis.success(
    id: 'context-${DateTime.now().millisecondsSinceEpoch}',
    contextData: contextData,
    requiredPermissions: [],
    grantedPermissions: [],
    deniedPermissions: [],
    confidenceScore: 0.8,
    anonymizedData: contextData,
    userId: userId,
  );
});

/// Provider for AI enhancement status
final aiEnhancementStatusProvider = Provider<bool>((ref) {
  final aiConfig = ref.watch(aiProviderConfigProvider);
  return aiConfig.hasAvailableProviders();
});

/// Provider for AI action recommendations
final aiActionRecommendationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  // Return basic recommendations - in real implementation this would use AI
  return [
    {
      'action': 'optimize_battery',
      'confidence': 0.85,
      'reasoning': 'Based on current battery level and usage patterns',
    },
    {
      'action': 'schedule_reminder',
      'confidence': 0.72,
      'reasoning': 'User has pending tasks that could benefit from reminders',
    },
  ];
});

/// Provider for current model info (enhanced)
final currentModelInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final aiConfig = ref.watch(aiProviderConfigProvider);
  final state = aiConfig.getProviderStatus();

  return {
    'name': state['currentProvider'] ?? 'none',
    'type': state['providerType'] ?? 'unknown',
    'isInitialized': state['initialized'] ?? false,
    'capabilities': ['text_generation', 'analysis'],
    'models': state.keys.toList(),
    'selectedModel': state['currentModel'] ?? 'none',
    'strength': 0.8,
    'taskOptimization': 'general',
  };
});

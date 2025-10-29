import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:state_notifier/state_notifier.dart';

import '../../infrastructure/ai/ai_provider_config.dart';
import '../../infrastructure/ai/model_selection_service.dart';
import '../../infrastructure/ai/model_selection_notifier.dart';
import '../../core/utils/logger.dart';
import 'app_providers.dart';
import '../../domain/models/autonomous/context_analysis.dart';

/// Provider for logger
final loggerProvider = Provider<AppLogger>((ref) {
  return logger;
});

/// Provider for AI provider configuration
final aiProviderConfigProvider = Provider<AIProviderConfig>((ref) {
  return AIProviderConfig();
});

/// Async notifier to manage favorite models loading
class FavoriteModelsNotifier extends AsyncNotifier<Map<String, List<String>>> {
  @override
  Future<Map<String, List<String>>> build() async {
    // Ensure the ModelSelectionService is initialized and return the
    // persisted favorite models. This avoids returning an immediate
    // empty map which caused the UI to think no favorites were set.
    final service = await ref.watch(initializedModelSelectionServiceProvider.future);
    return service.getAllFavoriteModels();
  }

  /// Manual refresh helper (keeps existing API for callers)
  Future<void> loadFavoriteModels() async {
    final service = ref.watch(modelSelectionServiceProvider);
    state = await AsyncValue.guard(() async {
      return service.getAllFavoriteModels();
    });
  }
}

/// Provider for favorite models using AsyncNotifierProvider (Riverpod 3.0+ pattern)
final favoriteModelsProvider = AsyncNotifierProvider<FavoriteModelsNotifier, Map<String, List<String>>>(() {
  return FavoriteModelsNotifier();
});

/// Helper function to load favorite models
void loadFavoriteModels(WidgetRef ref) {
  ref.read(favoriteModelsProvider.notifier).loadFavoriteModels();
}

/// Provider for active models across all providers
final activeModelsProvider = FutureProvider<Map<String, String>>((ref) async {
  final service = await ref.watch(initializedModelSelectionServiceProvider.future);
  return service.getAllActiveModels();
});

/// Provider for current selected model
final currentSelectedModelProvider = FutureProvider<String?>((ref) async {
    final service = await ref.watch(initializedModelSelectionServiceProvider.future);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  // First try to get the last selected model from preferences
  final lastSelectedModel = prefs.getString('last_selected_model');
  if (lastSelectedModel != null) {
    // Get the favorite models
    final favorites = <String, List<String>>{};
    for (final providerId in [
      'openai',
      'google',
      'claude',
      'anthropic',
      'zhipuai',
      'z_ai',
      'azure',
      'cohere',
      'mistral'
    ]) {
      favorites[providerId] = service.getFavoriteModels(providerId);
    }
    
    // Verify the model is still available in favorites
    for (final models in favorites.values) {
      if (models.contains(lastSelectedModel)) {
        return lastSelectedModel;
      }
    }
  }

  // Fall back to first available active model
  final activeModels = service.getAllActiveModels();
  if (activeModels.isNotEmpty) {
    return activeModels.values.first;
  }

  // Fall back to first favorite model
  for (final providerId in ['openai', 'google', 'claude', 'anthropic', 'zhipuai', 'z_ai']) {
    final providerFavorites = service.getFavoriteModels(providerId);
    if (providerFavorites.isNotEmpty) {
      return providerFavorites.first;
    }
  }

  return null;
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

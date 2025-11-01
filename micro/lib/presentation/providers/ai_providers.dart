import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/ai/ai_provider_config.dart';
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
    final service =
        await ref.watch(initializedModelSelectionServiceProvider.future);
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
final favoriteModelsProvider =
    AsyncNotifierProvider<FavoriteModelsNotifier, Map<String, List<String>>>(
        () {
  return FavoriteModelsNotifier();
});

/// Helper function to load favorite models
void loadFavoriteModels(WidgetRef ref) {
  ref.read(favoriteModelsProvider.notifier).loadFavoriteModels();
}

/// Provider for active models across all providers
final activeModelsProvider = FutureProvider<Map<String, String>>((ref) async {
  final service =
      await ref.watch(initializedModelSelectionServiceProvider.future);
  return service.getAllActiveModels();
});

/// Provider for current selected model
final currentSelectedModelProvider = FutureProvider<String?>((ref) async {
  final service =
      await ref.watch(initializedModelSelectionServiceProvider.future);
  final prefs = ref.watch(sharedPreferencesProvider);

  print('DEBUG: currentSelectedModelProvider called');

  // First try to get the last selected model from preferences
  final lastSelectedModel = prefs.getString('last_selected_model');
  print('DEBUG: Last selected model from prefs: $lastSelectedModel');

  // If we have a last selected model, trust the user's choice
  // The model was already validated when it was selected
  if (lastSelectedModel != null && lastSelectedModel.isNotEmpty) {
    print('DEBUG: Using last selected model from prefs: $lastSelectedModel');
    return lastSelectedModel;
  }

  // Only if no model is selected, fall back to active/favorite models
  // Get active models first to check availability
  final activeModels = service.getAllActiveModels();
  print('DEBUG: Active models: $activeModels');

  // Fall back to active models
  if (activeModels.isNotEmpty) {
    // If there's no last selected model, prioritize ZhipuAI if it has an active model
    final zhipuaiModel = activeModels['zhipuai'];
    if (zhipuaiModel != null) {
      print('DEBUG: Using ZhipuAI model: $zhipuaiModel');
      return zhipuaiModel;
    }

    // Otherwise check for Google model
    final googleModel = activeModels['google'];
    if (googleModel != null) {
      print('DEBUG: Using Google model: $googleModel');
      return googleModel;
    }

    // Otherwise return the first available model
    print('DEBUG: Using first available model: ${activeModels.values.first}');
    return activeModels.values.first;
  }

  // Fall back to first favorite model
  for (final providerId in [
    'openai',
    'google',
    'claude',
    'anthropic',
    'zhipuai',
    'z_ai'
  ]) {
    final providerFavorites = service.getFavoriteModels(providerId);
    if (providerFavorites.isNotEmpty) {
      print(
          'DEBUG: Using first favorite model for $providerId: ${providerFavorites.first}');
      return providerFavorites.first;
    }
  }

  print('DEBUG: No model found, returning null');
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

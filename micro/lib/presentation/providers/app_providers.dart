// Re-export AI providers for convenience
export 'ai_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../infrastructure/permissions/services/store_compliant_permissions_manager.dart';

/// Provider for permissions manager
final permissionsManagerProvider =
    Provider<StoreCompliantPermissionsManager>((ref) {
  throw UnimplementedError(
      'Permissions Manager provider must be overridden in main.dart');
});

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesProvider must be overridden');
});

/// Provider for onboarding completion state
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
});

/// Synchronous provider for onboarding completion state (for router redirects)
/// This uses a cached value that should be updated when the async provider completes
final onboardingCompleteSyncProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(onboardingCompleteProvider);
  return asyncValue.when(
    data: (isComplete) => isComplete,
    loading: () => false, // Default to not complete while loading
    error: (_, __) => false, // Default to not complete on error
  );
});

/// Provider for permissions setup completion state
final permissionsSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(AppConstants.permissionsSetupCompleteKey) ?? false;
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../routes/app_router.dart';

// Theme Provider
final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

// Onboarding Provider
final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete =
          prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
      state = isComplete;
    } catch (e) {
      // Keep default state (false) if there's an error
      state = false;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.onboardingCompleteKey, true);
      state = true;
    } catch (e) {
      // Handle error if needed
      state = false;
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.onboardingCompleteKey);
      state = false;
    } catch (e) {
      // Handle error if needed
    }
  }
}

// User Preferences Provider
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, Map<String, dynamic>>((ref) {
  return UserPreferencesNotifier();
});

class UserPreferencesNotifier extends StateNotifier<Map<String, dynamic>> {
  UserPreferencesNotifier() : super({}) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesString =
          prefs.getString(AppConstants.userPreferencesKey);

      if (preferencesString != null) {
        // Parse preferences from JSON string
        // For now, we'll use a simple implementation
        state = {
          'notifications': prefs.getBool('notifications') ?? true,
          'darkMode': prefs.getBool('darkMode') ?? false,
          'autoSync': prefs.getBool('autoSync') ?? true,
          'biometricAuth': prefs.getBool('biometricAuth') ?? false,
        };
      }
    } catch (e) {
      // Keep default state if there's an error
      state = {
        'notifications': true,
        'darkMode': false,
        'autoSync': true,
        'biometricAuth': false,
      };
    }
  }

  Future<void> updatePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update SharedPreferences
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }

      // Update state
      state = {...state, key: value};
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> resetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userPreferencesKey);

      // Reset to defaults
      state = {
        'notifications': true,
        'darkMode': false,
        'autoSync': true,
        'biometricAuth': false,
      };
    } catch (e) {
      // Handle error if needed
    }
  }
}

// Authentication State Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = AuthState.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.authTokenKey);

      if (token != null && token.isNotEmpty) {
        state = AuthState.authenticated(token);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login(String token) async {
    state = AuthState.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, token);
      state = AuthState.authenticated(token);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.authTokenKey);
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

class AuthState {
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState();
  factory AuthState.loading() => AuthState(isLoading: true);
  factory AuthState.authenticated(String token) => AuthState(token: token);
  factory AuthState.unauthenticated() => AuthState();
  factory AuthState.error(String message) => AuthState(errorMessage: message);
}

// App State Provider
final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.initial()) {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    state = AppState.loading();

    try {
      // Initialize app components
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate initialization

      state = AppState.loaded();
    } catch (e) {
      state = AppState.error(e.toString());
    }
  }

  void setLoading() {
    state = AppState.loading();
  }

  void setError(String error) {
    state = AppState.error(error);
  }

  void setLoaded() {
    state = AppState.loaded();
  }
}

class AppState {
  final bool isLoading;
  final String? errorMessage;

  AppState({
    this.isLoading = false,
    this.errorMessage,
  });

  factory AppState.initial() => AppState();
  factory AppState.loading() => AppState(isLoading: true);
  factory AppState.loaded() => AppState();
  factory AppState.error(String message) => AppState(errorMessage: message);
}

// Network Status Provider
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  NetworkStatusNotifier() : super(NetworkStatus.connected()) {
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    // In a real app, you would use connectivity_plus package
    // For now, we'll assume we're connected
    state = NetworkStatus.connected();
  }

  void setConnected() {
    state = NetworkStatus.connected();
  }

  void setDisconnected() {
    state = NetworkStatus.disconnected();
  }
}

class NetworkStatus {
  final bool isConnected;

  NetworkStatus({required this.isConnected});

  factory NetworkStatus.connected() => NetworkStatus(isConnected: true);
  factory NetworkStatus.disconnected() => NetworkStatus(isConnected: false);
}

// Battery Status Provider
final batteryStatusProvider =
    StateNotifierProvider<BatteryStatusNotifier, BatteryStatus>((ref) {
  return BatteryStatusNotifier();
});

class BatteryStatusNotifier extends StateNotifier<BatteryStatus> {
  BatteryStatusNotifier() : super(BatteryStatus.normal(100)) {
    _checkBatteryStatus();
  }

  Future<void> _checkBatteryStatus() async {
    // In a real app, you would use battery_plus package
    // For now, we'll simulate battery status
    state = BatteryStatus.normal(75);
  }

  void updateBatteryLevel(int level) {
    if (level <= AppConstants.batteryThresholdCritical) {
      state = BatteryStatus.critical(level);
    } else if (level <= AppConstants.batteryThresholdLow) {
      state = BatteryStatus.low(level);
    } else {
      state = BatteryStatus.normal(level);
    }
  }
}

class BatteryStatus {
  final int level;
  final BatteryStatusType type;

  BatteryStatus({
    required this.level,
    required this.type,
  });

  factory BatteryStatus.normal(int level) => BatteryStatus(
        level: level,
        type: BatteryStatusType.normal,
      );
  factory BatteryStatus.low(int level) => BatteryStatus(
        level: level,
        type: BatteryStatusType.low,
      );
  factory BatteryStatus.critical(int level) => BatteryStatus(
        level: level,
        type: BatteryStatusType.critical,
      );
}

enum BatteryStatusType {
  normal,
  low,
  critical,
}

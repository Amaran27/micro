import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'infrastructure/permissions/services/store_compliant_permissions_manager.dart';
import 'infrastructure/permissions/services/store_policy_validator.dart';
import 'infrastructure/permissions/services/runtime_permission_requester.dart';
import 'infrastructure/permissions/services/permission_auditor.dart';
import 'infrastructure/ai/ai_provider_config.dart';
import 'infrastructure/ai/model_selection_service.dart';
import 'infrastructure/ai/model_selection_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize logger
  await logger.initialize();
  logger.info('Starting Micro app v${AppConfig.appVersion}');

  // Initialize AI Provider Configuration
  final aiProviderConfig = AIProviderConfig();
  await aiProviderConfig.initialize();

  // Initialize ModelSelectionService (singleton)
  final modelSelectionService = ModelSelectionService.instance;
  await modelSelectionService.initialize();

  // Override the sharedPreferencesProvider with the actual instance
  // Create a simple permissions manager for testing
  final permissionsManager = StoreCompliantPermissionsManager(
    policyValidator: StorePolicyValidator(),
    requester: RuntimePermissionRequester(),
    auditor: PermissionAuditor(),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionsManagerProvider.overrideWithValue(permissionsManager),
        aiProviderConfigProvider.overrideWithValue(aiProviderConfig),
        modelSelectionServiceProvider.overrideWithValue(modelSelectionService),
      ],
      child: const MicroApp(),
    ),
  );
}

class MicroApp extends ConsumerWidget {
  const MicroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize ModelSelectionService by watching the provider
    ref.watch(initializedModelSelectionServiceProvider);

    // For now, using default theme and router
    final appRouter = AppRouter.router;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner:
          AppConfig.environment == Environment.development,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
        Locale('fr', 'FR'), // French
        Locale('de', 'DE'), // German
        Locale('ja', 'JP'), // Japanese
        Locale('zh', 'CN'), // Chinese
        Locale('hi', 'IN'), // Hindi
      ],

      // Router
      routerConfig: appRouter,

      // Builder for additional setup
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

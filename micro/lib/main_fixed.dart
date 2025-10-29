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
import 'infrastructure/ai/model_selection_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize logger
  AppLogger.initialize(
    enableConsole: true,
    enableFile: true,
    level: LogLevel.debug,
  );
  
  // Run the app with providers
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        permissionsManagerProvider.overrideWithValue(
          StoreCompliantPermissionsManager(
            storePolicyValidator: StorePolicyValidator(),
            runtimePermissionRequester: RuntimePermissionRequester(),
            permissionAuditor: PermissionAuditor(),
          ),
        ),
        aiProviderConfigProvider.overrideWithValue(AIProviderConfig()),
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
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppConstants.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
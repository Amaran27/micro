import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_config.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  await logger.initialize();
  logger.info('Starting Micro app v${AppConfig.appVersion}');

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: MicroApp(),
    ),
  );
}

class MicroApp extends ConsumerWidget {
  const MicroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner:
          AppConfig.environment == Environment.development,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appTheme,

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

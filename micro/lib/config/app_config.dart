class AppConfig {
  // App Information
  static const String appName = 'Micro';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A privacy-first, autonomous agentic mobile assistant';

  // Environment
  static const Environment environment = Environment.development;

  // API Configuration
  static const String apiBaseUrl = 'https://api.micro.psitrix.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Security Configuration
  static const bool enableEncryption = true;
  static const bool requireAuthentication = true;
  static const int maxLoginAttempts = 3;

  // Database Configuration
  static const String databaseName = 'micro.db';
  static const int databaseVersion = 1;
  static const bool enableDatabaseEncryption = true;

  // Performance Configuration
  static const int maxConcurrentWorkflows = 5;
  static const Duration workflowTimeout = Duration(minutes: 10);
  static const int maxMemoryUsageMB = 150;

  // Mobile Optimization
  static const int batteryThresholdLow = 20;
  static const int batteryThresholdCritical = 10;
  static const bool enableBatteryOptimization = true;
  static const bool enableAdaptivePerformance = true;

  // Logging Configuration
  static const LogLevel logLevel = LogLevel.info;
  static const bool enableRemoteLogging = false;
  static const int maxLogFiles = 5;

  // UI Configuration
  static const bool enableAnimations = true;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const bool enableDarkMode = true;
}

enum Environment {
  development,
  staging,
  production,
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

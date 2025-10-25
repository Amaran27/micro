class AppConstants {
  // App Information
  static const String appName = 'Micro';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'micro.db';
  static const int databaseVersion = 1;

  // Security
  static const String encryptionKeyAlias = 'micro_encryption_key';
  static const String biometricKeyAlias = 'micro_biometric_key';
  static const int maxLoginAttempts = 3;
  static const Duration sessionTimeout = Duration(hours: 24);

  // API Endpoints
  static const String mcpProtocolPath = '/mcp';
  static const String toolsEndpoint = '/tools';
  static const String workflowsEndpoint = '/workflows';
  static const String agentsEndpoint = '/agents';

  // Performance
  static const int maxConcurrentWorkflows = 5;
  static const Duration workflowTimeout = Duration(minutes: 10);
  static const int maxMemoryUsageMB = 150;
  static const int maxCpuUsagePercent = 80;

  // Battery Optimization
  static const int batteryThresholdLow = 20;
  static const int batteryThresholdCritical = 10;
  static const Duration batteryCheckInterval = Duration(minutes: 5);

  // UI Constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;

  // Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String deviceIdKey = 'device_id';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Error Messages
  static const String genericErrorMessage = 'An unexpected error occurred';
  static const String networkErrorMessage = 'Network connection failed';
  static const String authenticationErrorMessage = 'Authentication failed';
  static const String permissionDeniedMessage = 'Permission denied';

  // Success Messages
  static const String workflowCreatedMessage = 'Workflow created successfully';
  static const String workflowExecutedMessage =
      'Workflow executed successfully';
  static const String settingsSavedMessage = 'Settings saved successfully';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxWorkflowNameLength = 100;
  static const int maxDescriptionLength = 500;

  // Logging
  static const String logFileName = 'micro.log';
  static const int maxLogFileSizeKB = 1024; // 1MB
  static const int maxLogFiles = 5;

  // MCP Protocol
  static const String mcpVersion = '1.0.0';
  static const Duration mcpTimeout = Duration(seconds: 30);
  static const int mcpMaxRetries = 3;

  // Agent Communication
  static const String agentProtocolVersion = '1.0.0';
  static const Duration agentHeartbeatInterval = Duration(minutes: 5);
  static const Duration agentConnectionTimeout = Duration(seconds: 10);

  // Domain Specialization
  static const int domainAnalysisThreshold =
      3; // Minimum tools for domain detection
  static const double domainConfidenceThreshold =
      0.7; // 70% confidence for specialization
  static const Duration domainAnalysisInterval = Duration(hours: 1);

  // Security Monitoring
  static const Duration securityCheckInterval = Duration(minutes: 10);
  static const int maxFailedLogins = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Memory Management
  static const int cacheSizeMB = 50;
  static const Duration cacheCleanupInterval = Duration(hours: 6);
  static const int maxCachedItems = 1000;

  // Background Tasks
  static const Duration backgroundTaskInterval = Duration(minutes: 30);
  static const Duration syncInterval = Duration(hours: 2);
  static const Duration backupInterval = Duration(days: 1);
}

class DatabaseConstants {
  // Table Names
  static const String workflowsTable = 'workflows';
  static const String workflowInstancesTable = 'workflow_instances';
  static const String nodesTable = 'nodes';
  static const String nodeExecutionsTable = 'node_executions';
  static const String triggersTable = 'triggers';
  static const String auditLogsTable = 'audit_logs';
  static const String userPrefsTable = 'user_prefs';
  static const String memoriesTable = 'memories';
  static const String toolsTable = 'tools';
  static const String mcpServersTable = 'mcp_servers';

  // Column Names
  static const String idColumn = 'id';
  static const String nameColumn = 'name';
  static const String descriptionColumn = 'description';
  static const String manifestColumn = 'manifest';
  static const String ownerColumn = 'owner';
  static const String enabledColumn = 'enabled';
  static const String createdAtColumn = 'created_at';
  static const String updatedAtColumn = 'updated_at';

  // Indexes
  static const String workflowsOwnerIndex = 'idx_workflows_owner';
  static const String workflowsEnabledIndex = 'idx_workflows_enabled';
  static const String instancesWorkflowIndex = 'idx_instances_workflow';
  static const String instancesStateIndex = 'idx_instances_state';
  static const String nodesWorkflowIndex = 'idx_nodes_workflow';
  static const String executionsInstanceIndex = 'idx_executions_instance';
  static const String auditLogsTimestampIndex = 'idx_audit_logs_timestamp';
}

class RouteConstants {
  static const String home = '/home';
  static const String chat = '/chat';
  static const String dashboard = '/dashboard';
  static const String tools = '/tools';
  static const String settings = '/settings';
  static const String workflows = '/workflows';
  static const String onboarding = '/onboarding';
  static const String workflowDetail = '/workflow/:id';
  static const String toolDetail = '/tool/:id';
  static const String audit = '/audit';
}

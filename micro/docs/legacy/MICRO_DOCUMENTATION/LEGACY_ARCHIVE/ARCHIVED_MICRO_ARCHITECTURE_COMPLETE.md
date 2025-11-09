# Micro - Complete Architecture Guide

## Overview

Micro is a privacy-first, autonomous agentic mobile assistant built with Flutter, designed to adapt to any domain through its MCP-first architecture. This document provides the complete technical architecture, database design, technology stack, and implementation details.

## 1. System Architecture

### 1.1 Core Design Principles

- **Privacy-First**: All data stored locally by default, cloud sync opt-in
- **MCP-First**: All capabilities discovered and integrated through Model Context Protocol
- **Domain-Agnostic**: Universal architecture that adapts to any domain
- **Mobile-Optimized**: Designed for mobile constraints (battery, memory, CPU)
- **Security by Design**: Google Play compliant with comprehensive security framework

### 1.2 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Micro Mobile App                         │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (Flutter UI + Riverpod State)          │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Business Logic + Use Cases)                 │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure Layer (MCP Client + Services)              │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (SQLCipher + Secure Storage)                   │
├─────────────────────────────────────────────────────────────┤
│  Platform Layer (Android APIs + Device Integration)        │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Flutter Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration and routing
├── config/                   # Configuration files
│   ├── app_config.dart
│   ├── mcp_config.dart
│   └── theme_config.dart
├── core/                     # Core utilities and helpers
│   ├── constants.dart
│   ├── extensions.dart
│   ├── utils/
│   │   ├── crypto_utils.dart
│   │   ├── date_utils.dart
│   │   └── logger.dart
│   └── exceptions/
│       ├── app_exception.dart
│       └── mcp_exception.dart
├── data/                     # Data layer
│   ├── models/               # Data models
│   │   ├── base_model.dart
│   │   ├── workflow.dart
│   │   ├── tool.dart
│   │   ├── trigger.dart
│   │   └── user_preferences.dart
│   ├── repositories/         # Repository implementations
│   │   ├── base_repository.dart
│   │   ├── workflow_repository.dart
│   │   ├── tool_repository.dart
│   │   └── audit_repository.dart
│   ├── sources/              # Data sources
│   │   ├── local_data_source.dart
│   │   ├── remote_data_source.dart
│   │   └── mcp_data_source.dart
│   └── services/             # Data services
│       ├── database_service.dart
│       ├── secure_storage_service.dart
│       └── file_service.dart
├── domain/                   # Domain layer
│   ├── entities/             # Domain entities
│   │   ├── workflow.dart
│   │   ├── tool.dart
│   │   ├── trigger.dart
│   │   └── audit_log.dart
│   ├── repositories/         # Repository interfaces
│   │   ├── workflow_repository.dart
│   │   ├── tool_repository.dart
│   │   └── audit_repository.dart
│   ├── usecases/             # Business logic
│   │   ├── workflow/
│   │   │   ├── create_workflow.dart
│   │   │   ├── execute_workflow.dart
│   │   │   └── delete_workflow.dart
│   │   ├── tool/
│   │   │   ├── discover_tools.dart
│   │   │   └── execute_tool.dart
│   │   └── trigger/
│   │       ├── create_trigger.dart
│   │       └── monitor_triggers.dart
│   └── services/             # Domain services
│       ├── mcp_service.dart
│       ├── workflow_service.dart
│       ├── scheduler_service.dart
│       └── security_service.dart
├── presentation/             # Presentation layer
│   ├── pages/                # Main pages
│   │   ├── home_page.dart
│   │   ├── chat_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── tools_page.dart
│   │   ├── settings_page.dart
│   │   └── audit_page.dart
│   ├── widgets/              # Reusable widgets
│   │   ├── common/
│   │   ├── chat/
│   │   ├── workflow/
│   │   └── tools/
│   ├── providers/            # Riverpod providers
│   │   ├── app_providers.dart
│   │   ├── workflow_providers.dart
│   │   ├── tool_providers.dart
│   │   ├── mcp_providers.dart
│   │   └── auth_providers.dart
│   └── routes/               # Navigation
│       ├── app_routes.dart
│       └── route_names.dart
├── infrastructure/           # Infrastructure layer
│   ├── network/              # Network layer
│   │   ├── mcp_client.dart
│   │   ├── api_client.dart
│   │   └── websocket_client.dart
│   ├── repositories/         # Repository implementations
│   │   ├── workflow_repository_impl.dart
│   │   ├── tool_repository_impl.dart
│   │   └── audit_repository_impl.dart
│   ├── services/             # Platform services
│   │   ├── device_service.dart
│   │   ├── notification_service.dart
│   │   ├── location_service.dart
│   │   └── biometric_service.dart
│   └── mcp/                  # MCP implementation
│       ├── mcp_client_impl.dart
│       ├── mcp_protocol.dart
│       ├── mcp_tool.dart
│       └── mcp_server.dart
└── features/                 # Feature modules
    ├── onboarding/           # Onboarding feature
    ├── workflow/             # Workflow feature
    ├── tools/                # Tools feature
    ├── chat/                 # Chat feature
    └── settings/             # Settings feature
```

## 2. Database Design

### 2.1 Database Technology

- **SQLite** with **SQLCipher** encryption for secure local storage
- **Flutter Package**: `sqflite` with `sqlcipher_flutter_lib`
- **Encryption**: 256-bit AES encryption for all data at rest

### 2.2 Database Schema

#### Core Tables

```sql
-- Workflows table
CREATE TABLE workflows (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    manifest TEXT NOT NULL,  -- JSON workflow definition
    owner TEXT NOT NULL,     -- User ID
    enabled INTEGER DEFAULT 1,
    autonomy_level INTEGER DEFAULT 1,  -- 0=Off, 1=Ask, 2=Auto
    risk_score INTEGER DEFAULT 0,      -- Calculated risk score
    created_at INTEGER NOT NULL,       -- Unix timestamp
    updated_at INTEGER NOT NULL,
    last_executed_at INTEGER,          -- Unix timestamp
    execution_count INTEGER DEFAULT 0,
    UNIQUE(name, owner)
);

-- Workflow instances table
CREATE TABLE workflow_instances (
    instance_id TEXT PRIMARY KEY,
    workflow_id TEXT NOT NULL,
    state TEXT NOT NULL,      -- 'pending', 'running', 'paused', 'completed', 'failed', 'cancelled'
    current_node TEXT,        -- ID of current execution node
    inputs TEXT,              -- JSON input parameters
    outputs TEXT,             -- JSON output results
    error_message TEXT,
    created_at INTEGER NOT NULL,
    started_at INTEGER,
    completed_at INTEGER,
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);

-- Nodes table
CREATE TABLE nodes (
    node_id TEXT PRIMARY KEY,
    workflow_id TEXT NOT NULL,
    node_type TEXT NOT NULL,  -- 'tool', 'condition', 'loop', 'parallel'
    tool_id TEXT,             -- Reference to tool if node_type='tool'
    input_schema TEXT,        -- JSON input schema
    output_schema TEXT,       -- JSON output schema
    position INTEGER NOT NULL, -- Position in workflow graph
    depends_on TEXT,          -- JSON array of node IDs this node depends on
    compensation_node TEXT,   -- Node to execute on failure
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);

-- Node executions table
CREATE TABLE node_executions (
    execution_id TEXT PRIMARY KEY,
    instance_id TEXT NOT NULL,
    node_id TEXT NOT NULL,
    attempt INTEGER NOT NULL,
    status TEXT NOT NULL,     -- 'pending', 'running', 'completed', 'failed', 'skipped'
    inputs TEXT,              -- JSON input parameters
    outputs TEXT,             -- JSON output results
    error_message TEXT,
    started_at INTEGER NOT NULL,
    completed_at INTEGER,
    duration INTEGER,         -- Execution duration in milliseconds
    FOREIGN KEY (instance_id) REFERENCES workflow_instances(instance_id) ON DELETE CASCADE,
    FOREIGN KEY (node_id) REFERENCES nodes(node_id) ON DELETE CASCADE
);

-- Triggers table
CREATE TABLE triggers (
    trigger_id TEXT PRIMARY KEY,
    type TEXT NOT NULL,       -- 'time', 'event', 'location', 'sensor', etc.
    filter_spec TEXT NOT NULL, -- JSON filter specification
    enabled INTEGER DEFAULT 1,
    workflow_id TEXT NOT NULL,
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);

-- Audit logs table
CREATE TABLE audit_logs (
    log_id TEXT PRIMARY KEY,
    action TEXT NOT NULL,
    actor TEXT NOT NULL,
    details TEXT,
    timestamp INTEGER NOT NULL,
    risk_level INTEGER DEFAULT 0
);

-- User preferences table
CREATE TABLE user_prefs (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    encrypted INTEGER DEFAULT 0
);

-- Memories table (for vector search)
CREATE TABLE memories (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    vector BLOB,
    text TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    domain TEXT
);

-- Tools table
CREATE TABLE tools (
    tool_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    manifest TEXT NOT NULL,
    server_id TEXT NOT NULL,
    enabled INTEGER DEFAULT 1,
    risk_score INTEGER DEFAULT 0,
    domain TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- MCP servers table
CREATE TABLE mcp_servers (
    server_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    auth_token TEXT,
    enabled INTEGER DEFAULT 1,
    last_sync INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### 2.3 Database Indexes

```sql
-- Performance indexes
CREATE INDEX idx_workflows_owner ON workflows(owner);
CREATE INDEX idx_workflows_enabled ON workflows(enabled);
CREATE INDEX idx_workflows_autonomy ON workflows(autonomy_level);
CREATE INDEX idx_workflows_created ON workflows(created_at);

CREATE INDEX idx_workflow_instances_workflow ON workflow_instances(workflow_id);
CREATE INDEX idx_workflow_instances_state ON workflow_instances(state);
CREATE INDEX idx_workflow_instances_created ON workflow_instances(created_at);

CREATE INDEX idx_nodes_workflow ON nodes(workflow_id);
CREATE INDEX idx_nodes_type ON nodes(node_type);
CREATE INDEX idx_nodes_position ON nodes(position);

CREATE INDEX idx_node_executions_instance ON node_executions(instance_id);
CREATE INDEX idx_node_executions_node ON node_executions(node_id);
CREATE INDEX idx_node_executions_status ON node_executions(status);
CREATE INDEX idx_node_executions_started ON node_executions(started_at);

CREATE INDEX idx_triggers_workflow ON triggers(workflow_id);
CREATE INDEX idx_triggers_type ON triggers(type);
CREATE INDEX idx_triggers_enabled ON triggers(enabled);

CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_risk_level ON audit_logs(risk_level);

CREATE INDEX idx_tools_server ON tools(server_id);
CREATE INDEX idx_tools_domain ON tools(domain);
CREATE INDEX idx_tools_enabled ON tools(enabled);

CREATE INDEX idx_memories_domain ON memories(domain);
CREATE INDEX idx_memories_type ON memories(type);
CREATE INDEX idx_memories_created ON memories(created_at);
```

## 3. Technology Stack

### 3.1 Core Dependencies

```yaml
name: micro
description: A privacy-first, autonomous agentic mobile assistant.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # State Management
  riverpod: ^2.4.9
  hooks_riverpod: ^2.4.9
  
  # Navigation
  go_router: ^12.1.3
  
  # Database & Storage
  sqflite: ^2.3.0
  sqlcipher_flutter_lib: ^1.6.0
  path_provider: ^2.1.1
  flutter_secure_storage: ^9.0.0
  
  # Networking
  dio: ^5.4.0+1
  web_socket_channel: ^2.4.0
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # UI & Material Design
  flutter_animate: ^4.3.0
  fl_chart: ^0.68.0
  flutter_markdown: ^0.6.18
  
  # Permissions & Device Integration
  permission_handler: ^11.1.0
  local_auth: ^2.1.7
  sensors_plus: ^4.0.2
  geolocator: ^10.1.0
  sms_plus: ^1.0.0
  workmanager: ^0.5.2
  
  # Utilities
  intl: ^0.18.1
  logger: ^2.0.2+1
  path: ^1.8.3
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  
  # Forms
  flutter_form_builder: ^9.1.0
  form_builder_validators: ^9.1.0
  
  # Security
  encrypt: ^5.0.1
  pointycastle: ^3.7.3
  
  # Performance
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Markdown
  markdown: ^7.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  flutter_gen_runner: ^5.3.0
  json_serializable: ^6.7.1
  build_runner: ^2.4.6
  mocktail: ^1.0.1
  test: ^1.24.0
  equatable: ^2.0.5

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700

flutter_gen:
  output: lib/generated/
  line_length: 80
  integrations:
    flutter_svg: true
    lottie: true
    flare_flutter: true
    rive: true
```

### 3.2 Package Rationale

#### State Management
- **riverpod**: Compile-safe state management with excellent performance
- **hooks_riverpod**: Reactful state management with hooks

#### Database & Storage
- **sqflite**: SQLite wrapper for Flutter
- **sqlcipher_flutter_lib**: SQLCipher encryption for secure data storage
- **flutter_secure_storage**: Secure key-value storage for sensitive data

#### Networking
- **dio**: Powerful HTTP client with interceptors and retry logic
- **web_socket_channel**: WebSocket support for real-time communication

#### UI & UX
- **go_router**: Declarative routing with deep linking support
- **flutter_animate**: Easy-to-use animation library
- **fl_chart**: Beautiful charts for dashboard and analytics
- **flutter_markdown**: Markdown rendering for chat interface

#### Device Integration
- **permission_handler**: Comprehensive permission management
- **local_auth**: Biometric authentication
- **sensors_plus**: Device sensor access
- **geolocator**: Location services
- **workmanager**: Background task scheduling

#### Security
- **encrypt**: High-level encryption utilities
- **pointycastle**: Low-level cryptographic operations

## 4. MCP Implementation

### 4.1 MCP Client Architecture

```dart
class McpClient {
  final String serverUrl;
  final Dio _httpClient;
  final WebSocketChannel? _wsChannel;
  final SecurityService _securityService;
  
  // MCP protocol methods
  Future<List<Tool>> discoverTools();
  Future<ToolCallResult> callTool(ToolCall call);
  Future<List<ServerCapability>> getCapabilities();
  Future<void> subscribeToUpdates(String subscriptionId);
  
  // Security methods
  Future<void> authenticate(String token);
  bool validateToolManifest(ToolManifest manifest);
  
  // Error handling and retries
  Future<ToolCallResult> callToolWithRetry(ToolCall call, {int maxRetries = 3});
}
```

### 4.2 Tool Registry

```dart
class ToolRegistry {
  final Map<String, Tool> _localTools = {};
  final Map<String, Tool> _remoteTools = {};
  final SecurityService _securityService;
  
  void registerLocalTool(Tool tool);
  void registerRemoteTool(Tool tool);
  Tool? getTool(String toolId);
  List<Tool> getAllEnabledTools();
  List<Tool> getToolsByDomain(String domain);
  
  // Security validation
  bool validateToolSecurity(Tool tool);
  Future<SecurityRisk> assessToolRisk(Tool tool);
}
```

### 4.3 Universal Tool Adapter

```dart
abstract class UniversalToolAdapter {
  Future<ToolCapability> discoverCapabilities();
  Future<void> configureForDomain(String domain);
  Future<ToolResult> executeWithContext(ToolCall call, DomainContext context);
  Future<SecurityAssessment> assessSecurity();
}
```

## 5. Universal Domain Capabilities

### 5.1 Domain-Agnostic Core Design

Micro's architecture is fundamentally domain-agnostic, designed to adapt to any domain through tool discovery and intelligent orchestration:

```dart
class UniversalAgent {
  final ToolRegistry _toolRegistry;
  final ContextManager _contextManager;
  final LearningEngine _learningEngine;
  final DomainSpecializer _domainSpecializer;
  
  // Automatic domain specialization
  Future<DomainCapability> analyzeDomainCapabilities();
  Future<void> adaptToDomain(String domainContext);
  Future<WorkflowPlan> createSpecializedWorkflow(UserRequest request);
}
```

### 5.2 Dynamic Domain Recognition

Micro automatically recognizes domain contexts through:

- **Tool Pattern Analysis**: Analyzing available tools to identify domain capabilities
- **Context Inference**: Understanding user intent and domain-specific language
- **Knowledge Graph Integration**: Building domain expertise from available data sources
- **Adaptive Learning**: Learning domain patterns from user interactions

### 5.3 Domain Specialization Examples

#### Trading & Finance (When Tools Available)
When financial tools are available, Micro automatically becomes a financial specialist:

**Required MCP Tools (User-Configurable):**
- Market data APIs (Alpha Vantage, Yahoo Finance, etc.)
- Portfolio management services
- Trading platforms with API access
- Banking and payment services
- Financial analysis tools

**Workflow Examples:**
- Portfolio rebalancing based on market conditions
- Automated trading alerts with risk management
- Expense tracking and budget optimization
- Tax loss harvesting automation

#### Smart Home Automation (When Tools Available)
When home automation tools are available, Micro becomes a home management specialist:

**Required MCP Tools (User-Configurable):**
- Home Assistant integration
- Smart device APIs (lights, thermostats, security)
- IoT platform connections
- Energy monitoring services
- Voice assistant integrations

**Workflow Examples:**
- Adaptive lighting based on occupancy and time
- Energy optimization based on usage patterns
- Security automation with geofencing
- Appliance monitoring and maintenance alerts

#### Communication (When Tools Available)
When communication tools are available, Micro becomes a communication specialist:

**Required MCP Tools (User-Configurable):**
- Email service APIs (Gmail, Outlook, etc.)
- Messaging platforms (WhatsApp, Telegram, etc.)
- SMS and calling services
- Social media integrations
- Communication analytics tools

**Workflow Examples:**
- Intelligent message filtering and prioritization
- Automated responses for common inquiries
- Cross-platform message synchronization
- Communication pattern analysis

## 6. Security & Privacy Framework

### 6.1 Google Play Compliance

```dart
class GooglePlayComplianceFramework {
  // Data usage transparency
  Future<void> discloseDataUsage();
  
  // Permission management
  Future<void> managePermissions();
  
  // Content policy compliance
  Future<bool> checkContentCompliance();
  
  // Security best practices
  Future<void> implementSecurityBestPractices();
}
```

### 6.2 Security Architecture

```dart
class SecurityFramework {
  final EncryptionService _encryption;
  final AuthenticationManager _authManager;
  final ThreatDetectionService _threatDetection;
  final AuditLogger _auditLogger;
  
  // Core security methods
  Future<bool> authenticateUser();
  Future<void> encryptSensitiveData();
  Future<ThreatAssessment> assessThreats();
  Future<void> logSecurityEvent();
}
```

### 6.3 AI Safety & Abuse Prevention

#### Prompt Injection Detection
```dart
class PromptInjectionProtection {
  // Detect and prevent prompt injection attacks
  Future<PromptValidationResult> validatePrompt(String prompt);
  Future<InjectionResult> _detectAdvancedInjection(String prompt);
  Future<String> _sanitizePrompt(String prompt);
}
```

#### Malicious Workflow Identification
```dart
class WorkflowSecurityAnalyzer {
  // Analyze workflows for security risks
  Future<SecurityAssessment> analyzeWorkflow(Workflow workflow);
  Future<List<ThreatPattern>> detectMaliciousPatterns(Workflow workflow);
  Future<void> blockSuspiciousWorkflow(Workflow workflow);
}
```

#### Data Exfiltration Prevention
```dart
class DataExfiltrationPrevention {
  // Prevent data exfiltration
  Future<DataTransferResult> validateDataTransfer(DataTransferRequest request);
  Future<ExfiltrationRisk> _assessExfiltrationRisk(DataTransferRequest request);
  Future<void> applyDataProtection(DataTransferRequest request);
}
```

## 7. Mobile Optimization Strategy

### 7.1 Resource Optimization

#### Battery Management
```dart
class BatteryOptimizationManager {
  Future<void> optimizeForBatteryLevel();
  Future<BatteryOptimizationStrategy> _determineOptimizationStrategy();
  Future<void> _applyOptimizationStrategy(BatteryOptimizationStrategy strategy);
}
```

**Target**: < 5% battery usage over 24 hours

#### Memory Management
```dart
class MemoryManager {
  Future<void> optimizeMemoryUsage();
  Future<MemoryPressure> _calculateMemoryPressure(MemoryInfo memoryInfo);
  Future<void> _applyMemoryOptimization(MemoryPressure pressure);
}
```

**Target**: < 150MB average memory usage

#### CPU Management
```dart
class CPUManager {
  Future<void> optimizeCPUUsage();
  Future<ThermalState> _monitorThermalState();
  Future<void> _applyThrottling(ThermalState state);
}
```

#### Storage Management
```dart
class StorageManager {
  Future<void> optimizeStorage();
  Future<void> _cleanupOldData();
  Future<void> _compressData();
}
```

**Target**: < 100MB storage footprint

### 7.2 Resilience & Error Handling

#### Crash Recovery
```dart
class CrashRecoveryManager {
  Future<void> handleCrash(CrashInfo crashInfo);
  Future<RecoveryResult> _attemptStateRecovery();
  Future<void> _restoreApplicationState(AppState state);
}
```

**Target**: < 0.1% crash rate, > 95% recovery success

#### Network Resilience
```dart
class NetworkResilienceManager {
  Future<void> handleNetworkInterruption();
  Future<void> _enableOfflineMode();
  Future<void> _syncPendingData();
}
```

**Target**: Seamless operation with 50% packet loss

### 7.3 Performance Optimization

#### Adaptive Processing
```dart
class AdaptiveProcessingManager {
  Future<void> adjustProcessingBasedOnResources();
  Future<ProcessingLevel> _determineOptimalLevel();
  Future<void> _applyProcessingLevel(ProcessingLevel level);
}
```

#### Background Task Optimization
```dart
class BackgroundTaskOptimizer {
  Future<void> optimizeBackgroundTasks();
  Future<void> _scheduleTasksIntelligently();
  Future<void> _batchOperations();
}
```

## 8. State Management with Riverpod

### 8.1 Provider Architecture

```dart
// Main providers
final mcpClientProvider = Provider<McpClient>((ref) {
  return McpClient();
});

final workflowProvider = StateNotifierProvider<WorkflowNotifier, WorkflowState>((ref) {
  return WorkflowNotifier();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Domain-specific providers
final financeDomainProvider = Provider<FinanceDomain>((ref) {
  return FinanceDomain();
});

final homeAutomationDomainProvider = Provider<HomeAutomationDomain>((ref) {
  return HomeAutomationDomain();
});
```

### 8.2 State Management Patterns

```dart
class WorkflowNotifier extends StateNotifier<WorkflowState> {
  WorkflowNotifier(this._workflowRepository) : super(const WorkflowState.initial());
  
  final WorkflowRepository _workflowRepository;
  
  Future<void> createWorkflow(Workflow workflow) async {
    state = const WorkflowState.loading();
    try {
      await _workflowRepository.createWorkflow(workflow);
      state = WorkflowState.success(workflow);
    } catch (e) {
      state = WorkflowState.error(e.toString());
    }
  }
  
  Future<void> executeWorkflow(String workflowId) async {
    // Execute workflow logic
  }
}
```

## 9. UI Architecture

### 9.1 Navigation Structure

```dart
class AppRouter {
  final GoRouter _router;
  
  AppRouter() : _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/tools',
        builder: (context, state) => const ToolsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
```

### 9.2 Material Design 3 Implementation

```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    typography: AppTypography.textTheme,
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    typography: AppTypography.textTheme,
  );
}
```

## 10. Testing Strategy

### 10.1 Test Architecture

```dart
// Unit tests
test('workflow creation', () {
  final workflow = Workflow.test();
  expect(workflow.name, 'Test Workflow');
});

// Widget tests
testWidgets('chat interface renders', (tester) async {
  await tester.pumpWidget(const ChatPage());
  expect(find.byType(ChatInput), findsOneWidget);
});

// Integration tests
testWidgets('complete workflow execution', (tester) async {
  await tester.pumpWidget(const MicroApp());
  // Test complete workflow
});
```

### 10.2 Performance Testing

```dart
// Performance tests
test('workflow execution performance', () async {
  final stopwatch = Stopwatch()..start();
  await workflowEngine.executeWorkflow(workflow);
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

## 11. Success Metrics

### 11.1 Technical Metrics
- App startup time < 2 seconds
- Workflow execution time < 1 second for simple tasks
- Memory usage < 150MB average
- Battery impact < 5% over 24 hours
- Storage footprint < 100MB
- Network usage < 50MB daily

### 11.2 Security Metrics
- Threat detection accuracy > 99%
- False positive rate < 1%
- Incident response time < 1 minute
- Zero data exfiltration incidents
- 100% Google Play compliance

### 11.3 User Experience Metrics
- User satisfaction score > 4.7/5
- Task completion rate > 95%
- Error rate < 1%
- User retention rate > 70% after 30 days
- Feature adoption rate > 70%

## 12. Conclusion

This complete architecture guide provides the foundation for building Micro as a sophisticated, privacy-first, universal personal assistant. The architecture emphasizes:

1. **Privacy and Security**: End-to-end encryption, local-first data storage, and comprehensive security framework
2. **Universality**: Domain-agnostic design that adapts to any available tools and services
3. **Mobile Optimization**: Resource-efficient design optimized for mobile constraints
4. **Extensibility**: MCP-first architecture enabling unlimited tool integration
5. **User Experience**: Intuitive interface with Material Design 3 and adaptive interactions

The architecture ensures Micro can serve as a specialist in any domain while maintaining the highest standards of security, privacy, and user control. The Flutter-based implementation provides consistent UI/UX across all platforms while leveraging native capabilities when needed.

With this architecture, Micro is positioned to become the most advanced and customizable personal mobile assistant on the market, capable of adapting to user needs and available tools while maintaining excellent performance and user experience.
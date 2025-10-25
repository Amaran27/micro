# Micro - Development Guide

## Overview

This guide provides comprehensive resources for developing Micro, including setup instructions, code examples, troubleshooting, and best practices. It serves as the primary reference for developers working on the project.

## Quick Start Guide

### Prerequisites

- **Flutter SDK**: Latest stable version (>=3.16.0)
- **Dart SDK**: Compatible with Flutter version
- **Android Studio**: Latest version with Flutter plugin
- **Git**: For version control
- **Device**: Android device or emulator for testing

### Environment Setup

1. **Install Flutter**
   ```bash
   # Download Flutter SDK from https://flutter.dev/docs/get-started/install
   # Add Flutter to PATH
   export PATH="$PATH:/path/to/flutter/bin"
   
   # Verify installation
   flutter doctor
   ```

2. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd micro
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run Code Generation**
   ```bash
   flutter packages pub run build_runner build
   ```

5. **Run the App**
   ```bash
   flutter run
   ```

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write code following the architecture patterns
   - Add tests for new functionality
   - Update documentation as needed

3. **Run Tests**
   ```bash
   flutter test
   ```

4. **Code Quality Checks**
   ```bash
   flutter analyze
   dart format .
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create pull request on GitHub
   ```

## Code Examples & Patterns

### 1. MCP Client Implementation

```dart
// lib/infrastructure/mcp/mcp_client_impl.dart
class McpClientImpl implements McpClient {
  final Dio _httpClient;
  final SecurityService _securityService;
  final Logger _logger;
  
  McpClientImpl({
    required Dio httpClient,
    required SecurityService securityService,
    required Logger logger,
  }) : _httpClient = httpClient,
       _securityService = securityService,
       _logger = logger;

  @override
  Future<List<Tool>> discoverTools() async {
    try {
      _logger.info('Discovering tools from MCP server');
      
      final response = await _httpClient.get('/tools');
      final toolsData = response.data['tools'] as List;
      
      final tools = toolsData
          .map((toolData) => Tool.fromJson(toolData))
          .where((tool) => _securityService.validateTool(tool))
          .toList();
      
      _logger.info('Discovered ${tools.length} tools');
      return tools;
    } catch (e) {
      _logger.error('Failed to discover tools: $e');
      throw McpException('Tool discovery failed', e);
    }
  }

  @override
  Future<ToolCallResult> callTool(ToolCall call) async {
    try {
      _logger.info('Calling tool: ${call.toolId}');
      
      // Validate tool call
      await _securityService.validateToolCall(call);
      
      final response = await _httpClient.post(
        '/tools/${call.toolId}/execute',
        data: call.toJson(),
      );
      
      final result = ToolCallResult.fromJson(response.data);
      _logger.info('Tool call completed successfully');
      return result;
    } catch (e) {
      _logger.error('Tool call failed: $e');
      throw McpException('Tool execution failed', e);
    }
  }
}
```

### 2. State Management with Riverpod

```dart
// lib/presentation/providers/workflow_providers.dart
final workflowProvider = StateNotifierProvider<WorkflowNotifier, WorkflowState>((ref) {
  return WorkflowNotifier(ref.watch(workflowRepositoryProvider));
});

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  return WorkflowRepositoryImpl(
    dataSource: ref.watch(localDataSourceProvider),
    securityService: ref.watch(securityServiceProvider),
  );
});

class WorkflowNotifier extends StateNotifier<WorkflowState> {
  WorkflowNotifier(this._repository) : super(const WorkflowState.initial());
  
  final WorkflowRepository _repository;
  
  Future<void> createWorkflow(Workflow workflow) async {
    state = const WorkflowState.loading();
    try {
      await _repository.createWorkflow(workflow);
      state = WorkflowState.success(workflow);
    } catch (e) {
      state = WorkflowState.error(e.toString());
    }
  }
  
  Future<void> executeWorkflow(String workflowId) async {
    state = const WorkflowState.loading();
    try {
      final result = await _repository.executeWorkflow(workflowId);
      state = WorkflowState.success(result);
    } catch (e) {
      state = WorkflowState.error(e.toString());
    }
  }
}

@freezed
class WorkflowState with _$WorkflowState {
  const factory WorkflowState.initial() = _Initial;
  const factory WorkflowState.loading() = _Loading;
  const factory WorkflowState.success(dynamic data) = _Success;
  const factory WorkflowState.error(String message) = _Error;
}
```

### 3. Secure Database Implementation

```dart
// lib/data/services/database_service.dart
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'micro.db';
  static const int _dbVersion = 1;
  
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      password: await _getEncryptionKey(),
    );
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await db.execute('''
      CREATE TABLE workflows (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        manifest TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE workflow_instances (
        instance_id TEXT PRIMARY KEY,
        workflow_id TEXT NOT NULL,
        state TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (workflow_id) REFERENCES workflows(id)
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_workflows_enabled ON workflows(enabled)');
    await db.execute('CREATE INDEX idx_instances_workflow ON workflow_instances(workflow_id)');
  }
  
  static Future<String> _getEncryptionKey() async {
    // Generate or retrieve encryption key
    const keyStorage = FlutterSecureStorage();
    String? key = await keyStorage.read(key: 'db_encryption_key');
    
    if (key == null) {
      key = generateSecureRandomKey();
      await keyStorage.write(key: 'db_encryption_key', value: key);
    }
    
    return key;
  }
}
```

### 4. Security Service Implementation

```dart
// lib/infrastructure/services/security_service.dart
class SecurityService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  final Logger _logger;
  
  SecurityService({
    required FlutterSecureStorage secureStorage,
    required LocalAuthentication localAuth,
    required Logger logger,
  }) : _secureStorage = secureStorage,
       _localAuth = localAuth,
       _logger = logger;

  Future<bool> authenticateUser() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _logger.warning('Biometric authentication not available');
        return false;
      }
      
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Micro',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      
      _logger.info('User authentication: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      _logger.error('Authentication failed: $e');
      return false;
    }
  }
  
  Future<bool> validateTool(Tool tool) async {
    // Check tool manifest integrity
    if (!tool.manifest.isValid) {
      _logger.warning('Invalid tool manifest: ${tool.id}');
      return false;
    }
    
    // Check tool permissions
    final requiredPermissions = tool.manifest.requiredPermissions;
    for (final permission in requiredPermissions) {
      if (!await _hasPermission(permission)) {
        _logger.warning('Missing permission for tool ${tool.id}: $permission');
        return false;
      }
    }
    
    // Assess tool risk
    final riskScore = _assessToolRisk(tool);
    if (riskScore > RiskLevel.high) {
      _logger.warning('High risk tool detected: ${tool.id} (score: $riskScore)');
      return false;
    }
    
    return true;
  }
  
  Future<bool> validateToolCall(ToolCall call) async {
    // Implement prompt injection detection
    if (_detectPromptInjection(call.input)) {
      _logger.warning('Prompt injection detected in tool call');
      return false;
    }
    
    // Validate input parameters
    if (!_validateInputParameters(call)) {
      _logger.warning('Invalid input parameters in tool call');
      return false;
    }
    
    return true;
  }
  
  bool _detectPromptInjection(String input) {
    // Implement prompt injection detection logic
    final injectionPatterns = [
      RegExp(r'ignore previous instructions', caseSensitive: false),
      RegExp(r'system prompt', caseSensitive: false),
      RegExp(r'act as a different', caseSensitive: false),
    ];
    
    return injectionPatterns.any((pattern) => pattern.hasMatch(input));
  }
  
  RiskLevel _assessToolRisk(Tool tool) {
    // Implement risk assessment logic
    int riskScore = 0;
    
    // Check for network access
    if (tool.manifest.requiresNetwork) {
      riskScore += 2;
    }
    
    // Check for sensitive data access
    if (tool.manifest.accessesSensitiveData) {
      riskScore += 3;
    }
    
    // Check for system modifications
    if (tool.manifest.modifiesSystem) {
      riskScore += 4;
    }
    
    return RiskLevel.fromScore(riskScore);
  }
}
```

### 5. Mobile Optimization Implementation

```dart
// lib/infrastructure/services/battery_optimization_manager.dart
class BatteryOptimizationManager {
  final Battery _battery;
  final Workmanager _workmanager;
  final Logger _logger;
  
  BatteryOptimizationManager({
    required Battery battery,
    required Workmanager workmanager,
    required Logger logger,
  }) : _battery = battery,
       _workmanager = workmanager,
       _logger = logger;

  Future<void> optimizeForBatteryLevel() async {
    final batteryLevel = await _battery.batteryLevel;
    final isCharging = await _battery.isInBatteryOptimization;
    
    final strategy = _determineOptimizationStrategy(batteryLevel, isCharging);
    await _applyOptimizationStrategy(strategy);
  }
  
  BatteryOptimizationStrategy _determineOptimizationStrategy(
    int batteryLevel,
    bool isCharging,
  ) {
    if (isCharging) {
      return BatteryOptimizationStrategy.normal;
    }
    
    if (batteryLevel < 15) {
      return BatteryOptimizationStrategy.emergency;
    } else if (batteryLevel < 30) {
      return BatteryOptimizationStrategy.powerSaving;
    } else if (batteryLevel < 50) {
      return BatteryOptimizationStrategy.balanced;
    } else {
      return BatteryOptimizationStrategy.performance;
    }
  }
  
  Future<void> _applyOptimizationStrategy(BatteryOptimizationStrategy strategy) async {
    switch (strategy) {
      case BatteryOptimizationStrategy.emergency:
        await _enableEmergencyMode();
        break;
      case BatteryOptimizationStrategy.powerSaving:
        await _enablePowerSavingMode();
        break;
      case BatteryOptimizationStrategy.balanced:
        await _enableBalancedMode();
        break;
      case BatteryOptimizationStrategy.performance:
        await _enablePerformanceMode();
        break;
      case BatteryOptimizationStrategy.normal:
        await _enableNormalMode();
        break;
    }
  }
  
  Future<void> _enableEmergencyMode() async {
    _logger.info('Enabling emergency battery mode');
    
    // Disable non-essential background tasks
    await _workmanager.cancelAll();
    
    // Reduce processing frequency
    // Implementation depends on specific use case
    
    // Disable animations and visual effects
    // Implementation depends on UI framework
  }
  
  Future<void> _enablePowerSavingMode() async {
    _logger.info('Enabling power saving mode');
    
    // Limit background processing
    await _workmanager.cancelByTag('non-essential');
    
    // Reduce sync frequency
    // Implementation depends on sync requirements
    
    // Optimize UI rendering
    // Implementation depends on UI framework
  }
}
```

## Architecture Patterns

### 1. Clean Architecture Implementation

```dart
// Domain Layer - Business Logic
abstract class WorkflowRepository {
  Future<void> createWorkflow(Workflow workflow);
  Future<List<Workflow>> getWorkflows();
  Future<void> executeWorkflow(String workflowId);
}

// Data Layer - Implementation
class WorkflowRepositoryImpl implements WorkflowRepository {
  final LocalDataSource _dataSource;
  final SecurityService _securityService;
  
  WorkflowRepositoryImpl(this._dataSource, this._securityService);
  
  @override
  Future<void> createWorkflow(Workflow workflow) async {
    // Validate workflow
    await _securityService.validateWorkflow(workflow);
    
    // Save to local storage
    await _dataSource.saveWorkflow(workflow);
  }
}

// Presentation Layer - UI
class WorkflowPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowState = ref.watch(workflowProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Workflows')),
      body: workflowState.when(
        data: (workflows) => WorkflowList(workflows: workflows),
        loading: () => const CircularProgressIndicator(),
        error: (error) => Text('Error: $error'),
      ),
    );
  }
}
```

### 2. Dependency Injection with Riverpod

```dart
// lib/injection_container.dart
// Database
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Database must be overridden');
});

// Data Sources
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSourceImpl(ref.watch(databaseProvider));
});

// Repositories
final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  return WorkflowRepositoryImpl(
    ref.watch(localDataSourceProvider),
    ref.watch(securityServiceProvider),
  );
});

// Services
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(
    secureStorage: ref.watch(secureStorageProvider),
    localAuth: ref.watch(localAuthProvider),
    logger: ref.watch(loggerProvider),
  );
});

// Providers for app initialization
@override
ProviderContainer createContainer() {
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(DatabaseService.database),
    ],
  );
}
```

### 3. Error Handling Pattern

```dart
// lib/core/exceptions/app_exception.dart
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;
  
  const AppException(this.message, [this.originalError]);
  
  @override
  String toString() => 'AppException: $message';
}

class McpException extends AppException {
  const McpException(super.message, [super.originalError]);
}

class SecurityException extends AppException {
  const SecurityException(super.message, [super.originalError]);
}

// lib/core/utils/result.dart
@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = _Success;
  const factory Result.failure(AppException error) = _Failure;
}

// Usage example
class WorkflowService {
  Future<Result<Workflow>> createWorkflow(WorkflowData data) async {
    try {
      final workflow = await _repository.createWorkflow(data);
      return Result.success(workflow);
    } on SecurityException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException('Failed to create workflow', e));
    }
  }
}
```

## Testing Guidelines

### 1. Unit Testing

```dart
// test/unit/workflow_repository_test.dart
void main() {
  group('WorkflowRepository', () {
    late WorkflowRepository repository;
    late MockLocalDataSource mockDataSource;
    late MockSecurityService mockSecurityService;
    
    setUp(() {
      mockDataSource = MockLocalDataSource();
      mockSecurityService = MockSecurityService();
      repository = WorkflowRepositoryImpl(mockDataSource, mockSecurityService);
    });
    
    test('should create workflow successfully', () async {
      // Arrange
      final workflow = Workflow.test();
      when(mockSecurityService.validateWorkflow(any()))
          .thenAnswer((_) async {});
      when(mockDataSource.saveWorkflow(any()))
          .thenAnswer((_) async {});
      
      // Act
      await repository.createWorkflow(workflow);
      
      // Assert
      verify(mockSecurityService.validateWorkflow(workflow)).called(1);
      verify(mockDataSource.saveWorkflow(workflow)).called(1);
    });
    
    test('should throw SecurityException when validation fails', () async {
      // Arrange
      final workflow = Workflow.test();
      when(mockSecurityService.validateWorkflow(any()))
          .thenThrow(SecurityException('Validation failed'));
      
      // Act & Assert
      expect(
        () => repository.createWorkflow(workflow),
        throwsA(isA<SecurityException>()),
      );
    });
  });
}
```

### 2. Widget Testing

```dart
// test/widget/workflow_page_test.dart
void main() {
  testWidgets('WorkflowPage displays workflow list', (tester) async {
    // Arrange
    final workflows = [Workflow.test(), Workflow.test()];
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workflowProvider.overrideWith(
            (ref) => MockWorkflowNotifier(workflows),
          ),
        ],
        child: MaterialApp(home: WorkflowPage()),
      ),
    );
    
    // Act
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(WorkflowCard), findsNWidgets(2));
  });
}
```

### 3. Integration Testing

```dart
// integration_test/app_test.dart
void main() {
  group('Micro App Integration Tests', () {
    testWidgets('complete workflow execution', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();
      
      // Act
      // Navigate to workflow creation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Create workflow
      await tester.enterText(find.byType(TextField), 'Test Workflow');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      
      // Execute workflow
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Workflow executed successfully'), findsOneWidget);
    });
  });
}
```

## Troubleshooting Guide

### Common Issues

#### 1. Build Issues

**Problem**: Flutter build fails with dependency conflicts
```
Error: The method '...' isn't defined for the class '...'
```

**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs

# Check for version conflicts
flutter pub deps
```

#### 2. Database Issues

**Problem**: Database fails to open with encryption error
```
Error: file is encrypted or is not a database
```

**Solution**:
```dart
// Ensure encryption key is properly stored
final keyStorage = FlutterSecureStorage();
String? key = await keyStorage.read(key: 'db_encryption_key');

if (key == null) {
  // Generate new key only if none exists
  key = generateSecureRandomKey();
  await keyStorage.write(key: 'db_encryption_key', value: key);
}
```

#### 3. Security Issues

**Problem**: Biometric authentication fails
```
Error: Biometric authentication is not available
```

**Solution**:
```dart
// Check biometric availability before authentication
final localAuth = LocalAuthentication();
final isAvailable = await localAuth.canCheckBiometrics;

if (!isAvailable) {
  // Fallback to PIN/password authentication
  await _authenticateWithPIN();
} else {
  await _authenticateWithBiometrics();
}
```

#### 4. Performance Issues

**Problem**: App uses too much battery
```
Battery drain > 10% over 24 hours
```

**Solution**:
```dart
// Implement battery optimization
class BatteryOptimizedService {
  Future<void> performTask() async {
    final batteryLevel = await Battery().batteryLevel;
    
    if (batteryLevel < 20) {
      // Defer non-essential tasks
      await _scheduleTaskForLater();
      return;
    }
    
    // Perform task normally
    await _executeTask();
  }
}
```

### Performance Optimization

#### 1. Memory Management

```dart
// Use dispose patterns for controllers
class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Use const constructors where possible
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Text('Hello'); // Use const for static widgets
  }
}
```

#### 2. Image Optimization

```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)

// Optimize image sizes
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
  cacheWidth: 200, // Cache optimized size
  cacheHeight: 200,
)
```

#### 3. List Performance

```dart
// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].title),
    );
  },
)

// Use AutomaticKeepAliveClientMixin for complex items
class MyListItem extends StatefulWidget {
  @override
  _MyListItemState createState() => _MyListItemState();
}

class _MyListItemState extends State<MyListItem> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListTile(title: Text('Complex Item'));
  }
}
```

## Best Practices

### 1. Code Organization

- Follow clean architecture principles
- Use feature-based folder structure
- Keep files small and focused
- Use consistent naming conventions

### 2. Security

- Never hardcode sensitive information
- Use secure storage for keys and tokens
- Validate all inputs
- Implement proper error handling

### 3. Performance

- Use const constructors where possible
- Implement proper disposal of resources
- Optimize images and assets
- Use efficient data structures

### 4. Testing

- Write tests for all business logic
- Test edge cases and error conditions
- Use mock objects for dependencies
- Maintain high test coverage

### 5. Documentation

- Document public APIs
- Use meaningful commit messages
- Keep README files up to date
- Document architectural decisions

## Glossary of Terms

### Technical Terms

- **MCP (Model Context Protocol)**: Protocol for tool discovery and execution
- **DAG (Directed Acyclic Graph)**: Workflow structure used in Micro
- **SQLCipher**: SQLite extension providing transparent 256-bit AES encryption
- **Riverpod**: State management solution used in Micro
- **WorkManager**: Android library for deferrable, guaranteed background work

### Mobile Optimization Terms

- **Adaptive Processing**: Dynamic performance adjustment based on device state
- **Graceful Degradation**: Systematic feature reduction under resource constraints
- **Thermal Throttling**: Performance reduction to manage device temperature
- **Battery-Aware Scheduling**: Task scheduling based on battery level and charging state

### Security Terms

- **Prompt Injection**: Attack technique to manipulate AI behavior through input
- **Data Exfiltration**: Unauthorized transfer of data from a system
- **Zero-Trust Security**: Security model assuming no implicit trust
- **End-to-End Encryption**: Encryption of data at all points between sender and receiver

## Contributing Guidelines

### Code Style

- Follow Dart official style guide
- Use dart format for code formatting
- Use flutter analyze for static analysis
- Write meaningful variable and function names

### Pull Request Process

1. Create feature branch from main
2. Implement changes with tests
3. Ensure all tests pass
4. Update documentation
5. Create pull request with clear description
6. Address review feedback
7. Merge to main after approval

### Release Process

1. Update version number in pubspec.yaml
2. Update CHANGELOG.md
3. Create release tag
4. Build release APK/AAB
5. Deploy to app store
6. Update documentation

## Support and Resources

### Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [SQLCipher Documentation](https://www.zetetic.net/sqlcipher/)
- [Material Design 3](https://m3.material.io/)

### Community

- [Flutter Community](https://github.com/flutter/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit r/FlutterDev](https://www.reddit.com/r/FlutterDev/)

### Tools

- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
- [Android Studio](https://developer.android.com/studio)
- [VS Code](https://code.visualstudio.com/)

---

This development guide provides comprehensive resources for building Micro. Follow the patterns and best practices outlined here to ensure a high-quality, maintainable codebase that meets the project's security, performance, and user experience requirements.
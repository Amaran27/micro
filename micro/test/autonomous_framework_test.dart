import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../domain/models/autonomous/context_analysis.dart';
import '../../domain/models/autonomous/user_intent.dart';
import '../../domain/models/autonomous/autonomous_action.dart';
import '../../domain/interfaces/autonomous/i_autonomous_decision_framework.dart';
import '../../infrastructure/ai/ai_provider_config.dart';

/// Test suite for the autonomous decision framework
void main() {
  group('Autonomous Decision Framework', () {
    late StoreCompliantPermissionsManager mockPermissionsManager;
    late AppLogger mockLogger;
    late StoreCompliantContextAnalyzer mockContextAnalyzer;
    late StoreCompliantIntentRecognizer mockIntentRecognizer;
    late StoreCompliantDecisionEngine mockDecisionEngine;

    setUp(() {
      // Create mocks
      mockPermissionsManager = MockStoreCompliantPermissionsManager();
      mockLogger = MockAppLogger();
      mockContextAnalyzer = StoreCompliantContextAnalyzer(
        permissionsManager: mockPermissionsManager,
        logger: mockLogger,
      );
      mockIntentRecognizer = StoreCompliantIntentRecognizer(
        permissionsManager: mockPermissionsManager,
        logger: mockLogger,
      );
      mockDecisionEngine = StoreCompliantDecisionEngine(
        permissionsManager: mockPermissionsManager,
        logger: mockLogger,
      );

      // Initialize all components
      mockContextAnalyzer.initialize();
      mockIntentRecognizer.initialize();
      mockDecisionEngine.initialize();
    });

    test('should initialize all components', () async {
      // Verify initialization
      verify(mockPermissionsManager.initialize()).called(1);
      verify(mockLogger.info(anyNamed: 'initializing')).called(1);
      verify(mockContextAnalyzer.initialize()).called(1);
      verify(mockIntentRecognizer.initialize()).called(1);
      verify(mockDecisionEngine.initialize()).called(1);
    });

    test('should analyze context with user consent', () async {
      // Arrange
      const contextData = {
        'location': 'New York',
        'timestamp': '2023-10-25T10:30:00Z',
        'deviceType': 'mobile',
      };

      when(mockPermissionsManager.isPermissionGranted(any)).thenReturn(true);

      // Act
      final result = await mockContextAnalyzer.analyzeContext(
        contextData: contextData,
        userId: 'test-user',
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.contextData, isNot(equals(contextData)));
      expect(result.confidenceScore, greaterThan(0.5));
      expect(result.isCompliant, true);
      expect(result.requiredPermissions, contains(PermissionType.location));
      expect(result.grantedPermissions, contains(PermissionType.location));
      expect(result.deniedPermissions, isEmpty);
    });

    test('should recognize user intent with bias testing', () async {
      // Arrange
      const input = 'Send a message to my friend';
      const context = ContextAnalysis.success(
        id: 'test-context',
        contextData: {'timestamp': DateTime.now().toIso8601String()},
        requiredPermissions: [
          PermissionType.networkAccess,
          PermissionType.notifications
        ],
        grantedPermissions: [
          PermissionType.networkAccess,
          PermissionType.notifications
        ],
        deniedPermissions: [],
        confidenceScore: 0.8,
        anonymizedData: {'timestamp': DateTime.now().toIso8601String()},
      );

      when(mockPermissionsManager.isPermissionGranted(any)).thenReturn(true);

      // Act
      final result = await mockIntentRecognizer.recognizeIntent(
        input: input,
        contextAnalysis: context,
        userId: 'test-user',
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.intent.intentType, IntentType.communication);
      expect(result.intent.specificIntent, 'send_message');
      expect(result.intent.parameters, contains('message'));
      expect(result.intent.confidenceScore, greaterThan(0.7));
      expect(result.intent.requiredPermissions,
          contains(PermissionType.notifications));
      expect(result.biasScores, isNotEmpty);
      expect(result.passesBiasTest, true);
    });

    test('should generate autonomous action with risk assessment', () async {
      // Arrange
      final intent = UserIntent.success(
        id: 'test-intent',
        originalInput: 'Send a message',
        intentType: IntentType.communication,
        specificIntent: 'send_message',
        parameters: {'message': 'Hello world'},
        confidenceScore: 0.8,
        requiredPermissions: [PermissionType.notifications],
        userId: 'test-user',
      );

      final context = ContextAnalysis.success(
        id: 'test-context',
        contextData: {'timestamp': DateTime.now().toIso8601String()},
        requiredPermissions: [PermissionType.notifications],
        grantedPermissions: [PermissionType.notifications],
        deniedPermissions: [],
        confidenceScore: 0.8,
        anonymizedData: {'timestamp': DateTime.now().toIso8601String()},
      );

      when(mockPermissionsManager.isPermissionGranted(any)).thenReturn(true);

      // Act
      final result = await mockDecisionEngine.generateAction(
        intent: intent,
        context: context,
        userId: 'test-user',
      );

      // Assert
      expect(result.actionType, ActionType.communicate);
      expect(result.description, contains('Send a message'));
      expect(result.parameters, contains('message'));
      expect(
          result.requiredPermissions, contains(PermissionType.notifications));
      expect(result.riskLevel, ActionRiskLevel.medium);
      expect(result.isCompliant, true);
      expect(result.requiresUserApproval, false);
    });

    test('should execute autonomous action with resource monitoring', () async {
      // Arrange
      final intent = UserIntent.success(
        id: 'test-intent',
        originalInput: 'Send a message',
        intentType: IntentType.communication,
        specificIntent: 'send_message',
        parameters: {'message': 'Hello world'},
        confidenceScore: 0.8,
        requiredPermissions: [PermissionType.notifications],
        userId: 'test-user',
      );

      final context = ContextAnalysis.success(
        id: 'test-context',
        contextData: {'timestamp': DateTime.now().toIso8601String()},
        requiredPermissions: [PermissionType.notifications],
        grantedPermissions: [PermissionType.notifications],
        deniedPermissions: [],
        confidenceScore: 0.8,
        anonymizedData: {'timestamp': DateTime.now().toIso8601String()},
      );

      final action = await mockDecisionEngine.generateAction(
        intent: intent,
        context: context,
        userId: 'test-user',
      );

      when(mockPermissionsManager.isPermissionGranted(any)).thenReturn(true);

      // Act
      final result = await mockDecisionEngine.executeAction(action: action);

      // Assert
      expect(result.isSuccess, true);
      expect(result.action.status, ActionStatus.completed);
      expect(result.action.result, 'Action executed successfully');
      expect(result.resourceUsage, isNotEmpty);
      expect(result.withinResourceLimits, true);
    });

    test('should request user approval for high-risk actions', () async {
      // Arrange
      final intent = UserIntent.success(
        id: 'test-intent',
        originalInput: 'Delete all data',
        intentType: IntentType.action,
        specificIntent: 'delete_data',
        parameters: {},
        confidenceScore: 0.8,
        requiredPermissions: [PermissionType.storage],
        userId: 'test-user',
      );

      final context = ContextAnalysis.success(
        id: 'test-context',
        contextData: {'timestamp': DateTime.now().toIso8601String()},
        requiredPermissions: [PermissionType.storage],
        grantedPermissions: [PermissionType.storage],
        deniedPermissions: [],
        confidenceScore: 0.8,
        anonymizedData: {'timestamp': DateTime.now().toIso8601String()},
      );

      final action = await mockDecisionEngine.generateAction(
        intent: intent,
        context: context,
        userId: 'test-user',
      );

      when(mockPermissionsManager.isPermissionGranted(any)).thenReturn(true);

      // Act
      final requiresApproval =
          mockDecisionEngine.requiresUserApproval(action: action);
      expect(requiresApproval, true);

      final approved =
          await mockDecisionEngine.requestUserApproval(action: action);
      expect(approved, true);

      final approvedAction = action.approve();
      expect(approvedAction.userApproved, true);
    });

    test('should block actions with prohibited permissions', () async {
      // Arrange
      final intent = UserIntent.success(
        id: 'test-intent',
        originalInput: 'Access contacts',
        intentType: IntentType.communication,
        specificIntent: 'access_contacts',
        parameters: {},
        confidenceScore: 0.8,
        requiredPermissions: [PermissionType.contacts],
        userId: 'test-user',
      );

      final context = ContextAnalysis.success(
        id: 'test-context',
        contextData: {'timestamp': DateTime.now().toIso8601String()},
        requiredPermissions: [PermissionType.contacts],
        grantedPermissions: [PermissionType.contacts],
        deniedPermissions: [],
        confidenceScore: 0.8,
        anonymizedData: {'timestamp': DateTime.now().toIso8601String()},
      );

      when(mockPermissionsManager.isPermissionGranted(PermissionType.contacts))
          .thenReturn(false); // Contacts not granted

      // Act
      final result = await mockDecisionEngine.generateAction(
        intent: intent,
        context: context,
        userId: 'test-user',
      );

      // Assert
      expect(result.actionType, ActionType.unknown);
      expect(result.isCompliant, false);
      expect(result.requiresUserApproval, true);
      expect(result.status, ActionStatus.blocked);
      expect(
          result.complianceIssues, contains('Prohibited permissions required'));
    });

    test('should enforce daily action limits', () async {
      // Arrange
      final intent = UserIntent.success(
        id: 'test-intent',
        originalInput: 'Send a message',
        intentType: IntentType.communication,
        specificIntent: 'send_message',
        parameters: {'message': 'Hello world'},
        confidenceScore: 0.8,
        requiredPermissions: [PermissionType.notifications],
        userId: 'test-user',
      );

      final context = ContextAnalysis.success(
        id: 'test-context',
        contextData: {'timestamp': DateTime.now().toIso8601String()},
        requiredPermissions: [PermissionType.notifications],
        grantedPermissions: [PermissionType.notifications],
        deniedPermissions: [],
        confidenceScore: 0.8,
        anonymizedData: {'timestamp': DateTime.now().toIso8601String()},
      );

      // Simulate reaching daily limit
      for (int i = 0; i < 20; i++) {
        await mockDecisionEngine.generateAction(
          intent: intent,
          context: context,
          userId: 'test-user',
        );
      }

      // Act
      final result = await mockDecisionEngine.generateAction(
        intent: intent,
        context: context,
        userId: 'test-user',
      );

      // Assert
      expect(result.actionType, ActionType.unknown);
      expect(result.isCompliant, false);
      expect(result.status, ActionStatus.blocked);
      expect(result.complianceIssues, contains('Daily action limit exceeded'));
    });

    test('should generate compliance report', () async {
      // Arrange
      when(mockContextAnalyzer.getStatistics()).thenReturn({
        'totalAnalyses': 10,
        'compliantAnalyses': 8,
        'complianceRate': 0.8,
      });

      when(mockIntentRecognizer.getStatistics()).thenReturn({
        'totalRecognitions': 15,
        'compliantRecognitions': 12,
        'complianceRate': 0.8,
      });

      when(mockDecisionEngine.getStatistics()).thenReturn({
        'totalActions': 20,
        'successfulActions': 15,
        'failedActions': 3,
        'blockedActions': 2,
        'successRate': 0.75,
      });

      when(mockPermissionsManager.generateComplianceReport()).thenReturn({
        'totalPermissions': 5,
        'grantedPermissions': 4,
        'deniedPermissions': 1,
        'complianceRate': 0.8,
      });

      // Act
      final provider = AutonomousProvider(
        contextAnalyzer: mockContextAnalyzer,
        intentRecognizer: mockIntentRecognizer,
        decisionEngine: mockDecisionEngine,
        permissionsManager: mockPermissionsManager,
      );

      await provider.initialize();

      final report = await provider.getComplianceReport();

      // Assert
      expect(report, isNotEmpty);
      expect(report['contextAnalysis'], isNotEmpty);
      expect(report['intentRecognition'], isNotEmpty);
      expect(report['actionExecution'], isNotEmpty);
      expect(report['permissions'], isNotEmpty);
      expect(report['generatedAt'], isNotEmpty);
    });

    test('should export audit data', () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Create mock audit logs
      final mockLogs = [
        {
          'id': 'log-1',
          'timestamp': now.toIso8601String(),
          'component': 'context',
          'type': 'analysis',
          'status': 'completed',
        },
        {
          'id': 'log-2',
          'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
          'component': 'intent',
          'type': 'recognition',
          'status': 'completed',
        },
        {
          'id': 'log-3',
          'timestamp': yesterday.toIso8601String(),
          'component': 'action',
          'type': 'execution',
          'status': 'failed',
          'errorMessage': 'Simulated failure',
        },
      ];

      when(mockContextAnalyzer.getAuditLog(startDate: yesterday)).thenReturn(
          mockLogs.where((log) => log['component'] == 'context').toList());

      when(mockIntentRecognizer.getAuditLog(startDate: yesterday)).thenReturn(
          mockLogs.where((log) => log['component'] == 'intent').toList());

      when(mockDecisionEngine.getAuditLog(startDate: yesterday)).thenReturn(
          mockLogs.where((log) => log['component'] == 'action').toList());

      // Act
      final provider = AutonomousProvider(
        contextAnalyzer: mockContextAnalyzer,
        intentRecognizer: mockIntentRecognizer,
        decisionEngine: mockDecisionEngine,
        permissionsManager: mockPermissionsManager,
      );

      await provider.initialize();

      // Test JSON export
      final jsonExport = await provider.exportAuditData(
        format: 'json',
        startDate: yesterday,
      );

      expect(jsonExport, contains('"exportedAt"'));
      expect(jsonExport, contains('"totalRecords": 3'));
      expect(jsonExport, contains('"records"'));

      // Test CSV export
      final csvExport = await provider.exportAuditData(
        format: 'csv',
        startDate: yesterday,
      );

      expect(
          csvExport,
          contains(
              'timestamp,component,type,id,userId,status,riskLevel,result,errorMessage'));
      expect(csvExport, contains('log-1,context,analysis,completed'));
      expect(csvExport,
          contains('log-3,action,execution,failed,Simulated failure'));
    });

    group('Store Compliance', () {
      test('should enforce data minimization', () {
        // Test that context analyzer applies data minimization
        const sensitiveData = {
          'exactLocation': '40.7128° N, 74.0060° W',
          'phoneNumber': '+1-555-123-4567',
          'emailAddress': 'user@example.com',
          'deviceId': 'unique-device-id-12345',
        };

        const minimizedData = {
          'generalLocation': 'New York',
          'timestamp': '2023-10-25T10:30:00Z',
        };

        // Verify data minimization was applied
        final result = mockContextAnalyzer.applyDataMinimization(
          rawData: sensitiveData,
        );

        expect(result, isNot(equals(sensitiveData)));
        expect(result, equals(minimizedData));
      });

      test('should enforce user consent requirements', () async {
        // Test that context analyzer requires user consent for sensitive data
        const sensitiveData = {
          'contacts': ['John Doe', 'Jane Smith'],
          'calendarEvents': ['Meeting with CEO', 'Doctor appointment'],
        };

        when(mockContextAnalyzer.requiresUserConsent(
                contextData: sensitiveData))
            .thenReturn(true);

        // Act
        final result = await mockContextAnalyzer.analyzeContext(
          contextData: sensitiveData,
        );

        // Assert
        expect(result.isCompliant, false);
        expect(result.complianceIssues,
            contains('User consent required for context collection'));
      });

      test('should anonymize sensitive data', () {
        // Test that context analyzer anonymizes sensitive data
        const sensitiveData = {
          'userId': 'user-12345',
          'ipAddress': '192.168.1.100',
          'macAddress': '00:1A:2B:3C:4D:5E',
        };

        // Act
        final result = mockContextAnalyzer.anonymizeData(data: sensitiveData);

        // Assert
        expect(result['userId'], isNot(equals('user-12345')));
        expect(result['ipAddress'], isNot(equals('192.168.1.100')));
        expect(result['macAddress'], isNot(equals('00:1A:2B:3C:4D:5E')));
      });
    });

    group('Error Handling', () {
      test('should handle context analysis errors', () async {
        // Arrange
        when(mockContextAnalyzer.analyzeContext(any))
            .thenThrow(Exception('Context analysis failed'));

        // Act
        final result = await mockContextAnalyzer.analyzeContext();

        // Assert
        expect(result.isCompliant, false);
        expect(result.complianceIssues, contains('Context analysis failed'));
      });

      test('should handle intent recognition errors', () async {
        // Arrange
        when(mockIntentRecognizer.recognizeIntent(any))
            .thenThrow(Exception('Intent recognition failed'));

        // Act
        final result =
            await mockIntentRecognizer.recognizeIntent(input: 'test');

        // Assert
        expect(result.isSuccess, false);
        expect(result.biasWarnings, contains('Intent recognition failed'));
      });

      test('should handle action generation errors', () async {
        // Arrange
        when(mockDecisionEngine.generateAction(any))
            .thenThrow(Exception('Action generation failed'));

        // Act
        final result = await mockDecisionEngine.generateAction(
          intent: UserIntent.success(
            id: 'test-intent',
            originalInput: 'test',
            intentType: IntentType.query,
            specificIntent: 'test_query',
            parameters: {},
            confidenceScore: 0.8,
            requiredPermissions: [],
            userId: 'test-user',
          ),
          context: ContextAnalysis.success(
            id: 'test-context',
            contextData: {},
            requiredPermissions: [],
            grantedPermissions: [],
            deniedPermissions: [],
            confidenceScore: 0.8,
            anonymizedData: {},
          ),
          userId: 'test-user',
        );

        // Assert
        expect(result.actionType, ActionType.unknown);
        expect(result.isCompliant, false);
        expect(result.status, ActionStatus.blocked);
        expect(result.complianceIssues, contains('Action generation failed'));
      });

      test('should handle action execution errors', () async {
        // Arrange
        final action = AutonomousAction.create(
          id: 'test-action',
          actionType: ActionType.execute,
          description: 'Test action',
          parameters: {},
          requiredPermissions: [],
          riskLevel: ActionRiskLevel.low,
          userId: 'test-user',
        );

        when(mockDecisionEngine.executeAction(action: action))
            .thenThrow(Exception('Action execution failed'));

        // Act
        final result = await mockDecisionEngine.executeAction(action: action);

        // Assert
        expect(result.isSuccess, false);
        expect(result.action.status, ActionStatus.failed);
        expect(result.warnings, contains('Action execution failed'));
      });
    });
  });
}

/// Mock implementation of StoreCompliantPermissionsManager for testing
class MockStoreCompliantPermissionsManager extends Mock
    implements StoreCompliantPermissionsManager {
  @override
  Future<void> initialize() async {
    // Mock implementation
  }

  @override
  bool isPermissionGranted(PermissionType permission) {
    // Mock implementation - return true for all permissions except contacts
    return permission != PermissionType.contacts;
  }

  @override
  Future<PermissionRequestResult> requestPermission(
    PermissionType permission, {
    String? justification,
    Map<String, dynamic>? context,
  }) {
    // Mock implementation
    return PermissionRequestResult.granted(permission);
  }

  @override
  Future<Map<String, dynamic>> generateComplianceReport() async {
    // Mock implementation
    return {
      'totalPermissions': 5,
      'grantedPermissions': 4,
      'deniedPermissions': 1,
      'complianceRate': 0.8,
    };
  }
}

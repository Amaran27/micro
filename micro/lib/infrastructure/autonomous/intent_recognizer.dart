import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/autonomous/user_intent.dart';
import '../../domain/models/autonomous/context_analysis.dart';
import '../../domain/interfaces/autonomous/i_autonomous_decision_framework.dart';
import '../permissions/models/permission_type.dart';
import '../permissions/services/store_compliant_permissions_manager.dart';
import '../ai/ai_provider_config.dart';
import '../../core/utils/logger.dart';
import '../../core/exceptions/app_exception.dart';

/// Store-compliant intent recognizer for autonomous decision making
/// Implements intent recognition with bias testing, user opt-out mechanisms,
/// and policy validation for store compliance
class StoreCompliantIntentRecognizer implements IIntentRecognizer {
  final StoreCompliantPermissionsManager _permissionsManager;
  final AppLogger _logger;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // AI Provider integration
  final AIProviderConfig _aiProviderConfig;
  dynamic _chatModel;
  bool _aiIntentDetectionEnabled = false;

  // Cache for intent recognition results
  final Map<String, IntentRecognitionResult> _intentCache = {};

  // Audit log for intent recognition
  final List<Map<String, dynamic>> _auditLog = [];

  // Configuration
  bool _biasTestingEnabled = true;
  bool _auditLoggingEnabled = true;
  double _confidenceThreshold = 0.7;
  Duration _cacheExpiration = const Duration(minutes: 10);

  // Intent patterns for recognition
  final Map<IntentType, List<String>> _intentPatterns = {
    IntentType.action: [
      'execute',
      'run',
      'start',
      'perform',
      'do',
      'launch',
      'activate',
      'begin',
      'initiate',
      'trigger',
      'invoke',
      'call',
      'send',
    ],
    IntentType.query: [
      'what',
      'how',
      'when',
      'where',
      'why',
      'who',
      'which',
      'tell me',
      'show me',
      'find',
      'search',
      'look up',
      'get',
      'retrieve',
      'check',
    ],
    IntentType.configuration: [
      'configure',
      'set',
      'adjust',
      'change',
      'modify',
      'update',
      'settings',
      'preferences',
      'options',
      'customize',
      'setup',
      'enable',
      'disable',
    ],
    IntentType.feedback: [
      'feedback',
      'review',
      'rate',
      'opinion',
      'thought',
      'comment',
      'suggest',
      'recommend',
      'improve',
      'issue',
      'problem',
      'bug',
      'error',
    ],
    IntentType.navigation: [
      'go to',
      'navigate',
      'open',
      'show',
      'display',
      'view',
      'access',
      'enter',
      'move to',
      'switch to',
      'jump to',
      'browse',
    ],
    IntentType.communication: [
      'message',
      'email',
      'call',
      'contact',
      'notify',
      'alert',
      'remind',
      'share',
      'send',
      'tell',
      'inform',
      'update',
      'communicate',
    ],
    IntentType.analysis: [
      'analyze',
      'examine',
      'inspect',
      'review',
      'evaluate',
      'assess',
      'measure',
      'calculate',
      'compute',
      'process',
      'understand',
    ],
    IntentType.creation: [
      'create',
      'make',
      'build',
      'generate',
      'compose',
      'write',
      'draw',
      'design',
      'produce',
      'develop',
      'construct',
      'form',
    ],
    IntentType.monitoring: [
      'monitor',
      'watch',
      'track',
      'observe',
      'check',
      'verify',
      'validate',
      'supervise',
      'oversee',
      'keep an eye on',
      'follow',
      'log',
    ],
  };

  StoreCompliantIntentRecognizer({
    required StoreCompliantPermissionsManager permissionsManager,
    required AIProviderConfig aiProviderConfig,
    AppLogger? logger,
  })  : _permissionsManager = permissionsManager,
        _aiProviderConfig = aiProviderConfig,
        _logger = logger ?? AppLogger();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Store-Compliant Intent Recognizer');

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize AI provider
      await _aiProviderConfig.initialize();
      _chatModel = _aiProviderConfig.getBestAvailableChatModel();
      _aiIntentDetectionEnabled = _chatModel != null;

      if (_aiIntentDetectionEnabled) {
        _logger.info('AI-powered intent detection enabled');
      } else {
        _logger.info(
            'AI-powered intent detection disabled - using rule-based fallback');
      }

      // Load configuration
      _loadConfiguration();

      // Load audit log
      await _loadAuditLog();

      _isInitialized = true;
      _logger
          .info('Store-Compliant Intent Recognizer initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Intent Recognizer', error: e);
      throw const SecurityException('Failed to initialize Intent Recognizer');
    }
  }

  @override
  Future<IntentRecognitionResult> recognizeIntent({
    required String input,
    ContextAnalysis? contextAnalysis,
    String? userId,
  }) async {
    if (!_isInitialized) {
      throw const SecurityException('Intent Recognizer not initialized');
    }

    _logger.info('Recognizing intent for input: "$input"');

    try {
      // Check if user has opted out
      if (await hasUserOptedOut(userId)) {
        _logger.warning('User has opted out of intent recognition: $userId');
        return IntentRecognitionResult.failure(
          intent: UserIntent.failure(
            id: _generateIntentId(input, userId),
            originalInput: input,
            confidenceScore: 0.0,
            complianceIssues: ['User has opted out of intent recognition'],
            userId: userId,
          ),
          biasWarnings: ['User opt-out detected'],
        );
      }

      // Check cache first
      final cacheKey = _generateCacheKey(input, userId);
      if (_intentCache.containsKey(cacheKey)) {
        final cachedResult = _intentCache[cacheKey]!;
        if (_isCacheValid(cachedResult)) {
          _logger.debug('Using cached intent recognition: $cacheKey');
          return cachedResult;
        } else {
          _intentCache.remove(cacheKey);
        }
      }

      // Preprocess input
      final processedInput = _preprocessInput(input);

      // Recognize intent using AI if available, otherwise use rule-based approach
      IntentRecognitionResult result;
      if (_aiIntentDetectionEnabled) {
        result = await _recognizeIntentWithAI(
          processedInput: processedInput,
          contextAnalysis: contextAnalysis ??
              ContextAnalysis.failure(
                id: 'empty',
                contextData: {},
                requiredPermissions: [],
                grantedPermissions: [],
                deniedPermissions: [],
                confidenceScore: 0.0,
                complianceIssues: ['No context analysis provided'],
              ),
          userId: userId ?? 'anonymous',
        );
      } else {
        result = _recognizeIntentWithRules(
          processedInput: processedInput,
          contextAnalysis: contextAnalysis ??
              ContextAnalysis.failure(
                id: 'empty',
                contextData: {},
                requiredPermissions: [],
                grantedPermissions: [],
                deniedPermissions: [],
                confidenceScore: 0.0,
                complianceIssues: ['No context analysis provided'],
              ),
          userId: userId ?? 'anonymous',
        );
      }

      // Cache result
      _intentCache[cacheKey] = result;

      // Log for audit
      if (_auditLoggingEnabled) {
        await logIntentRecognition(result: result);
      }

      _logger.info(
          'Intent recognition completed: ${result.intent.intentType}, confidence: ${result.intent.confidenceScore}, compliant: ${result.intent.isCompliant}');
      return result;
    } catch (e) {
      _logger.error('Intent recognition failed', error: e);
      throw const SecurityException('Intent recognition failed');
    }
  }

  @override
  Future<bool> hasUserOptedOut(String? userId) async {
    if (userId == null) return false;
    return _prefs.getBool('intent_recognition_opt_out_$userId') ?? false;
  }

  @override
  Map<String, double> testForBias({
    required String input,
    required UserIntent intent,
  }) {
    final biasScores = <String, double>{};

    // Test for gender bias
    biasScores['gender'] = _testGenderBias(input);

    // Test for racial bias
    biasScores['racial'] = _testRacialBias(input);

    // Test for age bias
    biasScores['age'] = _testAgeBias(input);

    // Test for cultural bias
    biasScores['cultural'] = _testCulturalBias(input);

    // Test for accessibility bias
    biasScores['accessibility'] = _testAccessibilityBias(input);

    return biasScores;
  }

  @override
  double getConfidenceScore({
    required String input,
    required UserIntent intent,
  }) {
    return _calculateIntentConfidence(
      input: input,
      intentType: intent.intentType,
      specificIntent: intent.specificIntent,
      parameters: intent.parameters,
    );
  }

  @override
  IntentPolicyValidation validateIntentPolicy({
    required UserIntent intent,
  }) {
    final violations = <String>[];
    final warnings = <String>[];
    final requirements = <String, dynamic>{};

    // Check if intent requires prohibited permissions
    final prohibitedPermissions = intent.requiredPermissions
        .where((p) => p.isProhibitedForAutonomous)
        .toList();

    if (prohibitedPermissions.isNotEmpty) {
      violations.add(
        'Intent requires prohibited permissions: ${prohibitedPermissions.map((p) => p.displayName).join(', ')}',
      );
    }

    // Check if intent requires special justification
    final restrictedPermissions = intent.requiredPermissions
        .where((p) => p.requiresSpecialJustification)
        .toList();

    if (restrictedPermissions.isNotEmpty) {
      requirements['specialJustification'] = true;
      warnings.add(
        'Intent requires special justification: ${restrictedPermissions.map((p) => p.displayName).join(', ')}',
      );
    }

    // Check confidence score
    if (intent.confidenceScore < _confidenceThreshold) {
      violations.add(
        'Intent confidence score below threshold: ${intent.confidenceScore} < $_confidenceThreshold',
      );
    }

    // Check for high-risk actions
    if (_isHighRiskIntent(intent)) {
      requirements['userApproval'] = true;
      warnings.add('Intent may require user approval due to high risk');
    }

    return IntentPolicyValidation(
      isValid: violations.isEmpty,
      violations: violations,
      warnings: warnings,
      policyRequirements: requirements,
    );
  }

  @override
  List<PermissionType> getRequiredPermissions({
    required UserIntent intent,
  }) {
    final requiredPermissions = <PermissionType>[];

    // Base permissions for all intents
    requiredPermissions.addAll([
      PermissionType.networkAccess,
      PermissionType.deviceInfo,
    ]);

    // Intent-specific permissions
    switch (intent.intentType) {
      case IntentType.action:
        _addActionPermissions(intent, requiredPermissions);
        break;
      case IntentType.query:
        _addQueryPermissions(intent, requiredPermissions);
        break;
      case IntentType.configuration:
        _addConfigurationPermissions(intent, requiredPermissions);
        break;
      case IntentType.feedback:
        _addFeedbackPermissions(intent, requiredPermissions);
        break;
      case IntentType.navigation:
        _addNavigationPermissions(intent, requiredPermissions);
        break;
      case IntentType.communication:
        _addCommunicationPermissions(intent, requiredPermissions);
        break;
      case IntentType.analysis:
        _addAnalysisPermissions(intent, requiredPermissions);
        break;
      case IntentType.creation:
        _addCreationPermissions(intent, requiredPermissions);
        break;
      case IntentType.monitoring:
        _addMonitoringPermissions(intent, requiredPermissions);
        break;
      case IntentType.unknown:
        // No additional permissions for unknown intents
        break;
    }

    return requiredPermissions;
  }

  @override
  Future<void> logIntentRecognition({
    required IntentRecognitionResult result,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_auditLoggingEnabled) return;

    final auditRecord = {
      'id': result.intent.id,
      'timestamp': result.intent.timestamp.toIso8601String(),
      'userId': result.intent.userId,
      'originalInput': result.intent.originalInput,
      'intentType': result.intent.intentType.name,
      'specificIntent': result.intent.specificIntent,
      'confidenceScore': result.intent.confidenceScore,
      'isCompliant': result.intent.isCompliant,
      'requiredPermissions':
          result.intent.requiredPermissions.map((p) => p.name).toList(),
      'biasScores': result.biasScores,
      'biasWarnings': result.biasWarnings,
      'isBiasTested': result.isBiasTested,
      'passesBiasTest': result.passesBiasTest,
      'metadata': metadata ?? {},
    };

    _auditLog.add(auditRecord);

    // Save to persistent storage
    await _saveAuditLog();

    // Log to system logger
    _logger.info('Intent recognition logged: ${result.intent.id}');
  }

  /// Opt user out of intent recognition
  Future<void> optOutUser(String? userId) async {
    if (userId == null) return;
    await _prefs.setBool('intent_recognition_opt_out_$userId', true);
    _logger.info('User opted out of intent recognition: $userId');
  }

  /// Opt user in to intent recognition
  Future<void> optInUser(String? userId) async {
    if (userId == null) return;
    await _prefs.setBool('intent_recognition_opt_out_$userId', false);
    _logger.info('User opted in to intent recognition: $userId');
  }

  /// Clear intent cache
  void clearCache() {
    _intentCache.clear();
    _logger.info('Intent recognition cache cleared');
  }

  /// Get intent recognition statistics
  Map<String, dynamic> getStatistics() {
    final totalRecognitions = _auditLog.length;
    final compliantRecognitions =
        _auditLog.where((r) => r['isCompliant'] == true).length;
    final averageConfidence = _auditLog.isEmpty
        ? 0.0
        : _auditLog
                .map((r) => r['confidenceScore'] as double)
                .reduce((a, b) => a + b) /
            totalRecognitions;

    final intentTypeCounts = <String, int>{};
    for (final record in _auditLog) {
      final intentType = record['intentType'] as String;
      intentTypeCounts[intentType] = (intentTypeCounts[intentType] ?? 0) + 1;
    }

    return {
      'totalRecognitions': totalRecognitions,
      'compliantRecognitions': compliantRecognitions,
      'complianceRate': totalRecognitions > 0
          ? compliantRecognitions / totalRecognitions
          : 0.0,
      'averageConfidence': averageConfidence,
      'intentTypeDistribution': intentTypeCounts,
      'cacheSize': _intentCache.length,
      'biasTestingEnabled': _biasTestingEnabled,
      'auditLoggingEnabled': _auditLoggingEnabled,
      'confidenceThreshold': _confidenceThreshold,
    };
  }

  // Private helper methods

  Future<void> _loadConfiguration() async {
    _biasTestingEnabled = _prefs.getBool('bias_testing_enabled') ?? true;
    _auditLoggingEnabled = _prefs.getBool('audit_logging_enabled') ?? true;
    _confidenceThreshold = _prefs.getDouble('confidence_threshold') ?? 0.7;
    final cacheExpirationMinutes =
        _prefs.getInt('intent_cache_expiration_minutes') ?? 10;
    _cacheExpiration = Duration(minutes: cacheExpirationMinutes);
  }

  Future<void> _loadAuditLog() async {
    try {
      final auditLogJson = _prefs.getString('intent_audit_log') ?? '[]';
      final auditLogList = jsonDecode(auditLogJson) as List<dynamic>;

      _auditLog.clear();
      for (final record in auditLogList) {
        _auditLog.add(record as Map<String, dynamic>);
      }

      _logger
          .debug('Loaded ${_auditLog.length} intent recognition audit records');
    } catch (e) {
      _logger.error('Failed to load intent recognition audit log', error: e);
    }
  }

  Future<void> _saveAuditLog() async {
    try {
      final auditLogJson = jsonEncode(_auditLog);
      await _prefs.setString('intent_audit_log', auditLogJson);
    } catch (e) {
      _logger.error('Failed to save intent recognition audit log', error: e);
    }
  }

  String _generateIntentId(String input, String? userId) {
    final inputHash = _hashValue(input.toLowerCase());
    final userHash = userId != null ? _hashValue(userId) : 'anonymous';
    return '$userHash-${DateTime.now().millisecondsSinceEpoch}-$inputHash';
  }

  String _generateCacheKey(String input, String? userId) {
    final inputHash = _hashValue(input.toLowerCase());
    final userHash = userId != null ? _hashValue(userId) : 'anonymous';
    return '$userHash-$inputHash';
  }

  bool _isCacheValid(IntentRecognitionResult result) {
    return DateTime.now().difference(result.intent.timestamp) <
        _cacheExpiration;
  }

  String _preprocessInput(String input) {
    // Convert to lowercase
    var processed = input.toLowerCase();

    // Remove extra whitespace
    processed = processed.trim();

    // Remove special characters (keep letters, numbers, and spaces)
    processed = processed.replaceAll(RegExp(r'[^a-z0-9\s]'), '');

    // Normalize multiple spaces to single space
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');

    return processed;
  }

  IntentType _recognizeIntentType(String input) {
    final words = input.split(' ');
    final typeScores = <IntentType, double>{};

    // Score each intent type based on pattern matches
    for (final entry in _intentPatterns.entries) {
      final intentType = entry.key;
      final patterns = entry.value;

      double score = 0.0;
      for (final pattern in patterns) {
        if (input.contains(pattern)) {
          score += 1.0;
        }
      }

      // Bonus for exact word matches
      for (final word in words) {
        if (patterns.contains(word)) {
          score += 0.5;
        }
      }

      typeScores[intentType] = score;
    }

    // Find the intent type with highest score
    if (typeScores.isEmpty) return IntentType.unknown;

    final maxScore = typeScores.values.reduce((a, b) => a > b ? a : b);
    if (maxScore == 0.0) return IntentType.unknown;

    final bestTypes = typeScores.entries
        .where((entry) => entry.value == maxScore)
        .map((entry) => entry.key)
        .toList();

    // If tie, return unknown
    if (bestTypes.length > 1) return IntentType.unknown;

    return bestTypes.first;
  }

  String? _extractSpecificIntent(String input, IntentType intentType) {
    // This would use more sophisticated NLP in a real implementation
    // For now, return a simplified specific intent
    switch (intentType) {
      case IntentType.action:
        if (input.contains('message')) return 'send_message';
        if (input.contains('call')) return 'make_call';
        if (input.contains('email')) return 'send_email';
        break;
      case IntentType.query:
        if (input.contains('weather')) return 'get_weather';
        if (input.contains('time')) return 'get_time';
        if (input.contains('news')) return 'get_news';
        break;
      case IntentType.configuration:
        if (input.contains('notification')) return 'configure_notifications';
        if (input.contains('privacy')) return 'configure_privacy';
        if (input.contains('account')) return 'configure_account';
        break;
      default:
        return null;
    }
    return null;
  }

  Map<String, dynamic> _extractParameters(String input, IntentType intentType) {
    final parameters = <String, dynamic>{};

    // Extract common parameters
    if (RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(input)) {
      // Time format HH:MM
      final match = RegExp(r'\b(\d{1,2}:\d{2})\b').firstMatch(input);
      if (match != null) {
        parameters['time'] = match.group(1);
      }
    }

    if (RegExp(r'\b\d{1,2}/\d{1,2}/\d{2,4}\b').hasMatch(input)) {
      // Date format MM/DD/YYYY
      final match = RegExp(r'\b(\d{1,2}/\d{1,2}/\d{2,4})\b').firstMatch(input);
      if (match != null) {
        parameters['date'] = match.group(1);
      }
    }

    // Extract location mentions
    if (input.contains('in ') || input.contains('at ')) {
      final locationMatch =
          RegExp(r'\b(in|at)\s+([a-zA-Z\s]+)\b').firstMatch(input);
      if (locationMatch != null) {
        parameters['location'] = locationMatch.group(2)?.trim();
      }
    }

    return parameters;
  }

  double _calculateIntentConfidence({
    required String input,
    required IntentType intentType,
    String? specificIntent,
    Map<String, dynamic>? parameters,
    ContextAnalysis? contextAnalysis,
  }) {
    double confidence = 0.5; // Base confidence

    // Increase confidence based on intent type recognition
    if (intentType != IntentType.unknown) {
      confidence += 0.2;
    }

    // Increase confidence if specific intent was extracted
    if (specificIntent != null) {
      confidence += 0.1;
    }

    // Increase confidence if parameters were extracted
    if (parameters != null && parameters.isNotEmpty) {
      confidence += 0.1;
    }

    // Increase confidence if context analysis is available and positive
    if (contextAnalysis != null && contextAnalysis.isSuccess) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  IntentConfidence _getConfidenceLevel(double score) {
    if (score < 0.2) return IntentConfidence.veryLow;
    if (score < 0.4) return IntentConfidence.low;
    if (score < 0.6) return IntentConfidence.medium;
    if (score < 0.8) return IntentConfidence.high;
    return IntentConfidence.veryHigh;
  }

  void _addActionPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Check parameters for specific action requirements
    if (intent.parameters.containsKey('location')) {
      permissions.add(PermissionType.location);
    }
    if (intent.parameters.containsKey('message') ||
        intent.parameters.containsKey('email')) {
      permissions.add(PermissionType.notifications);
    }
  }

  void _addQueryPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Most queries need network access (already added)
    // Some queries might need location for location-based information
    if (intent.parameters.containsKey('location')) {
      permissions.add(PermissionType.location);
    }
  }

  void _addConfigurationPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Configuration typically needs storage
    permissions.add(PermissionType.storage);

    // Some configuration might need notifications
    if (intent.specificIntent?.contains('notification') == true) {
      permissions.add(PermissionType.notifications);
    }
  }

  void _addFeedbackPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Feedback typically needs network access and storage
    permissions.add(PermissionType.storage);
  }

  void _addNavigationPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Navigation might need location
    if (intent.parameters.containsKey('location')) {
      permissions.add(PermissionType.location);
    }
  }

  void _addCommunicationPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Communication needs notifications
    permissions.add(PermissionType.notifications);

    // Some communication might need contacts (but this is prohibited for autonomous)
    // So we don't add it here
  }

  void _addAnalysisPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Analysis might need storage for data
    permissions.add(PermissionType.storage);

    // Some analysis might need camera or microphone
    if (intent.specificIntent?.contains('image') == true ||
        intent.specificIntent?.contains('visual') == true) {
      permissions.add(PermissionType.camera);
    }

    if (intent.specificIntent?.contains('audio') == true ||
        intent.specificIntent?.contains('voice') == true) {
      permissions.add(PermissionType.microphone);
    }
  }

  void _addCreationPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Creation needs storage
    permissions.add(PermissionType.storage);

    // Some creation might need camera or microphone
    if (intent.specificIntent?.contains('image') == true ||
        intent.specificIntent?.contains('photo') == true ||
        intent.specificIntent?.contains('video') == true) {
      permissions.add(PermissionType.camera);
    }

    if (intent.specificIntent?.contains('audio') == true ||
        intent.specificIntent?.contains('voice') == true ||
        intent.specificIntent?.contains('recording') == true) {
      permissions.add(PermissionType.microphone);
    }
  }

  void _addMonitoringPermissions(
      UserIntent intent, List<PermissionType> permissions) {
    // Monitoring might need background processing
    permissions.add(PermissionType.backgroundProcessing);

    // Some monitoring might need location
    if (intent.specificIntent?.contains('location') == true) {
      permissions.add(PermissionType.location);
    }
  }

  bool _isHighRiskIntent(UserIntent intent) {
    // Define high-risk intent patterns
    final highRiskPatterns = [
      'delete',
      'remove',
      'erase',
      'format',
      'reset',
      'factory reset',
      'purchase',
      'buy',
      'pay',
      'transaction',
      'money',
      'share',
      'publish',
      'upload',
      'post',
      'broadcast',
    ];

    final input = intent.originalInput.toLowerCase();
    return highRiskPatterns.any((pattern) => input.contains(pattern));
  }

  Future<IntentRecognitionResult> _recognizeIntentWithAI({
    required String processedInput,
    required ContextAnalysis contextAnalysis,
    required String userId,
  }) async {
    try {
      // Create AI prompt for intent recognition
      final prompt = '''
You are an AI intent recognition system for a mobile autonomous agent. Analyze the user's input and determine their intent.

User Input: "$processedInput"

Context: ${contextAnalysis.toString()}

Please respond with a JSON object containing:
{
  "intentType": "one of: navigation, information, action, communication, system, unknown",
  "specificIntent": "specific intent within the type (e.g., 'navigate_to_location' for navigation)",
  "parameters": {"key": "value pairs of extracted parameters"},
  "confidence": 0.0-1.0 confidence score,
  "entities": ["list of extracted entities like locations, names, etc."]
}

Be precise and only output valid JSON.
''';

      // Call AI provider
      final response = await _chatModel.invoke(prompt);
      final responseText = response.content.toString();

      // Parse AI response
      final jsonResponse = json.decode(responseText) as Map<String, dynamic>;

      final intentType = _parseIntentType(jsonResponse['intentType'] as String);
      final specificIntent = jsonResponse['specificIntent'] as String?;
      final parameters =
          Map<String, dynamic>.from(jsonResponse['parameters'] as Map);
      final confidenceScore = (jsonResponse['confidence'] as num).toDouble();

      // Create intent
      final intent = UserIntent.success(
        id: _generateIntentId(processedInput, userId),
        originalInput: processedInput,
        intentType: intentType,
        specificIntent: specificIntent,
        parameters: parameters,
        confidenceScore: confidenceScore,
        requiredPermissions: getRequiredPermissions(
          intent: UserIntent(
            id: '',
            timestamp: DateTime.now(),
            originalInput: processedInput,
            intentType: intentType,
            specificIntent: specificIntent,
            parameters: parameters,
            confidenceScore: confidenceScore,
            confidenceLevel: _getConfidenceLevel(confidenceScore),
            requiredPermissions: [],
            isCompliant: true,
            userId: userId,
          ),
        ),
        userId: userId,
      );

      // Test for bias
      final biasScores = _biasTestingEnabled
          ? testForBias(input: processedInput, intent: intent)
          : <String, double>{};

      final biasWarnings = <String>[];
      for (final entry in biasScores.entries) {
        if (entry.value > 0.3) {
          biasWarnings
              .add('High bias detected in ${entry.key}: ${entry.value}');
        }
      }

      // Validate policy
      final policyValidation = validateIntentPolicy(intent: intent);
      final isCompliant = intent.isCompliant &&
          policyValidation.isValid &&
          biasWarnings.isEmpty;

      final finalIntent = isCompliant
          ? intent
          : UserIntent.failure(
              id: intent.id,
              originalInput: processedInput,
              confidenceScore: confidenceScore,
              complianceIssues: [
                ...intent.complianceIssues,
                ...policyValidation.violations,
                ...biasWarnings,
              ],
              userId: userId,
            );

      return IntentRecognitionResult.success(
        intent: finalIntent,
        biasScores: biasScores,
        biasWarnings: biasWarnings,
      );
    } catch (e) {
      // Fallback to rule-based recognition on AI failure
      return _recognizeIntentWithRules(
        processedInput: processedInput,
        contextAnalysis: contextAnalysis,
        userId: userId,
      );
    }
  }

  IntentRecognitionResult _recognizeIntentWithRules({
    required String processedInput,
    required ContextAnalysis contextAnalysis,
    required String userId,
  }) {
    // Recognize intent type
    final intentType = _recognizeIntentType(processedInput);

    // Extract specific intent and parameters
    final specificIntent = _extractSpecificIntent(processedInput, intentType);
    final parameters = _extractParameters(processedInput, intentType);

    // Calculate confidence score
    final confidenceScore = _calculateIntentConfidence(
      input: processedInput,
      intentType: intentType,
      specificIntent: specificIntent,
      parameters: parameters,
      contextAnalysis: contextAnalysis,
    );

    // Get required permissions
    final requiredPermissions = getRequiredPermissions(
      intent: UserIntent(
        id: _generateIntentId(processedInput, userId),
        timestamp: DateTime.now(),
        originalInput: processedInput,
        intentType: intentType,
        specificIntent: specificIntent,
        parameters: parameters,
        confidenceScore: confidenceScore,
        confidenceLevel: _getConfidenceLevel(confidenceScore),
        requiredPermissions: [],
        isCompliant: true,
        userId: userId,
      ),
    );

    // Create user intent
    final intent = UserIntent.success(
      id: _generateIntentId(processedInput, userId),
      originalInput: processedInput,
      intentType: intentType,
      specificIntent: specificIntent,
      parameters: parameters,
      confidenceScore: confidenceScore,
      requiredPermissions: requiredPermissions,
      userId: userId,
    );

    // Test for bias if enabled
    final biasScores = _biasTestingEnabled
        ? testForBias(input: processedInput, intent: intent)
        : <String, double>{};

    final biasWarnings = <String>[];
    for (final entry in biasScores.entries) {
      if (entry.value > 0.3) {
        biasWarnings.add('High bias detected in ${entry.key}: ${entry.value}');
      }
    }

    // Validate against store policies
    final policyValidation = validateIntentPolicy(intent: intent);

    // Check if intent is compliant
    final isCompliant =
        intent.isCompliant && policyValidation.isValid && biasWarnings.isEmpty;

    // Create final intent with compliance check
    final finalIntent = isCompliant
        ? intent
        : UserIntent.failure(
            id: intent.id,
            originalInput: processedInput,
            confidenceScore: confidenceScore,
            complianceIssues: [
              ...intent.complianceIssues,
              ...policyValidation.violations,
              ...biasWarnings,
            ],
            userId: userId,
          );

    // Create recognition result
    return IntentRecognitionResult.success(
      intent: finalIntent,
      biasScores: biasScores,
      biasWarnings: biasWarnings,
    );
  }

  IntentType _parseIntentType(String intentTypeString) {
    switch (intentTypeString.toLowerCase()) {
      case 'navigation':
        return IntentType.navigation;
      case 'information':
        return IntentType.query;
      case 'action':
        return IntentType.action;
      case 'communication':
        return IntentType.communication;
      case 'system':
        return IntentType.configuration;
      default:
        return IntentType.unknown;
    }
  }

  // Bias testing methods

  double _testGenderBias(String input) {
    final genderedTerms = {
      'he': 1.0,
      'him': 1.0,
      'his': 1.0,
      'male': 1.0,
      'man': 1.0,
      'men': 1.0,
      'she': 1.0,
      'her': 1.0,
      'hers': 1.0,
      'female': 1.0,
      'woman': 1.0,
      'women': 1.0,
    };

    final words = input.toLowerCase().split(' ');
    int genderedCount = 0;

    for (final word in words) {
      if (genderedTerms.containsKey(word)) {
        genderedCount++;
      }
    }

    return genderedCount / words.length;
  }

  double _testRacialBias(String input) {
    // This is a simplified implementation
    // In practice, this would use more sophisticated NLP techniques
    final racialTerms = [
      // List of potentially racially charged terms would go here
      // This is intentionally left empty as it requires careful curation
    ];

    final inputLower = input.toLowerCase();
    int racialTermCount = 0;

    for (final term in racialTerms) {
      if (inputLower.contains(term)) {
        racialTermCount++;
      }
    }

    return racialTermCount > 0 ? 1.0 : 0.0;
  }

  double _testAgeBias(String input) {
    final ageTerms = {
      'young': 1.0,
      'old': 1.0,
      'elderly': 1.0,
      'senior': 1.0,
      'teenager': 1.0,
      'child': 1.0,
      'kid': 1.0,
    };

    final words = input.toLowerCase().split(' ');
    int ageTermCount = 0;

    for (final word in words) {
      if (ageTerms.containsKey(word)) {
        ageTermCount++;
      }
    }

    return ageTermCount / words.length;
  }

  double _testCulturalBias(String input) {
    // This is a simplified implementation
    // In practice, this would use more sophisticated NLP techniques
    final culturalTerms = [
      // List of potentially culturally charged terms would go here
      // This is intentionally left empty as it requires careful curation
    ];

    final inputLower = input.toLowerCase();
    int culturalTermCount = 0;

    for (final term in culturalTerms) {
      if (inputLower.contains(term)) {
        culturalTermCount++;
      }
    }

    return culturalTermCount > 0 ? 1.0 : 0.0;
  }

  double _testAccessibilityBias(String input) {
    final accessibilityTerms = {
      'blind': 1.0,
      'deaf': 1.0,
      'disabled': 1.0,
      'handicapped': 1.0,
      'impaired': 1.0,
      'wheelchair': 1.0,
      'crutches': 1.0,
    };

    final words = input.toLowerCase().split(' ');
    int accessibilityTermCount = 0;

    for (final word in words) {
      if (accessibilityTerms.containsKey(word)) {
        accessibilityTermCount++;
      }
    }

    return accessibilityTermCount / words.length;
  }

  String _hashValue(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

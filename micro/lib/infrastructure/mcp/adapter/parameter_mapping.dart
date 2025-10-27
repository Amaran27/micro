import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/models/domain_context.dart';
import '../core/exceptions/mcp_exceptions.dart';
import 'models/adapter_models.dart';

/// System for mapping parameters between different domains and tool contexts
class ParameterMappingSystem {
  /// Cache for parameter mappings
  final Map<String, List<ParameterMapping>> _mappingCache = {};

  /// Cache for transformation functions
  final Map<String, dynamic Function(dynamic)> _transformationCache = {};

  /// Default parameter mappings for common types
  final Map<String, List<ParameterMapping>> _defaultMappings = {};

  /// Performance metrics
  final _MappingMetrics _metrics = _MappingMetrics();

  /// Constructor with default mappings
  ParameterMappingSystem() {
    _initializeDefaultMappings();
  }

  /// Maps parameters from source to target context
  Future<Map<String, dynamic>> mapParameters(
    Map<String, dynamic> sourceParameters,
    Map<String, String> sourceSchema,
    Map<String, String> targetSchema, {
    DomainContext? sourceContext,
    DomainContext? targetContext,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final cacheKey = _generateCacheKey(
        sourceParameters,
        sourceSchema,
        targetSchema,
        sourceContext?.id,
        targetContext?.id,
      );

      // Check cache first
      if (_mappingCache.containsKey(cacheKey)) {
        _metrics.recordCacheHit();
        return _applyMappings(sourceParameters, _mappingCache[cacheKey]!);
      }

      // Generate mappings
      final mappings = await _generateMappings(
        sourceSchema,
        targetSchema,
        sourceContext,
        targetContext,
      );

      // Cache the mappings
      _mappingCache[cacheKey] = mappings;
      _metrics.recordMappingGeneration();

      // Apply mappings
      final result = _applyMappings(sourceParameters, mappings);

      _metrics.recordMappingTime(stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      _metrics.recordError();
      throw McpAdapterException(
        'Failed to map parameters: ${e.toString()}',
        adapterType: 'ParameterMappingSystem',
        originalError: e,
      );
    }
  }

  /// Validates parameter mapping
  Future<bool> validateMapping(
    ParameterMapping mapping,
    dynamic testValue,
  ) async {
    try {
      // Type validation
      if (!_isValidTypeConversion(mapping.sourceType, mapping.targetType)) {
        return false;
      }

      // Apply transformation if present
      final transformedValue = mapping.transformationFunction != null
          ? _applyTransformation(mapping.transformationFunction!, testValue)
          : testValue;

      // Validate against target type
      return _validateValue(transformedValue, mapping.targetType);
    } catch (e) {
      return false;
    }
  }

  /// Gets parameter mappings for a specific domain pair
  List<ParameterMapping> getDomainMappings(
    String sourceDomain,
    String targetDomain,
  ) {
    final key = '${sourceDomain}_to_$targetDomain';
    return _defaultMappings[key] ?? [];
  }

  /// Adds a custom parameter mapping
  void addCustomMapping(
    String sourceDomain,
    String targetDomain,
    ParameterMapping mapping,
  ) {
    final key = '${sourceDomain}_to_$targetDomain';
    if (!_defaultMappings.containsKey(key)) {
      _defaultMappings[key] = [];
    }
    _defaultMappings[key]!.add(mapping);
  }

  /// Clears the mapping cache
  void clearCache() {
    _mappingCache.clear();
    _transformationCache.clear();
  }

  /// Gets performance metrics
  Map<String, dynamic> getMetrics() => _metrics.toJson();

  /// Generates parameter mappings between schemas
  Future<List<ParameterMapping>> _generateMappings(
    Map<String, String> sourceSchema,
    Map<String, String> targetSchema,
    DomainContext? sourceContext,
    DomainContext? targetContext,
  ) async {
    final mappings = <ParameterMapping>[];

    for (final targetEntry in targetSchema.entries) {
      final targetName = targetEntry.key;
      final targetType = targetEntry.value;

      // Find matching source parameter
      final sourceMatch = _findBestSourceMatch(targetName, sourceSchema);

      if (sourceMatch != null) {
        final sourceName = sourceMatch.key;
        final sourceType = sourceSchema[sourceName]!;

        // Create mapping
        final mapping = ParameterMapping(
          sourceParameter: sourceName,
          targetParameter: targetName,
          sourceType: sourceType,
          targetType: targetType,
          transformationFunction: _getTransformationFunction(
            sourceType,
            targetType,
            sourceContext,
            targetContext,
          ),
          isRequired: _isRequiredParameter(targetName, targetContext),
          validationRules: _getValidationRules(targetType, targetContext),
        );

        mappings.add(mapping);
      } else if (_isRequiredParameter(targetName, targetContext)) {
        // Required parameter with no source match
        throw McpAdapterException(
          'Required parameter "$targetName" has no source mapping',
          adapterType: 'ParameterMappingSystem',
        );
      }
    }

    return mappings;
  }

  /// Finds the best matching source parameter for a target parameter
  MapEntry<String, String>? _findBestSourceMatch(
    String targetName,
    Map<String, String> sourceSchema,
  ) {
    // Exact match
    if (sourceSchema.containsKey(targetName)) {
      return MapEntry(targetName, sourceSchema[targetName]!);
    }

    // Case-insensitive match
    for (final entry in sourceSchema.entries) {
      if (entry.key.toLowerCase() == targetName.toLowerCase()) {
        return entry;
      }
    }

    // Semantic similarity match (simplified)
    for (final entry in sourceSchema.entries) {
      if (_isSemanticMatch(targetName, entry.key)) {
        return entry;
      }
    }

    return null;
  }

  /// Checks if two parameter names are semantically similar
  bool _isSemanticMatch(String target, String source) {
    // Simple semantic matching based on common patterns
    final targetLower = target.toLowerCase();
    final sourceLower = source.toLowerCase();

    // Common synonyms and variations
    final semanticGroups = [
      ['id', 'identifier', 'uuid', 'key'],
      ['name', 'title', 'label', 'display_name'],
      ['description', 'desc', 'summary', 'details'],
      ['created', 'created_at', 'creation_date', 'timestamp'],
      ['updated', 'updated_at', 'modification_date', 'last_modified'],
      ['url', 'link', 'href', 'uri'],
      ['count', 'total', 'size', 'length'],
    ];

    for (final group in semanticGroups) {
      if (group.contains(targetLower) && group.contains(sourceLower)) {
        return true;
      }
    }

    return false;
  }

  /// Gets transformation function for type conversion
  String? _getTransformationFunction(
    String sourceType,
    String targetType,
    DomainContext? sourceContext,
    DomainContext? targetContext,
  ) {
    // Direct type match - no transformation needed
    if (sourceType == targetType) {
      return null;
    }

    // Common transformations
    if (sourceType == 'string' && targetType == 'int') {
      return 'stringToInt';
    } else if (sourceType == 'string' && targetType == 'double') {
      return 'stringToDouble';
    } else if (sourceType == 'string' && targetType == 'bool') {
      return 'stringToBool';
    } else if (sourceType == 'int' && targetType == 'string') {
      return 'intToString';
    } else if (sourceType == 'double' && targetType == 'string') {
      return 'doubleToString';
    } else if (sourceType == 'bool' && targetType == 'string') {
      return 'boolToString';
    } else if (sourceType == 'list' && targetType == 'string') {
      return 'listToString';
    } else if (sourceType == 'map' && targetType == 'string') {
      return 'mapToString';
    }

    // Domain-specific transformations
    if (sourceContext != null && targetContext != null) {
      return _getDomainTransformation(
        sourceType,
        targetType,
        sourceContext,
        targetContext,
      );
    }

    return null;
  }

  /// Gets domain-specific transformation function
  String? _getDomainTransformation(
    String sourceType,
    String targetType,
    DomainContext sourceContext,
    DomainContext targetContext,
  ) {
    // Example domain-specific transformations
    if (sourceContext.category == 'healthcare' &&
        targetContext.category == 'finance') {
      // Healthcare to finance transformations
      if (sourceType == 'medical_record' && targetType == 'financial_record') {
        return 'medicalToFinancial';
      }
    } else if (sourceContext.category == 'iot' &&
        targetContext.category == 'analytics') {
      // IoT to analytics transformations
      if (sourceType == 'sensor_data' && targetType == 'analytics_data') {
        return 'sensorToAnalytics';
      }
    }

    return null;
  }

  /// Applies parameter mappings to source parameters
  Map<String, dynamic> _applyMappings(
    Map<String, dynamic> sourceParameters,
    List<ParameterMapping> mappings,
  ) {
    final result = <String, dynamic>{};

    for (final mapping in mappings) {
      final sourceValue = sourceParameters[mapping.sourceParameter];

      if (sourceValue != null) {
        // Apply transformation if needed
        final transformedValue = mapping.transformationFunction != null
            ? _applyTransformation(mapping.transformationFunction!, sourceValue)
            : sourceValue;

        result[mapping.targetParameter] = transformedValue;
      } else if (mapping.defaultValue != null) {
        // Use default value
        result[mapping.targetParameter] = mapping.defaultValue;
      } else if (mapping.isRequired) {
        throw McpAdapterException(
          'Required parameter "${mapping.sourceParameter}" is missing',
          adapterType: 'ParameterMappingSystem',
        );
      }
    }

    return result;
  }

  /// Applies transformation function to a value
  dynamic _applyTransformation(String transformationFunction, dynamic value) {
    // Check cache first
    if (_transformationCache.containsKey(transformationFunction)) {
      return _transformationCache[transformationFunction]!(value);
    }

    dynamic Function(dynamic) transform;

    switch (transformationFunction) {
      case 'stringToInt':
        transform = (v) => int.tryParse(v.toString()) ?? 0;
        break;
      case 'stringToDouble':
        transform = (v) => double.tryParse(v.toString()) ?? 0.0;
        break;
      case 'stringToBool':
        transform = (v) {
          final str = v.toString().toLowerCase();
          return str == 'true' || str == '1' || str == 'yes';
        };
        break;
      case 'intToString':
        transform = (v) => v.toString();
        break;
      case 'doubleToString':
        transform = (v) => v.toString();
        break;
      case 'boolToString':
        transform = (v) => v.toString();
        break;
      case 'listToString':
        transform = (v) => jsonEncode(v);
        break;
      case 'mapToString':
        transform = (v) => jsonEncode(v);
        break;
      case 'medicalToFinancial':
        transform = (v) => _transformMedicalToFinancial(v);
        break;
      case 'sensorToAnalytics':
        transform = (v) => _transformSensorToAnalytics(v);
        break;
      default:
        throw McpAdapterException(
          'Unknown transformation function: $transformationFunction',
          adapterType: 'ParameterMappingSystem',
        );
    }

    // Cache the transformation function
    _transformationCache[transformationFunction] = transform;
    return transform(value);
  }

  /// Transforms medical record to financial record
  dynamic _transformMedicalToFinancial(dynamic value) {
    // Example transformation logic
    if (value is Map<String, dynamic>) {
      return {
        'patient_id': value['patient_id'],
        'cost': value['treatment_cost'] ?? 0.0,
        'date': value['visit_date'],
        'category': 'healthcare',
      };
    }
    return value;
  }

  /// Transforms sensor data to analytics data
  dynamic _transformSensorToAnalytics(dynamic value) {
    // Example transformation logic
    if (value is Map<String, dynamic>) {
      return {
        'sensor_id': value['sensor_id'],
        'timestamp': value['timestamp'],
        'value': value['reading'],
        'analytics_type': 'sensor_reading',
      };
    }
    return value;
  }

  /// Validates if a value matches the expected type
  bool _validateValue(dynamic value, String expectedType) {
    try {
      switch (expectedType.toLowerCase()) {
        case 'string':
          return value is String;
        case 'int':
          return value is int;
        case 'double':
          return value is double;
        case 'bool':
          return value is bool;
        case 'list':
          return value is List;
        case 'map':
          return value is Map;
        default:
          return true; // Unknown type, assume valid
      }
    } catch (e) {
      return false;
    }
  }

  /// Checks if type conversion is valid
  bool _isValidTypeConversion(String sourceType, String targetType) {
    // Define valid type conversions
    final validConversions = {
      'string': ['int', 'double', 'bool', 'list', 'map'],
      'int': ['string', 'double'],
      'double': ['string', 'int'],
      'bool': ['string'],
      'list': ['string'],
      'map': ['string'],
    };

    return validConversions[sourceType]?.contains(targetType) ?? false;
  }

  /// Checks if a parameter is required in the target context
  bool _isRequiredParameter(String parameterName, DomainContext? context) {
    // Check domain-specific requirements
    if (context != null) {
      final requiredParams =
          context.parameters['required_parameters'] as List<dynamic>?;
      if (requiredParams != null && requiredParams.contains(parameterName)) {
        return true;
      }
    }

    // Common required parameters
    final commonRequired = ['id', 'name', 'type'];
    return commonRequired.contains(parameterName.toLowerCase());
  }

  /// Gets validation rules for a parameter type
  List<String> _getValidationRules(String type, DomainContext? context) {
    final rules = <String>[];

    // Type-specific rules
    switch (type.toLowerCase()) {
      case 'string':
        rules.addAll(['not_null', 'max_length:1000']);
        break;
      case 'int':
        rules.addAll(['not_null', 'min_value:0']);
        break;
      case 'double':
        rules.addAll(['not_null', 'min_value:0.0']);
        break;
      case 'bool':
        rules.add('not_null');
        break;
    }

    // Domain-specific rules
    if (context != null) {
      final domainRules =
          context.parameters['validation_rules'] as Map<String, dynamic>?;
      if (domainRules != null && domainRules.containsKey(type)) {
        final typeRules = domainRules[type] as List<dynamic>?;
        if (typeRules != null) {
          rules.addAll(typeRules.cast<String>());
        }
      }
    }

    return rules;
  }

  /// Generates cache key for parameter mappings
  String _generateCacheKey(
    Map<String, dynamic> sourceParameters,
    Map<String, String> sourceSchema,
    Map<String, String> targetSchema,
    String? sourceDomainId,
    String? targetDomainId,
  ) {
    final keyData = {
      'source_schema': sourceSchema,
      'target_schema': targetSchema,
      'source_domain': sourceDomainId,
      'target_domain': targetDomainId,
    };

    final keyString = jsonEncode(keyData);
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Initializes default parameter mappings
  void _initializeDefaultMappings() {
    // Web to mobile mappings
    _defaultMappings['web_to_mobile'] = [
      ParameterMapping(
        sourceParameter: 'click',
        targetParameter: 'tap',
        sourceType: 'string',
        targetType: 'string',
      ),
      ParameterMapping(
        sourceParameter: 'hover',
        targetParameter: 'long_press',
        sourceType: 'string',
        targetType: 'string',
      ),
    ];

    // Desktop to mobile mappings
    _defaultMappings['desktop_to_mobile'] = [
      ParameterMapping(
        sourceParameter: 'right_click',
        targetParameter: 'long_press',
        sourceType: 'string',
        targetType: 'string',
      ),
      ParameterMapping(
        sourceParameter: 'keyboard_shortcut',
        targetParameter: 'gesture',
        sourceType: 'string',
        targetType: 'string',
        transformationFunction: 'keyboardToGesture',
      ),
    ];

    // API to database mappings
    _defaultMappings['api_to_database'] = [
      ParameterMapping(
        sourceParameter: 'query_params',
        targetParameter: 'filter_conditions',
        sourceType: 'map',
        targetType: 'map',
        transformationFunction: 'apiToDbFilter',
      ),
      ParameterMapping(
        sourceParameter: 'pagination',
        targetParameter: 'limit_offset',
        sourceType: 'map',
        targetType: 'map',
        transformationFunction: 'apiToDbPagination',
      ),
    ];
  }
}

/// Internal metrics tracking for parameter mapping
class _MappingMetrics {
  int _totalMappings = 0;
  int _cacheHits = 0;
  int _errors = 0;
  final List<int> _mappingTimes = [];

  void recordMappingGeneration() => _totalMappings++;
  void recordCacheHit() => _cacheHits++;
  void recordError() => _errors++;
  void recordMappingTime(int milliseconds) => _mappingTimes.add(milliseconds);

  Map<String, dynamic> toJson() {
    return {
      'total_mappings': _totalMappings,
      'cache_hits': _cacheHits,
      'cache_hit_rate': _totalMappings > 0 ? _cacheHits / _totalMappings : 0.0,
      'errors': _errors,
      'error_rate': _totalMappings > 0 ? _errors / _totalMappings : 0.0,
      'average_mapping_time_ms': _mappingTimes.isEmpty
          ? 0.0
          : _mappingTimes.reduce((a, b) => a + b) / _mappingTimes.length,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}

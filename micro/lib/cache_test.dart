import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Domain Model
class AIModel {
  final String id;
  final String name;
  final String provider;
  final String modelType;
  final Map<String, dynamic> capabilities;
  final DateTime lastUpdated;

  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.modelType,
    required this.capabilities,
    required this.lastUpdated,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      modelType: json['modelType'] as String,
      capabilities: json['capabilities'] as Map<String, dynamic>,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'modelType': modelType,
      'capabilities': capabilities,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  AIModel copyWith({
    String? id,
    String? name,
    String? provider,
    String? modelType,
    Map<String, dynamic>? capabilities,
    DateTime? lastUpdated,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      modelType: modelType ?? this.modelType,
      capabilities: capabilities ?? this.capabilities,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Cache Repository
class ModelCacheRepository {
  static const String _tableName = 'ai_models';
  static const String _cacheValidityKey = 'cache_validity';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_models_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            provider TEXT NOT NULL,
            modelType TEXT NOT NULL,
            capabilities TEXT NOT NULL,
            lastUpdated TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_cacheValidityKey (
            key TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveModels(List<AIModel> models) async {
    final db = await database;
    final batch = db.batch();

    // Clear existing models
    batch.delete(_tableName);

    // Insert new models
    for (final model in models) {
      batch.insert(_tableName, {
        'id': model.id,
        'name': model.name,
        'provider': model.provider,
        'modelType': model.modelType,
        'capabilities': jsonEncode(model.capabilities),
        'lastUpdated': model.lastUpdated.toIso8601String(),
      });
    }

    // Update cache validity timestamp
    batch.insert(
      _cacheValidityKey,
      {'key': 'last_update', 'timestamp': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await batch.commit();
  }

  Future<List<AIModel>> getCachedModels() async {
    final db = await database;
    final maps = await db.query(_tableName);

    return maps.map((map) {
      return AIModel(
        id: map['id'] as String,
        name: map['name'] as String,
        provider: map['provider'] as String,
        modelType: map['modelType'] as String,
        capabilities:
            jsonDecode(map['capabilities'] as String) as Map<String, dynamic>,
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      );
    }).toList();
  }

  Future<bool> isCacheValid(
      {Duration validityDuration = const Duration(hours: 24)}) async {
    final db = await database;
    final result = await db.query(
      _cacheValidityKey,
      where: 'key = ?',
      whereArgs: ['last_update'],
    );

    if (result.isEmpty) return false;

    final lastUpdate = DateTime.parse(result.first['timestamp'] as String);
    return DateTime.now().difference(lastUpdate) < validityDuration;
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete(_tableName);
    await db.delete(_cacheValidityKey);
  }
}

// Test Widget
class CacheTestWidget extends ConsumerStatefulWidget {
  const CacheTestWidget({super.key});

  @override
  ConsumerState<CacheTestWidget> createState() => _CacheTestWidgetState();
}

class _CacheTestWidgetState extends ConsumerState<CacheTestWidget> {
  final ModelCacheRepository _repository = ModelCacheRepository();
  List<AIModel> _cachedModels = [];
  bool _isLoading = false;
  String _status = 'Ready to test caching';

  @override
  void initState() {
    super.initState();
    _testCaching();
  }

  Future<void> _testCaching() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing cache functionality...';
    });

    try {
      // Test 1: Check if cache is empty initially
      final initialModels = await _repository.getCachedModels();
      setState(() {
        _status = 'Initial cache check: ${initialModels.length} models';
      });

      // Test 2: Save some test models
      final testModels = [
        AIModel(
          id: 'gpt-4',
          name: 'GPT-4',
          provider: 'OpenAI',
          modelType: 'chat',
          capabilities: {'maxTokens': 8192, 'supportsFunctions': true},
          lastUpdated: DateTime.now(),
        ),
        AIModel(
          id: 'claude-3',
          name: 'Claude 3',
          provider: 'Anthropic',
          modelType: 'chat',
          capabilities: {'maxTokens': 4096, 'supportsVision': true},
          lastUpdated: DateTime.now(),
        ),
      ];

      await _repository.saveModels(testModels);
      setState(() {
        _status = 'Saved ${testModels.length} test models to cache';
      });

      // Test 3: Load models from cache
      final cachedModels = await _repository.getCachedModels();
      setState(() {
        _cachedModels = cachedModels;
        _status = 'Loaded ${cachedModels.length} models from cache';
      });

      // Test 4: Check cache validity
      final isValid = await _repository.isCacheValid();
      setState(() {
        _status = 'Cache validity check: ${isValid ? "Valid" : "Invalid"}';
      });

      // Test 5: Clear cache
      await _repository.clearCache();
      final afterClear = await _repository.getCachedModels();
      setState(() {
        _status = 'Cache cleared. Remaining models: ${afterClear.length}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _testCaching,
                child: const Text('Run Cache Test'),
              ),
            const SizedBox(height: 20),
            const Text(
              'Cached Models:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _cachedModels.length,
                itemBuilder: (context, index) {
                  final model = _cachedModels[index];
                  return Card(
                    child: ListTile(
                      title: Text(model.name),
                      subtitle: Text('${model.provider} - ${model.modelType}'),
                      trailing: Text(model.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Test Provider
final cacheTestProvider = Provider<ModelCacheRepository>((ref) {
  return ModelCacheRepository();
});

// Main Test App
void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: CacheTestWidget(),
      ),
    ),
  );
}

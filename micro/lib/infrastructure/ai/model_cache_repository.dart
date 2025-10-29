import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../domain/models/ai_model.dart';

class ModelCacheRepository {
  static const String tableName = 'cached_models';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'model_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT NOT NULL,
        modelId TEXT NOT NULL,
        displayName TEXT NOT NULL,
        description TEXT,
        data TEXT NOT NULL,
        UNIQUE(provider, modelId)
      )
    ''');
  }

  Future<List<AIModel>> getCachedModels() async {
    final db = await database;
    final maps = await db.query(tableName);

    return maps.map((map) {
      final data = jsonDecode(map['data'] as String);
      return AIModel.fromJson(data);
    }).toList();
  }

  Future<void> saveModels(List<AIModel> models) async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear old cache
      await txn.delete(tableName);

      // Insert new models
      for (final model in models) {
        await txn.insert(
          tableName,
          {
            'provider': model.provider,
            'modelId': model.modelId,
            'displayName': model.displayName,
            'description': model.description,
            'data': jsonEncode(model.toJson()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<bool> isCacheValid() async {
    final db = await database;
    final result = await db.query(
      tableName,
      columns: ['COUNT(*) as count'],
      limit: 1,
    );

    if (result.isEmpty || result.first['count'] == 0) {
      return false; // No cached models
    }

    // Check timestamp from shared preferences
    // For simplicity, we'll assume cache is valid if models exist
    // In a full implementation, you'd store timestamp separately
    return true;
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete(tableName);
  }
}

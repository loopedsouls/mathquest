import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// SQLite database storage using Hive pattern (no Hive dependency)
class HiveStorage {
  HiveStorage._();

  static final HiveStorage _instance = HiveStorage._();
  static HiveStorage get instance => _instance;

  Database? _database;
  static const int _databaseVersion = 1;
  static const String _databaseName = 'mathquest.db';

  /// Initialize database
  Future<void> init() async {
    if (_database != null) return;

    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Database get database {
    if (_database == null) {
      throw Exception('HiveStorage not initialized. Call init() first.');
    }
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    // User progress table
    await db.execute('''
      CREATE TABLE user_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        correct_answers INTEGER DEFAULT 0,
        total_answers INTEGER DEFAULT 0,
        xp_earned INTEGER DEFAULT 0,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        time_spent_seconds INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        question_results TEXT,
        UNIQUE(user_id, lesson_id)
      )
    ''');

    // Cached questions table
    await db.execute('''
      CREATE TABLE cached_questions (
        id TEXT PRIMARY KEY,
        lesson_id TEXT,
        question TEXT NOT NULL,
        type TEXT NOT NULL,
        options TEXT,
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        difficulty TEXT DEFAULT 'médio',
        thematic_unit TEXT NOT NULL,
        school_year TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        source TEXT
      )
    ''');

    // User achievements table
    await db.execute('''
      CREATE TABLE user_achievements (
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        current_value INTEGER DEFAULT 0,
        is_unlocked INTEGER DEFAULT 0,
        unlocked_at TEXT,
        PRIMARY KEY (user_id, achievement_id)
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        user_id TEXT PRIMARY KEY,
        settings TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Module statistics table
    await db.execute('''
      CREATE TABLE module_statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        thematic_unit TEXT NOT NULL,
        school_year TEXT NOT NULL,
        total_correct INTEGER DEFAULT 0,
        total_answered INTEGER DEFAULT 0,
        total_time_seconds INTEGER DEFAULT 0,
        last_activity TEXT,
        UNIQUE(user_id, thematic_unit, school_year)
      )
    ''');

    if (kDebugMode) {
      print('Database created with version $version');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from $oldVersion to $newVersion');
    }

    // Add migrations here for future versions
    // if (oldVersion < 2) { ... }
  }

  /// Close database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Clear all data
  Future<void> clear() async {
    await database.delete('user_progress');
    await database.delete('cached_questions');
    await database.delete('user_achievements');
    await database.delete('user_settings');
    await database.delete('module_statistics');
  }

  // Generic CRUD operations

  /// Insert or replace a record
  Future<int> insertOrReplace(String table, Map<String, dynamic> data) async {
    return await database.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await database.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Update records
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await database.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Delete records
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await database.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Execute raw SQL
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    await database.execute(sql, arguments);
  }

  /// Raw query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return await database.rawQuery(sql, arguments);
  }
}

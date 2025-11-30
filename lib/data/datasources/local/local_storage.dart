import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Local storage for caching data
class LocalStorage {
  LocalStorage._();

  static final LocalStorage _instance = LocalStorage._();
  static LocalStorage get instance => _instance;

  SharedPreferences? _prefs;

  /// Initialize storage
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences.getInt(key);
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    return await _preferences.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _preferences.getDouble(key);
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  // List operations
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _preferences.getStringList(key);
  }

  // JSON operations
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await _preferences.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final value = _preferences.getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing JSON for key $key: $e');
      }
      return null;
    }
  }

  // JSON List operations
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    return await _preferences.setString(key, jsonEncode(value));
  }

  List<Map<String, dynamic>>? getJsonList(String key) {
    final value = _preferences.getString(key);
    if (value == null) return null;
    try {
      final list = jsonDecode(value) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing JSON list for key $key: $e');
      }
      return null;
    }
  }

  // Remove operations
  Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }

  // Clear all
  Future<bool> clear() async {
    return await _preferences.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }

  // Get all keys
  Set<String> get keys => _preferences.getKeys();

  // Cached data with expiration
  Future<bool> setCachedData(
    String key,
    Map<String, dynamic> data, {
    Duration expiration = const Duration(hours: 24),
  }) async {
    final cacheEntry = {
      'data': data,
      'expiresAt': DateTime.now().add(expiration).toIso8601String(),
    };
    return await setJson('cache_$key', cacheEntry);
  }

  Map<String, dynamic>? getCachedData(String key) {
    final cacheEntry = getJson('cache_$key');
    if (cacheEntry == null) return null;

    final expiresAt = DateTime.parse(cacheEntry['expiresAt'] as String);
    if (DateTime.now().isAfter(expiresAt)) {
      remove('cache_$key');
      return null;
    }

    return cacheEntry['data'] as Map<String, dynamic>;
  }

  // Clear expired cache
  Future<void> clearExpiredCache() async {
    final keysToRemove = <String>[];

    for (final key in keys) {
      if (key.startsWith('cache_')) {
        final cacheEntry = getJson(key);
        if (cacheEntry != null) {
          final expiresAt = DateTime.parse(cacheEntry['expiresAt'] as String);
          if (DateTime.now().isAfter(expiresAt)) {
            keysToRemove.add(key);
          }
        }
      }
    }

    for (final key in keysToRemove) {
      await remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      print('Cleared ${keysToRemove.length} expired cache entries');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for OpenAI API
class OpenAIConfig {
  static const String _envVarName = 'OPENAI_API_KEY';
  static const String _prefsKey = 'openai_api_key';

  static String? _cachedApiKey;

  /// Get the OpenAI API key from SharedPreferences, environment variables, or .env file
  static Future<String?> getApiKey() async {
    try {
      // 1. First, try to get from SharedPreferences (saved by settings screen)
      final prefs = await SharedPreferences.getInstance();
      final prefsKey = prefs.getString(_prefsKey);
      if (prefsKey != null && prefsKey.isNotEmpty) {
        _cachedApiKey = prefsKey;
        return prefsKey;
      }

      // 2. Try to get from environment variable
      final envKey = Platform.environment[_envVarName];
      if (envKey != null && envKey.isNotEmpty) {
        _cachedApiKey = envKey;
        return envKey;
      }

      // 3. Try to get from .env file
      final dotenvKey = dotenv.env[_envVarName];
      if (dotenvKey != null && dotenvKey.isNotEmpty) {
        _cachedApiKey = dotenvKey;
        return dotenvKey;
      }

      _cachedApiKey = null;
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting OpenAI API key: $e');
      }
      _cachedApiKey = null;
      return null;
    }
  }

  /// Get cached API key (sync version, may be null if not loaded)
  static String? get apiKey => _cachedApiKey;

  /// Check if OpenAI API is available
  static Future<bool> isApiAvailable() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Check if OpenAI API is available (sync version, may be inaccurate)
  static bool get isAvailable =>
      _cachedApiKey != null && _cachedApiKey!.isNotEmpty;

  /// Initialize and cache the API key
  static Future<void> initialize() async {
    await getApiKey();
  }
}

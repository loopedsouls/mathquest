import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Configuration for OpenAI API
class OpenAIConfig {
  static const String _envVarName = 'OPENAI_API_KEY';

  /// Get the OpenAI API key from environment variables
  static String? get apiKey {
    try {
      // Try to get from environment variable
      final envKey = Platform.environment[_envVarName];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }

      // Fallback: you can hardcode the key here for development
      // WARNING: Never commit API keys to version control!
      // const fallbackKey = 'your-api-key-here';
      // return fallbackKey;

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting OpenAI API key: $e');
      }
      return null;
    }
  }

  /// Check if OpenAI API is available
  static bool get isAvailable => apiKey != null && apiKey!.isNotEmpty;
}
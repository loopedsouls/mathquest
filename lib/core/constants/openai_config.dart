import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for OpenAI API
class OpenAIConfig {
  static const String _envVarName = 'OPENAI_API_KEY';

  /// Get the OpenAI API key from environment variables or .env file
  static String? get apiKey {
    try {
      // Try to get from environment variable
      final envKey = Platform.environment[_envVarName];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }

      // Try to get from .env file
      final dotenvKey = dotenv.env[_envVarName];
      if (dotenvKey != null && dotenvKey.isNotEmpty) {
        return dotenvKey;
      }

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
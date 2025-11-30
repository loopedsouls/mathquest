import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to check network connectivity
class NetworkInfo {
  NetworkInfo._();

  static final NetworkInfo _instance = NetworkInfo._();
  static NetworkInfo get instance => _instance;

  /// Check if device has internet connection
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking network: $e');
      }
      return false;
    }
  }

  /// Check connection to a specific host
  Future<bool> canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error reaching host $host: $e');
      }
      return false;
    }
  }

  /// Check if Firebase services are reachable
  Future<bool> get canReachFirebase async {
    return await canReachHost('firebase.google.com');
  }

  /// Check if Ollama local server is running
  Future<bool> get isOllamaRunning async {
    try {
      final socket = await Socket.connect('localhost', 11434, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

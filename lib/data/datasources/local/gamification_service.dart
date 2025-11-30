import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gamification service for streaks and achievements
class GamificacaoService {
  static const String _streakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';
  static const String _lastActivityKey = 'last_activity';

  /// Get current streak
  static Future<int> obterStreakAtual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_streakKey) ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error getting current streak: $e');
      return 0;
    }
  }

  /// Get best streak
  static Future<int> obterMelhorStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_bestStreakKey) ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error getting best streak: $e');
      return 0;
    }
  }

  /// Update streak after activity
  static Future<void> atualizarStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final lastActivityStr = prefs.getString(_lastActivityKey);
      
      int currentStreak = prefs.getInt(_streakKey) ?? 0;
      int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;

      if (lastActivityStr != null) {
        final lastActivity = DateTime.parse(lastActivityStr);
        final difference = now.difference(lastActivity).inDays;

        if (difference == 1) {
          // Continue streak
          currentStreak++;
        } else if (difference > 1) {
          // Reset streak
          currentStreak = 1;
        }
        // Same day - do nothing
      } else {
        // First activity
        currentStreak = 1;
      }

      // Update best streak
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
        await prefs.setInt(_bestStreakKey, bestStreak);
      }

      await prefs.setInt(_streakKey, currentStreak);
      await prefs.setString(_lastActivityKey, now.toIso8601String());
    } catch (e) {
      if (kDebugMode) print('Error updating streak: $e');
    }
  }

  /// Register correct answer
  static Future<List<String>> registrarRespostaCorreta({
    required String unidade,
    required String ano,
    required int tempoResposta,
  }) async {
    await atualizarStreak();
    
    // Return list of unlocked achievements
    return _verificarConquistas();
  }

  /// Check for unlocked achievements
  static Future<List<String>> _verificarConquistas() async {
    final conquistas = <String>[];
    
    try {
      final currentStreak = await obterStreakAtual();
      
      // Example achievements
      if (currentStreak >= 3) conquistas.add('3_dias_seguidos');
      if (currentStreak >= 7) conquistas.add('semana_completa');
      if (currentStreak >= 30) conquistas.add('mes_completo');
    } catch (e) {
      if (kDebugMode) print('Error checking achievements: $e');
    }

    return conquistas;
  }

  /// Verify module completion achievements
  static Future<List<String>> verificarConquistasModuloCompleto({
    required String unidade,
    required String ano,
  }) async {
    // Placeholder for module completion achievements
    return [];
  }
}

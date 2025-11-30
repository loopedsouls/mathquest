import 'package:flutter/foundation.dart';

/// User level enumeration
enum NivelUsuario {
  iniciante,
  basico,
  intermediario,
  avancado,
  especialista,
}

/// Extension for NivelUsuario display name
extension NivelUsuarioExtension on NivelUsuario {
  String get displayName {
    switch (this) {
      case NivelUsuario.iniciante:
        return 'Iniciante';
      case NivelUsuario.basico:
        return 'Básico';
      case NivelUsuario.intermediario:
        return 'Intermediário';
      case NivelUsuario.avancado:
        return 'Avançado';
      case NivelUsuario.especialista:
        return 'Especialista';
    }
  }
}

/// User Progress Model for tracking learning progress
@immutable
class ProgressoUsuario {
  final Map<String, Map<String, bool>> modulosCompletos;
  final NivelUsuario nivelUsuario;
  final Map<String, int> pontosPorUnidade;
  final Map<String, int> exerciciosCorretosConsecutivos;
  final Map<String, double> taxaAcertoPorModulo;
  final DateTime ultimaAtualizacao;
  final int totalExerciciosRespondidos;
  final int totalExerciciosCorretos;

  const ProgressoUsuario({
    this.modulosCompletos = const {},
    this.nivelUsuario = NivelUsuario.iniciante,
    this.pontosPorUnidade = const {},
    this.exerciciosCorretosConsecutivos = const {},
    this.taxaAcertoPorModulo = const {},
    required this.ultimaAtualizacao,
    this.totalExerciciosRespondidos = 0,
    this.totalExerciciosCorretos = 0,
  });

  /// Create empty progress
  factory ProgressoUsuario.empty() {
    return ProgressoUsuario(
      ultimaAtualizacao: DateTime.now(),
    );
  }

  /// Calculate overall progress percentage
  double get progressoGeral {
    if (modulosCompletos.isEmpty) return 0.0;
    
    int totalModulos = 0;
    int modulosCompletados = 0;
    
    for (final unidade in modulosCompletos.values) {
      for (final completo in unidade.values) {
        totalModulos++;
        if (completo) modulosCompletados++;
      }
    }
    
    if (totalModulos == 0) return 0.0;
    return (modulosCompletados / totalModulos) * 100;
  }

  /// Calculate accuracy rate
  double get taxaAcertoGeral {
    if (totalExerciciosRespondidos == 0) return 0.0;
    return (totalExerciciosCorretos / totalExerciciosRespondidos) * 100;
  }

  /// Check if a module is complete
  bool isModuloCompleto(String unidade, String ano) {
    return modulosCompletos[unidade]?[ano] ?? false;
  }

  /// Get points for a unit
  int getPontosUnidade(String unidade) {
    return pontosPorUnidade[unidade] ?? 0;
  }

  /// Get total points
  int get totalPontos {
    return pontosPorUnidade.values.fold(0, (sum, p) => sum + p);
  }

  /// Create from JSON
  factory ProgressoUsuario.fromJson(Map<String, dynamic> json) {
    return ProgressoUsuario(
      modulosCompletos: _parseModulosCompletos(json['modulosCompletos']),
      nivelUsuario: _parseNivelUsuario(json['nivelUsuario']),
      pontosPorUnidade: Map<String, int>.from(json['pontosPorUnidade'] ?? {}),
      exerciciosCorretosConsecutivos: Map<String, int>.from(
        json['exerciciosCorretosConsecutivos'] ?? {},
      ),
      taxaAcertoPorModulo: Map<String, double>.from(
        (json['taxaAcertoPorModulo'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      ultimaAtualizacao: json['ultimaAtualizacao'] != null
          ? DateTime.parse(json['ultimaAtualizacao'])
          : DateTime.now(),
      totalExerciciosRespondidos: json['totalExerciciosRespondidos'] ?? 0,
      totalExerciciosCorretos: json['totalExerciciosCorretos'] ?? 0,
    );
  }

  static Map<String, Map<String, bool>> _parseModulosCompletos(dynamic data) {
    if (data == null) return {};
    return Map<String, Map<String, bool>>.from(
      (data as Map).map(
        (key, value) => MapEntry(
          key as String,
          Map<String, bool>.from(value as Map),
        ),
      ),
    );
  }

  static NivelUsuario _parseNivelUsuario(dynamic data) {
    if (data == null) return NivelUsuario.iniciante;
    if (data is int) {
      return NivelUsuario.values[data.clamp(0, NivelUsuario.values.length - 1)];
    }
    if (data is String) {
      return NivelUsuario.values.firstWhere(
        (e) => e.name == data,
        orElse: () => NivelUsuario.iniciante,
      );
    }
    return NivelUsuario.iniciante;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'modulosCompletos': modulosCompletos,
      'nivelUsuario': nivelUsuario.index,
      'pontosPorUnidade': pontosPorUnidade,
      'exerciciosCorretosConsecutivos': exerciciosCorretosConsecutivos,
      'taxaAcertoPorModulo': taxaAcertoPorModulo,
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
      'totalExerciciosRespondidos': totalExerciciosRespondidos,
      'totalExerciciosCorretos': totalExerciciosCorretos,
    };
  }

  /// Create a copy with updated fields
  ProgressoUsuario copyWith({
    Map<String, Map<String, bool>>? modulosCompletos,
    NivelUsuario? nivelUsuario,
    Map<String, int>? pontosPorUnidade,
    Map<String, int>? exerciciosCorretosConsecutivos,
    Map<String, double>? taxaAcertoPorModulo,
    DateTime? ultimaAtualizacao,
    int? totalExerciciosRespondidos,
    int? totalExerciciosCorretos,
  }) {
    return ProgressoUsuario(
      modulosCompletos: modulosCompletos ?? this.modulosCompletos,
      nivelUsuario: nivelUsuario ?? this.nivelUsuario,
      pontosPorUnidade: pontosPorUnidade ?? this.pontosPorUnidade,
      exerciciosCorretosConsecutivos: exerciciosCorretosConsecutivos ?? 
        this.exerciciosCorretosConsecutivos,
      taxaAcertoPorModulo: taxaAcertoPorModulo ?? this.taxaAcertoPorModulo,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      totalExerciciosRespondidos: totalExerciciosRespondidos ?? 
        this.totalExerciciosRespondidos,
      totalExerciciosCorretos: totalExerciciosCorretos ?? 
        this.totalExerciciosCorretos,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressoUsuario &&
          runtimeType == other.runtimeType &&
          totalExerciciosRespondidos == other.totalExerciciosRespondidos &&
          totalExerciciosCorretos == other.totalExerciciosCorretos;

  @override
  int get hashCode =>
      totalExerciciosRespondidos.hashCode ^ totalExerciciosCorretos.hashCode;
}

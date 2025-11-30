import 'package:flutter/material.dart';

/// Math Course Model
class CursoMatematica {
  final String id;
  final String titulo;
  final String descricao;
  final String unidadeTematica;
  final String anoEscolar;
  final List<TrilhaAprendizado> trilhas;
  final int totalAulas;
  final int aulasCompletas;
  final String? imagemUrl;
  final DateTime? ultimaAtividade;
  final Color cor;
  final IconData icone;
  final String nivel;
  final List<String> competenciasDesenvolvidas;
  final int totalModulos;
  final String duracaoEstimada;

  const CursoMatematica({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.unidadeTematica,
    required this.anoEscolar,
    this.trilhas = const [],
    this.totalAulas = 0,
    this.aulasCompletas = 0,
    this.imagemUrl,
    this.ultimaAtividade,
    this.cor = Colors.blue,
    this.icone = Icons.calculate,
    this.nivel = 'Iniciante',
    this.competenciasDesenvolvidas = const [],
    this.totalModulos = 0,
    this.duracaoEstimada = '0h',
  });

  double get progressoPercentual {
    if (totalAulas == 0) return 0;
    return (aulasCompletas / totalAulas) * 100;
  }

  factory CursoMatematica.fromJson(Map<String, dynamic> json) {
    return CursoMatematica(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      unidadeTematica: json['unidade_tematica'] ?? '',
      anoEscolar: json['ano_escolar'] ?? '',
      trilhas: (json['trilhas'] as List<dynamic>?)
          ?.map((t) => TrilhaAprendizado.fromJson(t))
          .toList() ?? [],
      totalAulas: json['total_aulas'] ?? 0,
      aulasCompletas: json['aulas_completas'] ?? 0,
      imagemUrl: json['imagem_url'],
      ultimaAtividade: json['ultima_atividade'] != null 
        ? DateTime.parse(json['ultima_atividade']) 
        : null,
      nivel: json['nivel'] ?? 'Iniciante',
      competenciasDesenvolvidas: List<String>.from(json['competencias'] ?? []),
      totalModulos: json['total_modulos'] ?? 0,
      duracaoEstimada: json['duracao_estimada'] ?? '0h',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'unidade_tematica': unidadeTematica,
      'ano_escolar': anoEscolar,
      'trilhas': trilhas.map((t) => t.toJson()).toList(),
      'total_aulas': totalAulas,
      'aulas_completas': aulasCompletas,
      'imagem_url': imagemUrl,
      'ultima_atividade': ultimaAtividade?.toIso8601String(),
      'nivel': nivel,
      'competencias': competenciasDesenvolvidas,
      'total_modulos': totalModulos,
      'duracao_estimada': duracaoEstimada,
    };
  }
}

/// Learning Path Model
class TrilhaAprendizado {
  final String id;
  final String titulo;
  final String descricao;
  final List<Aula> aulas;
  final int ordem;
  final bool bloqueada;
  final String? prerequisitoId;
  final Color cor;
  final IconData icone;
  final List<String> modulos;
  final String duracaoEstimada;

  const TrilhaAprendizado({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.aulas = const [],
    this.ordem = 0,
    this.bloqueada = false,
    this.prerequisitoId,
    this.cor = Colors.blue,
    this.icone = Icons.school,
    this.modulos = const [],
    this.duracaoEstimada = '0h',
  });

  bool get completa => aulas.every((a) => a.completa);
  
  double get progressoPercentual {
    if (aulas.isEmpty) return 0;
    final completadas = aulas.where((a) => a.completa).length;
    return (completadas / aulas.length) * 100;
  }

  factory TrilhaAprendizado.fromJson(Map<String, dynamic> json) {
    return TrilhaAprendizado(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      aulas: (json['aulas'] as List<dynamic>?)
          ?.map((a) => Aula.fromJson(a))
          .toList() ?? [],
      ordem: json['ordem'] ?? 0,
      bloqueada: json['bloqueada'] ?? false,
      prerequisitoId: json['prerequisito_id'],
      modulos: List<String>.from(json['modulos'] ?? []),
      duracaoEstimada: json['duracao_estimada'] ?? '0h',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'aulas': aulas.map((a) => a.toJson()).toList(),
      'ordem': ordem,
      'bloqueada': bloqueada,
      'prerequisito_id': prerequisitoId,
      'modulos': modulos,
      'duracao_estimada': duracaoEstimada,
    };
  }
}

/// Lesson Model
class Aula {
  final String id;
  final String titulo;
  final String conteudo;
  final String tipo; // 'video', 'texto', 'exercicio', 'quiz'
  final int duracao; // in minutes
  final bool completa;
  final int pontos;
  final DateTime? dataCompletada;

  const Aula({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.tipo,
    this.duracao = 0,
    this.completa = false,
    this.pontos = 10,
    this.dataCompletada,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      conteudo: json['conteudo'] ?? '',
      tipo: json['tipo'] ?? 'texto',
      duracao: json['duracao'] ?? 0,
      completa: json['completa'] ?? false,
      pontos: json['pontos'] ?? 10,
      dataCompletada: json['data_completada'] != null 
        ? DateTime.parse(json['data_completada']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'tipo': tipo,
      'duracao': duracao,
      'completa': completa,
      'pontos': pontos,
      'data_completada': dataCompletada?.toIso8601String(),
    };
  }
}

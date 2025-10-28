/// Modelos para dados de quiz no módulo de aprendizado
///
/// Este arquivo contém as classes de modelo para representar
/// perguntas, sessões de quiz e respostas do usuário.

/// Representa uma pergunta de quiz
class QuizQuestion {
  final String id;
  final String pergunta;
  final List<String> opcoes;
  final String respostaCorreta;
  final String explicacao;
  final String tipo; // 'multipla_escolha', 'verdadeiro_falso', 'complete_frase'
  final String unidade;
  final String ano;
  final String dificuldade;
  final String? fonte; // 'firebase_ai', 'cache', 'offline'

  const QuizQuestion({
    required this.id,
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorreta,
    required this.explicacao,
    required this.tipo,
    required this.unidade,
    required this.ano,
    required this.dificuldade,
    this.fonte,
  });

  /// Cria uma instância a partir de dados dinâmicos (compatibilidade com código existente)
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      pergunta: map['pergunta'] ?? '',
      opcoes: List<String>.from(map['opcoes'] ?? []),
      respostaCorreta: map['resposta_correta'] ?? '',
      explicacao: map['explicacao'] ?? '',
      tipo: map['tipo'] ?? 'multipla_escolha',
      unidade: map['unidade'] ?? 'Números',
      ano: map['ano'] ?? '7º ano',
      dificuldade: map['dificuldade'] ?? 'médio',
      fonte: map['fonte_ia'] ?? map['fonte'],
    );
  }

  /// Converte para mapa (para compatibilidade)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pergunta': pergunta,
      'opcoes': opcoes,
      'resposta_correta': respostaCorreta,
      'explicacao': explicacao,
      'tipo': tipo,
      'unidade': unidade,
      'ano': ano,
      'dificuldade': dificuldade,
      'fonte': fonte,
    };
  }

  /// Verifica se a resposta fornecida está correta
  bool isCorrect(String resposta) {
    return resposta.trim().toLowerCase() == respostaCorreta.trim().toLowerCase();
  }
}

/// Representa uma resposta do usuário a uma pergunta
class QuizAnswer {
  final String questionId;
  final String respostaSelecionada;
  final bool correta;
  final int tempoResposta; // em segundos
  final DateTime timestamp;

  QuizAnswer({
    required this.questionId,
    required this.respostaSelecionada,
    required this.correta,
    required this.tempoResposta,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory QuizAnswer.create({
    required String questionId,
    required String respostaSelecionada,
    required bool correta,
    required int tempoResposta,
    DateTime? timestamp,
  }) {
    return QuizAnswer(
      questionId: questionId,
      respostaSelecionada: respostaSelecionada,
      correta: correta,
      tempoResposta: tempoResposta,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'respostaSelecionada': respostaSelecionada,
      'correta': correta,
      'tempoResposta': tempoResposta,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Representa uma sessão completa de quiz
class QuizSession {
  final String id;
  final String unidade;
  final String ano;
  final String dificuldade;
  final List<QuizQuestion> perguntas;
  final List<QuizAnswer> respostas;
  final DateTime inicio;
  final DateTime? fim;
  final int pontuacaoTotal;
  final bool isOfflineMode;

  const QuizSession({
    required this.id,
    required this.unidade,
    required this.ano,
    required this.dificuldade,
    required this.perguntas,
    required this.respostas,
    required this.inicio,
    this.fim,
    this.pontuacaoTotal = 0,
    this.isOfflineMode = false,
  });

  /// Calcula a pontuação baseada nas respostas
  int calcularPontuacao() {
    return respostas.where((answer) => answer.correta).length * 10; // 10 pontos por acerto
  }

  /// Calcula a taxa de acerto
  double get taxaAcerto {
    if (perguntas.isEmpty) return 0.0;
    return respostas.where((answer) => answer.correta).length / perguntas.length;
  }

  /// Verifica se o quiz está completo
  bool get isCompleto => respostas.length == perguntas.length;

  /// Tempo total gasto (em segundos)
  int get tempoTotal {
    if (fim == null) return 0;
    return fim!.difference(inicio).inSeconds;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unidade': unidade,
      'ano': ano,
      'dificuldade': dificuldade,
      'perguntas': perguntas.map((q) => q.toMap()).toList(),
      'respostas': respostas.map((r) => r.toMap()).toList(),
      'inicio': inicio.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'pontuacaoTotal': pontuacaoTotal,
      'isOfflineMode': isOfflineMode,
    };
  }
}

/// Estatísticas de performance em um quiz
class QuizStatistics {
  final int totalPerguntas;
  final int corretas;
  final int incorretas;
  final int tempoTotal; // em segundos
  final int pontuacao;
  final double taxaAcerto;

  const QuizStatistics({
    required this.totalPerguntas,
    required this.corretas,
    required this.incorretas,
    required this.tempoTotal,
    required this.pontuacao,
    required this.taxaAcerto,
  });

  factory QuizStatistics.fromSession(QuizSession session) {
    final corretas = session.respostas.where((r) => r.correta).length;
    return QuizStatistics(
      totalPerguntas: session.perguntas.length,
      corretas: corretas,
      incorretas: session.respostas.length - corretas,
      tempoTotal: session.tempoTotal,
      pontuacao: session.calcularPontuacao(),
      taxaAcerto: session.taxaAcerto,
    );
  }
}
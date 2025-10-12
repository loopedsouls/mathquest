import 'package:flutter/material.dart';

/// Mixin para gerenciar estado de carregamento em StatefulWidgets
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  /// Getter para o estado de carregamento
  bool get isLoading => _isLoading;

  /// Setter para o estado de carregamento com setState automático
  set isLoading(bool value) {
    if (mounted && _isLoading != value) {
      setState(() => _isLoading = value);
    }
  }

  /// Executa uma operação assíncrona com gerenciamento automático de loading
  /// Define isLoading = true no início e false no final (sucesso ou erro)
  Future<void> executeWithLoading(Future<void> Function() operation) async {
    isLoading = true;
    try {
      await operation();
    } finally {
      isLoading = false;
    }
  }

  /// Executa uma operação assíncrona com tratamento de erro
  /// Define isLoading = true no início e false no final
  /// Mostra SnackBar de erro se ocorrer exceção
  Future<void> executeWithLoadingAndError(
    Future<void> Function() operation,
    String errorMessage,
  ) async {
    isLoading = true;
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading = false;
    }
  }
}

/// Mixin para gerenciar animações comuns em telas
mixin AnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  AnimationController get animationController => _animationController;
  Animation<double> get fadeAnimation => _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this as TickerProvider,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void startAnimation() {
    _animationController.forward();
  }
}

/// Mixin para gerenciar estado comum dos quizzes
mixin QuizStateMixin<T extends StatefulWidget> on State<T> {
  // Estado comum dos quizzes
  Map<String, dynamic>? perguntaAtual;
  int perguntaIndex = 0;
  bool carregando = true;
  bool quizFinalizado = false;
  bool _useGemini = false;
  String _modeloOllama = 'gemma2:2b';
  Map<String, dynamic> estatisticas = {
    'corretas': 0,
    'total': 0,
    'tempoTotal': 0,
    'tempoMedio': 0,
  };

  // Getters para acesso aos valores
  bool get useGemini => _useGemini;
  String get modeloOllama => _modeloOllama;

  // Setters para modificar valores
  set useGemini(bool value) {
    setState(() => _useGemini = value);
  }

  set modeloOllama(String value) {
    setState(() => _modeloOllama = value);
  }

  // Métodos comuns
  void resetQuiz() {
    setState(() {
      perguntaAtual = null;
      perguntaIndex = 0;
      carregando = true;
      quizFinalizado = false;
      estatisticas = {
        'corretas': 0,
        'total': 0,
        'tempoTotal': 0,
        'tempoMedio': 0,
      };
    });
  }

  void avancarPergunta() {
    setState(() {
      perguntaIndex++;
      perguntaAtual = null;
      carregando = true;
    });
  }

  void finalizarQuiz() {
    setState(() {
      quizFinalizado = true;
      carregando = false;
    });
  }

  void atualizarEstatisticas(bool respostaCorreta, int tempoResposta) {
    setState(() {
      estatisticas['total'] = (estatisticas['total'] as int) + 1;
      if (respostaCorreta) {
        estatisticas['corretas'] = (estatisticas['corretas'] as int) + 1;
      }
      estatisticas['tempoTotal'] =
          (estatisticas['tempoTotal'] as int) + tempoResposta;
      estatisticas['tempoMedio'] =
          (estatisticas['tempoTotal'] as int) ~/ (estatisticas['total'] as int);
    });
  }
}

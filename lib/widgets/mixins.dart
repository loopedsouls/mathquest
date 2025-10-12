import 'package:flutter/material.dart';

/// Mixin para gerenciar estado de carregamento em StatefulWidgets
/// Útil para: Telas que fazem operações assíncronas (carregamento de dados, API calls)
/// Como usar: with LoadingStateMixin
/// Exemplo: await executeWithLoading(() async { /* operação */ });
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
/// Útil para: Telas com animações de entrada/saída, transições suaves
/// Como usar: with TickerProviderStateMixin, AnimationMixin
/// Exemplo: animationController.forward(); fadeAnimation.value
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

/// Mixin para gerenciar formulários com validação
/// Útil para: Telas com formulários, campos de entrada, validação de dados
/// Como usar: with FormMixin
/// Exemplo: submitForm(() async { /* salvar dados */ });
mixin FormMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  set isSubmitting(bool value) {
    setState(() => _isSubmitting = value);
  }

  /// Valida o formulário e executa uma ação se válido
  Future<void> submitForm(Future<void> Function() onSubmit) async {
    if (formKey.currentState?.validate() ?? false) {
      isSubmitting = true;
      try {
        await onSubmit();
      } finally {
        isSubmitting = false;
      }
    }
  }

  /// Reseta o formulário para o estado inicial
  void resetForm() {
    formKey.currentState?.reset();
    setState(() => _isSubmitting = false);
  }

  /// Validação comum para campos obrigatórios
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Validação comum para email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }
}

/// Mixin para gerenciar listas paginadas
/// Útil para: Telas com listas grandes, paginação, scroll infinito
/// Como usar: with ListMixin
/// Exemplo: loadMoreItems(); refreshList();
mixin ListMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  final ScrollController scrollController = ScrollController();

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreData) {
      loadMoreItems();
    }
  }

  /// Carrega a primeira página da lista
  Future<void> loadInitialItems(
      Future<List<dynamic>> Function(int, int) fetchFunction) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
    });

    try {
      final items = await fetchFunction(_currentPage, _pageSize);
      onItemsLoaded(items, isInitialLoad: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega mais itens (próxima página)
  Future<void> loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final items = await fetchMoreItems(_currentPage, _pageSize);
      onItemsLoaded(items, isInitialLoad: false);
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Método abstrato - deve ser implementado pelas subclasses
  Future<List<dynamic>> fetchMoreItems(int page, int pageSize);

  /// Método chamado quando novos itens são carregados
  void onItemsLoaded(List<dynamic> newItems, {required bool isInitialLoad}) {
    if (newItems.length < _pageSize) {
      _hasMoreData = false;
    }
    // Subclasses devem implementar como adicionar os itens à lista
  }

  /// Atualiza a lista completamente
  Future<void> refreshList() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });
    await loadInitialItems(fetchMoreItems);
  }
}

/// Mixin para gerenciar estado comum dos quizzes
/// Útil para: Telas de quiz, testes, avaliações interativas
/// Como usar: with TickerProviderStateMixin, QuizStateMixin, AnimationMixin
/// Exemplo: avancarPergunta(); atualizarEstatisticas(true, 30);
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

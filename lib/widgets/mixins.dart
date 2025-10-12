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

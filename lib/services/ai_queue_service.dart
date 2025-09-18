import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/conversa.dart';
import 'ia_service.dart';

enum GenerationStatus { pending, processing, completed, error, cancelled }

class GenerationRequest {
  final String id;
  final String conversaId;
  final String prompt;
  final String userMessage;
  final DateTime timestamp;
  final Completer<ChatMessage> completer;
  GenerationStatus status;
  String? error;

  GenerationRequest({
    required this.id,
    required this.conversaId,
    required this.prompt,
    required this.userMessage,
    required this.timestamp,
    required this.completer,
    this.status = GenerationStatus.pending,
    this.error,
  });
}

class AIQueueService extends ChangeNotifier {
  static final AIQueueService _instance = AIQueueService._internal();
  factory AIQueueService() => _instance;
  AIQueueService._internal();

  final List<GenerationRequest> _queue = [];
  final Map<String, GenerationRequest> _activeRequests = {};
  bool _isProcessing = false;
  MathTutorService? _tutorService;

  // Getters
  List<GenerationRequest> get queue => List.unmodifiable(_queue);
  Map<String, GenerationRequest> get activeRequests =>
      Map.unmodifiable(_activeRequests);
  bool get isProcessing => _isProcessing;

  /// Inicializa o serviço com o MathTutorService
  void initialize(MathTutorService tutorService) {
    _tutorService = tutorService;
  }

  /// Adiciona uma nova requisição de geração à fila
  Future<ChatMessage> addRequest({
    required String conversaId,
    required String prompt,
    required String userMessage,
    required bool useGemini,
    required String modeloOllama,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<ChatMessage>();

    final request = GenerationRequest(
      id: requestId,
      conversaId: conversaId,
      prompt: prompt,
      userMessage: userMessage,
      timestamp: DateTime.now(),
      completer: completer,
    );

    _queue.add(request);
    _activeRequests[conversaId] = request;

    notifyListeners();

    if (!_isProcessing) {
      _processQueue();
    }

    return completer.future;
  }

  /// Cancela uma requisição específica
  void cancelRequest(String conversaId) {
    // Remove da fila se estiver pendente
    _queue.removeWhere((request) {
      if (request.conversaId == conversaId &&
          request.status == GenerationStatus.pending) {
        request.status = GenerationStatus.cancelled;
        request.completer.completeError('Request cancelled');
        return true;
      }
      return false;
    });

    // Marca como cancelada se estiver processando
    final activeRequest = _activeRequests[conversaId];
    if (activeRequest != null &&
        activeRequest.status == GenerationStatus.processing) {
      activeRequest.status = GenerationStatus.cancelled;
    }

    _activeRequests.remove(conversaId);
    notifyListeners();
  }

  /// Verifica se uma conversa tem requisição ativa
  bool hasActiveRequest(String conversaId) {
    return _activeRequests.containsKey(conversaId);
  }

  /// Obtém o status de uma requisição
  GenerationStatus? getRequestStatus(String conversaId) {
    return _activeRequests[conversaId]?.status;
  }

  /// Processa a fila de requisições
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty || _tutorService == null) return;

    _isProcessing = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final request = _queue.removeAt(0);

      // Verifica se foi cancelada
      if (request.status == GenerationStatus.cancelled) {
        _activeRequests.remove(request.conversaId);
        continue;
      }

      request.status = GenerationStatus.processing;
      notifyListeners();

      try {
        final response =
            await _tutorService!.aiService.generate(request.prompt);

        // Verifica novamente se foi cancelada durante a geração
        if (request.status == GenerationStatus.cancelled) {
          _activeRequests.remove(request.conversaId);
          continue;
        }

        final message = ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          aiProvider: _tutorService!.aiService is GeminiService
              ? 'gemini'
              : (_tutorService!.aiService is FlutterGemmaService
                  ? 'flutter_gemma'
                  : 'ollama'),
        );

        request.status = GenerationStatus.completed;
        request.completer.complete(message);
        _activeRequests.remove(request.conversaId);
      } catch (e) {
        if (request.status != GenerationStatus.cancelled) {
          request.status = GenerationStatus.error;
          request.error = e.toString();

          final errorMessage = ChatMessage(
            text:
                'Desculpe, tive um probleminha para responder. Pode perguntar novamente? 😅',
            isUser: false,
            timestamp: DateTime.now(),
            aiProvider: _tutorService!.aiService is GeminiService
                ? 'gemini'
                : (_tutorService!.aiService is FlutterGemmaService
                    ? 'flutter_gemma'
                    : 'ollama'),
          );

          request.completer.complete(errorMessage);
          _activeRequests.remove(request.conversaId);
        }
      }

      notifyListeners();
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// Limpa todas as requisições
  void clearAll() {
    for (final request in _queue) {
      if (request.status == GenerationStatus.pending) {
        request.status = GenerationStatus.cancelled;
        request.completer.completeError('Queue cleared');
      }
    }

    for (final request in _activeRequests.values) {
      if (request.status == GenerationStatus.processing) {
        request.status = GenerationStatus.cancelled;
      }
    }

    _queue.clear();
    _activeRequests.clear();
    _isProcessing = false;
    notifyListeners();
  }

  /// Obtém informações de debug da fila
  Map<String, dynamic> getQueueInfo() {
    return {
      'queueLength': _queue.length,
      'activeRequests': _activeRequests.length,
      'isProcessing': _isProcessing,
      'pendingRequests':
          _queue.where((r) => r.status == GenerationStatus.pending).length,
      'processingRequests':
          _queue.where((r) => r.status == GenerationStatus.processing).length,
    };
  }
}

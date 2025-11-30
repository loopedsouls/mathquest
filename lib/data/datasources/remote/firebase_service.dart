import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import '../../../core/constants/openai_config.dart';

/// Firebase service for remote data operations
/// Wraps Firebase functionality with platform checks
class FirebaseService {
  FirebaseService._();

  static final FirebaseService _instance = FirebaseService._();
  static FirebaseService get instance => _instance;

  // OpenAI API constants
  static const String _openAIBaseUrl = 'https://api.openai.com/v1';
  static const String _openAIModel = 'gpt-3.5-turbo';

  /// Check if Firebase is available on this platform
  bool get isAvailable {
    if (Platform.isLinux) return false;
    return firebaseAvailable;
  }

  /// Initialize Firebase services
  Future<void> init() async {
    if (!isAvailable) {
      if (kDebugMode) {
        print('Firebase not available on this platform');
      }
      return;
    }

    // Firebase is already initialized in main.dart
    if (kDebugMode) {
      print('FirebaseService initialized');
    }
  }

  // Firestore operations

  /// Get document from Firestore
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    if (!isAvailable) return null;

    try {
      if (kDebugMode) {
        print('Getting document $collection/$documentId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting document: $e');
      }
      return null;
    }
  }

  /// Set document in Firestore
  Future<bool> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    if (!isAvailable) return false;

    try {
      if (kDebugMode) {
        print('Setting document $collection/$documentId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting document: $e');
      }
      return false;
    }
  }

  /// Update document in Firestore
  Future<bool> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    if (!isAvailable) return false;

    try {
      if (kDebugMode) {
        print('Updating document $collection/$documentId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating document: $e');
      }
      return false;
    }
  }

  /// Delete document from Firestore
  Future<bool> deleteDocument(
    String collection,
    String documentId,
  ) async {
    if (!isAvailable) return false;

    try {
      if (kDebugMode) {
        print('Deleting document $collection/$documentId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting document: $e');
      }
      return false;
    }
  }

  /// Query collection
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    String? whereField,
    dynamic isEqualTo,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    if (!isAvailable) return [];

    try {
      if (kDebugMode) {
        print('Querying collection $collection');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error querying collection: $e');
      }
      return [];
    }
  }

  // Firebase Auth operations

  /// Get current user ID
  String? get currentUserId {
    if (!isAvailable) return null;
    return null;
  }

  /// Check if user is signed in
  bool get isSignedIn {
    if (!isAvailable) return false;
    return false;
  }

  // Analytics operations

  /// Log event to Firebase Analytics
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    if (!isAvailable) return;

    try {
      if (kDebugMode) {
        print('Logging event: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging event: $e');
      }
    }
  }

  // Crashlytics operations

  /// Record error to Crashlytics
  Future<void> recordError(dynamic error, StackTrace? stackTrace) async {
    if (!isAvailable) return;

    try {
      if (kDebugMode) {
        print('Recording error: $error');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording to Crashlytics: $e');
      }
    }
  }
}

/// OpenAI-based AI Service (replaces Firebase AI)
class AIService {
  AIService._();

  static final AIService _instance = AIService._();
  static AIService get instance => _instance;

  /// Check if OpenAI API is available
  static bool get isAvailable => OpenAIConfig.isAvailable;

  /// Initialize AI service
  static Future<void> initialize() async {
    if (kDebugMode) {
      if (isAvailable) {
        print('✅ OpenAI API configured successfully');
      } else {
        print('❌ OpenAI API key not configured');
      }
    }
  }

  /// Make a chat completion request
  static Future<String?> _makeChatCompletionRequest(String prompt) async {
    final apiKey = OpenAIConfig.apiKey;
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse('${FirebaseService._openAIBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': FirebaseService._openAIModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        if (kDebugMode) {
          print('OpenAI API error: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI request error: $e');
      }
      return null;
    }
  }

  /// Generate math explanation
  static Future<String?> gerarExplicacaoMatematica({
    required String problema,
    required String ano,
    required String unidade,
  }) async {
    if (!isAvailable) return null;

    try {
      final prompt = '''
      Você é um tutor de matemática especializado no ensino para o $ano do ensino fundamental, 
      focado na unidade temática: $unidade.
      
      Problema: $problema
      
      Por favor, forneça uma explicação didática e passo a passo da solução, 
      usando linguagem apropriada para a idade. Inclua:
      
      1. Explicação conceitual
      2. Passo a passo da resolução
      3. Dica para memorizar
      4. Exemplo similar mais simples (se necessário)
      
      Mantenha a explicação clara, didática e motivadora.
      ''';

      return await _makeChatCompletionRequest(prompt);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating explanation: $e');
      }
      return null;
    }
  }

  /// Generate personalized exercise
  static Future<Map<String, dynamic>?> gerarExercicioPersonalizado({
    required String unidade,
    required String ano,
    required String dificuldade,
    required String tipo,
  }) async {
    if (!isAvailable) return null;

    try {
      final prompt = '''
      Crie um exercício de matemática para o $ano do ensino fundamental.
      
      Especificações:
      - Unidade temática: $unidade
      - Dificuldade: $dificuldade
      - Tipo: $tipo
      
      Formato de resposta em JSON:
      {
        "pergunta": "texto da pergunta",
        "opcoes": ["opção A", "opção B", "opção C", "opção D"],
        "resposta_correta": "resposta correta",
        "explicacao": "explicação passo a passo da solução",
        "dica": "dica útil para resolver"
      }
      
      Certifique-se de que o exercício seja apropriado para a idade e siga a BNCC.
      ''';

      final response = await _makeChatCompletionRequest(prompt);
      if (response == null) return null;

      try {
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}');

        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = response.substring(jsonStart, jsonEnd + 1);
          final parsedJson = json.decode(jsonString) as Map<String, dynamic>;

          if (parsedJson.containsKey('pergunta') &&
              parsedJson.containsKey('resposta_correta') &&
              parsedJson.containsKey('explicacao')) {
            if (tipo == 'multipla_escolha' && !parsedJson.containsKey('opcoes')) {
              return null;
            }
            return parsedJson;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing exercise JSON: $e');
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating exercise: $e');
      }
      return null;
    }
  }

  /// Evaluate student answer
  static Future<String?> avaliarResposta({
    required String pergunta,
    required String respostaEstudante,
    required String respostaCorreta,
    required bool acertou,
    required String ano,
  }) async {
    if (!isAvailable) return null;

    try {
      final prompt = '''
      Você é um tutor de matemática para o $ano do ensino fundamental.
      
      Pergunta: $pergunta
      Resposta do estudante: $respostaEstudante
      Resposta correta: $respostaCorreta
      Resultado: ${acertou ? 'CORRETO' : 'INCORRETO'}
      
      ${acertou ? 'Forneça um elogio motivador e explique brevemente por que a resposta está correta.' : 'Forneça um feedback construtivo, explicando o erro de forma gentil e dando dicas para a próxima tentativa.'}
      
      Use linguagem apropriada para a idade, seja encorajador e educativo.
      Máximo: 150 palavras.
      ''';

      return await _makeChatCompletionRequest(prompt);
    } catch (e) {
      if (kDebugMode) {
        print('Error evaluating answer: $e');
      }
      return null;
    }
  }

  /// Generate hint for a problem
  static Future<String?> gerarDica({
    required String problema,
    required String ano,
    required String unidade,
  }) async {
    if (!isAvailable) return null;

    try {
      final prompt = '''
      Forneça uma dica sutil para ajudar um estudante do $ano a resolver este problema de $unidade:
      
      $problema
      
      A dica deve:
      - Guiar sem dar a resposta completa
      - Ser apropriada para a idade
      - Focar no conceito matemático
      - Ser motivadora
      
      Máximo: 100 palavras.
      ''';

      return await _makeChatCompletionRequest(prompt);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating hint: $e');
      }
      return null;
    }
  }

  /// Send general message to AI
  static Future<String?> sendMessage(String message) async {
    if (!isAvailable) return null;

    try {
      return await _makeChatCompletionRequest(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return null;
    }
  }

  /// Test API connection
  static Future<String?> testarConexao() async {
    if (!isAvailable) {
      return 'OpenAI API not available';
    }

    try {
      return await _makeChatCompletionRequest('Diga "Olá, MathQuest!" em uma frase.');
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  /// Get service status
  static Map<String, dynamic> getStatus() {
    return {
      'openai_api_available': isAvailable,
      'service_initialized': isAvailable,
      'ai_status': 'integrated_with_openai_api',
    };
  }
}

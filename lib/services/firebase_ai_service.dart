import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Serviço para integração com Firebase AI (Gemini e Imagen)
class FirebaseAIService {
  static GenerativeModel? _geminiModel;

  /// Inicializa o Firebase AI
  static Future<void> initialize() async {
    try {
      // Inicializar Firebase AI - será configurado quando a API estiver disponível
      // Por ora, mantemos como placeholder para futuras implementações

      if (kDebugMode) {
        print('🔄 Firebase AI preparado (API em desenvolvimento)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar Firebase AI: $e');
      }
      // Firebase AI pode falhar em algumas plataformas
      // O app deve continuar funcionando normalmente
    }
  }

  /// Verifica se o Firebase AI está disponível
  static bool get isAvailable => _geminiModel != null;

  /// Gera explicação matemática usando Gemini
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

      final response =
          await _geminiModel!.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar explicação: $e');
      }
      return null;
    }
  }

  /// Gera exercício personalizado usando Gemini
  static Future<Map<String, dynamic>?> gerarExercicioPersonalizado({
    required String unidade,
    required String ano,
    required String dificuldade,
    required String tipo, // 'multipla_escolha', 'verdadeiro_falso', 'completar'
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
        "opcoes": ["opção A", "opção B", "opção C", "opção D"], // apenas para múltipla escolha
        "resposta_correta": "resposta correta",
        "explicacao": "explicação passo a passo da solução",
        "dica": "dica útil para resolver"
      }
      
      Certifique-se de que o exercício seja apropriado para a idade e siga a BNCC.
      ''';

      final response =
          await _geminiModel!.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) return null;

      // Tentar extrair JSON da resposta
      try {
        // Procurar por JSON na resposta
        final jsonStart = responseText.indexOf('{');
        final jsonEnd = responseText.lastIndexOf('}');

        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          // TODO: Implementar parsing JSON manual ou usar dart:convert
          // Por ora, retornar null e usar sistema offline como fallback
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao processar JSON do exercício: $e');
        }
      }

      return null; // Fallback para sistema offline
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar exercício personalizado: $e');
      }
      return null;
    }
  }

  /// Avalia resposta do estudante e fornece feedback personalizado
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

      final response =
          await _geminiModel!.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao avaliar resposta: $e');
      }
      return null;
    }
  }

  /// Gera dica personalizada para um problema específico
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

      final response =
          await _geminiModel!.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar dica: $e');
      }
      return null;
    }
  }

  /// Status do serviço para debugging
  static Map<String, dynamic> getStatus() {
    return {
      'gemini_model_available': _geminiModel != null,
      'service_initialized': isAvailable,
      'firebase_ai_status': 'preparado_para_futuras_implementações',
    };
  }
}

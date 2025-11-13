import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../openai_config.dart';

/// Serviço para integração com OpenAI GPT API
class FirebaseAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-3.5-turbo';

  /// Verifica se o OpenAI API está disponível
  static bool get isAvailable => OpenAIConfig.isAvailable;

  /// Inicializa o OpenAI API (não necessário para HTTP calls)
  static Future<void> initialize() async {
    if (kDebugMode) {
      if (isAvailable) {
        print('✅ OpenAI API configurado com sucesso');
      } else {
        print('❌ OpenAI API key não configurada');
      }
    }
  }

  /// Helper method para fazer requisições de chat completion
  static Future<String?> _makeChatCompletionRequest(String prompt) async {
    final apiKey = OpenAIConfig.apiKey;
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
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
        print('Erro na requisição OpenAI: $e');
      }
      return null;
    }
  }

  /// Gera explicação matemática usando OpenAI GPT
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

      final response = await _makeChatCompletionRequest(prompt);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar explicação: $e');
      }
      return null;
    }
  }

  /// Gera exercício personalizado usando OpenAI GPT
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

      final response = await _makeChatCompletionRequest(prompt);

      if (response == null) return null;

      // Tentar extrair JSON da resposta
      try {
        // Procurar por JSON na resposta
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}');

        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = response.substring(jsonStart, jsonEnd + 1);
          final parsedJson = json.decode(jsonString) as Map<String, dynamic>;

          // Validar estrutura básica do JSON
          if (parsedJson.containsKey('pergunta') &&
              parsedJson.containsKey('resposta_correta') &&
              parsedJson.containsKey('explicacao')) {
            // Para múltipla escolha, verificar se tem opções
            if (tipo == 'multipla_escolha' &&
                !parsedJson.containsKey('opcoes')) {
              if (kDebugMode) {
                print('JSON válido mas sem opções para múltipla escolha');
              }
              return null;
            }

            if (kDebugMode) {
              print('✅ JSON do exercício parseado com sucesso');
            }
            return parsedJson;
          } else {
            if (kDebugMode) {
              print('❌ JSON não contém campos obrigatórios');
            }
          }
        } else {
          if (kDebugMode) {
            print('❌ Não foi possível encontrar JSON válido na resposta');
          }
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

      final response = await _makeChatCompletionRequest(prompt);
      return response;
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

      final response = await _makeChatCompletionRequest(prompt);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar dica: $e');
      }
      return null;
    }
  }

  /// Envia uma mensagem geral para o OpenAI GPT
  static Future<String?> sendMessage(String message) async {
    if (!isAvailable) return null;

    try {
      final response = await _makeChatCompletionRequest(message);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao enviar mensagem para OpenAI: $e');
      }
      return null;
    }
  }

  /// Teste básico do OpenAI API
  static Future<String?> testarConexao() async {
    if (!isAvailable) {
      return 'OpenAI API não está disponível';
    }

    try {
      final response = await _makeChatCompletionRequest('Diga "Olá, MathQuest!" em uma frase.');
      return response ?? 'Resposta vazia recebida';
    } catch (e) {
      if (kDebugMode) {
        print('Erro no teste de conexão: $e');
      }
      return 'Erro na conexão: $e';
    }
  }

  /// Status do serviço para debugging
  static Map<String, dynamic> getStatus() {
    return {
      'openai_api_available': isAvailable,
      'service_initialized': isAvailable,
      'ai_status': 'integrado_com_openai_api',
    };
  }
}

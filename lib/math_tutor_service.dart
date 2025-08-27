import 'gemini_service.dart';

class MathTutorService {
  final GeminiService geminiService;

  MathTutorService({String? apiKey}) : geminiService = GeminiService(apiKey: apiKey);

  /// Gera pergunta com base na dificuldade usando Gemini
  Future<String> gerarPergunta(String nivelDificuldade) async {
    final prompt = '''
Crie uma pergunta de matemática de nível $nivelDificuldade. 
A pergunta deve ser clara, direta e apropriada para o nível especificado.
Inclua apenas a pergunta, sem a resposta.

Níveis de dificuldade:
- Fácil: operações básicas (adição, subtração, multiplicação, divisão)
- Médio: frações, percentagens, equações simples
- Difícil: álgebra, geometria, problemas complexos

Responda apenas com a pergunta matemática.
''';
    return await geminiService.generate(prompt);
  }

  /// Gera explicação para resposta errada
  Future<String> gerarExplicacao(String pergunta, String respostaCorreta, String respostaUsuario) async {
    final prompt = '''
O usuário respondeu incorretamente a uma pergunta de matemática.

Pergunta: $pergunta
Resposta correta: $respostaCorreta
Resposta do usuário: $respostaUsuario

Forneça uma explicação clara e didática de:
1. Por que a resposta do usuário está incorreta
2. Como resolver corretamente o problema, passo a passo
3. A resposta correta

Seja encorajador e educativo na explicação.
''';
    return await geminiService.generate(prompt);
  }

  /// Verifica se a resposta está correta e obtém a resposta correta
  Future<Map<String, dynamic>> verificarResposta(String pergunta, String resposta) async {
    final prompt = '''
Pergunta de matemática: "$pergunta"
Resposta do usuário: "$resposta"

Analise se a resposta está correta e forneça a resposta correta.

Responda no seguinte formato JSON:
{
  "correta": true/false,
  "resposta_correta": "valor correto",
  "explicacao_breve": "explicação concisa se estiver incorreta"
}

Seja preciso na análise matemática.
''';
    
    try {
      final resultado = await geminiService.generate(prompt);
      
      // Parse simples da resposta (pode ser melhorado com JSON parsing)
      final isCorrect = resultado.toLowerCase().contains('"correta": true') || 
                       resultado.toLowerCase().contains('correta');
      
      return {
        'correta': isCorrect,
        'resposta_completa': resultado,
      };
    } catch (e) {
      return {
        'correta': false,
        'resposta_completa': 'Erro ao verificar resposta: $e',
      };
    }
  }
}

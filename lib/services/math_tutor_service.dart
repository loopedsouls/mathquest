import 'gemini_service.dart';

class TutorService {
  final GeminiService geminiService;

  TutorService({String? apiKey})
      : geminiService = GeminiService(apiKey: apiKey);

  /// Gera pergunta de qualquer área
  Future<String> gerarPergunta(
      {required String area, required String nivelDificuldade}) async {
    final prompt = '''
Crie uma pergunta de $area de nível $nivelDificuldade.
A pergunta deve ser clara, direta e apropriada para o nível especificado.
Inclua apenas a pergunta, sem a resposta.

Exemplos de áreas:
- Matemática: operações, problemas, lógica
- História: fatos, datas, personagens
- Geografia: capitais, mapas, clima
- Ciências: biologia, física, química
- Língua Portuguesa: gramática, interpretação

Responda apenas com a pergunta.
''';
    return await geminiService.generate(prompt);
  }

  /// Gera explicação para resposta errada de qualquer área
  Future<String> gerarExplicacao(
      {required String area,
      required String pergunta,
      required String respostaCorreta,
      required String respostaUsuario}) async {
    final prompt = '''
O usuário respondeu incorretamente a uma pergunta de $area.

Pergunta: $pergunta
Resposta correta: $respostaCorreta
Resposta do usuário: $respostaUsuario

Forneça uma explicação clara e didática de:
1. Por que a resposta do usuário está incorreta
2. Como chegar à resposta correta, passo a passo
3. A resposta correta

Seja encorajador e educativo na explicação.
''';
    return await geminiService.generate(prompt);
  }

  /// Verifica se a resposta está correta e obtém a resposta correta para qualquer área
  Future<Map<String, dynamic>> verificarResposta(
      {required String area,
      required String pergunta,
      required String resposta}) async {
    final prompt = '''
Pergunta de $area: "$pergunta"
Resposta do usuário: "$resposta"

Analise se a resposta está correta e forneça a resposta correta.

Responda no seguinte formato JSON:
{
  "correta": true/false,
  "resposta_correta": "valor correto",
  "explicacao_breve": "explicação concisa se estiver incorreta"
}

Seja preciso na análise.
''';
    try {
      final resultado = await geminiService.generate(prompt);
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

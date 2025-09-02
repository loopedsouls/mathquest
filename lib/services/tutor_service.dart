import 'gemini_service.dart';

class TutorService {
  final GeminiService geminiService;

  TutorService({String? apiKey})
      : geminiService = GeminiService(apiKey: apiKey);

  Future<Map<String, dynamic>> gerarExercicioMatematico({
    required String prompt,
    required Map<String, dynamic> contexto,
    required String topico,
    required String nivel,
  }) async {
    final fullPrompt = '''
Gere um exercício matemático baseado no seguinte contexto:

$prompt

Responda no formato JSON:
{
  "exercicio": "texto do exercício",
  "opcoes": ["opção1", "opção2", "opção3", "opção4"],
  "resposta_correta": "opção correta"
}
''';

    try {
      final response = await geminiService.generate(fullPrompt);
      // For now, return dummy data; in production, parse JSON from response
      return {
        'exercicio': response.isNotEmpty ? response : 'Exercício gerado',
        'opcoes': ['A', 'B', 'C', 'D'],
      };
    } catch (e) {
      throw Exception('Erro ao gerar exercício: $e');
    }
  }

  Future<Map<String, dynamic>> avaliarResposta(String resposta) async {
    final prompt = '''
Avalie a resposta: $resposta

Responda no formato JSON:
{
  "explicacao": "explicação da resposta",
  "feedback": "feedback positivo ou negativo",
  "dica": "dica adicional"
}
''';

    try {
      final response = await geminiService.generate(prompt);
      return {
        'explicacao': response.isNotEmpty ? response : 'Explicação',
        'feedback': 'Feedback',
        'dica': 'Dica',
      };
    } catch (e) {
      throw Exception('Erro ao avaliar resposta: $e');
    }
  }
}

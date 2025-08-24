import 'ollama_service.dart';

class MathTutorService {
  final OllamaService ollamaService;
  final String modelo;

  MathTutorService({required this.modelo}) : ollamaService = OllamaService();

  /// Garante Ollama e modelo, depois gera pergunta com base na dificuldade
  Future<String> gerarPergunta(String nivelDificuldade) async {
    await ollamaService.ensureOllamaAndModel(modelo);
    final prompt = 'Crie uma pergunta de matemática de nível $nivelDificuldade.';
    return await ollamaService.generate(modelo, prompt);
  }

  /// Gera explicação para resposta errada
  Future<String> gerarExplicacao(String prompt) async {
    await ollamaService.ensureOllamaAndModel(modelo);
    return await ollamaService.generate(modelo, prompt);
  }

  /// Verifica se a resposta está correta
  Future<bool> verificarResposta(String pergunta, String resposta) async {
    final prompt =
        '''A pergunta de matemática era: "$pergunta". A resposta do usuário foi: "$resposta". A resposta está correta ou incorreta? Responda apenas "correta" ou "incorreta".''';
    final resultado = await ollamaService.generate(modelo, prompt);
    return resultado.toLowerCase().contains('correta');
  }
}

import 'ollama_service.dart';

class MathTutorService {
  final OllamaService ollamaService;
  final String modelo;

  MathTutorService({required this.modelo}) : ollamaService = OllamaService();

  /// Garante Ollama e modelo, depois gera pergunta
  Future<String> gerarPergunta(String prompt) async {
    await ollamaService.ensureOllamaAndModel(modelo);
    return await ollamaService.generate(modelo, prompt);
  }

  /// Gera explicação para resposta errada
  Future<String> gerarExplicacao(String prompt) async {
    await ollamaService.ensureOllamaAndModel(modelo);
    return await ollamaService.generate(modelo, prompt);
  }
}

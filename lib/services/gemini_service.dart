import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  late final GenerativeModel _model;
  final String _apiKey;

  GeminiService({String? apiKey})
      : _apiKey = apiKey ?? 'AIzaSyAiNcBfK0i7P6qPuqfhbT3ijZgHJKyW0xo' {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Gera uma resposta usando o modelo Gemini
  Future<String> generate(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Não foi possível gerar uma resposta.';
    } catch (e) {
      throw Exception('Erro ao gerar resposta com Gemini: $e');
    }
  }

  /// Verifica se o serviço está funcionando
  Future<bool> isServiceAvailable() async {
    try {
      await generate('Teste de conexão');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gera conteúdo com configurações específicas
  Future<String> generateWithConfig({
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: temperature ?? 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: maxOutputTokens ?? 1024,
        ),
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Não foi possível gerar uma resposta.';
    } catch (e) {
      throw Exception('Erro ao gerar resposta com Gemini: $e');
    }
  }
}

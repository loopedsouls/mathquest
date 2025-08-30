import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  late final GenerativeModel _model;
  final String _apiKey;
  final String persona;
  final List<String> _history = [];
  final String _cacheKey = 'gemini_cache';

  GeminiService({String? apiKey, this.persona = 'Narrador'})
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

  /// Envia prompt para Gemini, mantendo contexto e cache.
  Future<String> sendPrompt(String prompt) async {
    final fullPrompt = _buildPrompt(prompt);
    // Tenta cache
    final cached = await _getCachedResponse(fullPrompt);
    if (cached != null) return cached;
    try {
      final response = await _model.generateContent([Content.text(fullPrompt)]);
      final text = response.text ?? '';
      await _cacheResponse(fullPrompt, text);
      _history.add(prompt);
      return text;
    } catch (e) {
      // Fallback: retorna mensagem padrão
      return 'Desculpe, não consegui gerar uma resposta agora.';
    }
  }

  /// Faz o parse de uma string JSON para Map<String, dynamic>
  Map<String, dynamic> parseJson(String jsonStr) {
    try {
      return jsonStr.isNotEmpty
          ? Map<String, dynamic>.from(json.decode(jsonStr))
          : {};
    } catch (e) {
      return {};
    }
  }

  /// Monta prompt com contexto/histórico.
  String _buildPrompt(String prompt) {
    final context = _history.join('\n');
    return '$persona:\n$context\nJogador: $prompt';
  }

  /// Cache simples usando shared_preferences.
  Future<void> _cacheResponse(String prompt, String response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey + prompt.hashCode.toString(), response);
  }

  Future<String?> _getCachedResponse(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey + prompt.hashCode.toString());
  }

  /// Verifica se o serviço está funcionando
  Future<bool> isServiceAvailable() async {
    try {
      await sendPrompt('Teste de conexão');
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

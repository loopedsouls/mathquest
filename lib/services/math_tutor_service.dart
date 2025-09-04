import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


class OllamaService implements AIService {
  final String baseUrl;
  final String defaultModel;

  OllamaService(
      {this.baseUrl = 'http://localhost:11434',
      this.defaultModel = 'AUTODETECT'});

  /// Instala o Ollama automaticamente usando winget (Windows)
  Future<void> installOllama() async {
    // Executa o comando winget para instalar Ollama
    // Requer permissões administrativas
    await Process.run(
        'powershell', ['winget', 'install', 'Ollama.Ollama', '-h']);
  }

  /// Instala o modelo desejado via comando Ollama
  Future<void> installModel(String modelName) async {
    await Process.run('powershell', ['ollama', 'pull', modelName]);
  }

  /// Garante que Ollama e o modelo estejam instalados e rodando
  Future<void> ensureOllamaAndModel(String modelName) async {
    if (!await isOllamaRunning()) {
      await installOllama();
    }
    if (!await isModelInstalled(modelName)) {
      await installModel(modelName);
    }
  }

  /// Verifica se Ollama está rodando
  Future<bool> isOllamaRunning() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se um modelo está instalado
  Future<bool> isModelInstalled(String modelName) async {
    final models = await listModels();
    return models.contains(modelName);
  }

  /// Lista os modelos instalados no Ollama
  Future<List<String>> listModels() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tags'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = (data['models'] as List)
          .map((model) => model['name'] as String)
          .toList();
      return models;
    } else {
      throw Exception('Erro ao listar modelos: ${response.body}');
    }
  }

  /// Seleciona um modelo automaticamente (o primeiro instalado)
  Future<String> _selectAutomaticModel() async {
    final models = await listModels();
    if (models.isEmpty) {
      throw Exception('Nenhum modelo disponível para seleção automática');
    }
    return models.first;
  }

  /// Gera uma resposta usando o modelo padrão
  @override
  Future<String> generate(String prompt) async {
    return await generateWithModel(defaultModel, prompt);
  }

  /// Verifica se o serviço está funcionando
  @override
  Future<bool> isServiceAvailable() async {
    return await isOllamaRunning();
  }

  /// Gera uma resposta usando um modelo específico
  Future<String> generateWithModel(String model, String prompt) async {
    if (model == 'AUTODETECT') {
      model = await _selectAutomaticModel();
    }
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': false,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? '';
    } else {
      throw Exception('Erro ao gerar resposta: ${response.body}');
    }
  }
}

abstract class AIService {
  Future<String> generate(String prompt);
  Future<bool> isServiceAvailable();
}
class MathTutorService {
  final AIService aiService;

  MathTutorService({required this.aiService});

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
    return await aiService.generate(prompt);
  }

  /// Gera explicação para resposta errada
  Future<String> gerarExplicacao(
      String pergunta, String respostaCorreta, String respostaUsuario) async {
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
    return await aiService.generate(prompt);
  }

  /// Verifica se a resposta está correta e obtém a resposta correta
  Future<Map<String, dynamic>> verificarResposta(
      String pergunta, String resposta) async {
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
      final resultado = await aiService.generate(prompt);

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
  @override
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
  @override
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

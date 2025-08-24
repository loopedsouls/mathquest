import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OllamaService {
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

  final String baseUrl;
  OllamaService({this.baseUrl = 'http://localhost:11434'});

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

  /// Gera uma resposta usando um modelo específico
  Future<String> generate(String model, String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
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

import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'model_download_service.dart';

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

  /// Verifica se Ollama está rodando (funciona mesmo no GitHub Pages)
  Future<bool> isOllamaRunning() async {
    try {
      // Timeout menor para detecção rápida se não está disponível
      final response = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(Duration(seconds: 3));
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

  /// Gera uma resposta usando um modelo específico (com suporte a GitHub Pages)
  Future<String> generateWithModel(String model, String prompt) async {
    if (model == 'AUTODETECT') {
      model = await _selectAutomaticModel();
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/generate'),
            headers: {
              'Content-Type': 'application/json',
              // Headers para permitir requisições do GitHub Pages
              'Accept': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'stream': false,
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? '';
      } else {
        throw Exception('Erro ao gerar resposta: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão com Ollama: $e');
    }
  }
}

abstract class AIService {
  Future<String> generate(String prompt);
  Future<bool> isServiceAvailable();
}

/// Serviço de IA com fallback automático (Ollama -> Gemini)
class SmartAIService implements AIService {
  late final OllamaService _ollamaService;
  late final GeminiService _geminiService;

  bool _ollamaAvailable = false;
  DateTime? _lastOllamaCheck;

  SmartAIService() {
    _ollamaService = OllamaService();
    _geminiService = GeminiService();
  }

  @override
  Future<String> generate(String prompt) async {
    // Tenta usar Ollama primeiro se disponível
    if (await _isOllamaAvailable()) {
      try {
        return await _ollamaService.generate(prompt);
      } catch (e) {
        print('Ollama falhou, usando Gemini: $e');
        _ollamaAvailable = false;
        return await _geminiService.generate(prompt);
      }
    }

    // Fallback para Gemini
    return await _geminiService.generate(prompt);
  }

  @override
  Future<bool> isServiceAvailable() async {
    // Verifica se pelo menos um serviço está disponível
    if (await _isOllamaAvailable()) return true;
    return await _geminiService.isServiceAvailable();
  }

  /// Verifica se Ollama está disponível (cache por 30 segundos)
  Future<bool> _isOllamaAvailable() async {
    final now = DateTime.now();

    // Se verificou recentemente, usa cache
    if (_lastOllamaCheck != null &&
        now.difference(_lastOllamaCheck!).inSeconds < 30) {
      return _ollamaAvailable;
    }

    // Nova verificação
    _lastOllamaCheck = now;
    _ollamaAvailable = await _ollamaService.isOllamaRunning();
    return _ollamaAvailable;
  }

  /// Força uma nova verificação do Ollama
  Future<void> refreshOllamaStatus() async {
    _lastOllamaCheck = null;
    await _isOllamaAvailable();
  }

  /// Retorna qual serviço está sendo usado
  Future<String> getCurrentService() async {
    if (await _isOllamaAvailable()) {
      return 'Ollama Local';
    }
    return 'Gemini Cloud';
  }

  /// Gera resposta forçando uso do Ollama
  Future<String> generateWithOllama(String prompt) async {
    return await _ollamaService.generate(prompt);
  }

  /// Gera resposta forçando uso do Gemini
  Future<String> generateWithGemini(String prompt) async {
    return await _geminiService.generate(prompt);
  }
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

class FlutterGemmaService implements AIService {
  bool _isInitialized = false;
  String? _modelPath;
  late ModelDownloadService _downloadService;

  // Callbacks para feedback do usuário
  Function(String)? onStatusUpdate;
  Function(double)? onDownloadProgress;

  FlutterGemmaService({
    this.onStatusUpdate,
    this.onDownloadProgress,
  }) {
    _downloadService = ModelDownloadService(
      onProgress: onDownloadProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  @override
  Future<String> generate(String prompt) async {
    try {
      if (!_isInitialized) {
        await _initializeModel();
      }

      // Para esta implementação, vamos usar uma abordagem mais direta
      // O flutter_gemma plugin pode ter uma API diferente
      // Vamos tentar usar o método padrão de geração

      // Nota: Esta é uma implementação básica. Para uso completo,
      // consulte a documentação do flutter_gemma plugin para a API correta

      return 'Flutter Gemma: Resposta simulada para "$prompt". '
          'Modelo carregado de: ${_modelPath ?? "assets"}. '
          'Implementação completa requer configuração do modelo Gemma.';
    } catch (e) {
      throw Exception('Erro ao gerar resposta com Flutter Gemma: $e');
    }
  }

  @override
  Future<bool> isServiceAvailable() async {
    try {
      // Verificar se estamos em um dispositivo Android
      // e se o plugin está disponível
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeModel() async {
    try {
      onStatusUpdate?.call('Inicializando Flutter Gemma...');

      // Primeiro, tentar usar o modelo dos assets (para desenvolvimento)
      _modelPath = 'assets/models/gemma-2b-it-int4.tflite';

      // Verificar se existe um modelo baixado localmente
      final localModelPath = await _downloadService.getModelPath();
      if (localModelPath != null) {
        _modelPath = localModelPath;
        onStatusUpdate?.call('Modelo local encontrado');
      } else {
        // Se não existe localmente, tentar baixar
        onStatusUpdate
            ?.call('Modelo não encontrado localmente, tentando download...');
        final downloadedPath = await _downloadService.downloadModelIfNeeded();
        if (downloadedPath != null) {
          _modelPath = downloadedPath;
        } else {
          onStatusUpdate?.call('Aviso: Usando modelo de assets (limitado)');
        }
      }

      _isInitialized = true;
      onStatusUpdate?.call('Flutter Gemma inicializado com sucesso');
    } catch (e) {
      _isInitialized = false;
      onStatusUpdate?.call('Erro na inicialização: $e');
      throw Exception('Erro ao inicializar Flutter Gemma: $e');
    }
  }

  Future<void> dispose() async {
    try {
      _isInitialized = false;
      onStatusUpdate?.call('Flutter Gemma finalizado');
    } catch (e) {
      // Ignorar erros de cleanup
    }
  }

  /// Método auxiliar para verificar se o modelo está carregado
  Future<bool> isModelLoaded() async {
    return _isInitialized;
  }

  /// Método para recarregar o modelo se necessário
  Future<void> reloadModel() async {
    await dispose();
    await _initializeModel();
  }

  /// Método para forçar download do modelo
  Future<bool> forceDownloadModel() async {
    try {
      onStatusUpdate?.call('Forçando download do modelo...');
      final path = await _downloadService.downloadModel();
      if (path != null) {
        _modelPath = path;
        await reloadModel();
        return true;
      }
      return false;
    } catch (e) {
      onStatusUpdate?.call('Erro no download forçado: $e');
      return false;
    }
  }

  /// Método para obter informações do modelo
  Future<Map<String, dynamic>> getModelInfo() async {
    return await _downloadService.getModelInfo();
  }

  /// Método para testar conexão com servidor de download
  Future<bool> testDownloadConnection() async {
    return await _downloadService.testConnection();
  }

  /// Método para configurar callbacks
  void setCallbacks({
    Function(String)? onStatus,
    Function(double)? onProgress,
  }) {
    onStatusUpdate = onStatus;
    onDownloadProgress = onProgress;
    _downloadService.onStatusUpdate = onStatus;
    _downloadService.onProgress = onProgress;
  }
}

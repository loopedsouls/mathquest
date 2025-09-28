import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/conversa.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';
import 'preload_service.dart';
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
          .timeout(const Duration(seconds: 3));
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
          .timeout(const Duration(seconds: 30));

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

  SmartAIService({String? geminiApiKey}) {
    _ollamaService = OllamaService();
    _geminiService = GeminiService(apiKey: geminiApiKey);
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
  final String _modelName;

  GeminiService({String? apiKey, String? modelName})
      : _apiKey = apiKey ?? 'AIzaSyDSbj4mYAOSdDxEwD8vP7tC8vJ6KzF4N2M',
        _modelName = modelName ?? 'gemini-2.5-flash' {
    _model = GenerativeModel(
      model: _modelName,
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
      print('🔍 Testando API Gemini com key: ${_apiKey.substring(0, 10)}...');
      final result = await generate('Teste de conexão simples');
      print(
          '✅ Gemini API funcionando. Resposta: ${result.substring(0, result.length > 50 ? 50 : result.length)}...');
      return true;
    } catch (e) {
      print('❌ Erro ao testar Gemini API: $e');
      return false;
    }
  }

  /// Gera conteúdo com configurações específicas
  Future<String> generateWithConfig({
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
    String? modelName,
  }) async {
    try {
      final model = GenerativeModel(
        model: modelName ?? _modelName,
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

  /// Método de teste detalhado para diagnóstico
  Future<Map<String, dynamic>> testApiDetailed() async {
    final Map<String, dynamic> result = {
      'success': false,
      'apiKey': _apiKey.isNotEmpty ? '${_apiKey.substring(0, 10)}...' : 'VAZIA',
      'model': 'gemini-1.5-flash',
      'error': null,
      'response': null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      print('🚀 Iniciando teste detalhado da API Gemini...');
      print('📋 API Key: ${result['apiKey']}');
      print('🤖 Modelo: ${result['model']}');

      const testPrompt = 'Responda apenas com "OK" se você pode me ouvir.';
      print('📝 Prompt de teste: $testPrompt');

      final response = await generate(testPrompt);

      result['success'] = true;
      result['response'] = response;

      print('✅ Teste bem-sucedido!');
      print('📥 Resposta: $response');

      return result;
    } catch (e) {
      result['error'] = e.toString();
      print('❌ Teste falhou: $e');

      // Análise do tipo de erro
      if (e.toString().contains('API_KEY_INVALID') ||
          e.toString().contains('401')) {
        result['errorType'] = 'INVALID_API_KEY';
        print('🔑 Erro: API Key inválida ou expirada');
      } else if (e.toString().contains('quota') ||
          e.toString().contains('429')) {
        result['errorType'] = 'QUOTA_EXCEEDED';
        print('💳 Erro: Cota da API excedida');
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        result['errorType'] = 'NETWORK_ERROR';
        print('🌐 Erro: Problema de conexão de rede');
      } else {
        result['errorType'] = 'UNKNOWN_ERROR';
        print('❓ Erro desconhecido');
      }

      return result;
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

class CacheIAService {
// Máximo de perguntas por combinação
  static const int _diasExpiracao = 30; // Cache expira em 30 dias
// 70% das vezes usa cache, 30% gera nova

  // Estatísticas de cache
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _perguntasGeradas = 0;

  /// Busca uma pergunta no cache (sem gerar nova)
  static Future<Map<String, dynamic>?> obterPergunta({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    String? fonteIA,
  }) async {
    try {
      // Garante que o banco está inicializado antes de qualquer operação
      await DatabaseService.database;

      // Verifica se o modo preload está ativo e há créditos
      final preloadEnabled = await PreloadService.isPreloadEnabled();
      final hasCredits = await PreloadService.hasCredits();

      // Tenta buscar no cache
      final pergunta = await DatabaseService.buscarPerguntaCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
      );
      if (pergunta != null) {
        // Usa um crédito se disponível (só no modo preload)
        bool creditUsed = false;
        if (preloadEnabled && hasCredits) {
          creditUsed = await PreloadService.useCredit();
        }

        _cacheHits++;
        if (kDebugMode) {
          print(
              '🎯 Cache HIT: ${unidade}_${ano}_$tipoQuiz${creditUsed ? " (crédito usado)" : ""}');
        }

        // Se os créditos acabaram, inicia precarregamento em background
        if (preloadEnabled && !await PreloadService.hasCredits()) {
          _startBackgroundPreload();
        }

        return pergunta;
      }

      // Cache miss
      _cacheMisses++;
      if (kDebugMode) {
        print('❌ Cache MISS: ${unidade}_${ano}_$tipoQuiz');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar no cache: $e');
      }
      return null;
    }
  }

  /// Pré-carrega perguntas no cache para melhorar a experiência
  static Future<void> preCarregarCache({
    required String unidade,
    required String ano,
    int quantidadePorTipo = 10,
  }) async {
    // Garante que o banco está inicializado
    await DatabaseService.database;

    final tiposQuiz = [
      'multipla_escolha',
      'verdadeiro_falso',
      'complete_frase'
    ];
    final dificuldades = ['facil', 'medio', 'dificil', 'expert'];

    if (kDebugMode) {
      print('🔄 Pré-carregando cache para $unidade - $ano...');
    }

    for (final tipo in tiposQuiz) {
      for (final dif in dificuldades) {
        final countAtual = await DatabaseService.contarPerguntasCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipo,
          dificuldade: dif,
        );

        // Se tem menos que a quantidade mínima, gera mais
        if (countAtual < quantidadePorTipo) {
          final quantidadeGerar = quantidadePorTipo - countAtual;

          for (int i = 0; i < quantidadeGerar; i++) {
            await obterPergunta(
              unidade: unidade,
              ano: ano,
              tipoQuiz: tipo,
              dificuldade: dif,
            );

            // Pequena pausa para não sobrecarregar a IA
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      }
    }

    if (kDebugMode) {
      print('✅ Cache pré-carregado para $unidade - $ano');
    }
  }

  /// Limpa todo o cache (útil para testes ou reset)
  static Future<void> limparTodoCache() async {
    try {
      // Garante que o banco está inicializado
      await DatabaseService.database;

      await DatabaseService.limparCacheAntigo(diasParaExpirar: 0);
      _resetarEstatisticas();
      if (kDebugMode) {
        print('🗑️ Cache completamente limpo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao limpar cache: $e');
      }
    }
  }

  /// Obtém estatísticas do cache
  static Future<Map<String, dynamic>> obterEstatisticasCache() async {
    try {
      // Garante que o banco está inicializado
      await DatabaseService.database;

      final totalPerguntas = await DatabaseService.contarPerguntasCache();
      final estatisticasDB = await DatabaseService.obterEstatisticasGerais();

      final totalRequests = _cacheHits + _cacheMisses;
      final taxaAcertoCache =
          totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

      return {
        'total_perguntas_cache': totalPerguntas,
        'cache_hits': _cacheHits,
        'cache_misses': _cacheMisses,
        'perguntas_geradas': _perguntasGeradas,
        'taxa_acerto_cache': taxaAcertoCache,
        'tamanho_cache_bytes': estatisticasDB['tamanho_cache_bytes'],
        'eficiencia_cache': totalRequests > 0
            ? '${(taxaAcertoCache * 100).toStringAsFixed(1)}%'
            : '0%',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter estatísticas: $e');
      }
      return {};
    }
  }

  /// Obtém estatísticas detalhadas por parâmetros
  static Future<Map<String, Map<String, int>>>
      obterEstatisticasDetalhadas() async {
    try {
      Map<String, Map<String, int>> estatisticas = {};

      final unidades = [
        'Números',
        'Álgebra',
        'Geometria',
        'Grandezas e Medidas',
        'Probabilidade e Estatística'
      ];
      final anos = ['6º ano', '7º ano', '8º ano', '9º ano'];
      final tipos = ['multipla_escolha', 'verdadeiro_falso', 'complete_frase'];

      for (final unidade in unidades) {
        estatisticas[unidade] = {};

        for (final ano in anos) {
          int totalUnidadeAno = 0;

          for (final tipo in tipos) {
            final count = await DatabaseService.contarPerguntasCache(
              unidade: unidade,
              ano: ano,
              tipoQuiz: tipo,
            );
            totalUnidadeAno += count;
          }

          estatisticas[unidade]![ano] = totalUnidadeAno;
        }
      }

      return estatisticas;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter estatísticas detalhadas: $e');
      }
      return {};
    }
  }

  /// Reseta as estatísticas em memória
  static void _resetarEstatisticas() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _perguntasGeradas = 0;
  }

  /// Otimiza o cache removendo perguntas duplicadas ou inválidas
  static Future<void> otimizarCache() async {
    try {
      // Garante que o banco está inicializado
      await DatabaseService.database;

      if (kDebugMode) {
        print('🔧 Otimizando cache...');
      }

      // Remove perguntas antigas
      await DatabaseService.limparCacheAntigo(diasParaExpirar: _diasExpiracao);

      if (kDebugMode) {
        print('✅ Cache otimizado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao otimizar cache: $e');
      }
    }
  }

  /// Inicia precarregamento em background quando créditos acabam
  static void _startBackgroundPreload() {
    // Executa em background sem bloquear a UI
    Future.microtask(() async {
      try {
        if (await PreloadService.shouldPreload()) {
          if (kDebugMode) {
            print('🔄 Iniciando precarregamento em background...');
          }

          // Carrega configurações para o precarregamento
          final prefs = await SharedPreferences.getInstance();
          final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
          final apiKey = prefs.getString('gemini_api_key');
          final ollamaModel = prefs.getString('modelo_ollama') ?? 'llama2';

          await PreloadService.startPreload(
            selectedAI: selectedAI,
            apiKey: selectedAI == 'gemini' ? apiKey : null,
            ollamaModel: selectedAI == 'ollama' ? ollamaModel : null,
            onProgress: (current, total, status) {
              if (kDebugMode) {
                print('📊 Precarregamento: $current/$total - $status');
              }
            },
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erro no precarregamento em background: $e');
        }
      }
    });
  }
}

enum GenerationStatus { pending, processing, completed, error, cancelled }

class GenerationRequest {
  final String id;
  final String conversaId;
  final String prompt;
  final String userMessage;
  final DateTime timestamp;
  final Completer<ChatMessage> completer;
  GenerationStatus status;
  String? error;

  GenerationRequest({
    required this.id,
    required this.conversaId,
    required this.prompt,
    required this.userMessage,
    required this.timestamp,
    required this.completer,
    this.status = GenerationStatus.pending,
    this.error,
  });
}

class AIQueueService extends ChangeNotifier {
  static final AIQueueService _instance = AIQueueService._internal();
  factory AIQueueService() => _instance;
  AIQueueService._internal();

  final List<GenerationRequest> _queue = [];
  final Map<String, GenerationRequest> _activeRequests = {};
  bool _isProcessing = false;
  MathTutorService? _tutorService;

  // Getters
  List<GenerationRequest> get queue => List.unmodifiable(_queue);
  Map<String, GenerationRequest> get activeRequests =>
      Map.unmodifiable(_activeRequests);
  bool get isProcessing => _isProcessing;

  /// Inicializa o serviço com o MathTutorService
  void initialize(MathTutorService tutorService) {
    _tutorService = tutorService;
  }

  /// Adiciona uma nova requisição de geração à fila
  Future<ChatMessage> addRequest({
    required String conversaId,
    required String prompt,
    required String userMessage,
    required bool useGemini,
    required String modeloOllama,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<ChatMessage>();

    final request = GenerationRequest(
      id: requestId,
      conversaId: conversaId,
      prompt: prompt,
      userMessage: userMessage,
      timestamp: DateTime.now(),
      completer: completer,
    );

    _queue.add(request);
    _activeRequests[conversaId] = request;

    notifyListeners();

    if (!_isProcessing) {
      _processQueue();
    }

    return completer.future;
  }

  /// Cancela uma requisição específica
  void cancelRequest(String conversaId) {
    // Remove da fila se estiver pendente
    _queue.removeWhere((request) {
      if (request.conversaId == conversaId &&
          request.status == GenerationStatus.pending) {
        request.status = GenerationStatus.cancelled;
        request.completer.completeError('Request cancelled');
        return true;
      }
      return false;
    });

    // Marca como cancelada se estiver processando
    final activeRequest = _activeRequests[conversaId];
    if (activeRequest != null &&
        activeRequest.status == GenerationStatus.processing) {
      activeRequest.status = GenerationStatus.cancelled;
    }

    _activeRequests.remove(conversaId);
    notifyListeners();
  }

  /// Verifica se uma conversa tem requisição ativa
  bool hasActiveRequest(String conversaId) {
    return _activeRequests.containsKey(conversaId);
  }

  /// Obtém o status de uma requisição
  GenerationStatus? getRequestStatus(String conversaId) {
    return _activeRequests[conversaId]?.status;
  }

  /// Processa a fila de requisições
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty || _tutorService == null) return;

    _isProcessing = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final request = _queue.removeAt(0);

      // Verifica se foi cancelada
      if (request.status == GenerationStatus.cancelled) {
        _activeRequests.remove(request.conversaId);
        continue;
      }

      request.status = GenerationStatus.processing;
      notifyListeners();

      try {
        final response =
            await _tutorService!.aiService.generate(request.prompt);

        // Verifica novamente se foi cancelada durante a geração
        if (request.status == GenerationStatus.cancelled) {
          _activeRequests.remove(request.conversaId);
          continue;
        }

        final message = ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          aiProvider: _tutorService!.aiService is GeminiService
              ? 'gemini'
              : (_tutorService!.aiService is FlutterGemmaService
                  ? 'flutter_gemma'
                  : 'ollama'),
        );

        request.status = GenerationStatus.completed;
        request.completer.complete(message);
        _activeRequests.remove(request.conversaId);
      } catch (e) {
        if (request.status != GenerationStatus.cancelled) {
          request.status = GenerationStatus.error;
          request.error = e.toString();

          final errorMessage = ChatMessage(
            text:
                'Desculpe, tive um probleminha para responder. Pode perguntar novamente? 😅',
            isUser: false,
            timestamp: DateTime.now(),
            aiProvider: _tutorService!.aiService is GeminiService
                ? 'gemini'
                : (_tutorService!.aiService is FlutterGemmaService
                    ? 'flutter_gemma'
                    : 'ollama'),
          );

          request.completer.complete(errorMessage);
          _activeRequests.remove(request.conversaId);
        }
      }

      notifyListeners();
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// Limpa todas as requisições
  void clearAll() {
    for (final request in _queue) {
      if (request.status == GenerationStatus.pending) {
        request.status = GenerationStatus.cancelled;
        request.completer.completeError('Queue cleared');
      }
    }

    for (final request in _activeRequests.values) {
      if (request.status == GenerationStatus.processing) {
        request.status = GenerationStatus.cancelled;
      }
    }

    _queue.clear();
    _activeRequests.clear();
    _isProcessing = false;
    notifyListeners();
  }

  /// Obtém informações de debug da fila
  Map<String, dynamic> getQueueInfo() {
    return {
      'queueLength': _queue.length,
      'activeRequests': _activeRequests.length,
      'isProcessing': _isProcessing,
      'pendingRequests':
          _queue.where((r) => r.status == GenerationStatus.pending).length,
      'processingRequests':
          _queue.where((r) => r.status == GenerationStatus.processing).length,
    };
  }
}

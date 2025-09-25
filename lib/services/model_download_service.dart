import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Serviço responsável por baixar e gerenciar modelos de IA
class ModelDownloadService {
  static const String gemmaModelUrl =
      'https://huggingface.co/google/gemma-2b-it/resolve/main/gemma-2b-it-int4.tflite';
  static const String modelFileName = 'gemma-2b-it-int4.tflite';

  /// Callback para progresso do download
  Function(double)? onProgress;

  /// Callback para mensagens de status
  Function(String)? onStatusUpdate;

  ModelDownloadService({
    this.onProgress,
    this.onStatusUpdate,
  });

  /// Verifica se o modelo já existe localmente
  Future<bool> isModelDownloaded() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/$modelFileName';
      final file = File(modelPath);
      return await file.exists();
    } catch (e) {
      onStatusUpdate?.call('Erro ao verificar modelo: $e');
      return false;
    }
  }

  /// Obtém o caminho local do modelo
  Future<String?> getModelPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/$modelFileName';
      final file = File(modelPath);

      if (await file.exists()) {
        return modelPath;
      }
      return null;
    } catch (e) {
      onStatusUpdate?.call('Erro ao obter caminho do modelo: $e');
      return null;
    }
  }

  /// Baixa o modelo Gemma se não existir
  Future<String?> downloadModelIfNeeded() async {
    // Primeiro verifica se já existe
    final existingPath = await getModelPath();
    if (existingPath != null) {
      onStatusUpdate?.call('Modelo já existe localmente');
      return existingPath;
    }

    // Se não existe, baixa
    return await downloadModel();
  }

  /// Baixa o modelo Gemma
  Future<String?> downloadModel() async {
    try {
      onStatusUpdate?.call('Iniciando download do modelo Gemma...');

      // Criar diretório se não existir
      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final modelPath = '${modelsDir.path}/$modelFileName';

      // Fazer requisição HEAD primeiro para obter tamanho
      onStatusUpdate?.call('Verificando tamanho do arquivo...');
      final headResponse = await http.head(Uri.parse(gemmaModelUrl));

      if (headResponse.statusCode != 200) {
        throw Exception('Erro ao acessar o modelo: ${headResponse.statusCode}');
      }

      final contentLength = headResponse.headers['content-length'];
      final totalBytes =
          contentLength != null ? int.parse(contentLength) : null;

      onStatusUpdate
          ?.call('Baixando modelo (${_formatBytes(totalBytes ?? 0)})...');

      // Baixar o arquivo
      final request = http.Request('GET', Uri.parse(gemmaModelUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Erro no download: ${response.statusCode}');
      }

      // Salvar arquivo com progresso
      final file = File(modelPath);
      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes != null && totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;
          onProgress?.call(progress);
        }
      }

      await sink.close();

      // Verificar se o arquivo foi baixado corretamente
      final downloadedFile = File(modelPath);
      if (!await downloadedFile.exists()) {
        throw Exception('Arquivo não foi criado');
      }

      final fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        throw Exception('Arquivo baixado está vazio');
      }

      onStatusUpdate
          ?.call('Modelo baixado com sucesso! (${_formatBytes(fileSize)})');
      onProgress?.call(1.0);

      return modelPath;
    } catch (e) {
      onStatusUpdate?.call('Erro no download: $e');
      onProgress?.call(0.0);
      return null;
    }
  }

  /// Remove o modelo baixado
  Future<bool> deleteModel() async {
    try {
      final modelPath = await getModelPath();
      if (modelPath != null) {
        final file = File(modelPath);
        await file.delete();
        onStatusUpdate?.call('Modelo removido com sucesso');
        return true;
      }
      return false;
    } catch (e) {
      onStatusUpdate?.call('Erro ao remover modelo: $e');
      return false;
    }
  }

  /// Obtém informações sobre o modelo
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final modelPath = await getModelPath();
      if (modelPath == null) {
        return {
          'exists': false,
          'path': null,
          'size': 0,
          'sizeFormatted': '0 B',
        };
      }

      final file = File(modelPath);
      final size = await file.length();

      return {
        'exists': true,
        'path': modelPath,
        'size': size,
        'sizeFormatted': _formatBytes(size),
        'lastModified': await file.lastModified(),
      };
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  /// Formata bytes para formato legível
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes == 0) ? 0 : (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (10 * i));

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[i]}';
  }

  /// Testa a conectividade com o servidor de download
  Future<bool> testConnection() async {
    try {
      onStatusUpdate?.call('Testando conexão...');
      final response = await http
          .head(Uri.parse(gemmaModelUrl))
          .timeout(const Duration(seconds: 10));

      final success = response.statusCode == 200;
      onStatusUpdate?.call(success ? 'Conexão OK' : 'Erro de conexão');
      return success;
    } catch (e) {
      onStatusUpdate?.call('Erro de conexão: $e');
      return false;
    }
  }
}

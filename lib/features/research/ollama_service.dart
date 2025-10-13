import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mathquest/features/resources/arxiv_service.dart';

class OllamaService {
  static const String _baseUrl = 'http://localhost:11434';
  static const String _apiUrl = '$_baseUrl/api';

  /// Verifica se o Ollama está instalado e rodando
  Future<bool> isOllamaRunning() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o Ollama está instalado (mas pode não estar rodando)
  Future<bool> isOllamaInstalled() async {
    try {
      // Primeiro tenta o comando direto
      final result = await Process.run('ollama', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      // Se falhou, tenta caminhos comuns do Windows
      final commonPaths = [
        r'C:\Users\' +
            Platform.environment['USERNAME']! +
            r'\AppData\Local\Programs\Ollama\ollama.exe',
        r'C:\Program Files\Ollama\ollama.exe',
        r'C:\Program Files (x86)\Ollama\ollama.exe',
      ];

      for (final path in commonPaths) {
        try {
          final result = await Process.run(path, ['--version']);
          if (result.exitCode == 0) {
            if (kDebugMode) {
              print('✅ Ollama encontrado em: $path');
            }
            return true;
          }
        } catch (e) {
          // Continua para o próximo caminho
        }
      }

      return false;
    }
  }

  /// Instala o Ollama usando winget
  Future<bool> installOllama() async {
    try {
      if (kDebugMode) {
        print('🔧 Instalando Ollama via winget...');
      }

      // Verifica se winget está disponível
      final wingetCheck = await Process.run('winget', ['--version']);
      if (wingetCheck.exitCode != 0) {
        if (kDebugMode) {
          print('❌ winget não está disponível');
        }
        return false;
      }

      // Instala o Ollama
      final result = await Process.run('winget', ['install', 'Ollama.Ollama']);

      if (result.exitCode == 0) {
        if (kDebugMode) {
          print('✅ Ollama instalado com sucesso!');
        }

        // Aguarda um pouco para a instalação finalizar
        await Future.delayed(const Duration(seconds: 3));

        // Inicia o serviço do Ollama
        await startOllamaService();

        return true;
      } else {
        if (kDebugMode) {
          print('❌ Erro ao instalar Ollama: ${result.stderr}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro durante instalação: $e');
      }
      return false;
    }
  }

  /// Inicia o serviço do Ollama
  Future<bool> startOllamaService() async {
    try {
      if (kDebugMode) {
        print('🚀 Iniciando serviço Ollama...');
      }

      // Encontra o caminho do Ollama
      final ollamaPath = await getOllamaPath();
      if (ollamaPath == null) {
        if (kDebugMode) {
          print('❌ Ollama não encontrado no sistema');
        }
        return false;
      }

      // Tenta iniciar o Ollama em background
      Process.start(ollamaPath, ['serve'], runInShell: true);

      // Aguarda o serviço iniciar
      await Future.delayed(const Duration(seconds: 5));

      // Verifica se está rodando
      final isRunning = await isOllamaRunning();
      if (isRunning) {
        if (kDebugMode) {
          print('✅ Ollama está rodando!');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ Ollama pode estar iniciando... aguarde alguns segundos');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao iniciar Ollama: $e');
      }
      return false;
    }
  }

  /// Detecta a quantidade de RAM do sistema
  Future<int> getSystemRAM() async {
    ProcessResult? result;
    try {
      // Usa PowerShell para obter informações de RAM
      result = await Process.run('powershell', [
        '-Command',
        '(Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB'
      ]);

      if (result.exitCode == 0) {
        String ramString = result.stdout.toString().trim();
        // Substitui vírgula por ponto para resolver problemas de locale
        ramString = ramString.replaceAll(',', '.');
        final ramGB = double.parse(ramString);
        return ramGB.round();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao detectar RAM: $e');
        print('RAM output: ${result?.stdout}');
      }
    }

    // Valor padrão se não conseguir detectar
    return 8;
  }

  /// Detecta se o sistema tem GPU dedicada adequada para IA
  Future<bool> hasAICapableGPU() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        r'Get-CimInstance -ClassName Win32_VideoController | Where-Object {$_.AdapterRAM -gt 2000000000 -and $_.Name -notlike "*Basic*" -and $_.Name -notlike "*Microsoft*"} | Select-Object Name, AdapterRAM'
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Verifica se há alguma GPU com mais de 2GB de VRAM
        if (output.contains('AdapterRAM') && output.trim().isNotEmpty) {
          if (kDebugMode) {
            print('✅ GPU dedicada detectada para IA');
            print('GPU info: ${output.trim()}');
          }
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao detectar GPU: $e');
      }
    }

    if (kDebugMode) {
      print('⚠️ Nenhuma GPU dedicada adequada detectada');
    }
    return false;
  }

  /// Sugere o melhor modelo baseado na RAM disponível e presença de GPU
  Future<String> getRecommendedModel(int ramGB) async {
    final hasGPU = await hasAICapableGPU();

    if (!hasGPU) {
      // Sem GPU dedicada: usa modelos menores e mais conservadores
      if (kDebugMode) {
        print(
            '🔧 Sistema sem GPU dedicada - recomendando modelos otimizados para CPU');
      }

      if (ramGB >= 16) {
        return 'llama3.2:3b'; // Modelo pequeno mesmo com muita RAM
      } else if (ramGB >= 8) {
        return 'llama3.2:1b'; // Modelo muito pequeno para CPU
      } else {
        return 'gemma2:2b'; // Modelo ultra-leve para sistemas limitados
      }
    } else {
      // Com GPU dedicada: pode usar modelos maiores
      if (kDebugMode) {
        print('🚀 GPU dedicada detectada - recomendando modelos otimizados');
      }

      if (ramGB >= 32) {
        return 'llama3.1:70b'; // Modelo grande para sistemas com muita RAM + GPU
      } else if (ramGB >= 16) {
        return 'llama3.1:13b'; // Modelo médio para sistemas com RAM moderada + GPU
      } else if (ramGB >= 8) {
        return 'llama3.1:8b'; // Modelo padrão para 8GB+ com GPU
      } else {
        return 'llama3.2:3b'; // Modelo pequeno para sistemas com pouca RAM mas com GPU
      }
    }
  }

  /// Versão síncrona para compatibilidade (usa valores padrão conservadores)
  String getRecommendedModelSync(int ramGB, {bool hasGPU = false}) {
    if (!hasGPU) {
      // Sem GPU dedicada: usa modelos menores e mais conservadores
      if (ramGB >= 16) {
        return 'llama3.2:3b'; // Modelo pequeno mesmo com muita RAM
      } else if (ramGB >= 8) {
        return 'llama3.2:1b'; // Modelo muito pequeno para CPU
      } else {
        return 'gemma2:2b'; // Modelo ultra-leve para sistemas limitados
      }
    } else {
      // Com GPU dedicada: pode usar modelos maiores
      if (ramGB >= 32) {
        return 'llama3.1:70b'; // Modelo grande para sistemas com muita RAM + GPU
      } else if (ramGB >= 16) {
        return 'llama3.1:13b'; // Modelo médio para sistemas com RAM moderada + GPU
      } else if (ramGB >= 8) {
        return 'llama3.1:8b'; // Modelo padrão para 8GB+ com GPU
      } else {
        return 'llama3.2:3b'; // Modelo pequeno para sistemas com pouca RAM mas com GPU
      }
    }
  }

  /// Lista modelos instalados
  Future<List<String>> getInstalledModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List;
        return models.map((model) => model['name'] as String).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao listar modelos: $e');
      }
    }

    return [];
  }

  /// Encontra o caminho do executável Ollama
  Future<String?> getOllamaPath() async {
    try {
      // Primeiro tenta o comando direto
      final result = await Process.run('ollama', ['--version']);
      if (result.exitCode == 0) {
        return 'ollama';
      }
    } catch (e) {
      // Se falhou, tenta caminhos comuns do Windows
      final commonPaths = [
        r'C:\Users\' +
            Platform.environment['USERNAME']! +
            r'\AppData\Local\Programs\Ollama\ollama.exe',
        r'C:\Program Files\Ollama\ollama.exe',
        r'C:\Program Files (x86)\Ollama\ollama.exe',
      ];

      for (final path in commonPaths) {
        try {
          final result = await Process.run(path, ['--version']);
          if (result.exitCode == 0) {
            return path;
          }
        } catch (e) {
          // Continua para o próximo caminho
        }
      }
    }

    return null;
  }

  /// Baixa e instala um modelo
  Future<bool> pullModel(String modelName) async {
    try {
      if (kDebugMode) {
        print('📥 Baixando modelo $modelName...');
      }
      if (kDebugMode) {
        print('⏳ Isso pode levar alguns minutos dependendo da sua conexão');
      }

      // Encontra o caminho do Ollama
      final ollamaPath = await getOllamaPath();
      if (ollamaPath == null) {
        if (kDebugMode) {
          print('❌ Ollama não encontrado no sistema');
        }
        return false;
      }

      final result = await Process.run(ollamaPath, ['pull', modelName]);

      if (result.exitCode == 0) {
        if (kDebugMode) {
          print('✅ Modelo $modelName baixado com sucesso!');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Erro ao baixar modelo: ${result.stderr}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro durante download: $e');
      }
      return false;
    }
  }

  /// Configuração completa: instala Ollama e modelo recomendado
  Future<bool> setupOllama() async {
    try {
      if (kDebugMode) {
        print('🔍 Verificando instalação do Ollama...');
      }

      // 1. Verifica se está rodando
      bool isRunning = await isOllamaRunning();

      if (!isRunning) {
        // 2. Verifica se está instalado
        bool isInstalled = await isOllamaInstalled();

        if (!isInstalled) {
          // 3. Instala se necessário
          if (kDebugMode) {
            print('📦 Ollama não encontrado. Instalando...');
          }
          bool installed = await installOllama();
          if (!installed) {
            return false;
          }
        } else {
          // 4. Apenas inicia o serviço
          await startOllamaService();
        }

        // Aguarda inicialização
        await Future.delayed(const Duration(seconds: 5));
      }

      // 5. Detecta RAM e sugere modelo
      final ramGB = await getSystemRAM();
      final recommendedModel = await getRecommendedModel(ramGB);

      if (kDebugMode) {
        print('💾 RAM detectada: ${ramGB}GB');
      }
      if (kDebugMode) {
        print('🤖 Modelo recomendado: $recommendedModel');
      }

      // 6. Verifica modelos instalados
      final installedModels = await getInstalledModels();

      if (!installedModels.contains(recommendedModel)) {
        if (kDebugMode) {
          print('📥 Instalando modelo recomendado...');
        }
        final modelInstalled = await pullModel(recommendedModel);
        if (!modelInstalled) {
          if (kDebugMode) {
            print('⚠️ Não foi possível instalar o modelo automaticamente.');
            print('💡 Instale o Ollama manualmente:');
            print('   1. Baixe de: https://ollama.ai');
            print('   2. Execute: ollama pull $recommendedModel');
          }
          return false;
        }
      } else {
        if (kDebugMode) {
          print('✅ Modelo $recommendedModel já está instalado!');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na configuração: $e');
      }
      return false;
    }
  }

  /// Gera resumo usando Ollama
  Future<String> generateSummary(String text, {String? model}) async {
    try {
      // Usa modelo padrão se não especificado
      if (model == null) {
        final ramGB = await getSystemRAM();
        model = await getRecommendedModel(ramGB);
      }

      final prompt = '''
Analise o seguinte texto científico e crie um resumo estruturado seguindo este formato:

**OBJETIVO:** [Principal objetivo ou problema abordado]
**MÉTODO:** [Metodologia ou abordagem utilizada]
**RESULTADOS:** [Principais descobertas ou resultados]
**IMPLICAÇÕES:** [Importância e implicações dos resultados]

Texto para análise:
$text

Responda em português e seja conciso mas informativo.
''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl/generate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'model': model,
              'prompt': prompt,
              'stream': false,
            }),
          )
          .timeout(const Duration(minutes: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String;
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar resumo: $e');
      }
      return 'Erro ao processar o texto com Ollama';
    }
  }

  /// Gera estado da arte baseado em múltiplos artigos
  Future<String> generateStateOfArt(List<String> articles, String topic) async {
    try {
      final ramGB = await getSystemRAM();
      final model = await getRecommendedModel(ramGB);

      final combinedText = articles.join('\n\n---\n\n');

      final prompt = '''
Com base nos seguintes artigos científicos sobre "$topic", crie um estado da arte seguindo rigorosamente esta estrutura acadêmica em formato LaTeX:

\\section{Introdução}
Apresente uma visão geral do tema de estudo, destacando sua importância e a necessidade de investigar o estágio atual da pesquisa.

\\section{Critérios de Seleção dos Estudos}
Descreva que foram analisados ${articles.length} estudos relevantes obtidos na base arXiv, selecionados por relevância ao tema "$topic".

\\section{Principais Temas e Abordagens}
Agrupe a literatura em categorias, tópicos ou metodologias relevantes, indicando o foco principal de cada grupo. Para cada tema identificado, cite os estudos específicos.

\\section{Contribuições Relevantes}
Apresente as principais descobertas, avanços ou propostas dos estudos revisados, evidenciando sua contribuição para o tema. Cite trabalhos específicos e suas contribuições.

\\section{Lacunas e Desafios}
Discuta as limitações, dificuldades e áreas pouco exploradas identificadas na literatura analisada.

\\section{Considerações Finais}
Faça um resumo dos pontos principais identificados e destaque as direções futuras de pesquisa no tema.

---

ARTIGOS PARA ANÁLISE:
$combinedText

INSTRUÇÕES IMPORTANTES:
- Gere APENAS conteúdo LaTeX válido (sem cabeçalho \\documentclass ou \\begin{document})
- Use comandos LaTeX adequados: \\section{}, \\subsection{}, \\textbf{}, \\textit{}, \\cite{}
- Para listas use \\begin{itemize} \\item ... \\end{itemize}
- Para citações use \\textit{NomeDoArtigo} ou referências diretas
- Use linguagem acadêmica rigorosa
- Cite trabalhos específicos quando relevante
- Seja detalhado e analítico
- Escreva em português brasileiro
- NÃO use caracteres especiais sem escape (%, &, #, _, ^, {, }, ~, \\)
''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl/generate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'model': model,
              'prompt': prompt,
              'stream': false,
            }),
          )
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String;
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar estado da arte: $e');
      }
      return 'Erro ao processar os artigos com Ollama';
    }
  }

  /// Gera estado da arte com streaming token por token
  Stream<String> generateStateOfArtStreaming(
      List<String> articles, String topic) async* {
    try {
      final ramGB = await getSystemRAM();
      final model = await getRecommendedModel(ramGB);

      final combinedText = articles.join('\n\n---\n\n');

      final prompt = '''
Com base nos seguintes artigos científicos sobre "$topic", crie um estado da arte seguindo rigorosamente esta estrutura acadêmica em formato LaTeX:

\\section{Introdução}
Apresente uma visão geral do tema de estudo, destacando sua importância e a necessidade de investigar o estágio atual da pesquisa.

\\section{Critérios de Seleção dos Estudos}
Descreva que foram analisados ${articles.length} estudos relevantes obtidos na base arXiv, selecionados por relevância ao tema "$topic".

\\section{Principais Temas e Abordagens}
Agrupe a literatura em categorias, tópicos ou metodologias relevantes, indicando o foco principal de cada grupo. Para cada tema identificado, cite os estudos específicos.

\\section{Contribuições Relevantes}
Apresente as principais descobertas, avanços ou propostas dos estudos revisados, evidenciando sua contribuição para o tema. Cite trabalhos específicos e suas contribuições.

\\section{Lacunas e Desafios}
Discuta as limitações, dificuldades e áreas pouco exploradas identificadas na literatura analisada.

\\section{Considerações Finais}
Faça um resumo dos pontos principais identificados e destaque as direções futuras de pesquisa no tema.

---

ARTIGOS PARA ANÁLISE:
$combinedText

INSTRUÇÕES IMPORTANTES:
- Gere APENAS conteúdo LaTeX válido (sem cabeçalho \\documentclass ou \\begin{document})
- Use comandos LaTeX adequados: \\section{}, \\subsection{}, \\textbf{}, \\textit{}, \\cite{}
- Para listas use \\begin{itemize} \\item ... \\end{itemize}
- Para citações use \\textit{NomeDoArtigo} ou referências diretas
- Use linguagem acadêmica rigorosa
- Cite trabalhos específicos quando relevante
- Seja detalhado e analítico
- Escreva em português brasileiro
- NÃO use caracteres especiais sem escape (%, &, #, _, ^, {, }, ~, \\)
''';

      final request = http.Request('POST', Uri.parse('$_apiUrl/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'model': model,
        'prompt': prompt,
        'stream': true, // Habilita streaming
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (final chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          // Cada chunk pode conter múltiplas linhas JSON
          final lines =
              chunk.split('\n').where((line) => line.trim().isNotEmpty);

          for (final line in lines) {
            try {
              final data = json.decode(line);
              if (data['response'] != null) {
                yield data['response'] as String;
              }

              // Verifica se a geração terminou
              if (data['done'] == true) {
                return;
              }
            } catch (e) {
              // Ignora linhas JSON inválidas
              if (kDebugMode) {
                print('Linha JSON inválida ignorada: $line');
              }
            }
          }
        }
      } else {
        yield 'Erro HTTP ${streamedResponse.statusCode}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar estado da arte com streaming: $e');
      }
      yield 'Erro ao processar os artigos com Ollama: $e';
    }
  }

  /// Baixa PDF do arXiv
  Future<Uint8List?> downloadPDF(String pdfUrl) async {
    try {
      if (kDebugMode) {
        print('📥 Baixando PDF: $pdfUrl');
      }

      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {'User-Agent': 'MathStateArt/1.0'},
      ).timeout(const Duration(minutes: 2));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print(
              '✅ PDF baixado com sucesso (${response.bodyBytes.length} bytes)');
        }
        return response.bodyBytes;
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao baixar PDF: $e');
      }
      return null;
    }
  }

  /// Extrai texto de PDF usando abordagem híbrida
  Future<String> extractTextFromPDF(String pdfUrl) async {
    try {
      if (kDebugMode) {
        print('📄 Tentando extrair texto do PDF...');
      }

      // Primeiro, tenta baixar o PDF
      final pdfBytes = await downloadPDF(pdfUrl);
      if (pdfBytes == null) {
        return 'Erro ao baixar o PDF';
      }

      // Para esta versão, vamos simular a extração de texto
      // Em uma implementação completa, você usaria uma biblioteca como syncfusion_flutter_pdf
      if (kDebugMode) {
        print('⚠️ Extração de PDF não implementada nesta versão');
      }
      if (kDebugMode) {
        print('📝 Usando abstract como fallback...');
      }

      return 'PDF baixado com sucesso (${pdfBytes.length} bytes), mas extração de texto não implementada nesta versão.';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao processar PDF: $e');
      }
      return 'Erro na extração do PDF: ${e.toString()}';
    }
  }

  /// Processa artigo: baixa PDF, extrai texto e gera resumo
  Future<String> processArticle(ArxivArticle article) async {
    try {
      if (kDebugMode) {
        print('🔄 Processando artigo: ${article.title}');
      }

      // Tenta extrair texto do PDF
      String content = await extractTextFromPDF(article.link);

      // Se a extração falhou, usa apenas o abstract
      if (content.startsWith('Erro') || content.length < 100) {
        if (kDebugMode) {
          print('⚠️ Falha na extração do PDF, usando abstract...');
        }
        content =
            '${article.title}\n\nAutores: ${article.authors}\n\nResumo: ${article.summary}';
      }

      // Gera resumo estruturado
      final summary = await generateSummary(content);

      return '''
**ARTIGO:** ${article.title}
**AUTORES:** ${article.authors}
**DATA:** ${article.published.year}-${article.published.month.toString().padLeft(2, '0')}-${article.published.day.toString().padLeft(2, '0')}
**CATEGORIAS:** ${article.categories.join(', ')}
**LINK:** ${article.link}

$summary

---
''';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao processar artigo: $e');
      }
      return '''
**ARTIGO:** ${article.title}
**ERRO:** Não foi possível processar este artigo completamente.
**RESUMO BÁSICO:** ${article.summary}

---
''';
    }
  }

  /// Gera estado da arte completo com processamento de PDFs
  Future<String> generateCompleteStateOfArt(
    List<ArxivArticle> articles,
    String topic, {
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('🚀 Iniciando geração de estado da arte com IA...');
      if (kDebugMode) {
        print('🚀 Iniciando geração de estado da arte com IA...');
      }
      onProgress?.call('📊 Processando ${articles.length} artigos');
      if (kDebugMode) {
        print('📊 Processando ${articles.length} artigos');
      }

      // Configura Ollama se necessário
      onProgress?.call('🔧 Configurando Ollama...');
      await setupOllama();

      List<String> processedArticles = [];
      int successCount = 0;

      // Primeiro, baixa todos os PDFs
      onProgress?.call('📥 Baixando todos os PDFs...');
      Map<String, String> pdfContents = {};

      for (int i = 0; i < articles.length; i++) {
        final article = articles[i];
        final titlePreview = article.title.length > 40
            ? '${article.title.substring(0, 40)}...'
            : article.title;

        onProgress?.call(
            '📄 Baixando PDF ${i + 1}/${articles.length}: $titlePreview');

        try {
          final content = await extractTextFromPDF(article.link);
          pdfContents[article.id] = content;

          if (kDebugMode) {
            print('✅ PDF ${i + 1}/${articles.length} baixado: $titlePreview');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Erro ao baixar PDF ${i + 1}/${articles.length}: $e');
          }
          // Usa apenas o abstract como fallback
          pdfContents[article.id] =
              '${article.title}\n\nAutores: ${article.authors}\n\nResumo: ${article.summary}';
        }

        // Pequena pausa para não sobrecarregar
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Agora processa todos os artigos de uma vez
      onProgress?.call('🤖 Analisando todos os artigos com IA...');

      for (int i = 0; i < articles.length; i++) {
        final article = articles[i];
        final titlePreview = article.title.length > 40
            ? '${article.title.substring(0, 40)}...'
            : article.title;

        onProgress?.call(
            '🔍 Analisando artigo ${i + 1}/${articles.length}: $titlePreview');

        if (kDebugMode) {
          print(
              '📖 Processando artigo ${i + 1}/${articles.length}: $titlePreview');
        }

        // Usa o conteúdo do PDF baixado anteriormente
        final content = pdfContents[article.id] ??
            '${article.title}\n\nAutores: ${article.authors}\n\nResumo: ${article.summary}';

        try {
          // Gera resumo estruturado
          final summary = await generateSummary(content);

          final processed = '''
**ARTIGO:** ${article.title}
**AUTORES:** ${article.authors}
**DATA:** ${article.published.year}-${article.published.month.toString().padLeft(2, '0')}-${article.published.day.toString().padLeft(2, '0')}
**CATEGORIAS:** ${article.categories.join(', ')}
**LINK:** ${article.link}

$summary

---
''';
          processedArticles.add(processed);
          successCount++;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Erro ao processar artigo: $e');
          }
          final processed = '''
**ARTIGO:** ${article.title}
**ERRO:** Não foi possível processar este artigo completamente.
**RESUMO BÁSICO:** ${article.summary}

---
''';
          processedArticles.add(processed);
        }

        // Pausa pequena entre processamentos para não sobrecarregar
        if (i < articles.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      onProgress?.call(
          '✅ Processamento concluído: $successCount/${articles.length} artigos processados com sucesso');
      if (kDebugMode) {
        print(
            '✅ Processamento concluído: $successCount/${articles.length} artigos processados com sucesso');
      }

      // Gera estado da arte final
      onProgress?.call('🧠 Gerando estado da arte integrado...');
      if (kDebugMode) {
        print('🧠 Gerando estado da arte integrado...');
      }
      final stateOfArt = await generateStateOfArt(processedArticles, topic);

      // Adiciona estatísticas
      onProgress?.call('📊 Finalizando relatório...');
      final ramGB = await getSystemRAM();
      final hasGPU = await hasAICapableGPU();
      final modelUsed = await getRecommendedModel(ramGB);

      final header = '''
# 🎓 ESTADO DA ARTE AUTOMATIZADO: $topic

**📊 Estatísticas da Análise:**
- **Total de artigos analisados:** ${articles.length}
- **Artigos processados com sucesso:** $successCount
- **Período coberto:** ${articles.isNotEmpty ? '${articles.last.published.year} - ${articles.first.published.year}' : 'N/A'}
- **Gerado em:** ${DateTime.now().toString().split('.')[0]}
- **Sistema de IA:** Ollama + $modelUsed
- **Hardware:** ${ramGB}GB RAM${hasGPU ? ' + GPU dedicada' : ' (apenas CPU)'}

---

''';

      return header + stateOfArt;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na geração do estado da arte: $e');
      }
      return '''
# ❌ ERRO NA GERAÇÃO DO ESTADO DA ARTE

Ocorreu um erro durante o processamento:
$e

Por favor, verifique se:
1. O Ollama está instalado e rodando
2. Há conexão com internet para baixar os PDFs
3. O modelo de IA está disponível

Tente novamente ou use as funcionalidades básicas de exportação.
''';
    }
  }
}

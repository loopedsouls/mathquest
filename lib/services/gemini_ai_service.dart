import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mathquest/screens/arxiv_service.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  // A chave da API será solicitada ao usuário
  String? _apiKey;

  /// Define a chave da API do Gemini
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Verifica se a API key está configurada
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Verifica se o Gemini está funcionando
  Future<bool> isGeminiWorking() async {
    if (!hasApiKey) return false;

    try {
      final response = await http
          .post(
            Uri.parse(
                '$_baseUrl/models/gemini-2.0-flash-exp:generateContent?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Teste'}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao testar Gemini: $e');
      }
      return false;
    }
  }

  /// Gera resumo usando Gemini
  Future<String> generateSummary(String text) async {
    if (!hasApiKey) {
      throw Exception('API Key do Gemini não configurada');
    }

    try {
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
            Uri.parse(
                '$_baseUrl/models/gemini-2.0-flash-exp:generateContent?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 1024,
              }
            }),
          )
          .timeout(const Duration(minutes: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          return content as String;
        } else {
          throw Exception('Resposta vazia do Gemini');
        }
      } else {
        if (kDebugMode) {
          print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
        }
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar resumo com Gemini: $e');
      }
      throw Exception('Erro ao processar texto com Gemini: $e');
    }
  }

  /// Gera estado da arte usando Gemini com rate limiting e retry
  Future<String> generateStateOfArt(List<String> articles, String topic) async {
    if (!hasApiKey) {
      throw Exception('API Key do Gemini não configurada');
    }

    // Rate limiting: aguarda entre chamadas
    await Future.delayed(const Duration(seconds: 2));

    // Implementa retry com backoff exponencial
    int maxRetries = 3;
    int retryDelay = 1; // segundos

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
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
              Uri.parse(
                  '$_baseUrl/models/gemini-2.0-flash-exp:generateContent?key=$_apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.7,
                  'topK': 40,
                  'topP': 0.95,
                  'maxOutputTokens': 8192,
                }
              }),
            )
            .timeout(const Duration(minutes: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final content =
                data['candidates'][0]['content']['parts'][0]['text'];
            return content as String;
          } else {
            throw Exception('Resposta vazia do Gemini');
          }
        } else if (response.statusCode == 429) {
          // Rate limit - aumenta o delay e tenta novamente
          if (kDebugMode) {
            print(
                '⏳ Rate limit atingido (tentativa ${attempt + 1}/$maxRetries) - aguardando ${retryDelay * 2} segundos...');
          }
          if (attempt < maxRetries - 1) {
            await Future.delayed(Duration(seconds: retryDelay * 2));
            retryDelay *= 2; // Backoff exponencial
            continue;
          } else {
            throw Exception('Rate limit excedido após $maxRetries tentativas');
          }
        } else {
          if (kDebugMode) {
            print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
          }
          throw Exception('Erro HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (e.toString().contains('Rate limit')) {
          // Re-lança erros de rate limit para tentar novamente
          if (attempt < maxRetries - 1) {
            if (kDebugMode) {
              print(
                  '⏳ Erro de rate limit (tentativa ${attempt + 1}/$maxRetries) - aguardando ${retryDelay * 2} segundos...');
            }
            await Future.delayed(Duration(seconds: retryDelay * 2));
            retryDelay *= 2;
            continue;
          }
        }

        if (kDebugMode) {
          print(
              '❌ Erro ao gerar estado da arte com Gemini (tentativa ${attempt + 1}/$maxRetries): $e');
        }

        if (attempt == maxRetries - 1) {
          throw Exception(
              'Erro ao processar artigos com Gemini após $maxRetries tentativas: $e');
        }
      }
    }

    throw Exception('Falha após todas as tentativas');
  }

  /// Gera estado da arte com streaming (simulado, pois Gemini não tem streaming público ainda)
  Stream<String> generateStateOfArtStreaming(
      List<String> articles, String topic) async* {
    try {
      yield '🔧 Configurando Gemini 2.0 Flash...\n';

      // Processa cada artigo
      for (int i = 0; i < articles.length; i++) {
        yield '📄 Processando artigo ${i + 1}/${articles.length}...\n';
        await Future.delayed(const Duration(milliseconds: 200));
      }

      yield '🤖 Analisando com Gemini 2.0 Flash...\n';
      yield '🔄 Gerando síntese final...\n';

      // Gera o estado da arte completo
      final result = await generateStateOfArt(articles, topic);

      // Simula streaming dividindo o texto em pedaços
      final words = result.split(' ');
      for (int i = 0; i < words.length; i++) {
        yield '${words[i]} ';

        // Adiciona delay variável para simular velocidade de geração
        if (i % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      yield '\n❌ Erro ao gerar estado da arte com Gemini: $e\n';
    }
  }

  /// Processa um artigo individual
  Future<String> processArticle(ArxivArticle article) async {
    try {
      final content = '''
Título: ${article.title}
Autores: ${article.authors}
Data: ${article.published.year}
Categorias: ${article.categories.join(', ')}
Resumo: ${article.summary}
''';

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
        print('❌ Erro ao processar artigo com Gemini: $e');
      }
      return '''
**ARTIGO:** ${article.title}
**ERRO:** Não foi possível processar este artigo com Gemini.
**RESUMO BÁSICO:** ${article.summary}

---
''';
    }
  }
}

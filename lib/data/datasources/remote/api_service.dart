import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Generic API service for remote data operations
class ApiService {
  final HttpClient _httpClient;
  final Map<String, String> _headers;

  ApiService({
    HttpClient? httpClient,
    Map<String, String>? headers,
  })  : _httpClient = httpClient ?? HttpClient(),
        _headers = headers ?? {};

  /// Set authorization header
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization header
  void clearAuthToken() {
    _headers.remove('Authorization');
  }

  /// Set API key header
  void setApiKey(String key, {String headerName = 'X-API-Key'}) {
    _headers[headerName] = key;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final request = await _httpClient.getUrl(uri);
      _applyHeaders(request);

      final response = await request.close().timeout(AppConstants.apiTimeout);
      return await _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição GET: $e');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final request = await _httpClient.postUrl(uri);
      _applyHeaders(request);
      request.headers.contentType = ContentType.json;

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(AppConstants.apiTimeout);
      return await _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição POST: $e');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.putUrl(uri);
      _applyHeaders(request);
      request.headers.contentType = ContentType.json;

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(AppConstants.apiTimeout);
      return await _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição PUT: $e');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String url) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.deleteUrl(uri);
      _applyHeaders(request);

      final response = await request.close().timeout(AppConstants.apiTimeout);
      return await _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição DELETE: $e');
    }
  }

  /// Generate AI content using Gemini
  Future<Map<String, dynamic>> generateAIContent({
    required String prompt,
    required String apiKey,
  }) async {
    try {
      final url = '${ApiEndpoints.geminiGenerate}?key=$apiKey';
      final body = {
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
        },
      };

      final uri = Uri.parse(url);
      final request = await _httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));

      final response = await request.close().timeout(AppConstants.aiGenerationTimeout);
      final responseBody = await _handleResponse(response);

      // Extract generated text from Gemini response
      if (responseBody['candidates'] != null &&
          (responseBody['candidates'] as List).isNotEmpty) {
        final candidate = responseBody['candidates'][0];
        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            (candidate['content']['parts'] as List).isNotEmpty) {
          final text = candidate['content']['parts'][0]['text'];
          return {'text': text, 'raw': responseBody};
        }
      }

      throw AIServiceException(message: 'Resposta da IA vazia ou inválida');
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AIServiceException(message: 'Erro ao gerar conteúdo IA: $e');
    }
  }

  /// Search arXiv for articles
  Future<List<Map<String, dynamic>>> searchArxiv({
    required String query,
    int maxResults = 20,
  }) async {
    try {
      const url = ApiEndpoints.arxivSearch;
      final queryParams = {
        'search_query': 'all:$query',
        'start': '0',
        'max_results': maxResults.toString(),
        'sortBy': 'relevance',
        'sortOrder': 'descending',
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final request = await _httpClient.getUrl(uri);

      final response = await request.close().timeout(AppConstants.apiTimeout);
      final body = await response.transform(utf8.decoder).join();

      // Parse XML response (simplified - in production use xml package)
      return _parseArxivResponse(body);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching arXiv: $e');
      }
      return [];
    }
  }

  void _applyHeaders(HttpClientRequest request) {
    _headers.forEach((key, value) {
      request.headers.set(key, value);
    });
  }

  Future<Map<String, dynamic>> _handleResponse(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    final statusCode = response.statusCode;

    if (kDebugMode) {
      print('Response ($statusCode): ${body.substring(0, body.length.clamp(0, 200))}...');
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return {'success': true};
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {'data': body};
      }
    } else if (statusCode == 401) {
      throw AuthException(message: 'Não autorizado');
    } else if (statusCode == 404) {
      throw NotFoundException();
    } else if (statusCode >= 500) {
      throw ServerException(
        message: 'Erro no servidor',
        statusCode: statusCode,
      );
    } else {
      throw ServerException(
        message: 'Erro na requisição',
        statusCode: statusCode,
      );
    }
  }

  List<Map<String, dynamic>> _parseArxivResponse(String xml) {
    // Simplified XML parsing - in production use xml package
    final articles = <Map<String, dynamic>>[];
    final entryRegex = RegExp(r'<entry>(.*?)<\/entry>', dotAll: true);
    final matches = entryRegex.allMatches(xml);

    for (final match in matches) {
      final entry = match.group(1) ?? '';
      
      String extractTag(String tag) {
        final regex = RegExp('<$tag>(.*?)</$tag>', dotAll: true);
        final m = regex.firstMatch(entry);
        return m?.group(1)?.trim() ?? '';
      }

      articles.add({
        'id': extractTag('id'),
        'title': extractTag('title').replaceAll('\n', ' '),
        'summary': extractTag('summary').replaceAll('\n', ' '),
        'published': extractTag('published'),
      });
    }

    return articles;
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }
}

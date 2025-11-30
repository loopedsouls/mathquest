import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// HTTP client for API requests
class ApiClient {
  final HttpClient _httpClient;
  final Map<String, String> _defaultHeaders;

  ApiClient({
    HttpClient? httpClient,
    Map<String, String>? defaultHeaders,
  })  : _httpClient = httpClient ?? HttpClient(),
        _defaultHeaders = defaultHeaders ?? {};

  /// Set default header
  void setHeader(String key, String value) {
    _defaultHeaders[key] = value;
  }

  /// Remove default header
  void removeHeader(String key) {
    _defaultHeaders.remove(key);
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final request = await _httpClient.getUrl(uri);
      _applyHeaders(request, headers);

      final response = await request.close().timeout(
            AppConstants.apiTimeout,
            onTimeout: () => throw TimeoutException(),
          );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição: $e', originalError: e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final request = await _httpClient.postUrl(uri);
      _applyHeaders(request, headers);
      request.headers.contentType = ContentType.json;

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(
            AppConstants.apiTimeout,
            onTimeout: () => throw TimeoutException(),
          );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição: $e', originalError: e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final request = await _httpClient.putUrl(uri);
      _applyHeaders(request, headers);
      request.headers.contentType = ContentType.json;

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(
            AppConstants.apiTimeout,
            onTimeout: () => throw TimeoutException(),
          );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição: $e', originalError: e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final request = await _httpClient.deleteUrl(uri);
      _applyHeaders(request, headers);

      final response = await request.close().timeout(
            AppConstants.apiTimeout,
            onTimeout: () => throw TimeoutException(),
          );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro na requisição: $e', originalError: e);
    }
  }

  Uri _buildUri(String url, Map<String, dynamic>? queryParameters) {
    final uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }
    return uri;
  }

  void _applyHeaders(HttpClientRequest request, Map<String, String>? headers) {
    // Apply default headers
    _defaultHeaders.forEach((key, value) {
      request.headers.set(key, value);
    });

    // Apply custom headers
    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });
  }

  Future<Map<String, dynamic>> _handleResponse(HttpClientResponse response) async {
    final statusCode = response.statusCode;
    final body = await response.transform(utf8.decoder).join();

    if (kDebugMode) {
      print('API Response ($statusCode): ${body.substring(0, body.length.clamp(0, 500))}');
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return {'success': true};
      }
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return {'data': body};
      }
    } else if (statusCode == 401) {
      throw AuthException(message: 'Não autorizado. Faça login novamente.');
    } else if (statusCode == 403) {
      throw PermissionException();
    } else if (statusCode == 404) {
      throw NotFoundException();
    } else if (statusCode >= 500) {
      throw ServerException(
        message: 'Erro no servidor. Tente novamente mais tarde.',
        statusCode: statusCode,
      );
    } else {
      String errorMessage = 'Erro na requisição';
      try {
        final errorBody = jsonDecode(body);
        errorMessage = errorBody['message'] ?? errorBody['error'] ?? errorMessage;
      } catch (_) {}
      throw ServerException(message: errorMessage, statusCode: statusCode);
    }
  }

  /// Close the client
  void close() {
    _httpClient.close();
  }
}

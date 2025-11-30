/// Custom exceptions for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when server returns an error
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Exception thrown when there's no internet connection
class NetworkException extends AppException {
  NetworkException({
    super.message = 'Sem conexão com a internet',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Exception thrown when cache operation fails
class CacheException extends AppException {
  CacheException({
    super.message = 'Erro ao acessar cache local',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Exception thrown when AI service fails
class AIServiceException extends AppException {
  AIServiceException({
    required super.message,
    super.code = 'AI_ERROR',
    super.originalError,
  });
}

/// Exception thrown when database operation fails
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.code = 'DATABASE_ERROR',
    super.originalError,
  });
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Recurso não encontrado',
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}

/// Exception thrown when operation times out
class TimeoutException extends AppException {
  TimeoutException({
    super.message = 'Operação expirou. Tente novamente.',
    super.code = 'TIMEOUT',
    super.originalError,
  });
}

/// Exception thrown when user doesn't have permission
class PermissionException extends AppException {
  PermissionException({
    super.message = 'Você não tem permissão para esta ação',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

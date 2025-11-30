import 'package:flutter/foundation.dart';

/// Base class for all failures in the application
/// Failures are used for domain-level error handling
@immutable
abstract class Failure {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'Failure: $message${code != null ? ' (code: $code)' : ''}';
}

/// Failure when server request fails
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });
}

/// Failure when there's no network connection
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sem conexão com a internet. Verifique sua conexão.',
    super.code = 'NETWORK_FAILURE',
  });
}

/// Failure when cache operation fails
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erro ao acessar dados locais',
    super.code = 'CACHE_FAILURE',
  });
}

/// Failure when authentication fails
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_FAILURE',
  });
}

/// Failure when AI service is unavailable
class AIFailure extends Failure {
  const AIFailure({
    super.message = 'Serviço de IA indisponível',
    super.code = 'AI_FAILURE',
  });
}

/// Failure when database operation fails
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Erro ao acessar banco de dados',
    super.code = 'DATABASE_FAILURE',
  });
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_FAILURE',
    this.fieldErrors,
  });
}

/// Failure when a resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Recurso não encontrado',
    super.code = 'NOT_FOUND_FAILURE',
  });
}

/// Failure when operation times out
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'A operação demorou muito. Tente novamente.',
    super.code = 'TIMEOUT_FAILURE',
  });
}

/// Failure when user doesn't have permission
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Você não tem permissão para esta ação',
    super.code = 'PERMISSION_FAILURE',
  });
}

/// Failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Ocorreu um erro inesperado',
    super.code = 'UNEXPECTED_FAILURE',
  });
}

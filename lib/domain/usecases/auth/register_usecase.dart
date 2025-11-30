import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/errors/failures.dart';

/// Use case for user registration
class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  /// Execute registration with email and password
  Future<RegisterResult> call({
    required String email,
    required String password,
    required String confirmPassword,
    String? displayName,
  }) async {
    try {
      // Validate input
      if (email.isEmpty) {
        return RegisterResult.failure(const ValidationFailure(message: 'Digite seu email'));
      }
      if (!_isValidEmail(email)) {
        return RegisterResult.failure(const ValidationFailure(message: 'Email inválido'));
      }
      if (password.isEmpty) {
        return RegisterResult.failure(const ValidationFailure(message: 'Digite sua senha'));
      }
      if (password.length < 6) {
        return RegisterResult.failure(
          const ValidationFailure(message: 'A senha deve ter pelo menos 6 caracteres'),
        );
      }
      if (password != confirmPassword) {
        return RegisterResult.failure(const ValidationFailure(message: 'As senhas não coincidem'));
      }

      // Create user
      final user = await _authRepository.createUserWithEmailAndPassword(email, password);

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await _authRepository.updateProfile(displayName: displayName);
      }

      return RegisterResult.success(user);
    } on AuthFailure catch (e) {
      return RegisterResult.failure(e);
    } catch (e) {
      return RegisterResult.failure(AuthFailure(message: 'Erro ao criar conta: $e'));
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Result class for registration operation
class RegisterResult {
  final UserModel? user;
  final Failure? failure;

  RegisterResult._({this.user, this.failure});

  factory RegisterResult.success(UserModel user) => RegisterResult._(user: user);
  factory RegisterResult.failure(Failure failure) => RegisterResult._(failure: failure);

  bool get isSuccess => user != null;
  bool get isFailure => failure != null;
}

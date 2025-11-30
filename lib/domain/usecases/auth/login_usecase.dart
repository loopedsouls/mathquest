import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/errors/failures.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  /// Execute login with email and password
  Future<LoginResult> call({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.isEmpty) {
        return LoginResult.failure(const ValidationFailure(message: 'Digite seu email'));
      }
      if (password.isEmpty) {
        return LoginResult.failure(const ValidationFailure(message: 'Digite sua senha'));
      }

      // Attempt login
      final user = await _authRepository.signInWithEmailAndPassword(email, password);
      return LoginResult.success(user);
    } on AuthFailure catch (e) {
      return LoginResult.failure(e);
    } catch (e) {
      return LoginResult.failure(AuthFailure(message: 'Erro ao fazer login: $e'));
    }
  }

  /// Execute login with Google
  Future<LoginResult> callWithGoogle() async {
    try {
      final user = await _authRepository.signInWithGoogle();
      return LoginResult.success(user);
    } on AuthFailure catch (e) {
      return LoginResult.failure(e);
    } catch (e) {
      return LoginResult.failure(AuthFailure(message: 'Erro ao fazer login com Google: $e'));
    }
  }
}

/// Result class for login operation
class LoginResult {
  final UserModel? user;
  final Failure? failure;

  LoginResult._({this.user, this.failure});

  factory LoginResult.success(UserModel user) => LoginResult._(user: user);
  factory LoginResult.failure(Failure failure) => LoginResult._(failure: failure);

  bool get isSuccess => user != null;
  bool get isFailure => failure != null;
}

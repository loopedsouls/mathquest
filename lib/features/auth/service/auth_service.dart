import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  FirebaseAuth? _auth;

  FirebaseAuth get _authInstance {
    if (!Platform.isLinux) {
      _auth ??= FirebaseAuth.instance;
    }
    return _auth!;
  }

  // Stream para ouvir mudanças no estado de autenticação
  Stream<User?> get authStateChanges {
    if (Platform.isLinux) {
      // Retornar stream vazio no Linux
      return Stream.value(null);
    }
    return _authInstance.authStateChanges();
  }

  // Usuário atual
  User? get currentUser {
    if (Platform.isLinux) {
      return null;
    }
    return _authInstance.currentUser;
  }

  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    try {
      return await _authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Registro com email e senha
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    try {
      return await _authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> signOut() async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    await _authInstance.signOut();
  }

  // Resetar senha
  Future<void> sendPasswordResetEmail(String email) async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    try {
      await _authInstance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Atualizar senha
  Future<void> updatePassword(String newPassword) async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    try {
      await _authInstance.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reautenticar usuário (para operações sensíveis)
  Future<void> reauthenticateUser(String email, String password) async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _authInstance.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Deletar conta
  Future<void> deleteAccount() async {
    if (Platform.isLinux) {
      throw UnsupportedError('Firebase Auth não está disponível no Linux');
    }
    try {
      await _authInstance.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Método auxiliar para tratar exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado. Verifique o email digitado.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido. Verifique o formato.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'requires-recent-login':
        return 'Para esta operação, faça login novamente.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}

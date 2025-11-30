import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Implementation of AuthRepository using Firebase Auth
class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth? _auth;

  /// Check if Firebase Auth is available on this platform
  bool get _isFirebaseAvailable {
    if (kIsWeb) return true;
    try {
      return !Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  FirebaseAuth get _authInstance {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  @override
  UserModel? get currentUser {
    if (!_isFirebaseAvailable) return null;
    final user = _authInstance.currentUser;
    if (user == null) return null;
    return _userFromFirebase(user);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    if (!_isFirebaseAvailable) {
      return Stream.value(null);
    }
    return _authInstance.authStateChanges().map((user) {
      if (user == null) return null;
      return _userFromFirebase(user);
    });
  }

  @override
  bool get isSignedIn {
    if (!_isFirebaseAvailable) return false;
    return _authInstance.currentUser != null;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    try {
      final result = await _authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user == null) {
        throw Exception('Sign in failed');
      }
      return _userFromFirebase(result.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Future<UserModel> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    try {
      final result = await _authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user == null) {
        throw Exception('Account creation failed');
      }
      return _userFromFirebase(result.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login com Google cancelado pelo usuário');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _authInstance.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Falha no login com Google');
      }

      return _userFromFirebase(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    await _authInstance.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    try {
      await _authInstance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Future<UserModel> updateProfile({String? displayName, String? photoUrl}) async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    final user = _authInstance.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }
    try {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      await user.reload();
      return _userFromFirebase(_authInstance.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Future<void> deleteAccount() async {
    if (!_isFirebaseAvailable) {
      throw UnsupportedError('Firebase Auth not available on this platform');
    }
    try {
      await _authInstance.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  /// Convert Firebase User to UserModel
  UserModel _userFromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      level: 1,
      xp: 0,
      coins: 0,
      streakDays: 0,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  /// Handle Firebase Auth exceptions
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

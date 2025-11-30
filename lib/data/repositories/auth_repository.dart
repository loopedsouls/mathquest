import '../models/user_model.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Get current user
  UserModel? get currentUser;

  /// Stream of auth state changes
  Stream<UserModel?> get authStateChanges;

  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(String email, String password);

  /// Create user with email and password
  Future<UserModel> createUserWithEmailAndPassword(String email, String password);

  /// Sign in with Google
  Future<UserModel> signInWithGoogle();

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<UserModel> updateProfile({String? displayName, String? photoUrl});

  /// Delete account
  Future<void> deleteAccount();

  /// Check if user is signed in
  bool get isSignedIn;
}

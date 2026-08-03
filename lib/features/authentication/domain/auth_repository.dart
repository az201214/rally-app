import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser> register({required String email, required String password});

  Future<AuthUser> login({required String email, required String password});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> logout();

  Future<void> deleteCurrentUser();
}

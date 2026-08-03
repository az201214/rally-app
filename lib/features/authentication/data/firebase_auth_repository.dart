import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requiredUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    } catch (_) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requiredUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    } catch (_) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    } catch (_) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (_) {
      // Best-effort rollback after a failed profile write.
    }
  }

  static AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email ?? '');
  }

  static AuthUser _requiredUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) throw const AuthFailure(AuthFailureCode.unknown);
    return mapped;
  }

  static AuthFailure _translate(FirebaseAuthException error) {
    return AuthFailure(switch (error.code) {
      'email-already-in-use' => AuthFailureCode.emailAlreadyInUse,
      'weak-password' => AuthFailureCode.weakPassword,
      'invalid-email' => AuthFailureCode.invalidEmail,
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => AuthFailureCode.invalidCredentials,
      'network-request-failed' => AuthFailureCode.network,
      'user-token-expired' ||
      'invalid-user-token' => AuthFailureCode.sessionExpired,
      'too-many-requests' ||
      'operation-not-allowed' => AuthFailureCode.unavailable,
      _ => AuthFailureCode.unknown,
    });
  }
}

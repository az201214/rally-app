import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/firestore_player_profile_repository.dart';
import '../../profile/domain/player_profile.dart';
import '../../profile/domain/player_profile_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final playerProfileRepositoryProvider = Provider<PlayerProfileRepository>(
  (ref) => FirestorePlayerProfileRepository(FirebaseFirestore.instance),
);

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentPlayerProfileProvider = StreamProvider<PlayerProfile?>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.value;
  if (user == null) return const Stream<PlayerProfile?>.empty();
  return ref.watch(playerProfileRepositoryProvider).watchProfile(user.uid);
});

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);

class AuthActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading<void>();
    final authRepository = ref.read(authRepositoryProvider);
    try {
      final user = await authRepository.register(
        email: email,
        password: password,
      );
      final profile = PlayerProfile.newPlayer(
        uid: user.uid,
        fullName: fullName,
        email: user.email.isEmpty ? email : user.email,
      );
      try {
        await ref.read(playerProfileRepositoryProvider).createProfile(profile);
      } catch (_) {
        await authRepository.deleteCurrentUser();
        rethrow;
      }
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading<void>();
    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    if (state.isLoading) return false;
    state = const AsyncLoading<void>();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }

  Future<bool> logout() async {
    if (state.isLoading) return false;
    state = const AsyncLoading<void>();
    try {
      await ref.read(authRepositoryProvider).logout();
      ref.invalidate(currentPlayerProfileProvider);
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }
}

String userFacingAuthError(Object error) => error is AuthFailure
    ? error.message
    : error is Exception && error.toString().contains('profile')
    ? 'Your player profile could not be created. Please try again.'
    : 'Something went wrong. Please try again.';

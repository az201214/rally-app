import 'dart:async';

import '../features/authentication/domain/auth_repository.dart';
import '../features/authentication/domain/auth_user.dart';
import '../features/profile/domain/player_profile.dart';
import '../features/profile/domain/player_profile_repository.dart';

class DemoAuthRepository implements AuthRepository {
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.multi((listener) {
    listener.add(_user);
    final subscription = _changes.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return _authenticate(email);
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    return _authenticate(email);
  }

  AuthUser _authenticate(String email) {
    final user = AuthUser(uid: 'rally-demo-player', email: email.trim());
    _user = user;
    _changes.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
  }

  @override
  Future<void> logout() async {
    _user = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async => logout();
}

class DemoPlayerProfileRepository implements PlayerProfileRepository {
  DemoPlayerProfileRepository() : _profile = _defaultProfile();

  final _changes = StreamController<PlayerProfile?>.broadcast();
  PlayerProfile _profile;

  @override
  Stream<PlayerProfile?> watchProfile(String uid) =>
      Stream<PlayerProfile?>.multi((listener) {
        listener.add(_profile);
        final subscription = _changes.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });

  @override
  Future<PlayerProfile?> loadProfile(String uid) async => _profile;

  @override
  Future<void> createProfile(PlayerProfile profile) async {
    _profile = profile.copyWith(
      skillLevel: 'Advanced',
      preferredSide: 'Right',
      playingStyle: 'Balanced',
      homeClubId: 'padelverse-clifton',
      city: 'Karachi',
    );
    _changes.add(_profile);
  }

  @override
  Future<void> updateProfile(PlayerProfile profile) async {
    _profile = profile;
    _changes.add(_profile);
  }

  static PlayerProfile _defaultProfile() {
    final now = DateTime.utc(2026, 8, 3);
    return PlayerProfile(
      uid: 'rally-demo-player',
      fullName: 'Hamza Khan',
      email: 'hamza@rally.app',
      photoUrl: '',
      skillLevel: 'Advanced',
      preferredSide: 'Right',
      playingStyle: 'Balanced',
      homeClubId: 'padelverse-clifton',
      city: 'Karachi',
      searchRadiusKm: 10,
      reliabilityScore: 92,
      rating: 4.9,
      matchesPlayed: 68,
      isVerified: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}

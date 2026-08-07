import 'dart:async';

import 'package:rally/features/authentication/domain/auth_failure.dart';
import 'package:rally/features/authentication/domain/auth_repository.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/profile/domain/player_profile.dart';
import 'package:rally/features/profile/domain/player_profile_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? user, this.delay = Duration.zero})
    : _currentUser = user;

  final Duration delay;
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  AuthFailure? nextFailure;
  int registerCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;
  int resetCalls = 0;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.multi((listener) {
    listener.add(_currentUser);
    final subscription = _changes.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  Future<void> _waitAndFailIfNeeded() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    registerCalls++;
    await _waitAndFailIfNeeded();
    final user = AuthUser(uid: 'user-1', email: email);
    _currentUser = user;
    _changes.add(user);
    return user;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    await _waitAndFailIfNeeded();
    final user = AuthUser(uid: 'user-1', email: email);
    _currentUser = user;
    _changes.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    await _waitAndFailIfNeeded();
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    await _waitAndFailIfNeeded();
    _currentUser = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    _currentUser = null;
    _changes.add(null);
  }

  void dispose() => _changes.close();
}

class FakePlayerProfileRepository implements PlayerProfileRepository {
  FakePlayerProfileRepository({this.profile, this.error});

  PlayerProfile? profile;
  Object? error;
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Stream<PlayerProfile?> watchProfile(String uid) async* {
    if (error != null) throw error!;
    yield profile;
  }

  @override
  Stream<PlayerProfile?> watchPublicProfile(String uid) => watchProfile(uid);

  @override
  Future<PlayerProfile?> loadProfile(String uid) async {
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<void> createProfile(PlayerProfile profile) async {
    createCalls++;
    if (error != null) throw error!;
    this.profile = profile;
  }

  @override
  Future<void> updateProfile(PlayerProfile profile) async {
    updateCalls++;
    if (error != null) throw error!;
    this.profile = profile;
  }
}

PlayerProfile testProfile({
  String uid = 'user-1',
  String fullName = 'Hamza Khan',
  String city = 'Clifton',
  String homeClubId = 'padelverse-clifton',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PlayerProfile(
    uid: uid,
    fullName: fullName,
    email: 'hamza@rally.pk',
    photoUrl: '',
    skillLevel: 'Advanced',
    preferredSide: 'Right',
    playingStyle: 'Balanced',
    homeClubId: homeClubId,
    city: city,
    searchRadiusKm: 10,
    reliabilityScore: 92,
    rating: 4.9,
    matchesPlayed: 68,
    isVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}

import 'player_profile.dart';

abstract interface class PlayerProfileRepository {
  Stream<PlayerProfile?> watchProfile(String uid);

  Stream<PlayerProfile?> watchPublicProfile(String uid);

  Future<PlayerProfile?> loadProfile(String uid);

  Future<void> createProfile(PlayerProfile profile);

  Future<void> updateProfile(PlayerProfile profile);
}

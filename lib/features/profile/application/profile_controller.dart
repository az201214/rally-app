import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/domain/club.dart';
import '../data/firestore_profile_insights_repository.dart';
import '../domain/player_profile.dart';
import '../domain/profile_insights.dart';

final profileInsightsRepositoryProvider = Provider<ProfileInsightsRepository>(
  (_) => FirestoreProfileInsightsRepository(
    // The concrete repository remains behind the profile-owned abstraction.
    // Firebase is initialized before production providers are read.
    FirebaseFirestore.instance,
  ),
);

final publicPlayerProfileProvider = StreamProvider.autoDispose
    .family<PlayerProfile?, String>(
      (ref, uid) =>
          ref.watch(playerProfileRepositoryProvider).watchPublicProfile(uid),
    );

final profileMatchHistoryProvider = StreamProvider.autoDispose
    .family<List<ProfileMatchHistoryItem>, String>(
      (ref, uid) =>
          ref.watch(profileInsightsRepositoryProvider).watchMatchHistory(uid),
    );

final profileStatisticsProvider = Provider.autoDispose
    .family<AsyncValue<ProfileStatistics>, String>((ref, uid) {
      return ref
          .watch(profileMatchHistoryProvider(uid))
          .whenData(
            (items) => ProfileStatistics.fromMatches(
              uid,
              items.map((item) => item.match).toList(),
            ),
          );
    });

final favoriteClubsProvider = FutureProvider.autoDispose
    .family<List<Club>, PlayerProfile>((ref, profile) async {
      final ids = profile.favoriteClubIds.toSet();
      if (ids.isEmpty) return const <Club>[];
      final clubs = await ref.watch(clubRepositoryProvider).watchClubs().first;
      return clubs
          .where((club) => ids.contains(club.id))
          .toList(growable: false);
    });

final profileUpdateControllerProvider =
    AsyncNotifierProvider<ProfileUpdateController, void>(
      ProfileUpdateController.new,
    );

class ProfileUpdateController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> saveProfile(PlayerProfile profile) async {
    if (state.isLoading) return false;
    state = const AsyncLoading<void>();
    try {
      await ref.read(playerProfileRepositoryProvider).updateProfile(profile);
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }
}

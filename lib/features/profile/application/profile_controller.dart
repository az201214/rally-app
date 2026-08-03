import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../domain/player_profile.dart';

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

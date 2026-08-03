import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/demo/demo_matchmaking_repositories.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/matchmaking/application/matchmaking_controller.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';

import 'fake_repositories.dart';

Widget matchmakingTestScope({required Widget child}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(
        user: const AuthUser(uid: 'user-1', email: 'player@rally.pk'),
      ),
    ),
    playerProfileRepositoryProvider.overrideWithValue(
      FakePlayerProfileRepository(profile: testProfile()),
    ),
    availabilityRepositoryProvider.overrideWithValue(
      DemoAvailabilityRepository(),
    ),
    matchmakingRepositoryProvider.overrideWithValue(
      _WaitingDemoMatchmakingRepository(),
    ),
  ],
  child: child,
);

class _WaitingDemoMatchmakingRepository extends DemoMatchmakingRepository {
  @override
  Future<List<MatchRequest>> findCompatibleRequests(
    MatchRequest request,
  ) async => const <MatchRequest>[];
}

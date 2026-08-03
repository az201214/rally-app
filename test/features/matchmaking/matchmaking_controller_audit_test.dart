import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/demo/demo_matchmaking_repositories.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/matchmaking/application/matchmaking_controller.dart';
import 'package:rally/features/matchmaking/domain/compatibility_engine.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_repositories.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  test(
    'two compatible authenticated users converge on one live match',
    () async {
      final repository = _ConcurrentRepository();
      final first = _container('user-a', repository);
      final second = _container('user-b', repository);
      final firstStates = <MatchmakingState>[];
      final secondStates = <MatchmakingState>[];
      final firstListener = first.listen(
        matchmakingControllerProvider,
        (_, next) => firstStates.add(next),
        fireImmediately: true,
      );
      final secondListener = second.listen(
        matchmakingControllerProvider,
        (_, next) => secondStates.add(next),
        fireImmediately: true,
      );
      addTearDown(() {
        firstListener.close();
        secondListener.close();
        first.dispose();
        second.dispose();
        repository.dispose();
      });

      final now = DateTime.now();
      await Future.wait(<Future<bool>>[
        first
            .read(matchmakingControllerProvider.notifier)
            .startSearch(
              availableFrom: now,
              availableUntil: now.add(const Duration(hours: 2)),
            ),
        second
            .read(matchmakingControllerProvider.notifier)
            .startSearch(
              availableFrom: now,
              availableUntil: now.add(const Duration(hours: 2)),
            ),
      ]);
      await _waitFor(
        () =>
            first.read(matchmakingControllerProvider).match != null &&
            second.read(matchmakingControllerProvider).match != null,
      );

      final firstMatch = first.read(matchmakingControllerProvider).match!;
      final secondMatch = second.read(matchmakingControllerProvider).match!;
      expect(firstMatch.id, secondMatch.id);
      expect(repository.matches, hasLength(1));
      expect(
        firstStates.any((state) => state.phase == MatchmakingPhase.matchFound),
        isTrue,
      );
      expect(
        secondStates.any((state) => state.phase == MatchmakingPhase.matchFound),
        isTrue,
      );
    },
  );

  test(
    'cancellation atomically closes request and availability state',
    () async {
      final repository = _ConcurrentRepository();
      final container = _container('user-a', repository);
      final listener = container.listen(
        matchmakingControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() {
        listener.close();
        container.dispose();
        repository.dispose();
      });
      final now = DateTime.now();
      expect(
        await container
            .read(matchmakingControllerProvider.notifier)
            .startSearch(
              availableFrom: now,
              availableUntil: now.add(const Duration(hours: 2)),
            ),
        isTrue,
      );
      expect(
        await container
            .read(matchmakingControllerProvider.notifier)
            .cancelSearch(),
        isTrue,
      );
      expect(repository.requests.single.status, MatchRequestStatus.cancelled);
      expect(
        repository.cancelledAvailabilityIds,
        contains('availability_user-a'),
      );
      expect(
        container.read(matchmakingControllerProvider).phase,
        MatchmakingPhase.cancelled,
      );
    },
  );

  test('logout cancels request and match subscriptions', () async {
    final repository = _ConcurrentRepository();
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'user-a', email: 'a@rally.pk'),
    );
    final container = _container('user-a', repository, auth: auth);
    final listener = container.listen(
      matchmakingControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() {
      listener.close();
      container.dispose();
      auth.dispose();
      repository.dispose();
    });
    final now = DateTime.now();
    await container
        .read(matchmakingControllerProvider.notifier)
        .startSearch(
          availableFrom: now,
          availableUntil: now.add(const Duration(hours: 2)),
        );
    await _waitFor(() => repository.activeSubscriptions > 0);
    await auth.logout();
    await _waitFor(() => repository.activeSubscriptions == 0);
    expect(
      container.read(matchmakingControllerProvider).phase,
      MatchmakingPhase.idle,
    );
  });
}

ProviderContainer _container(
  String uid,
  MatchmakingRepository repository, {
  FakeAuthRepository? auth,
}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      auth ??
          FakeAuthRepository(
            user: AuthUser(uid: uid, email: '$uid@rally.pk'),
          ),
    ),
    playerProfileRepositoryProvider.overrideWithValue(
      FakePlayerProfileRepository(
        profile: testProfile(uid: uid, fullName: uid, city: 'Karachi'),
      ),
    ),
    availabilityRepositoryProvider.overrideWithValue(
      DemoAvailabilityRepository(),
    ),
    matchmakingRepositoryProvider.overrideWithValue(repository),
  ],
);

Future<void> _waitFor(bool Function() condition) async {
  final timeout = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(timeout)) {
      fail('Timed out waiting for matchmaking state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _ConcurrentRepository implements MatchmakingRepository {
  final Map<String, MatchRequest> _requests = <String, MatchRequest>{};
  final Map<String, RallyMatch> matches = <String, RallyMatch>{};
  final Map<String, StreamController<MatchRequest?>> _requestChanges = {};
  final Map<String, StreamController<RallyMatch?>> _matchChanges = {};
  final Set<String> cancelledAvailabilityIds = <String>{};
  int activeSubscriptions = 0;

  Iterable<MatchRequest> get requests => _requests.values;

  @override
  Future<void> createSearch(
    PlayerAvailability availability,
    MatchRequest request,
  ) async {
    if (_requests.values.any(
      (item) =>
          item.userId == request.userId &&
          item.status == MatchRequestStatus.searching,
    )) {
      throw StateError('duplicate');
    }
    _requests[request.id] = request;
    _requestChanges[request.id]?.add(request);
  }

  @override
  Future<MatchRequest> createMatchRequest(MatchRequest request) async {
    await createSearch(_availability(request), request);
    return request;
  }

  @override
  Future<MatchRequest?> getActiveRequestForUser(String userId) async =>
      _requests.values
          .where(
            (item) =>
                item.userId == userId &&
                (item.status == MatchRequestStatus.searching ||
                    item.status == MatchRequestStatus.matched),
          )
          .firstOrNull;

  @override
  Future<List<MatchRequest>> findCompatibleRequests(
    MatchRequest request,
  ) async => _requests.values
      .where((item) => CompatibilityEngine.isCompatible(request, item))
      .toList();

  @override
  Future<RallyMatch?> createOrJoinMatch(
    MatchRequest own,
    MatchRequest candidate,
  ) async {
    final pair = <String>[own.id, candidate.id]..sort();
    final id = 'pair_${pair.join('_')}';
    if (matches[id] case final existing?) return existing;
    final currentOwn = _requests[own.id];
    final currentCandidate = _requests[candidate.id];
    if (currentOwn == null ||
        currentCandidate == null ||
        !CompatibilityEngine.isCompatible(currentOwn, currentCandidate)) {
      return null;
    }
    final now = DateTime.now().toUtc();
    MatchParticipant participant(MatchRequest request) => MatchParticipant(
      userId: request.userId,
      displayName: request.displayName,
      photoUrl: request.photoUrl,
      skillLevel: request.skillLevel,
      preferredSide: request.preferredSide,
      reliabilityScore: request.reliabilityScore,
      acceptanceStatus: AcceptanceStatus.pending,
      joinedAt: now,
    );
    final result = CompatibilityEngine.score(currentOwn, currentCandidate);
    final match = RallyMatch(
      id: id,
      participantIds: <String>[own.userId, candidate.userId],
      participants: <MatchParticipant>[
        participant(currentOwn),
        participant(currentCandidate),
      ],
      city: own.city,
      clubId: '',
      clubName: 'Club to be confirmed',
      scheduledStart: own.availableFrom,
      scheduledEnd: own.availableUntil,
      status: RallyMatchStatus.awaitingAcceptance,
      compatibilityScore: result.score,
      compatibilityReasons: result.reasons,
      createdBy: own.userId,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
      cancellationReason: '',
    );
    matches[id] = match;
    for (final request in <MatchRequest>[currentOwn, currentCandidate]) {
      final matched = MatchRequest.fromMap(<String, Object?>{
        ...request.toMap(),
        'status': 'matched',
        'matchedMatchId': id,
        'expiresAt': match.expiresAt,
      }, id: request.id);
      _requests[request.id] = matched;
      _requestChanges[request.id]?.add(matched);
    }
    _matchChanges[id]?.add(match);
    return match;
  }

  @override
  Stream<MatchRequest?> watchMatchRequest(String id) =>
      Stream<MatchRequest?>.multi((listener) {
        activeSubscriptions++;
        listener.add(_requests[id]);
        final controller = _requestChanges.putIfAbsent(
          id,
          () => StreamController.broadcast(),
        );
        final subscription = controller.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = () async {
          await subscription.cancel();
          activeSubscriptions--;
        };
      });

  @override
  Stream<RallyMatch?> watchMatch(String id) =>
      Stream<RallyMatch?>.multi((listener) {
        activeSubscriptions++;
        listener.add(matches[id]);
        final controller = _matchChanges.putIfAbsent(
          id,
          () => StreamController.broadcast(),
        );
        final subscription = controller.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = () async {
          await subscription.cancel();
          activeSubscriptions--;
        };
      });

  @override
  Future<void> cancelSearch({
    required String requestId,
    required String availabilityId,
    required String userId,
    required bool expired,
  }) async {
    final request = _requests[requestId]!;
    final cancelled = MatchRequest.fromMap(<String, Object?>{
      ...request.toMap(),
      'status': expired ? 'expired' : 'cancelled',
    }, id: request.id);
    _requests[requestId] = cancelled;
    cancelledAvailabilityIds.add(availabilityId);
    _requestChanges[requestId]?.add(cancelled);
  }

  @override
  Future<void> cancelMatchRequest(String id, String userId) => cancelSearch(
    requestId: id,
    availabilityId: _requests[id]!.availabilityId,
    userId: userId,
    expired: false,
  );
  @override
  Future<void> acceptMatch(String id, String userId) async {}
  @override
  Future<void> declineMatch(String id, String userId) async {}
  @override
  Future<void> cancelMatch(String id, String userId, String reason) async {}
  @override
  Future<void> expireMatch(String id) async {}

  PlayerAvailability _availability(MatchRequest request) => PlayerAvailability(
    id: request.availabilityId,
    userId: request.userId,
    city: request.city,
    latitude: request.latitude,
    longitude: request.longitude,
    searchRadiusKm: request.searchRadiusKm,
    availableFrom: request.availableFrom,
    availableUntil: request.availableUntil,
    skillLevel: request.skillLevel,
    preferredSide: request.preferredSide,
    preferredClubIds: request.preferredClubIds,
    reliabilityScore: request.reliabilityScore,
    status: AvailabilityStatus.active,
    createdAt: request.createdAt,
    updatedAt: request.updatedAt,
    expiresAt: request.expiresAt,
  );

  void dispose() {
    for (final controller in _requestChanges.values) {
      controller.close();
    }
    for (final controller in _matchChanges.values) {
      controller.close();
    }
  }
}

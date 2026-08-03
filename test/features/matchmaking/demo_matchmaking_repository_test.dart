import 'package:flutter_test/flutter_test.dart';
import 'package:rally/demo/demo_matchmaking_repositories.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';

void main() {
  final now = DateTime.now().toUtc();
  MatchRequest request() => MatchRequest(
    id: 'request',
    userId: 'user',
    availabilityId: 'availability',
    city: 'Karachi',
    latitude: 24.86,
    longitude: 67,
    searchRadiusKm: 10,
    availableFrom: now,
    availableUntil: now.add(const Duration(hours: 2)),
    skillLevel: 'Advanced',
    preferredSide: 'Right',
    preferredClubIds: const <String>['club'],
    reliabilityScore: 92,
    status: MatchRequestStatus.searching,
    matchedMatchId: '',
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(hours: 2)),
  );

  test('prevents duplicate active requests', () async {
    final repository = DemoMatchmakingRepository();
    await repository.createMatchRequest(request());
    expect(() => repository.createMatchRequest(request()), throwsStateError);
  });

  test(
    'formation is idempotent and acceptance confirms all participants',
    () async {
      final repository = DemoMatchmakingRepository();
      final own = request();
      await repository.createMatchRequest(own);
      final candidate = (await repository.findCompatibleRequests(own)).single;
      final first = await repository.createOrJoinMatch(own, candidate);
      final duplicate = await repository.createOrJoinMatch(own, candidate);
      expect(duplicate?.id, first?.id);
      await repository.acceptMatch(first!.id, own.userId);
      final confirmed = await repository.watchMatch(first.id).first;
      expect(confirmed?.status, RallyMatchStatus.confirmed);
    },
  );

  test('cancellation removes active request', () async {
    final repository = DemoMatchmakingRepository();
    final own = request();
    await repository.createMatchRequest(own);
    await repository.cancelMatchRequest(own.id, own.userId);
    expect(await repository.getActiveRequestForUser(own.userId), isNull);
  });

  test('decline transitions match lifecycle', () async {
    final repository = DemoMatchmakingRepository();
    final own = request();
    await repository.createMatchRequest(own);
    final match = await repository.createOrJoinMatch(
      own,
      (await repository.findCompatibleRequests(own)).single,
    );
    await repository.declineMatch(match!.id, own.userId);
    expect(
      (await repository.watchMatch(match.id).first)?.status,
      RallyMatchStatus.declined,
    );
  });
}

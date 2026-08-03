import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';

void main() {
  test('request round trips through Firestore-compatible map', () {
    final now = DateTime.utc(2026, 8, 3, 19);
    final value = MatchRequest(
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
    final decoded = MatchRequest.fromMap(value.toMap(), id: value.id);
    expect(decoded.userId, 'user');
    expect(decoded.status, MatchRequestStatus.searching);
    expect(decoded.preferredClubIds, <String>['club']);
  });

  test('legacy and missing fields use safe defaults', () {
    final request = MatchRequest.fromMap(const <String, Object?>{
      'userId': 'user',
      'status': 'unknown',
    });
    expect(request.status, MatchRequestStatus.expired);
    expect(request.searchRadiusKm, 10);
    expect(request.skillLevel, 'Beginner');
    final match = RallyMatch.fromMap(const <String, Object?>{
      'status': 'old-status',
    });
    expect(match.status, RallyMatchStatus.expired);
    expect(match.participants, isEmpty);
  });
}

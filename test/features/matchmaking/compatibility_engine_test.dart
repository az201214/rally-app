import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/matchmaking/domain/compatibility_engine.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';

void main() {
  final now = DateTime.now().toUtc();
  MatchRequest request({
    String id = 'a',
    String userId = 'a',
    String city = 'Karachi',
    double latitude = 24.8607,
    double longitude = 67.0011,
    double radius = 10,
    DateTime? from,
    DateTime? until,
    String skill = 'Advanced',
    String side = 'Left',
    double reliability = 92,
    List<String> clubs = const <String>['club'],
  }) => MatchRequest(
    id: id,
    userId: userId,
    availabilityId: 'availability-$id',
    city: city,
    latitude: latitude,
    longitude: longitude,
    searchRadiusKm: radius,
    availableFrom: from ?? now,
    availableUntil: until ?? now.add(const Duration(hours: 2)),
    skillLevel: skill,
    preferredSide: side,
    preferredClubIds: clubs,
    reliabilityScore: reliability,
    status: MatchRequestStatus.searching,
    matchedMatchId: '',
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(hours: 3)),
  );

  test('scores a compatible pair with human-readable reasons', () {
    final result = CompatibilityEngine.score(
      request(),
      request(id: 'b', userId: 'b', side: 'Right'),
    );
    expect(result.score, inInclusiveRange(1, 100));
    expect(result.reasons, contains('Similar skill level'));
    expect(result.reasons, contains('Complementary left/right sides'));
    expect(result.reasons, contains('Same preferred club'));
  });

  test('rejects windows without time overlap', () {
    expect(
      CompatibilityEngine.isCompatible(
        request(),
        request(
          id: 'b',
          userId: 'b',
          from: now.add(const Duration(hours: 3)),
          until: now.add(const Duration(hours: 4)),
        ),
      ),
      isFalse,
    );
  });

  test('rejects players outside both search radii', () {
    expect(
      CompatibilityEngine.isCompatible(
        request(radius: 2),
        request(id: 'b', userId: 'b', latitude: 25.1, radius: 2),
      ),
      isFalse,
    );
  });

  test('rejects incompatible skill band', () {
    expect(
      CompatibilityEngine.isCompatible(
        request(),
        request(id: 'b', userId: 'b', skill: 'Beginner'),
      ),
      isFalse,
    );
  });

  test('accepts complementary playing sides', () {
    expect(
      CompatibilityEngine.isCompatible(
        request(side: 'Left'),
        request(id: 'b', userId: 'b', side: 'Right'),
      ),
      isTrue,
    );
  });

  test('rejects reliability below threshold', () {
    expect(
      CompatibilityEngine.isCompatible(
        request(),
        request(id: 'b', userId: 'b', reliability: 59),
      ),
      isFalse,
    );
  });

  test('distance calculation is symmetric', () {
    final forward = CompatibilityEngine.distanceKm(24.86, 67, 24.88, 67.02);
    final reverse = CompatibilityEngine.distanceKm(24.88, 67.02, 24.86, 67);
    expect(forward, closeTo(reverse, .0001));
  });
}

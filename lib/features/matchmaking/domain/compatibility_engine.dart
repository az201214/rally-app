import 'dart:math' as math;

import 'matchmaking_models.dart';

class CompatibilityResult {
  const CompatibilityResult(this.score, this.reasons);
  final int score;
  final List<String> reasons;
}

abstract final class CompatibilityEngine {
  static const double minimumReliability = 60;

  static bool isCompatible(MatchRequest a, MatchRequest b) {
    if (a.userId == b.userId ||
        a.status != MatchRequestStatus.searching ||
        b.status != MatchRequestStatus.searching ||
        a.city.toLowerCase() != b.city.toLowerCase() ||
        a.expiresAt.isBefore(DateTime.now().toUtc()) ||
        b.expiresAt.isBefore(DateTime.now().toUtc()) ||
        a.reliabilityScore < minimumReliability ||
        b.reliabilityScore < minimumReliability ||
        !_overlaps(a, b) ||
        (_skill(a.skillLevel) - _skill(b.skillLevel)).abs() > 1) {
      return false;
    }
    final distance = distanceKm(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return distance <= a.searchRadiusKm && distance <= b.searchRadiusKm;
  }

  static CompatibilityResult score(MatchRequest a, MatchRequest b) {
    if (!isCompatible(a, b)) return const CompatibilityResult(0, <String>[]);
    final reasons = <String>[];
    var score = 0.0;
    final skillDelta = (_skill(a.skillLevel) - _skill(b.skillLevel)).abs();
    score += skillDelta == 0 ? 25 : 16;
    reasons.add('Similar skill level');
    final overlapMinutes =
        math.max(
          0,
          math.min(
                a.availableUntil.millisecondsSinceEpoch,
                b.availableUntil.millisecondsSinceEpoch,
              ) -
              math.max(
                a.availableFrom.millisecondsSinceEpoch,
                b.availableFrom.millisecondsSinceEpoch,
              ),
        ) /
        Duration.millisecondsPerMinute;
    score += (overlapMinutes / 120 * 20).clamp(8, 20);
    reasons.add('Overlapping availability');
    final distance = distanceKm(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    score += (20 - distance * 1.5).clamp(5, 20);
    reasons.add('${distance.toStringAsFixed(1)} km apart');
    if (_complementarySides(a.preferredSide, b.preferredSide)) {
      score += 15;
      reasons.add('Complementary left/right sides');
    } else {
      score += 7;
    }
    score += ((a.reliabilityScore + b.reliabilityScore) / 200 * 12).clamp(
      0,
      12,
    );
    if (a.reliabilityScore >= 85 && b.reliabilityScore >= 85) {
      reasons.add('Strong reliability history');
    }
    if (a.preferredClubIds
        .toSet()
        .intersection(b.preferredClubIds.toSet())
        .isNotEmpty) {
      score += 8;
      reasons.add('Same preferred club');
    }
    return CompatibilityResult(score.round().clamp(0, 100), reasons);
  }

  static bool _overlaps(MatchRequest a, MatchRequest b) =>
      a.availableFrom.isBefore(b.availableUntil) &&
      b.availableFrom.isBefore(a.availableUntil);

  static bool _complementarySides(String a, String b) {
    final leftRight = <String>{a.toLowerCase(), b.toLowerCase()};
    return leftRight.contains('left') && leftRight.contains('right') ||
        a.toLowerCase().contains('preference') ||
        b.toLowerCase().contains('preference');
  }

  static int _skill(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('advanced') || normalized.contains('expert')) {
      return 3;
    }
    if (normalized.contains('intermediate')) return 2;
    return 1;
  }

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    double radians(double value) => value * math.pi / 180;
    final dLat = radians(lat2 - lat1);
    final dLon = radians(lon2 - lon1);
    final haversine =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }
}

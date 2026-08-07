import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';
import 'package:rally/features/profile/domain/player_profile.dart';
import 'package:rally/features/profile/domain/profile_insights.dart';

void main() {
  test('legacy profile parsing uses safe Profile 2 defaults', () {
    final profile = PlayerProfile.fromMap(<String, Object?>{
      'uid': 'legacy',
      'fullName': 'Legacy Player',
      'email': 'private@example.com',
    });
    expect(profile.playingHand, 'Right');
    expect(profile.preferredDays, isEmpty);
    expect(profile.favoriteClubIds, isEmpty);
    expect(profile.verificationStatus, 'unverified');
  });

  test('full profile parsing preserves new fields', () {
    final profile = PlayerProfile.fromMap(<String, Object?>{
      'uid': 'full',
      'fullName': 'Full Player',
      'bio': 'A reliable player',
      'city': 'Karachi',
      'skillLevel': 'Advanced',
      'playingHand': 'Left',
      'preferredSide': 'Right',
      'playingStyle': 'Attacking',
      'preferredDays': <String>['Tuesday'],
      'preferredTimeRanges': <String>['Evening'],
      'preferredClubIds': <String>['club-1'],
      'favoriteClubIds': <String>['club-1'],
      'verificationStatus': 'verified',
    });
    expect(profile.playingHand, 'Left');
    expect(profile.favoriteClubIds, <String>['club-1']);
    expect(profile.hasTrustedVerification, isTrue);
    expect(profile.profileCompletion, 100);
  });

  test('profile completion names missing fields', () {
    final profile = PlayerProfile.newPlayer(
      uid: 'u',
      fullName: 'Player',
      email: 'p@example.com',
    );
    expect(profile.profileCompletion, lessThan(100));
    expect(
      profile.missingProfileFields,
      containsAll(<String>[
        'bio',
        'city',
        'preferred days',
        'preferred times',
        'preferred club',
      ]),
    );
  });

  test('statistics derive reliability without editable counters', () {
    final matches = <RallyMatch>[
      _match('1', RallyMatchStatus.completed),
      _match('2', RallyMatchStatus.completed),
      _match('3', RallyMatchStatus.cancelled),
    ];
    final stats = ProfileStatistics.fromMatches(
      'owner',
      matches,
      now: DateTime.utc(2026, 8, 6),
    );
    expect(stats.completedMatches, 2);
    expect(stats.cancelledMatches, 1);
    expect(stats.reliabilityScore, closeTo(66.67, 0.1));
    expect(stats.uniquePlayersMet, 1);
  });

  test('achievements unlock deterministically from real values', () {
    final profile = PlayerProfile.fromMap(<String, Object?>{
      'uid': 'owner',
      'fullName': 'Player',
      'createdAt': '2026-01-01T00:00:00Z',
    });
    final stats = ProfileStatistics.fromMatches(
      'owner',
      List.generate(5, (i) => _match('$i', RallyMatchStatus.completed)),
    );
    final unlocked = ProfileAchievement.evaluate(
      profile,
      stats,
    ).where((a) => a.unlocked).map((a) => a.id);
    expect(
      unlocked,
      containsAll(<String>[
        'first-match',
        'five-matches',
        'reliable-player',
        'early-adopter',
      ]),
    );
  });
}

RallyMatch _match(String id, RallyMatchStatus status) {
  final now = DateTime.utc(2026, 8, 1);
  return RallyMatch(
    id: id,
    participantIds: const <String>['owner', 'other'],
    participants: <MatchParticipant>[
      MatchParticipant(
        userId: 'owner',
        displayName: 'Owner',
        photoUrl: '',
        skillLevel: 'Advanced',
        preferredSide: 'Right',
        reliabilityScore: 100,
        acceptanceStatus: AcceptanceStatus.accepted,
        joinedAt: now,
      ),
    ],
    city: 'Karachi',
    clubId: 'club',
    clubName: 'Rally Club',
    scheduledStart: now,
    scheduledEnd: now.add(const Duration(minutes: 90)),
    status: status,
    compatibilityScore: 90,
    compatibilityReasons: const <String>[],
    createdBy: 'owner',
    createdAt: now,
    updatedAt: now,
    expiresAt: now,
    cancellationReason: '',
  );
}

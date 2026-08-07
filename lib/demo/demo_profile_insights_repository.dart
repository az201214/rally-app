import '../features/matchmaking/domain/matchmaking_models.dart';
import '../features/profile/domain/profile_insights.dart';

class DemoProfileInsightsRepository implements ProfileInsightsRepository {
  @override
  Stream<List<ProfileMatchHistoryItem>> watchMatchHistory(
    String uid, {
    int limit = 25,
  }) {
    final now = DateTime.utc(2026, 8, 6, 19);
    final items = List<ProfileMatchHistoryItem>.generate(6, (index) {
      final completed = index < 5;
      final match = RallyMatch(
        id: 'demo-profile-match-$index',
        participantIds: <String>[uid, 'demo-player-$index'],
        participants: <MatchParticipant>[
          MatchParticipant(
            userId: uid,
            displayName: 'Hamza Khan',
            photoUrl: '',
            skillLevel: 'Advanced',
            preferredSide: 'Right',
            reliabilityScore: 96,
            acceptanceStatus: AcceptanceStatus.accepted,
            joinedAt: now,
          ),
          MatchParticipant(
            userId: 'demo-player-$index',
            displayName: 'Rally Player ${index + 1}',
            photoUrl: '',
            skillLevel: 'Advanced',
            preferredSide: 'Left',
            reliabilityScore: 94,
            acceptanceStatus: AcceptanceStatus.accepted,
            joinedAt: now,
          ),
        ],
        city: 'Karachi',
        clubId: index.isEven ? 'padelverse-clifton' : 'the-padel-club-dha',
        clubName: index.isEven ? 'Padelverse Clifton' : 'The Padel Club DHA',
        scheduledStart: now.subtract(Duration(days: index * 5)),
        scheduledEnd: now
            .subtract(Duration(days: index * 5))
            .add(const Duration(minutes: 90)),
        status: completed
            ? RallyMatchStatus.completed
            : RallyMatchStatus.confirmed,
        compatibilityScore: 91 - index,
        compatibilityReasons: const <String>['Compatible skill level'],
        createdBy: uid,
        createdAt: now.subtract(Duration(days: index * 5 + 1)),
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 1)),
        confirmedAt: now,
        cancellationReason: '',
      );
      return ProfileMatchHistoryItem(
        match: match,
        otherPlayerName: 'Rally Player ${index + 1}',
      );
    });
    return Stream.value(items.take(limit).toList(growable: false));
  }
}

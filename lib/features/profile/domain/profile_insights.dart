import '../../matchmaking/domain/matchmaking_models.dart';
import 'player_profile.dart';

class ProfileStatistics {
  const ProfileStatistics({
    required this.totalMatches,
    required this.completedMatches,
    required this.cancelledMatches,
    required this.noShows,
    required this.acceptedMatches,
    required this.matchesThisMonth,
    required this.averageMatchScore,
    required this.uniquePlayersMet,
    required this.reliabilityScore,
  });

  const ProfileStatistics.empty()
    : totalMatches = 0,
      completedMatches = 0,
      cancelledMatches = 0,
      noShows = 0,
      acceptedMatches = 0,
      matchesThisMonth = 0,
      averageMatchScore = null,
      uniquePlayersMet = 0,
      reliabilityScore = 100;

  final int totalMatches;
  final int completedMatches;
  final int cancelledMatches;
  final int noShows;
  final int acceptedMatches;
  final int matchesThisMonth;
  final double? averageMatchScore;
  final int uniquePlayersMet;
  final double reliabilityScore;

  factory ProfileStatistics.fromMatches(
    String uid,
    List<RallyMatch> matches, {
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    final completed = matches
        .where((m) => m.status == RallyMatchStatus.completed)
        .length;
    final cancelled = matches
        .where((m) => m.status == RallyMatchStatus.cancelled)
        .length;
    final noShows = matches
        .where((m) => m.cancellationReason.toLowerCase().contains('no-show'))
        .length;
    final accepted = matches
        .where(
          (m) => m.participants.any(
            (p) =>
                p.userId == uid &&
                p.acceptanceStatus == AcceptanceStatus.accepted,
          ),
        )
        .length;
    final thisMonth = matches
        .where(
          (m) =>
              m.scheduledStart.year == reference.year &&
              m.scheduledStart.month == reference.month,
        )
        .length;
    final scored = matches.where((m) => m.compatibilityScore > 0).toList();
    final people = matches
        .expand((m) => m.participantIds)
        .where((id) => id != uid)
        .toSet();
    final decided = completed + cancelled + noShows;
    final reliability =
        (decided == 0 ? 100.0 : ((completed / decided) * 100).clamp(0, 100))
            .toDouble();
    return ProfileStatistics(
      totalMatches: matches.length,
      completedMatches: completed,
      cancelledMatches: cancelled,
      noShows: noShows,
      acceptedMatches: accepted,
      matchesThisMonth: thisMonth,
      averageMatchScore: scored.isEmpty
          ? null
          : scored.map((m) => m.compatibilityScore).reduce((a, b) => a + b) /
                scored.length,
      uniquePlayersMet: people.length,
      reliabilityScore: reliability,
    );
  }
}

class ProfileMatchHistoryItem {
  const ProfileMatchHistoryItem({
    required this.match,
    required this.otherPlayerName,
  });
  final RallyMatch match;
  final String otherPlayerName;
}

class ProfileAchievement {
  const ProfileAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  static List<ProfileAchievement> evaluate(
    PlayerProfile profile,
    ProfileStatistics stats,
  ) => <ProfileAchievement>[
    ProfileAchievement(
      id: 'first-match',
      title: 'First Match',
      description: 'Complete one Rally match.',
      unlocked: stats.completedMatches >= 1,
    ),
    ProfileAchievement(
      id: 'five-matches',
      title: 'Five Matches',
      description: 'Complete five Rally matches.',
      unlocked: stats.completedMatches >= 5,
    ),
    ProfileAchievement(
      id: 'reliable-player',
      title: 'Reliable Player',
      description: 'Complete at least five matches with 90% reliability.',
      unlocked: stats.completedMatches >= 5 && stats.reliabilityScore >= 90,
    ),
    ProfileAchievement(
      id: 'early-adopter',
      title: 'Early Adopter',
      description: 'Joined Rally before 2027.',
      unlocked: profile.createdAt.year > 1970 && profile.createdAt.year < 2027,
    ),
    ProfileAchievement(
      id: 'social-player',
      title: 'Social Player',
      description: 'Meet five different Rally players.',
      unlocked: stats.uniquePlayersMet >= 5,
    ),
  ];
}

abstract interface class ProfileInsightsRepository {
  Stream<List<ProfileMatchHistoryItem>> watchMatchHistory(
    String uid, {
    int limit = 25,
  });
}

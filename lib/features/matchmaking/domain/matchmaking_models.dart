enum AvailabilityStatus { active, matched, cancelled, expired }

enum MatchRequestStatus { searching, matched, cancelled, expired }

enum RallyMatchStatus {
  forming,
  awaitingAcceptance,
  confirmed,
  declined,
  cancelled,
  expired,
  completed,
}

enum AcceptanceStatus { pending, accepted, declined }

T _enum<T extends Enum>(Iterable<T> values, Object? value, T fallback) =>
    values.where((item) => item.name == value).firstOrNull ?? fallback;

String _string(Object? value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;
double _double(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
DateTime _date(Object? value, [DateTime? fallback]) {
  if (value is DateTime) return value.toUtc();
  try {
    final dynamic timestamp = value;
    final converted = timestamp?.toDate();
    if (converted is DateTime) return converted.toUtc();
  } catch (_) {}
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc() ?? fallback ?? _epoch;
  }
  return fallback ?? _epoch;
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

class PlayerAvailability {
  const PlayerAvailability({
    required this.id,
    required this.userId,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.searchRadiusKm,
    required this.availableFrom,
    required this.availableUntil,
    required this.skillLevel,
    required this.preferredSide,
    required this.preferredClubIds,
    required this.reliabilityScore,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory PlayerAvailability.fromMap(Map<String, Object?> map, {String? id}) {
    final now = DateTime.now().toUtc();
    return PlayerAvailability(
      id: _string(map['id'], id ?? ''),
      userId: _string(map['userId']),
      city: _string(map['city']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      searchRadiusKm: _double(map['searchRadiusKm'], 10).clamp(1, 100),
      availableFrom: _date(map['availableFrom'], now),
      availableUntil: _date(map['availableUntil'], now),
      skillLevel: _string(map['skillLevel'], 'Beginner'),
      preferredSide: _string(map['preferredSide'], 'No preference'),
      preferredClubIds: _strings(map['preferredClubIds']),
      reliabilityScore: _double(map['reliabilityScore'], 100).clamp(0, 100),
      status: _enum(
        AvailabilityStatus.values,
        map['status'],
        AvailabilityStatus.expired,
      ),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      expiresAt: _date(map['expiresAt'], now),
    );
  }

  final String id;
  final String userId;
  final String city;
  final double latitude;
  final double longitude;
  final double searchRadiusKm;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final String skillLevel;
  final String preferredSide;
  final List<String> preferredClubIds;
  final double reliabilityScore;
  final AvailabilityStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'userId': userId,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'searchRadiusKm': searchRadiusKm,
    'availableFrom': availableFrom,
    'availableUntil': availableUntil,
    'skillLevel': skillLevel,
    'preferredSide': preferredSide,
    'preferredClubIds': preferredClubIds,
    'reliabilityScore': reliabilityScore,
    'status': status.name,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'expiresAt': expiresAt,
  };
}

class MatchRequest {
  const MatchRequest({
    required this.id,
    required this.userId,
    required this.availabilityId,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.searchRadiusKm,
    required this.availableFrom,
    required this.availableUntil,
    required this.skillLevel,
    required this.preferredSide,
    required this.preferredClubIds,
    required this.reliabilityScore,
    required this.status,
    required this.matchedMatchId,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.displayName = '',
    this.photoUrl = '',
  });

  factory MatchRequest.fromMap(Map<String, Object?> map, {String? id}) {
    final now = DateTime.now().toUtc();
    return MatchRequest(
      id: _string(map['id'], id ?? ''),
      userId: _string(map['userId']),
      availabilityId: _string(map['availabilityId']),
      city: _string(map['city']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      searchRadiusKm: _double(map['searchRadiusKm'], 10).clamp(1, 100),
      availableFrom: _date(map['availableFrom'], now),
      availableUntil: _date(map['availableUntil'], now),
      skillLevel: _string(map['skillLevel'], 'Beginner'),
      preferredSide: _string(map['preferredSide'], 'No preference'),
      preferredClubIds: _strings(map['preferredClubIds']),
      reliabilityScore: _double(map['reliabilityScore'], 100).clamp(0, 100),
      status: _enum(
        MatchRequestStatus.values,
        map['status'],
        MatchRequestStatus.expired,
      ),
      matchedMatchId: _string(map['matchedMatchId']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      expiresAt: _date(map['expiresAt'], now),
      displayName: _string(map['displayName'], 'Rally player'),
      photoUrl: _string(map['photoUrl']),
    );
  }

  final String id,
      userId,
      availabilityId,
      city,
      skillLevel,
      preferredSide,
      matchedMatchId;
  final String displayName, photoUrl;
  final double latitude, longitude, searchRadiusKm, reliabilityScore;
  final DateTime availableFrom, availableUntil, createdAt, updatedAt, expiresAt;
  final List<String> preferredClubIds;
  final MatchRequestStatus status;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'userId': userId,
    'availabilityId': availabilityId,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'searchRadiusKm': searchRadiusKm,
    'availableFrom': availableFrom,
    'availableUntil': availableUntil,
    'skillLevel': skillLevel,
    'preferredSide': preferredSide,
    'preferredClubIds': preferredClubIds,
    'reliabilityScore': reliabilityScore,
    'status': status.name,
    'matchedMatchId': matchedMatchId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'expiresAt': expiresAt,
    'displayName': displayName,
    'photoUrl': photoUrl,
  };
}

class MatchParticipant {
  const MatchParticipant({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.skillLevel,
    required this.preferredSide,
    required this.reliabilityScore,
    required this.acceptanceStatus,
    required this.joinedAt,
    this.acceptedAt,
  });
  factory MatchParticipant.fromMap(Map<String, Object?> map) =>
      MatchParticipant(
        userId: _string(map['userId']),
        displayName: _string(map['displayName'], 'Rally player'),
        photoUrl: _string(map['photoUrl']),
        skillLevel: _string(map['skillLevel'], 'Beginner'),
        preferredSide: _string(map['preferredSide'], 'No preference'),
        reliabilityScore: _double(map['reliabilityScore'], 100).clamp(0, 100),
        acceptanceStatus: _enum(
          AcceptanceStatus.values,
          map['acceptanceStatus'],
          AcceptanceStatus.pending,
        ),
        joinedAt: _date(map['joinedAt']),
        acceptedAt: map['acceptedAt'] == null ? null : _date(map['acceptedAt']),
      );
  final String userId, displayName, photoUrl, skillLevel, preferredSide;
  final double reliabilityScore;
  final AcceptanceStatus acceptanceStatus;
  final DateTime joinedAt;
  final DateTime? acceptedAt;
  Map<String, Object?> toMap() => <String, Object?>{
    'userId': userId,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'skillLevel': skillLevel,
    'preferredSide': preferredSide,
    'reliabilityScore': reliabilityScore,
    'acceptanceStatus': acceptanceStatus.name,
    'joinedAt': joinedAt,
    'acceptedAt': acceptedAt,
  };
}

class RallyMatch {
  const RallyMatch({
    required this.id,
    required this.participantIds,
    required this.participants,
    required this.city,
    required this.clubId,
    required this.clubName,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.compatibilityScore,
    required this.compatibilityReasons,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.confirmedAt,
    this.cancelledAt,
    required this.cancellationReason,
  });
  factory RallyMatch.fromMap(
    Map<String, Object?> map, {
    String? id,
  }) => RallyMatch(
    id: _string(map['id'], id ?? ''),
    participantIds: _strings(map['participantIds']),
    participants: ((map['participants'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => MatchParticipant.fromMap(
            item.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .toList(),
    city: _string(map['city']),
    clubId: _string(map['clubId']),
    clubName: _string(map['clubName'], 'Club to be confirmed'),
    scheduledStart: _date(map['scheduledStart']),
    scheduledEnd: _date(map['scheduledEnd']),
    status: _enum(
      RallyMatchStatus.values,
      map['status'],
      RallyMatchStatus.expired,
    ),
    compatibilityScore: _double(
      map['compatibilityScore'],
    ).round().clamp(0, 100),
    compatibilityReasons: _strings(map['compatibilityReasons']),
    createdBy: _string(map['createdBy']),
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
    expiresAt: _date(map['expiresAt']),
    confirmedAt: map['confirmedAt'] == null ? null : _date(map['confirmedAt']),
    cancelledAt: map['cancelledAt'] == null ? null : _date(map['cancelledAt']),
    cancellationReason: _string(map['cancellationReason']),
  );
  final String id, city, clubId, clubName, createdBy, cancellationReason;
  final List<String> participantIds, compatibilityReasons;
  final List<MatchParticipant> participants;
  final DateTime scheduledStart, scheduledEnd, createdAt, updatedAt, expiresAt;
  final DateTime? confirmedAt, cancelledAt;
  final RallyMatchStatus status;
  final int compatibilityScore;
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'participantIds': participantIds,
    'participants': participants.map((item) => item.toMap()).toList(),
    'city': city,
    'clubId': clubId,
    'clubName': clubName,
    'scheduledStart': scheduledStart,
    'scheduledEnd': scheduledEnd,
    'status': status.name,
    'compatibilityScore': compatibilityScore,
    'compatibilityReasons': compatibilityReasons,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'expiresAt': expiresAt,
    'confirmedAt': confirmedAt,
    'cancelledAt': cancelledAt,
    'cancellationReason': cancellationReason,
  };
}

List<String> _strings(Object? value) => value is Iterable
    ? value
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false)
    : const <String>[];

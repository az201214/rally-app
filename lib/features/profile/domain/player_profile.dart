class PlayerProfile {
  const PlayerProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.skillLevel,
    required this.preferredSide,
    required this.playingStyle,
    required this.homeClubId,
    required this.city,
    required this.searchRadiusKm,
    required this.reliabilityScore,
    required this.rating,
    required this.matchesPlayed,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerProfile.newPlayer({
    required String uid,
    required String fullName,
    required String email,
  }) {
    final now = DateTime.now().toUtc();
    return PlayerProfile(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      photoUrl: '',
      skillLevel: 'Beginner',
      preferredSide: 'No preference',
      playingStyle: 'Balanced',
      homeClubId: '',
      city: '',
      searchRadiusKm: 10,
      reliabilityScore: 100,
      rating: 0,
      matchesPlayed: 0,
      isVerified: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PlayerProfile.fromMap(Map<String, Object?> map, {String? uid}) {
    return PlayerProfile(
      uid: _string(map['uid'], fallback: uid ?? ''),
      fullName: _string(map['fullName']),
      email: _string(map['email']),
      photoUrl: _string(map['photoUrl']),
      skillLevel: _string(map['skillLevel'], fallback: 'Beginner'),
      preferredSide: _string(map['preferredSide'], fallback: 'No preference'),
      playingStyle: _string(map['playingStyle'], fallback: 'Balanced'),
      homeClubId: _string(map['homeClubId']),
      city: _string(map['city']),
      searchRadiusKm: _int(map['searchRadiusKm'], fallback: 10, min: 1),
      reliabilityScore: _double(
        map['reliabilityScore'],
        fallback: 100,
      ).clamp(0, 100),
      rating: _double(map['rating']).clamp(0, 5),
      matchesPlayed: _int(map['matchesPlayed'], min: 0),
      isVerified: map['isVerified'] == true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  final String uid;
  final String fullName;
  final String email;
  final String photoUrl;
  final String skillLevel;
  final String preferredSide;
  final String playingStyle;
  final String homeClubId;
  final String city;
  final int searchRadiusKm;
  final double reliabilityScore;
  final double rating;
  final int matchesPlayed;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isComplete =>
      fullName.isNotEmpty && city.isNotEmpty && homeClubId.isNotEmpty;

  Map<String, Object?> toMap() => <String, Object?>{
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'photoUrl': photoUrl,
    'skillLevel': skillLevel,
    'preferredSide': preferredSide,
    'playingStyle': playingStyle,
    'homeClubId': homeClubId,
    'city': city,
    'searchRadiusKm': searchRadiusKm,
    'reliabilityScore': reliabilityScore,
    'rating': rating,
    'matchesPlayed': matchesPlayed,
    'isVerified': isVerified,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  PlayerProfile copyWith({
    String? fullName,
    String? skillLevel,
    String? preferredSide,
    String? playingStyle,
    String? homeClubId,
    String? city,
    int? searchRadiusKm,
    DateTime? updatedAt,
  }) => PlayerProfile(
    uid: uid,
    fullName: fullName ?? this.fullName,
    email: email,
    photoUrl: photoUrl,
    skillLevel: skillLevel ?? this.skillLevel,
    preferredSide: preferredSide ?? this.preferredSide,
    playingStyle: playingStyle ?? this.playingStyle,
    homeClubId: homeClubId ?? this.homeClubId,
    city: city ?? this.city,
    searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
    reliabilityScore: reliabilityScore,
    rating: rating,
    matchesPlayed: matchesPlayed,
    isVerified: isVerified,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
  );

  static String _string(Object? value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static int _int(Object? value, {int fallback = 0, int min = 0}) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return (parsed ?? fallback).clamp(min, 1000);
  }

  static double _double(Object? value, {double fallback = 0}) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

  static DateTime _date(Object? value) {
    if (value is DateTime) return value.toUtc();
    try {
      final dynamic timestamp = value;
      final result = timestamp?.toDate();
      if (result is DateTime) return result.toUtc();
    } catch (_) {
      // Legacy or malformed values use the Unix epoch deterministically.
    }
    if (value is String) return DateTime.tryParse(value)?.toUtc() ?? _epoch;
    return _epoch;
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
}

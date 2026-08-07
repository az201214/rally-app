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
    this.bio = '',
    this.playingHand = 'Right',
    this.preferredDays = const <String>[],
    this.preferredTimeRanges = const <String>[],
    this.preferredClubIds = const <String>[],
    this.favoriteClubIds = const <String>[],
    this.achievementIds = const <String>[],
    this.verificationStatus = 'unverified',
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
      preferredClubIds: const <String>[],
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
      bio: _string(map['bio']),
      playingHand: _string(map['playingHand'], fallback: 'Right'),
      preferredDays: _strings(map['preferredDays']),
      preferredTimeRanges: _strings(map['preferredTimeRanges']),
      preferredClubIds: _strings(
        map['preferredClubIds'],
        fallback: _string(map['homeClubId']).isEmpty
            ? const <String>[]
            : <String>[_string(map['homeClubId'])],
      ),
      favoriteClubIds: _strings(map['favoriteClubIds']),
      achievementIds: _strings(map['achievementIds']),
      verificationStatus: _string(
        map['verificationStatus'],
        fallback: map['isVerified'] == true ? 'verified' : 'unverified',
      ),
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
  final String bio;
  final String playingHand;
  final List<String> preferredDays;
  final List<String> preferredTimeRanges;
  final List<String> preferredClubIds;
  final List<String> favoriteClubIds;
  final List<String> achievementIds;
  final String verificationStatus;

  List<String> get missingProfileFields => <String>[
    if (fullName.isEmpty) 'display name',
    if (bio.isEmpty) 'bio',
    if (city.isEmpty) 'city',
    if (skillLevel.isEmpty) 'skill level',
    if (preferredDays.isEmpty) 'preferred days',
    if (preferredTimeRanges.isEmpty) 'preferred times',
    if (preferredClubIds.isEmpty && homeClubId.isEmpty) 'preferred club',
  ];

  int get profileCompletion =>
      (((7 - missingProfileFields.length) / 7) * 100).round().clamp(0, 100);

  bool get isComplete => missingProfileFields.isEmpty;

  bool get hasTrustedVerification =>
      verificationStatus == 'verified' || isVerified;

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
    'bio': bio,
    'playingHand': playingHand,
    'preferredDays': preferredDays,
    'preferredTimeRanges': preferredTimeRanges,
    'preferredClubIds': preferredClubIds,
    'favoriteClubIds': favoriteClubIds,
    'achievementIds': achievementIds,
    'verificationStatus': verificationStatus,
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
    String? bio,
    String? playingHand,
    List<String>? preferredDays,
    List<String>? preferredTimeRanges,
    List<String>? preferredClubIds,
    List<String>? favoriteClubIds,
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
    bio: bio ?? this.bio,
    playingHand: playingHand ?? this.playingHand,
    preferredDays: preferredDays ?? this.preferredDays,
    preferredTimeRanges: preferredTimeRanges ?? this.preferredTimeRanges,
    preferredClubIds: preferredClubIds ?? this.preferredClubIds,
    favoriteClubIds: favoriteClubIds ?? this.favoriteClubIds,
    achievementIds: achievementIds,
    verificationStatus: verificationStatus,
  );

  static String _string(Object? value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static int _int(Object? value, {int fallback = 0, int min = 0}) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return (parsed ?? fallback).clamp(min, 1000);
  }

  static double _double(Object? value, {double fallback = 0}) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

  static List<String> _strings(
    Object? value, {
    List<String> fallback = const <String>[],
  }) => value is Iterable
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
      : fallback;

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

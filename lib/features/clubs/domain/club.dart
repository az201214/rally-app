import 'dart:math' as math;

class GeoPosition {
  const GeoPosition(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  double distanceTo(GeoPosition other) {
    const earthRadiusKm = 6371.0;
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLon = (other.longitude - longitude) * math.pi / 180;
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.position,
    required this.courtCount,
    required this.rating,
    required this.openingHours,
    required this.phone,
    required this.email,
    required this.photoUrls,
    required this.amenities,
    this.googlePlaceId = '',
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final GeoPosition position;
  final int courtCount;
  final double rating;
  final String openingHours;
  final String phone;
  final String email;
  final List<String> photoUrls;
  final List<String> amenities;
  final String googlePlaceId;

  factory Club.fromMap(String id, Map<String, Object?> map) {
    final location = map['location'];
    double latitude = 0;
    double longitude = 0;
    if (location is Map) {
      latitude = (location['latitude'] as num?)?.toDouble() ?? 0;
      longitude = (location['longitude'] as num?)?.toDouble() ?? 0;
    } else {
      try {
        latitude = ((location as dynamic).latitude as num).toDouble();
        longitude = ((location as dynamic).longitude as num).toDouble();
      } catch (_) {}
    }
    return Club(
      id: id,
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      address: map['address'] as String? ?? '',
      position: GeoPosition(latitude, longitude),
      courtCount: (map['courtCount'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      openingHours: map['openingHours'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrls: List<String>.from(map['photoUrls'] as List? ?? const []),
      amenities: List<String>.from(map['amenities'] as List? ?? const []),
      googlePlaceId: map['googlePlaceId'] as String? ?? '',
    );
  }
}

class NearbyClub {
  const NearbyClub({required this.club, required this.distanceKm});

  final Club club;
  final double distanceKm;

  int get estimatedTravelMinutes => math.max(3, (distanceKm / 24 * 60).round());
}

import '../domain/club.dart';
import '../domain/club_repository.dart';

const demoClubs = <Club>[
  Club(
    id: 'padelverse-clifton',
    name: 'Padelverse Clifton',
    city: 'Karachi',
    address: 'Khayaban-e-Saadi, Clifton',
    position: GeoPosition(24.8138, 67.0305),
    courtCount: 6,
    rating: 4.8,
    openingHours: 'Daily · 6 AM–12 AM',
    phone: '+922135872400',
    email: 'hello@padelverse.pk',
    photoUrls: <String>[],
    amenities: <String>['Indoor AC', 'Parking', 'Showers', 'Café', 'Pro shop'],
  ),
  Club(
    id: 'the-padel-club-dha',
    name: 'The Padel Club DHA',
    city: 'Karachi',
    address: 'DHA Phase 6, Karachi',
    position: GeoPosition(24.7965, 67.0716),
    courtCount: 4,
    rating: 4.7,
    openingHours: 'Daily · 7 AM–11 PM',
    phone: '+922135008800',
    email: 'play@thepadelclub.pk',
    photoUrls: <String>[],
    amenities: <String>['Outdoor', 'Parking', 'Changing rooms'],
  ),
  Club(
    id: 'smash-arena',
    name: 'Smash Arena',
    city: 'Karachi',
    address: 'Khayaban-e-Ittehad, Karachi',
    position: GeoPosition(24.8019, 67.0652),
    courtCount: 3,
    rating: 4.6,
    openingHours: 'Mon–Sun · 8 AM–12 AM',
    phone: '+923001234567',
    email: 'courts@smasharena.pk',
    photoUrls: <String>[],
    amenities: <String>['Floodlights', 'Parking', 'Café'],
  ),
];

class DemoClubRepository implements ClubRepository {
  @override
  Future<Club?> getClub(String id) async => demoClubs.cast<Club?>().firstWhere(
    (club) => club?.id == id,
    orElse: () => null,
  );

  @override
  Stream<List<Club>> watchClubs() => Stream.value(demoClubs);
}

class DemoClubLocationService implements ClubLocationService {
  @override
  Future<GeoPosition> currentPosition() async =>
      const GeoPosition(24.817, 67.025);
  @override
  Future<bool> isServiceEnabled() async => true;
  @override
  Future<void> openSettings() async {}
  @override
  Future<LocationPermissionState> permissionStatus() async =>
      LocationPermissionState.granted;
  @override
  Future<LocationPermissionState> requestPermission() async =>
      LocationPermissionState.granted;
}

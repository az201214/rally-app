import 'club.dart';

abstract interface class ClubRepository {
  Stream<List<Club>> watchClubs();
  Future<Club?> getClub(String id);
}

enum LocationPermissionState { notDetermined, granted, denied, deniedForever }

abstract interface class ClubLocationService {
  Future<bool> isServiceEnabled();
  Future<LocationPermissionState> permissionStatus();
  Future<LocationPermissionState> requestPermission();
  Future<GeoPosition> currentPosition();
  Future<void> openSettings();
}

abstract interface class ClubNavigationService {
  Future<bool> openDirections(Club club);
  Future<bool> call(String phone);
  Future<bool> email(String email);
}

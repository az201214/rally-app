import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/club.dart';
import '../domain/club_repository.dart';

class GeolocatorClubLocationService implements ClubLocationService {
  @override
  Future<GeoPosition> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return GeoPosition(position.latitude, position.longitude);
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<LocationPermissionState> permissionStatus() async =>
      _map(await Geolocator.checkPermission());

  @override
  Future<LocationPermissionState> requestPermission() async =>
      _map(await Geolocator.requestPermission());

  LocationPermissionState _map(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationPermissionState.granted,
        LocationPermission.deniedForever =>
          LocationPermissionState.deniedForever,
        LocationPermission.denied => LocationPermissionState.denied,
        LocationPermission.unableToDetermine =>
          LocationPermissionState.notDetermined,
      };
}

class GoogleMapsClubNavigationService implements ClubNavigationService {
  @override
  Future<bool> openDirections(Club club) => launchUrl(
    Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': '${club.position.latitude},${club.position.longitude}',
      if (club.googlePlaceId.isNotEmpty)
        'destination_place_id': club.googlePlaceId,
      'travelmode': 'driving',
    }),
    mode: LaunchMode.externalApplication,
  );

  @override
  Future<bool> call(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

  @override
  Future<bool> email(String email) =>
      launchUrl(Uri(scheme: 'mailto', path: email));
}

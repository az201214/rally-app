import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_club_repository.dart';
import '../data/platform_club_services.dart';
import '../domain/club.dart';
import '../domain/club_repository.dart';

final clubRepositoryProvider = Provider<ClubRepository>(
  (_) => FirestoreClubRepository(FirebaseFirestore.instance),
);
final clubLocationServiceProvider = Provider<ClubLocationService>(
  (_) => GeolocatorClubLocationService(),
);
final clubNavigationServiceProvider = Provider<ClubNavigationService>(
  (_) => GoogleMapsClubNavigationService(),
);

final clubDiscoveryProvider =
    AsyncNotifierProvider<ClubDiscoveryController, ClubDiscovery>(
      ClubDiscoveryController.new,
    );

class ClubDiscovery {
  const ClubDiscovery({
    required this.clubs,
    required this.permission,
    this.position,
    this.locationServiceDisabled = false,
    this.message,
  });

  final List<NearbyClub> clubs;
  final LocationPermissionState permission;
  final GeoPosition? position;
  final bool locationServiceDisabled;
  final String? message;
}

class ClubDiscoveryController extends AsyncNotifier<ClubDiscovery> {
  @override
  Future<ClubDiscovery> build() async {
    final repository = ref.watch(clubRepositoryProvider);
    final clubs = await repository.watchClubs().first;
    final location = ref.read(clubLocationServiceProvider);
    var permission = await location.permissionStatus();
    GeoPosition? position;
    var disabled = false;
    String? message;
    if (permission == LocationPermissionState.granted) {
      disabled = !await location.isServiceEnabled();
      if (!disabled) {
        try {
          position = await location.currentPosition();
        } on TimeoutException {
          message = 'Location timed out. Showing all clubs.';
        } catch (_) {
          message = 'Current location is unavailable. Showing all clubs.';
        }
      }
    }
    return _compose(clubs, permission, position, disabled, message);
  }

  Future<void> requestLocation() async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading<ClubDiscovery>();
    final service = ref.read(clubLocationServiceProvider);
    final permission = await service.requestPermission();
    if (permission == LocationPermissionState.deniedForever) {
      state = AsyncData(
        _compose(
          current.clubs.map((e) => e.club).toList(),
          permission,
          null,
          false,
          'Enable location in Settings to rank nearby clubs.',
        ),
      );
      return;
    }
    ref.invalidateSelf();
  }

  Future<void> openLocationSettings() =>
      ref.read(clubLocationServiceProvider).openSettings();

  ClubDiscovery _compose(
    List<Club> clubs,
    LocationPermissionState permission,
    GeoPosition? position,
    bool disabled,
    String? message,
  ) {
    final nearby = clubs
        .map(
          (club) => NearbyClub(
            club: club,
            distanceKm: position?.distanceTo(club.position) ?? 0,
          ),
        )
        .toList();
    if (position != null) {
      nearby.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
      nearby.sort((a, b) => a.club.name.compareTo(b.club.name));
    }
    return ClubDiscovery(
      clubs: nearby,
      permission: permission,
      position: position,
      locationServiceDisabled: disabled,
      message: message,
    );
  }
}

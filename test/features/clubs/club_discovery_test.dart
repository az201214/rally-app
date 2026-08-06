import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/clubs/application/club_providers.dart';
import 'package:rally/features/clubs/data/demo_club_repository.dart';
import 'package:rally/features/clubs/domain/club.dart';
import 'package:rally/features/clubs/domain/club_repository.dart';

void main() {
  test('distance calculation and travel estimate are deterministic', () {
    const origin = GeoPosition(24.817, 67.025);
    final distance = origin.distanceTo(demoClubs.first.position);
    final nearby = NearbyClub(club: demoClubs.first, distanceKm: distance);
    expect(distance, greaterThan(0));
    expect(distance, lessThan(2));
    expect(nearby.estimatedTravelMinutes, greaterThanOrEqualTo(3));
  });

  test('multiple clubs are ordered by user distance', () async {
    final container = ProviderContainer(
      overrides: [
        clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
        clubLocationServiceProvider.overrideWithValue(
          DemoClubLocationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final state = await container.read(clubDiscoveryProvider.future);
    expect(state.clubs, hasLength(3));
    expect(state.position, isNotNull);
    expect(
      state.clubs.first.distanceKm,
      lessThanOrEqualTo(state.clubs.last.distanceKm),
    );
  });

  test('permission denied still returns clubs without fake distance', () async {
    final container = ProviderContainer(
      overrides: [
        clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
        clubLocationServiceProvider.overrideWithValue(_DeniedLocation()),
      ],
    );
    addTearDown(container.dispose);
    final state = await container.read(clubDiscoveryProvider.future);
    expect(state.permission, LocationPermissionState.denied);
    expect(state.position, isNull);
    expect(state.clubs, hasLength(3));
  });

  test('GPS unavailable is represented without losing clubs', () async {
    final container = ProviderContainer(
      overrides: [
        clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
        clubLocationServiceProvider.overrideWithValue(_GpsOffLocation()),
      ],
    );
    addTearDown(container.dispose);
    final state = await container.read(clubDiscoveryProvider.future);
    expect(state.locationServiceDisabled, isTrue);
    expect(state.clubs, isNotEmpty);
  });

  test('empty clubs is a valid discovery result', () async {
    final container = ProviderContainer(
      overrides: [
        clubRepositoryProvider.overrideWithValue(_EmptyRepository()),
        clubLocationServiceProvider.overrideWithValue(
          DemoClubLocationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect((await container.read(clubDiscoveryProvider.future)).clubs, isEmpty);
  });

  test('offline repository failure remains an AsyncError', () async {
    final container = ProviderContainer(
      overrides: [
        clubRepositoryProvider.overrideWithValue(_OfflineRepository()),
        clubLocationServiceProvider.overrideWithValue(
          DemoClubLocationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(clubDiscoveryProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}

class _DeniedLocation extends DemoClubLocationService {
  @override
  Future<LocationPermissionState> permissionStatus() async =>
      LocationPermissionState.denied;
}

class _GpsOffLocation extends DemoClubLocationService {
  @override
  Future<bool> isServiceEnabled() async => false;
}

class _EmptyRepository implements ClubRepository {
  @override
  Future<Club?> getClub(String id) async => null;
  @override
  Stream<List<Club>> watchClubs() => Stream.value(const []);
}

class _OfflineRepository implements ClubRepository {
  @override
  Future<Club?> getClub(String id) => throw StateError('offline');
  @override
  Stream<List<Club>> watchClubs() => Stream.error(StateError('offline'));
}

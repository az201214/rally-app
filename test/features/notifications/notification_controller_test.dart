import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/notifications/application/notification_controller.dart';
import 'package:rally/features/notifications/domain/notification_models.dart';
import 'package:rally/features/notifications/domain/notification_repository.dart';

void main() {
  test('notification payload validates and maps supported types', () {
    final notification = RallyNotification.fromData(<String, dynamic>{
      'type': 'newChatMessage',
      'route': '/match-chat',
      'matchId': 'match-1',
      'threadId': 'thread-1',
    });

    expect(notification.type, RallyNotificationType.newChatMessage);
    expect(notification.route, '/match-chat');
    expect(notification.matchId, 'match-1');
    expect(notification.threadId, 'thread-1');
    expect(
      () => RallyNotification.fromData(<String, dynamic>{'type': 'unknown'}),
      throwsFormatException,
    );
  });

  test('all notification types resolve to an existing Rally destination', () {
    expect(
      routeForNotificationType(RallyNotificationType.matchFound),
      '/match-found',
    );
    expect(
      routeForNotificationType(RallyNotificationType.matchAccepted),
      '/match-details',
    );
    expect(
      routeForNotificationType(RallyNotificationType.newChatMessage),
      '/match-chat',
    );
    expect(
      routeForNotificationType(RallyNotificationType.matchReminder),
      '/match-details',
    );
    expect(
      routeForNotificationType(RallyNotificationType.matchCancelled),
      '/home',
    );
  });

  test(
    'registers, refreshes, and removes the authenticated device token',
    () async {
      const user = AuthUser(uid: 'user-1', email: 'player@rally.test');
      final gateway = _FakeGateway();
      final tokens = _FakeTokenRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          pushMessagingGatewayProvider.overrideWithValue(gateway),
          deviceTokenRepositoryProvider.overrideWithValue(tokens),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await gateway.dispose();
      });

      final listener = container.listen(
        notificationControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(listener.close);
      await _waitFor(
        () =>
            container.read(notificationControllerProvider).phase ==
            NotificationSetupPhase.ready,
      );
      expect(tokens.registered.map((entry) => entry.value), <String>[
        'token-1',
      ]);

      gateway.refresh.add('token-2');
      await _waitFor(
        () => tokens.registered.length == 2 && tokens.removed.length == 1,
      );
      expect(tokens.registered.last.value, 'token-2');
      expect(tokens.removed.single, 'token-1');
    },
  );

  test('exposes denied permission without attempting token storage', () async {
    final gateway = _FakeGateway(
      permission: NotificationPermissionState.denied,
    );
    final tokens = _FakeTokenRepository();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(
            const AuthUser(uid: 'user-1', email: 'player@rally.test'),
          ),
        ),
        pushMessagingGatewayProvider.overrideWithValue(gateway),
        deviceTokenRepositoryProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await gateway.dispose();
    });
    final listener = container.listen(
      notificationControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(listener.close);

    await _waitFor(
      () =>
          container.read(notificationControllerProvider).phase ==
          NotificationSetupPhase.denied,
    );
    expect(tokens.registered, isEmpty);
  });

  test(
    'logout removes the Firestore token and deletes the FCM token',
    () async {
      const user = AuthUser(uid: 'user-1', email: 'player@rally.test');
      final authChanges = StreamController<AuthUser?>.broadcast();
      final gateway = _FakeGateway();
      final tokens = _FakeTokenRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authChanges.stream),
          pushMessagingGatewayProvider.overrideWithValue(gateway),
          deviceTokenRepositoryProvider.overrideWithValue(tokens),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await authChanges.close();
        await gateway.dispose();
      });
      final listener = container.listen(
        notificationControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(listener.close);

      authChanges.add(user);
      await _waitFor(() => tokens.registered.length == 1);
      authChanges.add(null);
      await _waitFor(() => tokens.removed.length == 1 && gateway.deleted);

      expect(tokens.removed.single, 'token-1');
    },
  );
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for notification state.');
}

class _FakeGateway implements PushMessagingGateway {
  _FakeGateway({this.permission = NotificationPermissionState.authorized});

  final NotificationPermissionState permission;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<RallyNotification>.broadcast();
  final opened = StreamController<RallyNotification>.broadcast();
  bool deleted = false;

  Future<void> dispose() async {
    await refresh.close();
    await foreground.close();
    await opened.close();
  }

  @override
  Future<void> deleteToken() async {
    deleted = true;
  }

  @override
  Stream<RallyNotification> get foregroundNotifications => foreground.stream;
  @override
  Future<String?> getToken({String? webVapidKey}) async => 'token-1';
  @override
  Future<RallyNotification?> getInitialNotification() async => null;
  @override
  Stream<RallyNotification> get openedNotifications => opened.stream;
  @override
  Future<NotificationPermissionState> requestPermission() async => permission;
  @override
  Stream<String> get tokenRefreshes => refresh.stream;
}

class _FakeTokenRepository implements DeviceTokenRepository {
  final registered = <DeviceToken>[];
  final removed = <String>[];

  @override
  Future<void> register({
    required String userId,
    required DeviceToken token,
  }) async {
    registered.add(token);
  }

  @override
  Future<void> unregister({
    required String userId,
    required String token,
  }) async {
    removed.add(token);
  }
}

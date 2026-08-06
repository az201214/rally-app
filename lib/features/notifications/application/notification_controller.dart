import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_router.dart';
import '../../../routes/app_routes.dart';
import '../../authentication/application/auth_providers.dart';
import '../../matchmaking/application/matchmaking_controller.dart';
import '../data/firebase_notification_repository.dart';
import '../domain/notification_models.dart';
import '../domain/notification_repository.dart';

const String rallyWebPushVapidKey = String.fromEnvironment(
  'RALLY_WEB_PUSH_VAPID_KEY',
);

final pushMessagingGatewayProvider = Provider<PushMessagingGateway>(
  (ref) => NoopPushMessagingGateway(),
);

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>(
  (ref) => NoopDeviceTokenRepository(),
);

enum NotificationSetupPhase {
  idle,
  requestingPermission,
  registering,
  ready,
  denied,
  error,
}

class NotificationState {
  const NotificationState({
    this.phase = NotificationSetupPhase.idle,
    this.errorMessage,
    this.foregroundNotification,
  });

  final NotificationSetupPhase phase;
  final String? errorMessage;
  final RallyNotification? foregroundNotification;
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

class NotificationController extends Notifier<NotificationState> {
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RallyNotification>? _foregroundSubscription;
  StreamSubscription<RallyNotification>? _openedSubscription;
  String? _registeredUserId;
  String? _registeredToken;
  RallyNotification? _pendingNavigation;
  int _generation = 0;

  @override
  NotificationState build() {
    final gateway = ref.watch(pushMessagingGatewayProvider);
    ref
      ..onDispose(_dispose)
      ..listen(authStateProvider, (previous, next) {
        if (next.isLoading) return;
        final user = next.value;
        if (user == null) {
          unawaited(_unregister());
          state = const NotificationState();
        } else if (user.uid != _registeredUserId) {
          unawaited(_register(user.uid));
          final pending = _pendingNavigation;
          if (pending != null) {
            _pendingNavigation = null;
            unawaited(_open(pending));
          }
        }
      });
    _foregroundSubscription = gateway.foregroundNotifications.listen(
      (notification) => state = NotificationState(
        phase: state.phase,
        errorMessage: state.errorMessage,
        foregroundNotification: notification,
      ),
    );
    _openedSubscription = gateway.openedNotifications.listen(_handleOpen);
    unawaited(
      gateway.getInitialNotification().then((value) {
        if (value != null) _handleOpen(value);
      }),
    );
    final user = ref.read(authStateProvider).value;
    if (user != null) unawaited(_register(user.uid));
    return const NotificationState();
  }

  Future<void> retry() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) await _register(user.uid);
  }

  Future<void> _register(String userId) async {
    final generation = ++_generation;
    state = const NotificationState(
      phase: NotificationSetupPhase.requestingPermission,
    );
    try {
      final gateway = ref.read(pushMessagingGatewayProvider);
      final permission = await gateway.requestPermission();
      if (generation != _generation) return;
      if (permission != NotificationPermissionState.authorized) {
        state = const NotificationState(phase: NotificationSetupPhase.denied);
        return;
      }
      state = const NotificationState(
        phase: NotificationSetupPhase.registering,
      );
      final token = await gateway.getToken(
        webVapidKey: rallyWebPushVapidKey.isEmpty ? null : rallyWebPushVapidKey,
      );
      if (generation != _generation) return;
      if (token == null || token.isEmpty) {
        throw StateError('Firebase did not return a messaging token.');
      }
      await _saveToken(userId, token);
      if (generation != _generation) return;
      await _tokenSubscription?.cancel();
      _tokenSubscription = gateway.tokenRefreshes.listen(
        (freshToken) => unawaited(_replaceToken(userId, freshToken)),
        onError: (Object error, StackTrace stackTrace) => _setError(),
      );
      state = const NotificationState(phase: NotificationSetupPhase.ready);
    } catch (_) {
      if (generation == _generation) _setError();
    }
  }

  Future<void> _replaceToken(String userId, String freshToken) async {
    if (_registeredToken == freshToken) return;
    final oldToken = _registeredToken;
    try {
      await _saveToken(userId, freshToken);
      if (oldToken != null) {
        await ref
            .read(deviceTokenRepositoryProvider)
            .unregister(userId: userId, token: oldToken);
      }
      state = const NotificationState(phase: NotificationSetupPhase.ready);
    } catch (_) {
      _setError();
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await ref
        .read(deviceTokenRepositoryProvider)
        .register(
          userId: userId,
          token: DeviceToken(
            value: token,
            platform: FirebasePushMessagingGateway.platformName,
          ),
        );
    _registeredUserId = userId;
    _registeredToken = token;
  }

  Future<void> _unregister() async {
    final generation = ++_generation;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    final userId = _registeredUserId;
    final token = _registeredToken;
    _registeredUserId = null;
    _registeredToken = null;
    if (userId == null || token == null) return;
    var failed = false;
    try {
      await ref
          .read(deviceTokenRepositoryProvider)
          .unregister(userId: userId, token: token);
    } catch (_) {
      failed = true;
    }
    try {
      await ref.read(pushMessagingGatewayProvider).deleteToken();
    } catch (_) {
      failed = true;
    }
    if (failed && generation == _generation) _setError();
  }

  void _handleOpen(RallyNotification notification) {
    if (ref.read(authStateProvider).value == null) {
      _pendingNavigation = notification;
      return;
    }
    unawaited(_open(notification));
  }

  Future<void> _open(RallyNotification notification) async {
    final allowed = <String>{
      AppRoutes.matchFound,
      AppRoutes.matchDetails,
      AppRoutes.matchChat,
      AppRoutes.home,
    };
    final route = allowed.contains(notification.route)
        ? notification.route
        : routeForNotificationType(notification.type);
    if (notification.matchId.isNotEmpty) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref
            .read(matchmakingControllerProvider.notifier)
            .restore(user.uid);
      }
    }
    ref.read(appRouterProvider).go(route);
  }

  void _setError() {
    state = const NotificationState(
      phase: NotificationSetupPhase.error,
      errorMessage: 'Notifications could not be enabled. Try again later.',
    );
  }

  void _dispose() {
    ++_generation;
    unawaited(_tokenSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
  }
}

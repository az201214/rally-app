import 'notification_models.dart';

abstract interface class PushMessagingGateway {
  Future<NotificationPermissionState> requestPermission();
  Future<String?> getToken({String? webVapidKey});
  Future<void> deleteToken();
  Stream<String> get tokenRefreshes;
  Stream<RallyNotification> get foregroundNotifications;
  Stream<RallyNotification> get openedNotifications;
  Future<RallyNotification?> getInitialNotification();
}

abstract interface class DeviceTokenRepository {
  Future<void> register({required String userId, required DeviceToken token});
  Future<void> unregister({required String userId, required String token});
}

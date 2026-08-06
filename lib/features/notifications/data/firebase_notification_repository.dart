import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/notification_models.dart';
import '../domain/notification_repository.dart';

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<NotificationPermissionState> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => NotificationPermissionState.authorized,
      AuthorizationStatus.denied => NotificationPermissionState.denied,
      _ => NotificationPermissionState.notDetermined,
    };
  }

  @override
  Future<String?> getToken({String? webVapidKey}) =>
      _messaging.getToken(vapidKey: kIsWeb ? webVapidKey : null);

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<RallyNotification> get foregroundNotifications => FirebaseMessaging
      .onMessage
      .map(_mapMessage)
      .where((value) => value != null)
      .cast();

  @override
  Stream<RallyNotification> get openedNotifications => FirebaseMessaging
      .onMessageOpenedApp
      .map(_mapMessage)
      .where((value) => value != null)
      .cast();

  @override
  Future<RallyNotification?> getInitialNotification() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _mapMessage(message);
  }

  static RallyNotification? _mapMessage(RemoteMessage message) {
    try {
      return RallyNotification.fromData(
        message.data,
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      );
    } on FormatException {
      return null;
    }
  }

  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unsupported';
  }
}

class FirestoreDeviceTokenRepository implements DeviceTokenRepository {
  FirestoreDeviceTokenRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> register({required String userId, required DeviceToken token}) {
    final id = _tokenId(token.value);
    final reference = _tokens(userId).doc(id);
    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      transaction.set(reference, <String, Object?>{
        'id': id,
        'userId': userId,
        'token': token.value,
        'platform': token.platform,
        'enabled': true,
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> unregister({required String userId, required String token}) =>
      _tokens(userId).doc(_tokenId(token)).delete();

  CollectionReference<Map<String, dynamic>> _tokens(String userId) =>
      _firestore.collection('users').doc(userId).collection('deviceTokens');

  static String _tokenId(String token) {
    int hash(int seed) {
      var value = seed;
      for (final unit in token.codeUnits) {
        value = ((value * 33) ^ unit) & 0x1fffffff;
      }
      return value;
    }

    final first = hash(5381).toRadixString(16).padLeft(8, '0');
    final second = hash(52711).toRadixString(16).padLeft(8, '0');
    return '$first$second';
  }
}

class NoopPushMessagingGateway implements PushMessagingGateway {
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<RallyNotification> get foregroundNotifications => const Stream.empty();
  @override
  Future<String?> getToken({String? webVapidKey}) async => null;
  @override
  Future<RallyNotification?> getInitialNotification() async => null;
  @override
  Stream<RallyNotification> get openedNotifications => const Stream.empty();
  @override
  Future<NotificationPermissionState> requestPermission() async =>
      NotificationPermissionState.denied;
  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}

class NoopDeviceTokenRepository implements DeviceTokenRepository {
  @override
  Future<void> register({
    required String userId,
    required DeviceToken token,
  }) async {}
  @override
  Future<void> unregister({
    required String userId,
    required String token,
  }) async {}
}

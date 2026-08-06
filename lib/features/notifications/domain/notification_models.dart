enum RallyNotificationType {
  matchFound,
  matchAccepted,
  newChatMessage,
  matchReminder,
  matchCancelled,
}

class RallyNotification {
  const RallyNotification({
    required this.type,
    required this.route,
    this.matchId = '',
    this.threadId = '',
    this.title = '',
    this.body = '',
  });

  factory RallyNotification.fromData(
    Map<String, dynamic> data, {
    String title = '',
    String body = '',
  }) {
    final rawType = data['type'] as String? ?? '';
    final type = RallyNotificationType.values.where(
      (value) => value.name == rawType,
    );
    if (type.isEmpty) {
      throw const FormatException('Unsupported Rally notification type.');
    }
    return RallyNotification(
      type: type.first,
      route: data['route'] as String? ?? '',
      matchId: data['matchId'] as String? ?? '',
      threadId: data['threadId'] as String? ?? '',
      title: title,
      body: body,
    );
  }

  final RallyNotificationType type;
  final String route;
  final String matchId;
  final String threadId;
  final String title;
  final String body;
}

String routeForNotificationType(RallyNotificationType type) => switch (type) {
  RallyNotificationType.matchFound => '/match-found',
  RallyNotificationType.matchAccepted ||
  RallyNotificationType.matchReminder => '/match-details',
  RallyNotificationType.newChatMessage => '/match-chat',
  RallyNotificationType.matchCancelled => '/home',
};

enum NotificationPermissionState { notDetermined, denied, authorized }

class DeviceToken {
  const DeviceToken({required this.value, required this.platform});

  final String value;
  final String platform;
}

import 'package:flutter/foundation.dart';

abstract final class DemoMode {
  static const bool enabled = bool.fromEnvironment(
    'RALLY_DEMO_MODE',
    defaultValue: false,
  );

  static bool get showDeveloperIndicator => enabled && kDebugMode;
}

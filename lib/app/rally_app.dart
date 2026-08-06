import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/app_router.dart';
import '../demo/demo_mode.dart';
import '../features/notifications/application/notification_controller.dart';
import '../shared/widgets/rally_snackbar.dart';
import '../theme/app_theme.dart';

/// Root widget for the Rally application.
class RallyApp extends ConsumerWidget {
  const RallyApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationControllerProvider);
    ref.listen(notificationControllerProvider, (previous, next) {
      final notification = next.foregroundNotification;
      if (notification == null ||
          identical(notification, previous?.foregroundNotification)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final snackbarContext = scaffoldMessengerKey.currentContext;
        if (snackbarContext == null) return;
        RallySnackbar.show(
          snackbarContext,
          message: notification.body.isEmpty
              ? notification.title
              : notification.body,
          icon: Icons.notifications_active_rounded,
        );
      });
    });
    return MaterialApp.router(
      title: 'Rally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => Stack(
        children: <Widget>[
          child ?? const SizedBox.shrink(),
          if (DemoMode.showDeveloperIndicator)
            const Positioned(
              top: 4,
              right: 4,
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'DEMO',
                      style: TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

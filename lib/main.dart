import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/rally_app.dart';
import 'demo/demo_matchmaking_repositories.dart';
import 'demo/demo_chat_repository.dart';
import 'demo/demo_mode.dart';
import 'demo/demo_repositories.dart';
import 'features/authentication/application/auth_providers.dart';
import 'features/chat/application/chat_providers.dart';
import 'features/clubs/application/club_providers.dart';
import 'features/clubs/data/demo_club_repository.dart';
import 'features/matchmaking/application/matchmaking_controller.dart';
import 'features/notifications/application/notification_controller.dart';
import 'features/notifications/data/firebase_notification_repository.dart';
import 'features/notifications/data/notification_background_handler.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint(
      <String, Object>{
        'scope': 'rally_boot',
        'demoMode': DemoMode.enabled,
      }.toString(),
    );
  }
  if (DemoMode.enabled) {
    runApp(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
          playerProfileRepositoryProvider.overrideWithValue(
            DemoPlayerProfileRepository(),
          ),
          availabilityRepositoryProvider.overrideWithValue(
            DemoAvailabilityRepository(),
          ),
          matchmakingRepositoryProvider.overrideWithValue(
            DemoMatchmakingRepository(),
          ),
          chatRepositoryProvider.overrideWithValue(DemoChatRepository()),
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          clubLocationServiceProvider.overrideWithValue(
            DemoClubLocationService(),
          ),
          pushMessagingGatewayProvider.overrideWithValue(
            NoopPushMessagingGateway(),
          ),
          deviceTokenRepositoryProvider.overrideWithValue(
            NoopDeviceTokenRepository(),
          ),
        ],
        child: const RallyApp(),
      ),
    );
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(
      rallyFirebaseMessagingBackgroundHandler,
    );
    runApp(
      ProviderScope(
        overrides: [
          pushMessagingGatewayProvider.overrideWithValue(
            FirebasePushMessagingGateway(FirebaseMessaging.instance),
          ),
          deviceTokenRepositoryProvider.overrideWithValue(
            FirestoreDeviceTokenRepository(FirebaseFirestore.instance),
          ),
        ],
        child: const RallyApp(),
      ),
    );
  } catch (_) {
    runApp(const _FirebaseSetupRequiredApp());
  }
}

class _FirebaseSetupRequiredApp extends StatelessWidget {
  const _FirebaseSetupRequiredApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.carbonBlack,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Rally needs Firebase configuration before it can start.\n\n'
                'Run flutterfire configure, then launch again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

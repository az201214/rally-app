import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/rally_app.dart';
import 'demo/demo_mode.dart';
import 'demo/demo_repositories.dart';
import 'demo/demo_matchmaking_repositories.dart';
import 'features/authentication/application/auth_providers.dart';
import 'features/matchmaking/application/matchmaking_controller.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    runApp(const ProviderScope(child: RallyApp()));
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

import 'package:flutter_test/flutter_test.dart';
import 'package:rally/demo/demo_repositories.dart';
import 'package:rally/demo/rally_demo_service.dart';
import 'package:rally/features/profile/domain/player_profile.dart';

void main() {
  test(
    'demo account and profile repositories complete the local auth slice',
    () async {
      final auth = DemoAuthRepository();
      final profiles = DemoPlayerProfileRepository();
      final user = await auth.register(
        email: 'client@rally.app',
        password: 'valid-password',
      );
      final profile = PlayerProfile.newPlayer(
        uid: user.uid,
        fullName: 'Client Player',
        email: user.email,
      );
      await profiles.createProfile(profile);

      expect(auth.currentUser?.uid, 'rally-demo-player');
      expect((await profiles.loadProfile(user.uid))?.fullName, 'Client Player');
      await auth.logout();
      expect(auth.currentUser, isNull);
    },
  );

  test('demo chat messages persist for the current app session', () {
    final service = RallyDemoService.instance..resetSession();
    service.sendChatMessage('Court 03 confirmed.');
    expect(service.chatMessages, <String>['Court 03 confirmed.']);
    service.resetSession();
  });
}

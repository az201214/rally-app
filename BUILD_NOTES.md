# Rally Build Update

This update adds the first complete premium demo journey:

- Searching automatically resolves after 7.2 seconds.
- New cinematic Match Found screen.
- Animated Rally Pulse reveal and compatibility ring.
- Verified player identity, reliability, distance, match time and AI rationale.
- Accept Match flow.
- New Match Details screen with venue, players, match plan and confirmation state.
- New routes: `/match-found` and `/match-details`.
- Reduced-motion behavior and haptic feedback support.

## Demo flow

Home → Find Match → Searching → Match Found → Accept Match → Match Details

## Run

```bash
flutter pub get
flutter run -d chrome
```

The environment used to modify this archive did not include the Flutter SDK, so run `flutter analyze` locally before presenting the build.

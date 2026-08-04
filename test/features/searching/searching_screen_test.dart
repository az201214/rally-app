import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/searching/presentation/screens/searching_screen.dart';
import 'package:rally/theme/app_theme.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: true, textScaler: TextScaler.noScaling),
        child: child!,
      ),
      home: const SearchingScreen(),
    );
  }

  testWidgets('renders search status and mock discovery data', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(find.text('SEARCHING FOR MATCH'), findsOneWidget);
    expect(find.text('Finding nearby players...'), findsOneWidget);
    expect(find.text('Players Nearby'), findsOneWidget);
    expect(find.text('Compatible'), findsOneWidget);
    expect(find.text('Ready Now'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const Key('cancel-search-button')), findsOneWidget);
  });

  testWidgets('renders without overflow on a compact display', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

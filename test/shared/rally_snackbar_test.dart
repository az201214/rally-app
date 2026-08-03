import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/shared/widgets/rally_snackbar.dart';
import 'package:rally/theme/app_colors.dart';
import 'package:rally/theme/app_theme.dart';

void main() {
  testWidgets('renders the branded Rally Snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => RallySnackbar.show(
                context,
                message: 'Your match is confirmed.',
              ),
              child: const Text('Show status'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show status'));
    await tester.pump();

    expect(find.text('Your match is confirmed.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackbar.behavior, SnackBarBehavior.floating);
    expect(snackbar.backgroundColor, Colors.transparent);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                AppColors.surfaceElevated.withValues(alpha: 0.98),
      ),
      findsOneWidget,
    );
  });
}

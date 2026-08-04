import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/divider_with_text.dart';
import '../../../../shared/widgets/page_scaffold.dart';
import '../../../../shared/widgets/password_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_logo.dart';
import '../../../../shared/widgets/rally_text_field.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../../theme/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const RallyLogo(),
            const SizedBox(height: AppSpacing.xl),
            const RallyTextField(
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icon(Icons.email_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            const PasswordTextField(
              labelText: 'Password',
              textInputAction: TextInputAction.done,
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('login-button'),
              label: 'Log in',
              isLoading: _loading,
              onPressed: _login,
            ),
            const SizedBox(height: AppSpacing.lg),
            const DividerWithText(label: 'or'),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: 'Create account',
              onPressed: () => context.push(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}

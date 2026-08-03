import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/divider_with_text.dart';
import '../../../../shared/widgets/password_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_logo.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../shared/widgets/rally_text_field.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _canSubmit = false;

  String? _emailError(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _passwordError(String? value) =>
      value == null || value.isEmpty ? 'Enter your password.' : null;

  void _updateValidity(String _) {
    final valid =
        _emailError(_emailController.text) == null &&
        _passwordError(_passwordController.text) == null;
    if (valid != _canSubmit) setState(() => _canSubmit = valid);
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authActionControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted || success) return;
    final error = ref.read(authActionControllerProvider).error;
    RallySnackbar.show(
      context,
      message: userFacingAuthError(error ?? const Object()),
      icon: Icons.error_outline_rounded,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionControllerProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const RallyLogo(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'WELCOME BACK',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    RallyTextField(
                      key: const Key('login-email-field'),
                      controller: _emailController,
                      validator: _emailError,
                      onChanged: _updateValidity,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordTextField(
                      key: const Key('login-password-field'),
                      controller: _passwordController,
                      validator: _passwordError,
                      onChanged: _updateValidity,
                      onFieldSubmitted: (_) =>
                          _canSubmit && !isLoading ? _login() : null,
                      labelText: 'Password',
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PrimaryButton(
                      key: const Key('login-button'),
                      label: 'Log in',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: isLoading,
                      onPressed: _canSubmit ? _login : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const DividerWithText(label: 'or'),
                    const SizedBox(height: AppSpacing.lg),
                    SecondaryButton(
                      label: 'Create account',
                      onPressed: isLoading
                          ? null
                          : () => context.push(AppRoutes.register),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

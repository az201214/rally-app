import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/password_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_logo.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../shared/widgets/rally_text_field.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isValid = false;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name.';
    }
    if (value.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Enter your first and last name.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Create a password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(authActionControllerProvider.notifier)
        .register(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted || success) return;
    RallySnackbar.show(
      context,
      message: userFacingAuthError(
        ref.read(authActionControllerProvider).error ?? const Object(),
      ),
      icon: Icons.error_outline_rounded,
    );
  }

  void _updateValidity(String _) {
    final valid =
        _validateName(_nameController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null &&
        _validateConfirmation(_confirmPasswordController.text) == null;
    if (valid != _isValid) setState(() => _isValid = valid);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authActionControllerProvider).isLoading;
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        key: const Key('register-back-button'),
                        onPressed: isSubmitting ? null : _goBack,
                        tooltip: 'Back to login',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const RallyLogo(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'CREATE YOUR PLAYER PROFILE',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'One account. Your level, availability, and next Rally.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    RallyTextField(
                      key: const Key('register-name-field'),
                      controller: _nameController,
                      validator: _validateName,
                      onChanged: _updateValidity,
                      labelText: 'Full name',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RallyTextField(
                      key: const Key('register-email-field'),
                      controller: _emailController,
                      validator: _validateEmail,
                      onChanged: _updateValidity,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordTextField(
                      key: const Key('register-password-field'),
                      controller: _passwordController,
                      validator: _validatePassword,
                      onChanged: _updateValidity,
                      labelText: 'Password',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordTextField(
                      key: const Key('register-confirm-password-field'),
                      controller: _confirmPasswordController,
                      validator: _validateConfirmation,
                      onChanged: _updateValidity,
                      onFieldSubmitted: (_) =>
                          _isValid && !isSubmitting ? _createAccount() : null,
                      labelText: 'Confirm password',
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const Key('create-account-button'),
                      label: 'Create account',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: isSubmitting,
                      onPressed: _isValid ? _createAccount : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Already a player?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          key: const Key('register-login-link'),
                          onPressed: isSubmitting
                              ? null
                              : () => context.go(AppRoutes.login),
                          child: const Text('Log in'),
                        ),
                      ],
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

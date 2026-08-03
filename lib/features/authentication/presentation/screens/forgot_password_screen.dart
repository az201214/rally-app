import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../shared/widgets/rally_text_field.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isValid = false;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authActionControllerProvider.notifier)
        .resetPassword(_emailController.text);
    if (!mounted) return;
    if (success) {
      RallySnackbar.show(
        context,
        message: 'Password reset email sent. Check your inbox.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      context.go(AppRoutes.login);
    } else {
      RallySnackbar.show(
        context,
        message: userFacingAuthError(
          ref.read(authActionControllerProvider).error ?? const Object(),
        ),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authActionControllerProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        onPressed: loading
                            ? null
                            : () => context.canPop()
                                  ? context.pop()
                                  : context.go(AppRoutes.login),
                        tooltip: 'Back to login',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 56,
                      color: AppColors.electricGreen,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'RESET PASSWORD',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter your email and we’ll send a secure reset link.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    RallyTextField(
                      key: const Key('reset-email-field'),
                      controller: _emailController,
                      validator: _validateEmail,
                      onChanged: (value) {
                        final valid = _validateEmail(value) == null;
                        if (valid != _isValid) setState(() => _isValid = valid);
                      },
                      onFieldSubmitted: (_) =>
                          _isValid && !loading ? _submit() : null,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const Key('reset-password-button'),
                      label: 'Send reset link',
                      isLoading: loading,
                      onPressed: _isValid ? _submit : null,
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

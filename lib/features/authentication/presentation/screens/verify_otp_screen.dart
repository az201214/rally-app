import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_text_field.dart';
import '../../../../theme/app_spacing.dart';

class VerifyOtpScreen extends StatelessWidget {
  const VerifyOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.forgotPassword),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'CHECK YOUR EMAIL',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter the four-digit code sent to your email.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const RallyTextField(
                    labelText: 'Verification code',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Verify and continue',
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

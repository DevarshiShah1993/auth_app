import 'dart:async';

import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/core/widgets/app_text_field.dart';
import 'package:auth_app/core/widgets/auth_card.dart';
import 'package:auth_app/core/widgets/auth_icon_tile.dart';
import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:auth_app/core/widgets/inline_banner.dart';
import 'package:auth_app/core/widgets/inline_banner_variant.dart';
import 'package:auth_app/core/widgets/primary_button.dart';
import 'package:auth_app/core/widgets/primary_button_variant.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_bloc.dart';
import 'package:auth_app/features/auth/presentation/utils/failure_messages.dart';
import 'package:auth_app/features/auth/presentation/widgets/shaking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Check Your Email: confirmation-link instructions with a resend action
/// (AC-07 to AC-13). Shows the expired-link variant when the session bloc
/// reports an invalid link.
///
/// Expects a [CheckEmailBloc] and the app-wide [AuthSessionBloc] above it.
class CheckEmailPage extends StatefulWidget {
  /// Creates the page.
  const CheckEmailPage({super.key});

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  static const Duration _successBannerDuration = Duration(seconds: 5);

  final _emailController = TextEditingController();
  final _emailKey = GlobalKey<AppTextFieldState>();
  Timer? _bannerTimer;
  late bool _expired;

  @override
  void initState() {
    super.initState();
    final session = context.read<AuthSessionBloc>();
    // Latch the variant: the one-shot link result is cleared right after.
    _expired = session.state.linkResult == EmailLinkResult.invalid;
    if (_expired) _consumeLinkResult();
  }

  void _consumeLinkResult() {
    final session = context.read<AuthSessionBloc>();
    // The session bloc lives for the whole app run, so it is never closed
    // while a page is shown.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => session.add(const AuthSessionLinkResultConsumed()),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _resend(CheckEmailState state) {
    final known = state.email;
    if (known == null) {
      // Same validation as Sign In; invalid input makes no network call.
      if (!(_emailKey.currentState?.validate() ?? false)) return;
      FocusScope.of(context).unfocus();
      context.read<CheckEmailBloc>().add(
        CheckEmailResendRequested(email: _emailController.text),
      );
    } else {
      context.read<CheckEmailBloc>().add(
        CheckEmailResendRequested(email: known),
      );
    }
  }

  void _onBlocChanged(BuildContext context, CheckEmailState state) {
    _bannerTimer?.cancel();
    if (state.status == SubmitStatus.success) {
      // Back to the normal variant once a new email went out.
      if (_expired) setState(() => _expired = false);
      _bannerTimer = Timer(_successBannerDuration, () {
        if (mounted) {
          context.read<CheckEmailBloc>().add(
            const CheckEmailMessageDismissed(),
          );
        }
      });
    }
  }

  static String _clock(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthSessionBloc, AuthSessionState>(
          listenWhen: (previous, current) =>
              current.linkResult == EmailLinkResult.invalid,
          listener: (context, state) {
            setState(() => _expired = true);
            _consumeLinkResult();
          },
        ),
        BlocListener<CheckEmailBloc, CheckEmailState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onBlocChanged,
        ),
      ],
      child: AuthScaffold(
        child: BlocBuilder<CheckEmailBloc, CheckEmailState>(
          builder: (context, state) => _buildCard(context, state),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, CheckEmailState state) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final email = state.email;
    final loading = state.status == SubmitStatus.loading;
    final cooling = state.isCoolingDown;
    final failure = state.status == SubmitStatus.failure ? state.failure : null;

    Widget tile = AuthIconTile(
      icon: _expired ? Icons.link_off : Icons.mark_email_read_outlined,
      size: 56,
      isError: _expired,
    );
    if (!AppMotion.reduced(context)) {
      tile = tile
          .animate()
          .fadeIn(duration: AppMotion.successIn)
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: AppMotion.successIn,
            curve: AppMotion.curve,
          );
    }

    final resendLabel = cooling
        ? 'Resend email in ${_clock(state.remainingSeconds)}'
        : 'Resend email';

    return AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: tile),
          SizedBox(height: spacing.md),
          Text(
            _expired ? 'Link expired' : 'Check your email',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          SizedBox(height: spacing.sm),
          if (_expired) ...[
            Shaking(
              child: const InlineBanner(message: FailureMessages.linkExpired),
            ),
            SizedBox(height: spacing.md),
            Text(
              'Request a new confirmation email below, or go back to sign in.',
              textAlign: TextAlign.center,
              style: secondary,
            ),
          ] else if (email != null) ...[
            Text(
              'We sent a confirmation link to',
              textAlign: TextAlign.center,
              style: secondary,
            ),
          ],
          if (email != null) ...[
            SizedBox(height: spacing.sm),
            SelectableText(
              email,
              textAlign: TextAlign.center,
              style: context.appText.dataSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
          if (!_expired) ...[
            SizedBox(height: spacing.sm),
            Text(
              'Tap the link in the email to confirm your account, then sign '
              'in.',
              textAlign: TextAlign.center,
              style: secondary,
            ),
            SizedBox(height: spacing.sm),
            Text(
              "Can't find it? Check your spam folder.",
              textAlign: TextAlign.center,
              style: secondary,
            ),
          ],
          SizedBox(height: spacing.lg),
          if (email == null) ...[
            AppTextField(
              key: _emailKey,
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              enableSuggestions: false,
              enabled: !loading,
              validator: Validators.email,
              onChanged: (_) {
                if (state.status == SubmitStatus.failure) {
                  context.read<CheckEmailBloc>().add(
                    const CheckEmailMessageDismissed(),
                  );
                }
              },
              onFieldSubmitted: (_) {
                if (!cooling) _resend(state);
              },
            ),
            SizedBox(height: spacing.md),
          ],
          if (state.status == SubmitStatus.success) ...[
            const InlineBanner(
              message: FailureMessages.resendSuccess,
              variant: InlineBannerVariant.success,
            ),
            SizedBox(height: spacing.md),
          ] else if (failure != null) ...[
            Shaking(child: InlineBanner(message: FailureMessages.of(failure))),
            SizedBox(height: spacing.md),
          ],
          PrimaryButton(
            label: resendLabel,
            variant: PrimaryButtonVariant.outlined,
            isLoading: loading,
            onPressed: cooling ? null : () => _resend(state),
          ),
          SizedBox(height: spacing.sm),
          TextButton(
            onPressed: () => context.goNamed(Routes.signIn),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}

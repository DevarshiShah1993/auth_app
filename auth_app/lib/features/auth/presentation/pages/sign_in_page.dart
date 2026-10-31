import 'package:auth_app/core/error/email_not_confirmed_failure.dart';
import 'package:auth_app/core/error/invalid_credentials_failure.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/core/widgets/app_text_field.dart';
import 'package:auth_app/core/widgets/auth_card.dart';
import 'package:auth_app/core/widgets/auth_icon_tile.dart';
import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:auth_app/core/widgets/inline_banner.dart';
import 'package:auth_app/core/widgets/inline_banner_variant.dart';
import 'package:auth_app/core/widgets/password_field.dart';
import 'package:auth_app/core/widgets/primary_button.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:auth_app/features/auth/presentation/utils/failure_messages.dart';
import 'package:auth_app/features/auth/presentation/widgets/shaking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Sign In: email and password (AC-14 to AC-20).
///
/// Expects a [SignInBloc] and the app's [AuthSessionBloc] above it in the
/// tree. On success the router moves the user to Home. It shows the
/// "email confirmed" banner once when the session bloc holds a confirmed
/// link result, then consumes that result.
class SignInPage extends StatefulWidget {
  /// Creates the page. [initialEmail] prefills the email field.
  const SignInPage({super.key, this.initialEmail});

  /// Address to prefill, or null.
  final String? initialEmail;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<PasswordFieldState>();
  bool _showConfirmed = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    final session = context.read<AuthSessionBloc>();
    if (session.state.linkResult == EmailLinkResult.confirmed) {
      _showConfirmed = true;
      session.add(const AuthSessionLinkResultConsumed());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onEdited() {
    final bloc = context.read<SignInBloc>();
    if (bloc.state.status == SubmitStatus.failure) {
      bloc.add(const SignInFailureDismissed());
    }
    if (_showConfirmed) setState(() => _showConfirmed = false);
  }

  void _submit() {
    final bloc = context.read<SignInBloc>();
    if (bloc.state.status == SubmitStatus.loading) return;
    // Run every validator (no short-circuit) so all invalid fields shake.
    final emailOk = _emailKey.currentState?.validate() ?? true;
    final passwordOk = _passwordKey.currentState?.validate() ?? true;
    if (!emailOk) {
      _emailFocus.requestFocus();
    } else if (!passwordOk) {
      _passwordFocus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      if (_showConfirmed) setState(() => _showConfirmed = false);
      bloc.add(SignInSubmitted(email: _email.text, password: _password.text));
    }
  }

  void _onSignInState(BuildContext context, SignInState state) {
    if (state.failure is InvalidCredentialsFailure) {
      // AC-18: clear the password, keep the email.
      _password.clear();
      _passwordFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final hideTile = keyboardOpen && media.size.height < 700;

    return MultiBlocListener(
      listeners: [
        BlocListener<SignInBloc, SignInState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == SubmitStatus.failure,
          listener: _onSignInState,
        ),
        BlocListener<AuthSessionBloc, AuthSessionState>(
          // A link opened while this page is already showing.
          listenWhen: (previous, current) =>
              previous.linkResult != current.linkResult &&
              current.linkResult == EmailLinkResult.confirmed,
          listener: (context, state) {
            setState(() => _showConfirmed = true);
            context.read<AuthSessionBloc>().add(
              const AuthSessionLinkResultConsumed(),
            );
          },
        ),
      ],
      child: AuthScaffold(
        child: BlocBuilder<SignInBloc, SignInState>(
          builder: (context, state) {
            // `success` keeps the spinner until the router leaves this page.
            final busy =
                state.status == SubmitStatus.loading ||
                state.status == SubmitStatus.success;
            final failure = state.status == SubmitStatus.failure
                ? state.failure
                : null;
            final unconfirmed = failure is EmailNotConfirmedFailure;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthCard(
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.topLeft,
                          child: hideTile
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: EdgeInsets.only(bottom: spacing.md),
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: AuthIconTile(
                                      icon: Icons.lock_outline,
                                    ),
                                  ),
                                ),
                        ),
                        Text('Sign in', style: theme.textTheme.headlineMedium),
                        SizedBox(height: spacing.sm),
                        Text(
                          'Welcome back. Enter your details to continue.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: spacing.lg),
                        if (failure != null) ...[
                          Shaking(
                            child: InlineBanner(
                              message: FailureMessages.of(failure),
                              icon: unconfirmed
                                  ? Icons.mark_email_unread
                                  : null,
                              actionLabel: unconfirmed
                                  ? 'Resend confirmation email'
                                  : null,
                              onAction: unconfirmed
                                  ? () => context.goNamed(
                                      Routes.checkEmail,
                                      extra: Validators.normalizeEmail(
                                        _email.text,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(height: spacing.md),
                        ] else if (_showConfirmed) ...[
                          const InlineBanner(
                            message: FailureMessages.emailConfirmed,
                            variant: InlineBannerVariant.success,
                          ),
                          SizedBox(height: spacing.md),
                        ],
                        AppTextField(
                          key: _emailKey,
                          label: 'Email',
                          controller: _email,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          enableSuggestions: false,
                          enabled: !busy,
                          validator: Validators.email,
                          onChanged: (_) => _onEdited(),
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                        ),
                        SizedBox(height: spacing.md),
                        PasswordField(
                          key: _passwordKey,
                          label: 'Password',
                          controller: _password,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !busy,
                          validator: Validators.requiredPassword,
                          onChanged: (_) => _onEdited(),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        SizedBox(height: spacing.lg),
                        PrimaryButton(
                          label: 'Sign in',
                          isLoading: busy,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => context.goNamed(Routes.signUp),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

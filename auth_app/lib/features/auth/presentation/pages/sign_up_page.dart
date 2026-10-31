import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/core/widgets/app_text_field.dart';
import 'package:auth_app/core/widgets/auth_card.dart';
import 'package:auth_app/core/widgets/auth_icon_tile.dart';
import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:auth_app/core/widgets/inline_banner.dart';
import 'package:auth_app/core/widgets/password_field.dart';
import 'package:auth_app/core/widgets/primary_button.dart';
import 'package:auth_app/core/error/user_already_exists_failure.dart';
import 'package:auth_app/core/error/weak_password_failure.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:auth_app/features/auth/presentation/utils/failure_messages.dart';
import 'package:auth_app/features/auth/presentation/widgets/shaking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Sign Up: email, password and confirm password (AC-01 to AC-06).
///
/// Expects a [SignUpBloc] above it in the tree (provided by the route).
/// On success it goes to Check Your Email with the address as `extra`.
class SignUpPage extends StatefulWidget {
  /// Creates the page.
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<PasswordFieldState>();
  final _confirmKey = GlobalKey<PasswordFieldState>();
  bool _confirmTouched = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _dismissFailure() {
    final bloc = context.read<SignUpBloc>();
    if (bloc.state.status == SubmitStatus.failure) {
      bloc.add(const SignUpFailureDismissed());
    }
  }

  void _submit() {
    final bloc = context.read<SignUpBloc>();
    if (bloc.state.status == SubmitStatus.loading) return;
    _confirmTouched = true;
    // Run every validator (no short-circuit) so all invalid fields shake.
    final emailOk = _emailKey.currentState?.validate() ?? true;
    final passwordOk = _passwordKey.currentState?.validate() ?? true;
    final confirmOk = _confirmKey.currentState?.validate() ?? true;
    if (!emailOk) {
      _emailFocus.requestFocus();
    } else if (!passwordOk) {
      _passwordFocus.requestFocus();
    } else if (!confirmOk) {
      _confirmFocus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      bloc.add(SignUpSubmitted(email: _email.text, password: _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final hideTile = keyboardOpen && media.size.height < 700;
    final hideSubtitle = keyboardOpen && media.size.height < 640;

    return BlocListener<SignUpBloc, SignUpState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SubmitStatus.success,
      listener: (context, state) =>
          context.goNamed(Routes.checkEmail, extra: state.email),
      child: AuthScaffold(
        child: BlocBuilder<SignUpBloc, SignUpState>(
          builder: (context, state) {
            final loading = state.status == SubmitStatus.loading;
            final failure = state.status == SubmitStatus.failure
                ? state.failure
                : null;
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
                                      icon: Icons.person_add_alt,
                                    ),
                                  ),
                                ),
                        ),
                        Text(
                          'Create account',
                          style: theme.textTheme.headlineMedium,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.topLeft,
                          child: hideSubtitle
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: EdgeInsets.only(top: spacing.sm),
                                  child: Text(
                                    'Sign up with your email. We will send you '
                                    'a confirmation link.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                        ),
                        SizedBox(height: spacing.lg),
                        if (failure != null) ...[
                          Shaking(
                            child: InlineBanner(
                              message: FailureMessages.of(failure),
                              actionLabel: failure is UserAlreadyExistsFailure
                                  ? 'Sign in'
                                  : null,
                              onAction: failure is UserAlreadyExistsFailure
                                  ? () => context.goNamed(
                                      Routes.signIn,
                                      extra: Validators.normalizeEmail(
                                        _email.text,
                                      ),
                                    )
                                  : null,
                            ),
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
                          enabled: !loading,
                          validator: Validators.email,
                          onChanged: (_) => _dismissFailure(),
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                        ),
                        SizedBox(height: spacing.md),
                        PasswordField(
                          key: _passwordKey,
                          label: 'Password',
                          controller: _password,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          helperText:
                              'At least 8 characters, with a letter and a '
                              'number',
                          enabled: !loading,
                          showErrorBorder: failure is WeakPasswordFailure,
                          validator: Validators.newPassword,
                          onChanged: (_) {
                            _dismissFailure();
                            if (_confirmTouched) {
                              _confirmKey.currentState?.validate();
                            }
                          },
                          onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                        ),
                        SizedBox(height: spacing.md),
                        PasswordField(
                          key: _confirmKey,
                          label: 'Confirm password',
                          controller: _confirm,
                          focusNode: _confirmFocus,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !loading,
                          validator: (value) =>
                              Validators.confirmPassword(_password.text, value),
                          onChanged: (_) {
                            _confirmTouched = true;
                            _dismissFailure();
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        SizedBox(height: spacing.lg),
                        PrimaryButton(
                          label: 'Sign up',
                          isLoading: loading,
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
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => context.goNamed(Routes.signIn),
                      child: const Text('Sign in'),
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

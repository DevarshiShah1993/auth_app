import 'package:auth_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// [AppTextField] that hides its text with a show/hide toggle.
///
/// Visibility is widget-local, so it resets to hidden when the page is left.
class PasswordField extends StatefulWidget {
  /// Creates a password field.
  const PasswordField({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.errorText,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.helperText,
  });

  /// Floating label, also the accessible name.
  final String label;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Action key on the keyboard.
  final TextInputAction? textInputAction;

  /// Use `AutofillHints.password` (sign in) or `newPassword` (sign up).
  final Iterable<String> autofillHints;

  /// Externally controlled error; wins over the validator error.
  final String? errorText;

  /// Returns an error message or null; run on blur and on `validate()`.
  final String? Function(String value)? validator;

  /// Whether the field accepts input.
  final bool enabled;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onFieldSubmitted;

  /// Persistent helper text, replaced by the error when invalid.
  final String? helperText;

  @override
  State<PasswordField> createState() => PasswordFieldState();
}

/// State of [PasswordField]; exposes [validate] to parent forms.
class PasswordFieldState extends State<PasswordField> {
  final GlobalKey<AppTextFieldState> _fieldKey = GlobalKey<AppTextFieldState>();
  bool _obscured = true;

  /// Runs the validator; true when valid.
  bool validate() => _fieldKey.currentState?.validate() ?? true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      key: _fieldKey,
      label: widget.label,
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.text,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      errorText: widget.errorText,
      validator: widget.validator,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      helperText: widget.helperText,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      suffix: IconButton(
        iconSize: 20,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: widget.enabled
            ? () => setState(() => _obscured = !_obscured)
            : null,
        icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
      ),
    );
  }
}

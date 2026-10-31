import 'dart:math' as math;

import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Outlined text field with a floating label, an icon + text error row,
/// validate-on-blur / clear-on-edit behaviour and a shake on new errors.
///
/// Errors come either from [errorText] (set by a bloc or parent, takes
/// precedence) or from [validator], run on blur and by calling
/// [AppTextFieldState.validate] through a `GlobalKey`.
class AppTextField extends StatefulWidget {
  /// Creates a text field.
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.showErrorBorder = false,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.helperText,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Floating label, also the accessible name.
  final String label;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Action key on the keyboard.
  final TextInputAction? textInputAction;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  /// Externally controlled error; wins over the validator error.
  final String? errorText;

  /// Shows the error border without any error text. Use when the message
  /// is already shown elsewhere (e.g. a banner) so it is not duplicated;
  /// the caller must keep that message visible (not colour-only).
  final bool showErrorBorder;

  /// Returns an error message or null; run on blur and on `validate()`.
  final String? Function(String value)? validator;

  /// Whether the field accepts input.
  final bool enabled;

  /// Called on every edit (after the internal error was cleared).
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onFieldSubmitted;

  /// Optional leading icon.
  final Widget? prefixIcon;

  /// Optional trailing widget (48dp hit area is the caller's duty).
  final Widget? suffix;

  /// Persistent helper text, replaced by the error when invalid.
  final String? helperText;

  /// Hides the text (used by `PasswordField`).
  final bool obscureText;

  /// Whether to autocorrect.
  final bool autocorrect;

  /// Whether to show input suggestions.
  final bool enableSuggestions;

  /// Capitalisation behaviour.
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

/// State of [AppTextField]; exposes [validate] to parent forms.
class AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.shake,
  );
  String? _error;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  String? get _visibleError => widget.errorText ?? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.errorText == null && widget.errorText != null) {
      _playShake();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.validator != null && mounted) {
      validate();
    }
  }

  void _playShake() {
    if (AppMotion.reduced(context)) return;
    _shake.forward(from: 0);
  }

  /// Runs the validator, shows the result and shakes on a new error.
  /// Returns true when the field is valid (or has no validator).
  bool validate() {
    final validator = widget.validator;
    if (validator == null) return widget.errorText == null;
    final result = validator(_controller.text);
    final isNew = result != null && _visibleError == null;
    setState(() => _error = result);
    if (isNew) _playShake();
    return result == null && widget.errorText == null;
  }

  void _onChanged(String value) {
    if (_error != null) setState(() => _error = null);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = _visibleError;
    final inputStyle = theme.textTheme.bodyLarge?.copyWith(
      color: widget.enabled
          ? scheme.onSurface
          : scheme.onSurface.withValues(alpha: 0.38),
    );

    final inputTheme = theme.inputDecorationTheme;
    final borderOnly = widget.showErrorBorder && error == null;

    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      textCapitalization: widget.textCapitalization,
      style: inputStyle,
      onChanged: _onChanged,
      onSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        fillColor: widget.enabled ? null : context.appColors.disabledFill,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffix,
        enabledBorder: borderOnly ? inputTheme.errorBorder : null,
        focusedBorder: borderOnly ? inputTheme.focusedErrorBorder : null,
        error: error == null ? null : _FieldError(message: error),
      ),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _shake,
        child: field,
        builder: (context, child) {
          // 4 Hz horizontal shake, 6dp amplitude, decaying to rest.
          final t = _shake.value;
          final dx = math.sin(t * 2 * math.pi * 4 * 0.32) * 6 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      ),
    );
  }
}

/// Error row: icon + text so the error is not colour-only; announced as a
/// live region.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onErrorContainer;
    final child = Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, size: 16, color: color),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
    if (AppMotion.reduced(context)) return child;
    return child
        .animate()
        .fadeIn(duration: AppMotion.errorIn)
        .slideY(
          begin: -0.1,
          end: 0,
          duration: AppMotion.errorIn,
          curve: AppMotion.curve,
        );
  }
}

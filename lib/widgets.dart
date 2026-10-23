import 'package:flutter/material.dart';

import 'theme.dart';

/// Centers its child and caps its width so screens read well on tablets and
/// desktop browsers instead of stretching edge to edge.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = AppTheme.maxContentWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Text field with a leading icon and, for passwords, a show/hide toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.autofillHints,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      enableSuggestions: !widget.obscureText,
      autocorrect: !widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              )
            : null,
      ),
    );
  }
}

enum MessageKind { error, success, info }

/// Inline message box for errors, confirmations and hints.
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.kind = MessageKind.error,
    this.onRetry,
  });

  final String message;
  final MessageKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (kind) {
      MessageKind.error => (Theme.of(context).colorScheme.error, Icons.error_outline),
      MessageKind.success => (ThemeColors.success, Icons.check_circle_outline),
      MessageKind.info => (ThemeColors.pokeBlue, Icons.info_outline),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: ThemeColors.deepNavy, height: 1.35)),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown when a list has nothing in it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          IconBadge(icon: icon, color: ThemeColors.accentMuted, size: 64),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: ThemeColors.textMuted)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Icon on a soft tinted rounded square.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Small rounded label, e.g. a monster type or a status.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Bold section title with an optional trailing widget.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ThemeColors.deepNavy)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// The team logo in a white circle.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Image.asset('assets/icons/app_logo.png', semanticLabel: 'Monster Control Center logo'),
    );
  }
}

/// Spinner sized for inside a button.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';

/// Pink CTA — used for Submit Guess, PLAY, Play Again, Claim, etc.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool flexFill;
  final bool glow;
  final IconData? leadingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.flexFill = false,
    this.glow = true,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final disabled = onPressed == null;
    final btn = Material(
      color: disabled
          ? v.accent.withValues(alpha: 0.35)
          : v.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onPressed,
        child: SizedBox(
          height: height,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: AppText.title(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final wrapped = glow && !disabled
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: v.glowAccent,
            ),
            child: btn,
          )
        : btn;

    return flexFill ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}

/// Outline button — secondary actions (Menu, Reveal, etc.)
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: v.lineStrong, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: v.text2, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppText.body(color: v.text1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ghost button — text-only, low emphasis.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: v.text2, size: 16),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppText.body(color: v.text2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill chip — used for Lv / coins / streak indicators.
class StatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? accent;

  const StatChip({super.key, required this.label, this.icon, this.accent});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final accentColor = accent ?? v.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: v.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.caption(color: v.text1).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

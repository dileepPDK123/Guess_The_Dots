import 'package:flutter/material.dart';

/// Royal Velvet — the locked-in default theme.
/// All design tokens from `design_handoff_guess_the_dots/README.md`.
///
/// Used via [Theme.of(context).extension<RoyalVelvet>()].
class RoyalVelvet extends ThemeExtension<RoyalVelvet> {
  // ── Surfaces ───────────────────────────────────────────────────────────
  final Color bg0; // deepest
  final Color bg1; // app bg
  final Color bg2; // elevated surface — cards, sheets
  final Color bg3; // rows, secondary buttons
  final Color bg4; // hover, divider heavy

  final Color line; // 8% white
  final Color lineStrong; // 14% white

  // ── Text ───────────────────────────────────────────────────────────────
  final Color text1; // primary
  final Color text2; // secondary
  final Color text3; // tertiary
  final Color textMuted;

  // ── Accents ────────────────────────────────────────────────────────────
  final Color accent; // CTA pink
  final Color accent2; // gold rewards
  final Color accentSoft; // 16% pink

  // ── Dot palette (6 jewel tones) ────────────────────────────────────────
  final Color dot1; // ruby
  final Color dot2; // amber
  final Color dot3; // emerald
  final Color dot4; // sapphire
  final Color dot5; // amethyst
  final Color dot6; // rose quartz

  // ── Pip feedback ───────────────────────────────────────────────────────
  final Color pipGreen;
  final Color pipYellow;
  final Color pipEmpty;

  // ── Shadows / glows ────────────────────────────────────────────────────
  final List<BoxShadow> el1;
  final List<BoxShadow> el2;
  final List<BoxShadow> el3;
  final List<BoxShadow> glowAccent;

  const RoyalVelvet({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.line,
    required this.lineStrong,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.textMuted,
    required this.accent,
    required this.accent2,
    required this.accentSoft,
    required this.dot1,
    required this.dot2,
    required this.dot3,
    required this.dot4,
    required this.dot5,
    required this.dot6,
    required this.pipGreen,
    required this.pipYellow,
    required this.pipEmpty,
    required this.el1,
    required this.el2,
    required this.el3,
    required this.glowAccent,
  });

  /// The default Royal Velvet theme — values from `tokens.css`.
  static const royalVelvet = RoyalVelvet(
    bg0: Color(0xFF0E0A1F),
    bg1: Color(0xFF17102E),
    bg2: Color(0xFF1F1740),
    bg3: Color(0xFF2A1F52),
    bg4: Color(0xFF3A2C6B),
    line: Color(0x14FFFFFF), // rgba(255,255,255,0.08) — 0x14/255 ≈ 0.078
    lineStrong: Color(0x24FFFFFF), // 0.14
    text1: Color(0xFFF5F1FF),
    text2: Color(0xFFB9ADE0),
    text3: Color(0xFF7A6EA8),
    textMuted: Color(0xFF554A82),
    accent: Color(0xFFF43F8E),
    accent2: Color(0xFFFFB547),
    accentSoft: Color(0x29F43F8E), // rgba(244,63,142,0.16) — 0x29/255 ≈ 0.16
    dot1: Color(0xFFFF4D6D),
    dot2: Color(0xFFFFB547),
    dot3: Color(0xFF3DDC97),
    dot4: Color(0xFF4FC3FF),
    dot5: Color(0xFFB285FF),
    dot6: Color(0xFFFF7AC6),
    pipGreen: Color(0xFF3DDC97),
    pipYellow: Color(0xFFFFB547),
    pipEmpty: Color(0x1AFFFFFF), // 0.10
    el1: [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    el2: [
      BoxShadow(
        color: Color(0x73000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    el3: [
      BoxShadow(
        color: Color(0x8C000000),
        blurRadius: 50,
        offset: Offset(0, 20),
      ),
    ],
    glowAccent: [
      BoxShadow(
        color: Color(0x73F43F8E), // rgba(244,63,142,0.45)
        blurRadius: 24,
        offset: Offset(0, 6),
      ),
    ],
  );

  /// Returns the dot color for a 1-indexed color number (1-6).
  Color dotColor(int colorNumber) {
    switch (colorNumber) {
      case 1:
        return dot1;
      case 2:
        return dot2;
      case 3:
        return dot3;
      case 4:
        return dot4;
      case 5:
        return dot5;
      case 6:
        return dot6;
      default:
        return text1;
    }
  }

  /// Velvet glow background — radial gradients on top of [bg1].
  /// Used as the app's root scaffold background.
  static Decoration velvetBackground(RoyalVelvet rv) {
    return BoxDecoration(
      color: rv.bg1,
      gradient: RadialGradient(
        center: const Alignment(-0.76, -0.84),
        radius: 1.6,
        colors: [
          rv.accent.withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ),
    );
  }

  @override
  RoyalVelvet copyWith({
    Color? bg0,
    Color? bg1,
    Color? bg2,
    Color? bg3,
    Color? bg4,
    Color? line,
    Color? lineStrong,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? textMuted,
    Color? accent,
    Color? accent2,
    Color? accentSoft,
    Color? dot1,
    Color? dot2,
    Color? dot3,
    Color? dot4,
    Color? dot5,
    Color? dot6,
    Color? pipGreen,
    Color? pipYellow,
    Color? pipEmpty,
    List<BoxShadow>? el1,
    List<BoxShadow>? el2,
    List<BoxShadow>? el3,
    List<BoxShadow>? glowAccent,
  }) {
    return RoyalVelvet(
      bg0: bg0 ?? this.bg0,
      bg1: bg1 ?? this.bg1,
      bg2: bg2 ?? this.bg2,
      bg3: bg3 ?? this.bg3,
      bg4: bg4 ?? this.bg4,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      accentSoft: accentSoft ?? this.accentSoft,
      dot1: dot1 ?? this.dot1,
      dot2: dot2 ?? this.dot2,
      dot3: dot3 ?? this.dot3,
      dot4: dot4 ?? this.dot4,
      dot5: dot5 ?? this.dot5,
      dot6: dot6 ?? this.dot6,
      pipGreen: pipGreen ?? this.pipGreen,
      pipYellow: pipYellow ?? this.pipYellow,
      pipEmpty: pipEmpty ?? this.pipEmpty,
      el1: el1 ?? this.el1,
      el2: el2 ?? this.el2,
      el3: el3 ?? this.el3,
      glowAccent: glowAccent ?? this.glowAccent,
    );
  }

  @override
  RoyalVelvet lerp(ThemeExtension<RoyalVelvet>? other, double t) {
    if (other is! RoyalVelvet) return this;
    return RoyalVelvet(
      bg0: Color.lerp(bg0, other.bg0, t)!,
      bg1: Color.lerp(bg1, other.bg1, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      bg3: Color.lerp(bg3, other.bg3, t)!,
      bg4: Color.lerp(bg4, other.bg4, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      text1: Color.lerp(text1, other.text1, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      dot1: Color.lerp(dot1, other.dot1, t)!,
      dot2: Color.lerp(dot2, other.dot2, t)!,
      dot3: Color.lerp(dot3, other.dot3, t)!,
      dot4: Color.lerp(dot4, other.dot4, t)!,
      dot5: Color.lerp(dot5, other.dot5, t)!,
      dot6: Color.lerp(dot6, other.dot6, t)!,
      pipGreen: Color.lerp(pipGreen, other.pipGreen, t)!,
      pipYellow: Color.lerp(pipYellow, other.pipYellow, t)!,
      pipEmpty: Color.lerp(pipEmpty, other.pipEmpty, t)!,
      el1: t < 0.5 ? el1 : other.el1,
      el2: t < 0.5 ? el2 : other.el2,
      el3: t < 0.5 ? el3 : other.el3,
      glowAccent: t < 0.5 ? glowAccent : other.glowAccent,
    );
  }
}

/// Convenience extension so callers can do `context.velvet`.
extension RoyalVelvetContext on BuildContext {
  RoyalVelvet get velvet =>
      Theme.of(this).extension<RoyalVelvet>() ?? RoyalVelvet.royalVelvet;
}

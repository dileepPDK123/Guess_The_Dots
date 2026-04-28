import 'package:flutter/material.dart';

import '../theme/royal_velvet.dart';

/// Visual styles for a dot — see `dots.jsx` in the design handoff.
enum DotStyle { flat, sphere, glow, gem }

/// Optional state ribbon — used to show "this dot was correct" or empty etc.
enum SlotState { empty, active, filled }

/// A single circular dot. Used for:
/// - past-row guesses (filled)
/// - the active row (empty / active / filled)
/// - palette buttons
/// - notes-strip dots
///
/// The default [style] is gem (locked-in design choice).
class DotSlot extends StatelessWidget {
  /// 1-indexed color number (1-6). When null, the slot is empty.
  final int? color;
  final double size;
  final DotStyle style;
  final SlotState state;
  final bool ruledOut; // notes strip: shows X overlay + grayscale
  final String? colorblindGlyph; // overlay glyph (●■▲◆★✕) when colorblind on
  final Color? ring; // per-dot ring (Easy hint: green/yellow/grey)
  final bool locked; // Hard / hint: shows a small lock badge

  const DotSlot({
    super.key,
    required this.color,
    this.size = 44,
    this.style = DotStyle.gem,
    this.state = SlotState.filled,
    this.ruledOut = false,
    this.colorblindGlyph,
    this.ring,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;

    if (color == null) {
      return _EmptySlot(size: size, state: state, theme: v);
    }

    final dotColor = v.dotColor(color!);

    Widget dot;
    switch (style) {
      case DotStyle.flat:
        dot = _FlatDot(color: dotColor, size: size);
        break;
      case DotStyle.sphere:
        dot = _SphereDot(color: dotColor, size: size);
        break;
      case DotStyle.glow:
        dot = _GlowDot(color: dotColor, size: size);
        break;
      case DotStyle.gem:
        dot = _GemDot(color: dotColor, size: size);
        break;
    }

    if (colorblindGlyph != null) {
      dot = Stack(
        alignment: Alignment.center,
        children: [
          dot,
          Text(
            colorblindGlyph!,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
              shadows: const [
                Shadow(color: Color(0x66000000), offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      );
    }

    if (ruledOut) {
      dot = Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 0.7, 0,
            ]),
            child: dot,
          ),
          Icon(Icons.close_rounded, size: size * 0.55, color: v.text2),
        ],
      );
    }

    if (ring != null) {
      // Adds a ring around the dot (Easy hint: green=exact, yellow=misplaced)
      dot = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring!, width: 2.5),
          boxShadow: [
            BoxShadow(color: ring!.withValues(alpha: 0.4), blurRadius: 6),
          ],
        ),
        child: dot,
      );
    }

    if (locked) {
      dot = Stack(
        clipBehavior: Clip.none,
        children: [
          dot,
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: v.bg0,
                border: Border.all(color: v.lineStrong),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: size * 0.22,
                color: v.text2,
              ),
            ),
          ),
        ],
      );
    }

    return dot;
  }
}

class _EmptySlot extends StatelessWidget {
  final double size;
  final SlotState state;
  final RoyalVelvet theme;

  const _EmptySlot({
    required this.size,
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = state == SlotState.active;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: isActive ? theme.text2 : theme.lineStrong,
          width: isActive ? 2 : 2,
          style: isActive ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.accentSoft,
                  blurRadius: 0,
                  spreadRadius: 4,
                )
              ]
            : null,
      ),
    );
  }
}

// ── Gem (default) ────────────────────────────────────────────────────────────
class _GemDot extends StatelessWidget {
  final Color color;
  final double size;
  const _GemDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Base: linear-gradient(160deg, white 0.18, black 0.32) over the
          // solid color, plus a top-left highlight.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.36, -0.44),
                radius: 0.95,
                colors: [
                  const Color(0xFFFFFFFF).withValues(alpha: 0.55),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55],
              ),
            ),
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: const Alignment(0, -1),
                end: const Alignment(0, 1),
                colors: [
                  const Color(0xFFFFFFFF).withValues(alpha: 0.18),
                  const Color(0xFF000000).withValues(alpha: 0.32),
                ],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
          // Inset bright top + dark bottom rims (StyleBoxFlat-like).
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment(0, -1),
                  end: Alignment(0, 1),
                  colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                  stops: [0, 0.16],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment(0, 1),
                  end: Alignment(0, -1),
                  colors: [Color(0x2E000000), Color(0x00000000)],
                  stops: [0, 0.18],
                ),
              ),
            ),
          ),
          // Small white triangular highlight upper-left.
          Positioned(
            left: size * 0.18,
            top: size * 0.14,
            width: size * 0.30,
            height: size * 0.22,
            child: Transform.rotate(
              angle: -0.21, // ~-12°
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flat ──────────────────────────────────────────────────────────────────────
class _FlatDot extends StatelessWidget {
  final Color color;
  final double size;
  const _FlatDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }
}

// ── Sphere ────────────────────────────────────────────────────────────────────
class _SphereDot extends StatelessWidget {
  final Color color;
  final double size;
  const _SphereDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.85,
          colors: [
            color.withValues(alpha: 1),
            color,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 0.6,
            colors: [
              Colors.white.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glow ──────────────────────────────────────────────────────────────────────
class _GlowDot extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: size * 0.6,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: size * 1.0,
            spreadRadius: 4,
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.8,
            colors: [
              Colors.white.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

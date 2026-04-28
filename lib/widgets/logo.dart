import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import 'dot_slot.dart';

/// Variant B — the locked-in logo. Animated:
/// - "GTD" letters stagger-bounce on a 3.6s loop, 120ms between letters
/// - 4-dot row underneath wave-bobs on a 1.6s loop, 160ms stagger
class LogoB extends StatefulWidget {
  final double size;
  final bool animate;

  const LogoB({super.key, this.size = 64, this.animate = true});

  @override
  State<LogoB> createState() => _LogoBState();
}

class _LogoBState extends State<LogoB> with TickerProviderStateMixin {
  late final AnimationController _letters;
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _letters = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) {
      _letters.repeat();
      _dots.repeat();
    }
  }

  @override
  void dispose() {
    _letters.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _letters,
          builder: (_, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_letters.value - i * 0.034).clamp(0.0, 1.0);
                // 1 cycle of bounce inside the loop, rest of time still
                final wave = phase < 0.4 ? sin(phase / 0.4 * pi) : 0.0;
                final dy = -wave * 6;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      'GTD'[i],
                      style: AppText.displayL(color: v.text1).copyWith(
                        fontSize: widget.size,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.035 * widget.size,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        SizedBox(height: widget.size * 0.18),
        AnimatedBuilder(
          animation: _dots,
          builder: (_, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final phase = (_dots.value - i * 0.1) % 1.0;
                final wave = sin(phase * 2 * pi);
                final dy = wave * 4;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DotSlot(color: i + 1, size: widget.size * 0.22),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

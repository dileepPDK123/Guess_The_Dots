import 'package:flutter/material.dart';

import '../game/feedback.dart';
import '../theme/royal_velvet.dart';

/// 2×N grid of small circular pips, shown to the right of a [GuessRow].
///
/// Layout follows the design: pill-shaped wrapper, 4px gap, 10px pips,
/// inset 1px line + soft white-4% bg.
class FeedbackPipRow extends StatelessWidget {
  final PipFeedback? feedback;
  final int slotCount;

  const FeedbackPipRow({
    super.key,
    required this.feedback,
    required this.slotCount,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final fb = feedback;
    final greens = fb?.green ?? 0;
    final yellows = fb?.yellow ?? 0;
    final empties = slotCount - greens - yellows;

    final pips = <Widget>[];
    for (var i = 0; i < greens; i++) {
      pips.add(_Pip(color: v.pipGreen));
    }
    for (var i = 0; i < yellows; i++) {
      pips.add(_Pip(color: v.pipYellow));
    }
    for (var i = 0; i < empties; i++) {
      pips.add(_Pip(color: v.pipEmpty, glow: false));
    }

    // 2-column grid
    final cols = 2;
    final rows = (slotCount / cols).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: v.line, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (r) {
          return Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(cols, (c) {
                final idx = r * cols + c;
                if (idx >= pips.length) return const SizedBox(width: 10);
                return Padding(
                  padding: EdgeInsets.only(left: c == 0 ? 0 : 4),
                  child: pips[idx],
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  final Color color;
  final bool glow;
  const _Pip({required this.color, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

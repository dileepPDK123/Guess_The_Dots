import 'package:flutter/material.dart';

import '../theme/royal_velvet.dart';
import 'dot_slot.dart';

/// Bottom color palette: 5–6 large 48px dots. Tappable to fill the next slot.
class Palette extends StatelessWidget {
  final int colorCount;
  final ValueChanged<int> onPick;
  final DotStyle dotStyle;

  const Palette({
    super.key,
    required this.colorCount,
    required this.onPick,
    this.dotStyle = DotStyle.gem,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(colorCount, (i) {
        final color = i + 1; // 1-indexed
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPick(color),
            child: DotSlot(
              color: color,
              size: 48,
              style: dotStyle,
            ),
          ),
        );
      }),
    );
  }
}

/// Smaller "notes" palette — for ruling out colors. 24px dots; tap to toggle X.
class NotesStrip extends StatelessWidget {
  final int colorCount;
  final Map<int, bool> notes;
  final ValueChanged<int> onToggle;
  final DotStyle dotStyle;

  const NotesStrip({
    super.key,
    required this.colorCount,
    required this.notes,
    required this.onToggle,
    this.dotStyle = DotStyle.gem,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'TAP TO RULE OUT',
          style: TextStyle(
            color: v.text3,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.08 * 10,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(colorCount, (i) {
            final color = i + 1;
            final ruled = notes[color] ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onToggle(color),
                child: DotSlot(
                  color: color,
                  size: 24,
                  style: dotStyle,
                  ruledOut: ruled,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

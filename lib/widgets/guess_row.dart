import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../game/feedback.dart';
import '../theme/app_motion.dart';
import '../theme/royal_velvet.dart';
import 'dot_slot.dart';
import 'feedback_pip_row.dart';

enum RowState { past, active, future }

/// One row of the board: N circle slots + a PipCluster.
class GuessRow extends StatelessWidget {
  /// 1-indexed colors; null = empty.
  final List<int?> guess;
  final PipFeedback? feedback;
  final PipFeedback? secondFeedback; // Duo only
  final PerDotFeedback? perDotFeedback; // Easy only
  final RowState rowState;
  final int slotCount;
  final int? activeSlotIndex;
  final ValueChanged<int>? onSlotTap;
  final Set<int> lockedSlots; // Hard / hint
  final DotStyle dotStyle;

  const GuessRow({
    super.key,
    required this.guess,
    required this.feedback,
    this.secondFeedback,
    this.perDotFeedback,
    required this.rowState,
    required this.slotCount,
    this.activeSlotIndex,
    this.onSlotTap,
    this.lockedSlots = const {},
    this.dotStyle = DotStyle.gem,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final size = _slotSize(slotCount);

    Color? ringFor(int i) {
      if (perDotFeedback == null || rowState != RowState.past) return null;
      if (i >= perDotFeedback!.length) return null;
      switch (perDotFeedback![i]) {
        case 'exact':
          return v.pipGreen;
        case 'misplaced':
          return v.pipYellow;
        default:
          return null;
      }
    }

    Widget row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(slotCount, (i) {
          final color = i < guess.length ? guess[i] : null;
          final isLocked = lockedSlots.contains(i);
          SlotState slotState;
          if (rowState == RowState.future) {
            slotState = SlotState.empty;
          } else if (color != null) {
            slotState = SlotState.filled;
          } else if (rowState == RowState.active && i == activeSlotIndex) {
            slotState = SlotState.active;
          } else {
            slotState = SlotState.empty;
          }

          Widget dot = DotSlot(
            color: color,
            size: size,
            style: dotStyle,
            state: slotState,
            ring: ringFor(i),
            locked: isLocked && color != null,
          );

          if (rowState == RowState.active && onSlotTap != null && !isLocked) {
            dot = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSlotTap!(i),
              child: dot,
            );
          }

          if (color != null && rowState == RowState.active) {
            dot = dot.animate(key: ValueKey('${color}_$i'))
              .scale(
                duration: AppMotion.pop,
                curve: AppMotion.popCurve,
                begin: const Offset(0.2, 0.2),
                end: const Offset(1, 1),
              );
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 5),
            child: dot,
          );
        }),
        const SizedBox(width: 12),
        FeedbackPipRow(feedback: feedback, slotCount: slotCount),
        if (secondFeedback != null) ...[
          const SizedBox(width: 4),
          FeedbackPipRow(feedback: secondFeedback, slotCount: slotCount),
        ],
      ],
    );

    double opacity = 1;
    if (rowState == RowState.past) opacity = 0.9;
    if (rowState == RowState.future) opacity = 0.45;

    return Opacity(
      opacity: opacity,
      child: row,
    );
  }

  static double _slotSize(int slotCount) {
    if (slotCount >= 6) return 36;
    if (slotCount == 5) return 40;
    return 44;
  }
}

import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/dot_slot.dart';
import '../widgets/feedback_pip_row.dart';
import '../widgets/buttons.dart';
import '../game/feedback.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Scaffold(
      backgroundColor: v.bg1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: v.text1),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text('How to Play', style: AppText.title(color: v.text1)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Section(
            step: '01',
            title: 'Guess the hidden code',
            body:
                "There's a secret 4-dot sequence. You have a limited number of guesses to crack it. Each guess gives you feedback — use it to narrow down.",
            demo: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in [3, 1, 5, 2])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DotSlot(color: c, size: 36),
                  ),
              ],
            ),
          ),
          _Section(
            step: '02',
            title: 'Tap a color. Fill a row.',
            body:
                'Tap a color in the bottom palette to drop it into the next empty slot. Tap a filled slot to clear it. Drag a color directly onto a slot if you prefer.',
            demo: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in [1, 2, 3, 4, 5])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DotSlot(color: c, size: 28),
                  ),
              ],
            ),
          ),
          _Section(
            step: '03',
            title: 'Read the pips',
            body:
                "After you submit, look at the pips on the right. 🟢 = right color, right slot. 🟡 = right color, wrong slot. ⚫ = not in the code. The pips don't say WHICH slot — that's the puzzle.",
            demo: const FeedbackPipRow(
              feedback: PipFeedback(green: 2, yellow: 1),
              slotCount: 4,
            ),
          ),
          _Section(
            step: '04',
            title: 'Use the notes strip',
            body:
                "Tap a color in the small Notes strip to mark it as ruled out. The dot dims with an X — visual reminder so you don't waste a guess.",
            demo: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: DotSlot(
                      color: i,
                      size: 22,
                      ruledOut: i == 1 || i == 4,
                    ),
                  ),
              ],
            ),
          ),
          _Section(
            step: '05',
            title: 'Build your streak',
            body:
                'A new Daily puzzle drops every midnight. Win to grow your streak. Miss a day, lose your streak — unless you spend a Streak Shield.',
            demo: Icon(Icons.local_fire_department_rounded,
                color: v.accent2, size: 48),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Got it',
            onPressed: () => Navigator.maybePop(context),
            flexFill: true,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String step;
  final String title;
  final String body;
  final Widget demo;

  const _Section({
    required this.step,
    required this.title,
    required this.body,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: v.bg2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: v.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step, style: AppText.tag(color: v.accent)),
          const SizedBox(height: 8),
          Text(title, style: AppText.displayM(color: v.text1).copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(body, style: AppText.body(color: v.text2)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            decoration: BoxDecoration(
              color: v.bg3,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(child: demo),
          ),
        ],
      ),
    );
  }
}

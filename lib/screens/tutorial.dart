import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/feedback.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/buttons.dart';
import '../widgets/dot_slot.dart';
import '../widgets/feedback_pip_row.dart';
import 'home.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _index = 0;

  late final List<_Card> _cards = [
    _Card(
      headline: 'Welcome to Guess the Dots',
      body:
          "It's a daily color-code puzzle. Crack the secret. Read the pips. Build a streak.",
      visual: const _DotsRow(colors: [3, 1, 5, 2]),
    ),
    _Card(
      headline: 'These are dots',
      body: 'Each puzzle uses 4 to 6 dots from a small color palette.',
      visual: const _DotsRow(colors: [1, 2, 3, 4, 5]),
    ),
    _Card(
      headline: 'There is a hidden code',
      body: 'Same number of dots, in a secret order. Your job: figure it out.',
      visual: const _DotsRow(colors: [3, 1, 5, 2], blurred: true),
    ),
    _Card(
      headline: 'Pick a color from the palette',
      body: 'Tap a dot at the bottom to drop it into the next empty slot.',
      visual: const _DotsRow(colors: [1, null, null, null]),
    ),
    _Card(
      headline: 'Fill the row',
      body: 'Then tap Submit to lock in your guess.',
      visual: const _DotsRow(colors: [1, 2, 3, 4]),
    ),
    _Card(
      headline: '🟢 = right color, right slot',
      body: 'A green pip appears on the right side of the row for each exact match.',
      visual: const FeedbackPipRow(
        feedback: PipFeedback(green: 4, yellow: 0),
        slotCount: 4,
      ),
    ),
    _Card(
      headline: '🟡 = right color, wrong slot',
      body: "The color is in the secret, but not at that position.",
      visual: const FeedbackPipRow(
        feedback: PipFeedback(green: 0, yellow: 4),
        slotCount: 4,
      ),
    ),
    _Card(
      headline: '⚫ = not in the secret',
      body: "An empty pip means none of those dots are correct. Drop them.",
      visual: const FeedbackPipRow(
        feedback: PipFeedback(green: 0, yellow: 0),
        slotCount: 4,
      ),
    ),
    _Card(
      headline: 'Pips do not say WHICH slot',
      body: 'You learn how many are right — figuring out where is the puzzle.',
      visual: const FeedbackPipRow(
        feedback: PipFeedback(green: 2, yellow: 1),
        slotCount: 4,
      ),
    ),
    _Card(
      headline: 'Use the notes strip',
      body: 'Tap a color in the small Notes strip to mark it ruled out.',
      visual: const _NotesDemo(),
    ),
    _Card(
      headline: 'Stuck? Watch an ad for a hint',
      body: 'A hint reveals one correct dot. Always optional, never required.',
      visual: Icon(Icons.lightbulb_rounded, size: 56, color: const Color(0xFFFFB547)),
    ),
    _Card(
      headline: 'Mistakes happen',
      body: 'Tap a filled slot to clear it. Hit Undo to clear the last dot.',
      visual: Icon(Icons.undo_rounded, size: 56, color: const Color(0xFFB9ADE0)),
    ),
    _Card(
      headline: 'Eleven ways to play',
      body: 'Daily, Classic, Blitz, Hard, Zen, Campaign, Mystery, and more.',
      visual: const Wrap(
        spacing: 12,
        children: [Text('🎯', style: TextStyle(fontSize: 28)),
          Text('⚡', style: TextStyle(fontSize: 28)),
          Text('💀', style: TextStyle(fontSize: 28)),
          Text('🧘', style: TextStyle(fontSize: 28)),
          Text('🗺️', style: TextStyle(fontSize: 28))],
      ),
    ),
    _Card(
      headline: 'Build your streak',
      body: 'A new Daily drops at midnight. Win to grow your streak.',
      visual: Icon(Icons.local_fire_department_rounded,
          size: 64, color: const Color(0xFFFFB547)),
    ),
    _Card(
      headline: 'Share your win',
      body: 'After every game you get a spoiler-free emoji grid. Drop it in any chat.',
      visual: const Text('🟢🟢🟡⚫\n🟢🟢🟢🟢',
          style: TextStyle(fontFamily: 'monospace', fontSize: 24)),
    ),
  ];

  void _next() {
    if (_index < _cards.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  void _finish() {
    ref.read(playerProvider.notifier).setTutorialSeen(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final card = _cards[_index];
    return Scaffold(
      backgroundColor: v.bg1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / _cards.length,
                        backgroundColor: v.bg3,
                        valueColor: AlwaysStoppedAnimation(v.accent),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('${_index + 1}/${_cards.length}',
                      style: AppText.mono(color: v.text2, size: 12)),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip',
                        style: AppText.caption(color: v.text2)),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: v.bg2,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: v.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          child: Center(child: card.visual),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          card.headline,
                          style: AppText.displayM(color: v.text1),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          card.body,
                          style: AppText.body(color: v.text2),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      flex: 1,
                      child: OutlineButton(
                        label: 'Back',
                        onPressed: _back,
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _index == _cards.length - 1 ? 'Start playing' : 'Next',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card {
  final String headline;
  final String body;
  final Widget visual;
  const _Card({
    required this.headline,
    required this.body,
    required this.visual,
  });
}

class _DotsRow extends StatelessWidget {
  final List<int?> colors;
  final bool blurred;
  const _DotsRow({required this.colors, this.blurred = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in colors)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Opacity(
              opacity: blurred ? 0.2 : 1.0,
              child: DotSlot(color: c, size: 38),
            ),
          ),
      ],
    );
  }
}

class _NotesDemo extends StatelessWidget {
  const _NotesDemo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DotSlot(color: i, size: 28, ruledOut: i == 1 || i == 4),
          ),
      ],
    );
  }
}

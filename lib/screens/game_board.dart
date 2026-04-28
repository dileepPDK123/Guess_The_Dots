import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import '../game/game_state.dart';
import '../game/modes.dart';
import '../game/status_message.dart';
import '../services/ads_service.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/banner_ad.dart';
import '../widgets/buttons.dart';
import '../widgets/guess_row.dart';
import '../widgets/palette.dart';
import 'result_sheet.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  final int? seed;

  const GameBoardScreen({super.key, required this.mode, this.seed});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  bool _resultShown = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(gameNotifierProvider.notifier)
          .start(m: widget.mode, withSeed: widget.seed);
      // Start the Blitz / Time-Trial ticker if the mode has a timer
      if (widget.mode.timerSeconds != null) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          ref.read(gameNotifierProvider.notifier).tickTimer();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _maybeShowResult(GameState s) {
    if (_resultShown || s.result == null) return;
    _resultShown = true;
    _ticker?.cancel();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      ResultSheet.show(
        context,
        mode: widget.mode,
        seed: widget.seed,
        gameState: s,
        onPlayAgain: () {
          if (!mounted) return;
          // Start the new game first (which clears result) BEFORE clearing
          // _resultShown, to prevent a re-entry window where build() sees
          // a non-null result with _resultShown==false.
          ref
              .read(gameNotifierProvider.notifier)
              .start(m: widget.mode, withSeed: widget.seed);
          if (widget.mode.timerSeconds != null) {
            _ticker?.cancel();
            _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
              ref.read(gameNotifierProvider.notifier).tickTimer();
            });
          }
          setState(() => _resultShown = false);
        },
        onMenu: () {
          if (!mounted) return;
          Navigator.of(context).maybePop();
        },
        onSecondChance: () {
          if (!mounted) return;
          setState(() => _resultShown = false);
          ref.read(gameNotifierProvider.notifier).grantExtraGuesses(3);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    _maybeShowResult(state);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _Header(mode: widget.mode, state: state),
              const SizedBox(height: 8),
              if (widget.mode.timerSeconds != null)
                _BlitzTimer(state: state, totalSeconds: widget.mode.timerSeconds!),
              _StatusLine(state: state),
              const SizedBox(height: 16),
              Expanded(
                child: _Board(
                  state: state,
                  onSlotTap: notifier.tapSlot,
                ),
              ),
              const SizedBox(height: 12),
              NotesStrip(
                colorCount: widget.mode.colors,
                notes: state.notes,
                onToggle: notifier.toggleNote,
              ),
              const SizedBox(height: 12),
              _Actions(
                state: state,
                notifier: notifier,
                onHint: () => _onHint(context),
              ),
              const SizedBox(height: 16),
              Palette(
                colorCount: widget.mode.colors,
                onPick: notifier.placeColor,
              ),
              const SizedBox(height: 8),
              const Center(child: AppBannerAd()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onHint(BuildContext context) async {
    final notifier = ref.read(gameNotifierProvider.notifier);
    final p = ref.read(playerProvider.notifier);
    final hasToken = ref.read(playerProvider).hintTokens > 0;
    if (hasToken) {
      // Apply the hint first — only charge the token if a slot was actually
      // revealed. Prevents silently wasting tokens in Hard mode when all
      // unlocked slots are already filled.
      final revealed = notifier.useHint();
      if (revealed) p.spendHint();
      return;
    }
    // No tokens — offer a rewarded ad instead.
    final ads = ref.read(adsProvider);
    final earned = await ads.showRewarded();
    if (!mounted) return;
    if (earned) notifier.useHint();
    // If not earned, do nothing — no free hint on ad failure in production.
  }
}

class _Header extends StatelessWidget {
  final GameMode mode;
  final GameState state;
  const _Header({required this.mode, required this.state});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: v.text1),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Column(
            children: [
              Text(mode.name, style: AppText.tag(color: v.text3)),
              const SizedBox(height: 2),
              Text(
                _headerSubtitle(state),
                style: AppText.caption(color: v.text1).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.menu_rounded, color: v.text1),
          onPressed: () {},
        ),
      ],
    );
  }

  String _headerSubtitle(GameState s) {
    if (s.guesses > 100) {
      return 'Guess ${s.activeRow + 1} · unlimited';
    }
    return 'Guess ${s.activeRow + 1} of ${s.guesses}';
  }
}

class _BlitzTimer extends StatelessWidget {
  final GameState state;
  final int totalSeconds;
  const _BlitzTimer({required this.state, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final remaining = state.secondsRemaining ?? 0;
    final pct = totalSeconds > 0
        ? (remaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final critical = remaining <= 15;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              color: critical ? v.accent : v.text2, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: v.bg3,
                valueColor: AlwaysStoppedAnimation(critical ? v.accent : v.accent2),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
            style: AppText.mono(color: critical ? v.accent : v.text1, size: 13),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final GameState state;
  const _StatusLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final msg = statusMessage(
      rowIdx: state.activeRow,
      filled: state.filled,
      slotCount: state.effectiveSlots,
      lastFb: state.lastFeedback,
      solved: state.result == GameResult.win,
      lost: state.result == GameResult.loss,
    );
    return SizedBox(
      height: 28,
      child: Center(
        child: Text(msg, style: AppText.caption(color: v.text2)),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final GameState state;
  final ValueChanged<int> onSlotTap;
  const _Board({required this.state, required this.onSlotTap});

  @override
  Widget build(BuildContext context) {
    final lockedSet = state.lockedSlots.keys.toSet();
    return SingleChildScrollView(
      child: Column(
        children: List.generate(state.guesses, (i) {
          RowState rowState;
          if (i < state.activeRow) {
            rowState = RowState.past;
          } else if (i == state.activeRow && !state.isFinished) {
            rowState = RowState.active;
          } else {
            rowState = RowState.future;
          }
          int? activeSlotIndex;
          if (rowState == RowState.active) {
            for (var j = 0; j < state.effectiveSlots; j++) {
              if (state.lockedSlots.containsKey(j)) continue;
              if (state.currentRow[j] == null) {
                activeSlotIndex = j;
                break;
              }
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GuessRow(
              guess: state.rows[i].take(state.effectiveSlots).toList(),
              feedback: state.feedback[i],
              secondFeedback: state.secondCode != null
                  ? state.secondFeedback[i]
                  : null,
              perDotFeedback: state.perDotFeedback[i],
              rowState: rowState,
              slotCount: state.effectiveSlots,
              activeSlotIndex: activeSlotIndex,
              onSlotTap: rowState == RowState.active ? onSlotTap : null,
              lockedSlots: lockedSet,
            ),
          );
        }),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;
  final VoidCallback onHint;
  const _Actions({
    required this.state,
    required this.notifier,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.undo_rounded,
          onPressed: state.filled > 0 && !state.isFinished
              ? notifier.undo
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'Submit Guess',
            onPressed:
                state.isComplete && !state.isFinished ? notifier.submit : null,
          ),
        ),
        const SizedBox(width: 12),
        _SquareIconButton(
          icon: Icons.lightbulb_outline_rounded,
          onPressed: state.isFinished ? null : onHint,
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _SquareIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: v.lineStrong, width: 1.5),
          ),
          child: Icon(
            icon,
            color: disabled ? v.text3 : v.text1,
            size: 22,
          ),
        ),
      ),
    );
  }
}

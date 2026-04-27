import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import '../game/game_state.dart';
import '../game/modes.dart';
import '../game/status_message.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/buttons.dart';
import '../widgets/guess_row.dart';
import '../widgets/palette.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  final int? seed;

  const GameBoardScreen({super.key, required this.mode, this.seed});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameNotifierProvider.notifier)
          .start(m: widget.mode, withSeed: widget.seed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _Header(mode: widget.mode, state: state),
              const SizedBox(height: 8),
              _StatusLine(state: state),
              const SizedBox(height: 16),
              Expanded(child: _Board(state: state, onSlotTap: notifier.tapSlot)),
              const SizedBox(height: 12),
              NotesStrip(
                colorCount: widget.mode.colors,
                notes: state.notes,
                onToggle: notifier.toggleNote,
              ),
              const SizedBox(height: 12),
              _Actions(state: state, notifier: notifier),
              const SizedBox(height: 16),
              Palette(
                colorCount: widget.mode.colors,
                onPick: notifier.placeColor,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
                'Guess ${state.activeRow + 1} of ${state.guesses}',
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
      slotCount: state.slots,
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
          // active slot index = first empty
          int? activeSlotIndex;
          if (rowState == RowState.active) {
            activeSlotIndex = state.currentRow.indexWhere((c) => c == null);
            if (activeSlotIndex < 0) activeSlotIndex = null;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GuessRow(
              guess: state.rows[i],
              feedback: state.feedback[i],
              rowState: rowState,
              slotCount: state.slots,
              activeSlotIndex: activeSlotIndex,
              onSlotTap: rowState == RowState.active ? onSlotTap : null,
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
  const _Actions({required this.state, required this.notifier});

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
          onPressed: state.isFinished ? null : () {},
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

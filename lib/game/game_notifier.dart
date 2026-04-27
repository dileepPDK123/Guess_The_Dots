import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback.dart';
import 'game_state.dart';
import 'modes.dart';
import 'seeded_rng.dart';

/// Manages a single playable game. Created by passing config (mode + seed) to
/// the family provider [gameNotifierProvider].
class GameNotifier extends Notifier<GameState> {
  late final GameMode mode;
  late final int? seed;

  @override
  GameState build() {
    // Default to a non-deterministic Classic round if no config supplied.
    mode = GameModes.classic;
    seed = null;
    final code = generateSecret(slots: mode.slots, colors: mode.colors);
    return GameState.initial(
      code: code,
      slots: mode.slots,
      colors: mode.colors,
      guesses: mode.guesses,
      secondsRemaining: mode.timerSeconds,
    );
  }

  void start({required GameMode m, int? withSeed}) {
    final code = generateSecret(
      slots: m.slots,
      colors: m.colors,
      seed: withSeed,
    );
    state = GameState.initial(
      code: code,
      slots: m.slots,
      colors: m.colors,
      guesses: m.guesses,
      secondsRemaining: m.timerSeconds,
    );
  }

  /// Place [color] (1-indexed) into the next empty slot of the active row.
  void placeColor(int color) {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    final emptyIdx = row.indexWhere((c) => c == null);
    if (emptyIdx < 0) return;
    row[emptyIdx] = color;
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  /// Tap an existing slot to clear it.
  void tapSlot(int slotIndex) {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    if (slotIndex < 0 || slotIndex >= row.length) return;
    row[slotIndex] = null;
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  /// Undo: clear the last filled slot in the active row.
  void undo() {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    for (var i = row.length - 1; i >= 0; i--) {
      if (row[i] != null) {
        row[i] = null;
        break;
      }
    }
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  /// Clear: empty the active row entirely.
  void clear() {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    rows[state.activeRow] = List.filled(state.slots, null);
    state = state.copyWith(rows: rows);
  }

  /// Submit the active row. Computes feedback and advances or ends the game.
  void submit() {
    if (state.isFinished || !state.isComplete) return;
    final guess = state.currentRow.map((c) => c ?? 0).toList();
    final fb = computeFeedback(guess, state.code);
    final newFeedback = List<PipFeedback?>.from(state.feedback);
    newFeedback[state.activeRow] = fb;

    if (fb.green == state.slots) {
      state = state.copyWith(
        feedback: newFeedback,
        result: GameResult.win,
      );
      return;
    }
    if (state.activeRow + 1 >= state.guesses) {
      state = state.copyWith(
        feedback: newFeedback,
        result: GameResult.loss,
      );
      return;
    }
    state = state.copyWith(
      feedback: newFeedback,
      activeRow: state.activeRow + 1,
    );
  }

  /// Toggle a "ruled out" mark on a color (1-indexed).
  void toggleNote(int color) {
    final notes = Map<int, bool>.from(state.notes);
    notes[color] = !(notes[color] ?? false);
    state = state.copyWith(notes: notes);
  }
}

final gameNotifierProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

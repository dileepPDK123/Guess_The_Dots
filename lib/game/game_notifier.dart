import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback.dart';
import 'game_state.dart';
import 'modes.dart';
import 'seeded_rng.dart';

/// Manages a single playable game.
class GameNotifier extends Notifier<GameState> {
  late GameMode mode;

  @override
  GameState build() {
    mode = GameModes.classic;
    return _initial(GameModes.classic, null);
  }

  GameState _initial(GameMode m, int? seed) {
    // Mystery: secret stays hidden in slot count, revealedSlots starts at slots-1.
    final isMystery = m.id == 'mystery';
    final isHard = m.id == 'hard';
    final isDuo = m.id == 'duo';
    final isSudden = m.id == 'sudden';

    final code = generateSecret(slots: m.slots, colors: m.colors, seed: seed);
    final secondCode = isDuo
        ? generateSecret(slots: m.slots, colors: m.colors, seed: seed != null ? seed + 7 : null)
        : null;

    final lockedSlots = <int, int>{};
    if (isHard) {
      // Pre-lock 1 slot at random with the correct color (deterministic for seeded modes)
      final rng = SeededRng(seed ?? DateTime.now().microsecondsSinceEpoch);
      final lockedIdx = rng.nextInt(0, m.slots - 1);
      lockedSlots[lockedIdx] = code[lockedIdx];
    }

    return GameState.initial(
      code: code,
      slots: m.slots,
      colors: m.colors,
      guesses: m.guesses,
      secondCode: secondCode,
      lockedSlots: lockedSlots,
      revealedSlots: isMystery ? (m.slots - 2).clamp(2, m.slots) : null,
      suddenDeath: isSudden,
      secondsRemaining: m.timerSeconds,
    );
  }

  void start({required GameMode m, int? withSeed}) {
    mode = m;
    state = _initial(m, withSeed);
  }

  /// Place [color] (1-indexed) into the next empty slot of the active row,
  /// skipping locked slots.
  void placeColor(int color) {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    final effective = state.effectiveSlots;
    int? targetIdx;
    for (var i = 0; i < effective; i++) {
      if (state.lockedSlots.containsKey(i)) continue;
      if (row[i] == null) {
        targetIdx = i;
        break;
      }
    }
    if (targetIdx == null) return;
    row[targetIdx] = color;
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  void tapSlot(int slotIndex) {
    if (state.isFinished) return;
    if (state.lockedSlots.containsKey(slotIndex)) return;
    if (slotIndex < 0 || slotIndex >= state.effectiveSlots) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    row[slotIndex] = null;
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  void undo() {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    for (var i = state.effectiveSlots - 1; i >= 0; i--) {
      if (state.lockedSlots.containsKey(i)) continue;
      if (row[i] != null) {
        row[i] = null;
        break;
      }
    }
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  void clear() {
    if (state.isFinished) return;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = List<int?>.filled(state.slots, null);
    state.lockedSlots.forEach((idx, color) => row[idx] = color);
    rows[state.activeRow] = row;
    state = state.copyWith(rows: rows);
  }

  /// Submit. Computes feedback per-mode.
  void submit() {
    if (state.isFinished || !state.isComplete) return;
    final guess = state.currentRow.map((c) => c ?? 0).toList();
    final eff = state.effectiveSlots;
    final guessSlice = guess.take(eff).toList();
    final codeSlice = state.code.take(eff).toList();
    final fb = computeFeedback(guessSlice, codeSlice);
    final newFeedback = List<PipFeedback?>.from(state.feedback);
    newFeedback[state.activeRow] = fb;

    // Easy: per-dot feedback aligned with effective slots
    final newPerDot = List<PerDotFeedback?>.from(state.perDotFeedback);
    if (mode.id == 'easy') {
      newPerDot[state.activeRow] = computePerDot(guessSlice, codeSlice);
    }

    // Duo: also evaluate against second code
    final newSecondFb = List<PipFeedback?>.from(state.secondFeedback);
    if (state.secondCode != null) {
      newSecondFb[state.activeRow] =
          computeFeedback(guessSlice, state.secondCode!.take(eff).toList());
    }

    // Win conditions:
    final isPrimaryWin = fb.green == eff;
    final isDuoWin = state.secondCode != null &&
        isPrimaryWin &&
        newSecondFb[state.activeRow]!.green == eff;

    if (state.secondCode != null) {
      // Duo wins only when both codes match
      if (isDuoWin) {
        state = state.copyWith(
          feedback: newFeedback,
          secondFeedback: newSecondFb,
          perDotFeedback: newPerDot,
          result: GameResult.win,
        );
        return;
      }
    } else if (isPrimaryWin) {
      state = state.copyWith(
        feedback: newFeedback,
        perDotFeedback: newPerDot,
        result: GameResult.win,
      );
      return;
    }

    // Sudden death: any submitted guess with 0 exact ends the game.
    if (state.suddenDeath && fb.green == 0) {
      state = state.copyWith(
        feedback: newFeedback,
        secondFeedback: newSecondFb,
        perDotFeedback: newPerDot,
        result: GameResult.loss,
      );
      return;
    }

    // Out of guesses
    if (state.activeRow + 1 >= state.guesses) {
      state = state.copyWith(
        feedback: newFeedback,
        secondFeedback: newSecondFb,
        perDotFeedback: newPerDot,
        result: GameResult.loss,
      );
      return;
    }

    // Mystery: reveal one more slot (up to total)
    int? newRevealed = state.revealedSlots;
    if (newRevealed != null && newRevealed < state.slots) {
      newRevealed = (newRevealed + 1).clamp(0, state.slots);
    }

    state = state.copyWith(
      feedback: newFeedback,
      secondFeedback: newSecondFb,
      perDotFeedback: newPerDot,
      activeRow: state.activeRow + 1,
      revealedSlots: newRevealed,
    );
  }

  void toggleNote(int color) {
    final notes = Map<int, bool>.from(state.notes);
    notes[color] = !(notes[color] ?? false);
    state = state.copyWith(notes: notes);
  }

  /// Award an extra +N guesses (used by second-chance rewarded ad).
  void grantExtraGuesses(int n) {
    if (state.result != GameResult.loss) return;
    final newGuesses = state.guesses + n;
    final newRows = List<List<int?>>.from(state.rows.map(List<int?>.from));
    final newFeedback = List<PipFeedback?>.from(state.feedback);
    final newSecondFb = List<PipFeedback?>.from(state.secondFeedback);
    final newPerDot = List<PerDotFeedback?>.from(state.perDotFeedback);
    while (newRows.length < newGuesses) {
      final row = List<int?>.filled(state.slots, null);
      state.lockedSlots.forEach((idx, color) => row[idx] = color);
      newRows.add(row);
      newFeedback.add(null);
      newSecondFb.add(null);
      newPerDot.add(null);
    }
    state = state.copyWith(
      guesses: newGuesses,
      rows: newRows,
      feedback: newFeedback,
      secondFeedback: newSecondFb,
      perDotFeedback: newPerDot,
      activeRow: state.activeRow + 1,
      clearResult: true,
    );
  }

  /// Reveal one currently-empty slot in the active row with the correct color.
  /// Used by Hint feature (cost = 1 hint token or watch ad).
  bool useHint() {
    if (state.isFinished) return false;
    final rows = state.rows.map(List<int?>.from).toList();
    final row = rows[state.activeRow];
    final eff = state.effectiveSlots;
    for (var i = 0; i < eff; i++) {
      if (state.lockedSlots.containsKey(i)) continue;
      if (row[i] == null) {
        row[i] = state.code[i];
        rows[state.activeRow] = row;
        // Lock the hint so it can't be cleared.
        final newLocked = Map<int, int>.from(state.lockedSlots);
        newLocked[i] = state.code[i];
        state = state.copyWith(rows: rows, lockedSlots: newLocked);
        return true;
      }
    }
    return false;
  }

  /// Tick down the Blitz timer. Caller drives this each second.
  /// On expiry, ends the game as a loss.
  void tickTimer() {
    if (state.isFinished || state.secondsRemaining == null) return;
    final next = state.secondsRemaining! - 1;
    if (next <= 0) {
      state = state.copyWith(secondsRemaining: 0, result: GameResult.loss);
    } else {
      state = state.copyWith(secondsRemaining: next);
    }
  }
}

final gameNotifierProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

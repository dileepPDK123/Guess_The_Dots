import 'package:flutter/foundation.dart';

import 'feedback.dart';

enum GameResult { win, loss }

/// Per-row Easy-mode hints. `perDotFeedback[i]` is null until that row is
/// submitted; afterward it's a [PerDotFeedback] aligned with the guess.
@immutable
class GameState {
  final List<int> code; // primary secret
  final List<int>? secondCode; // Duo: second secret
  final List<List<int?>> rows; // each row is a guess; null = empty slot
  final List<PipFeedback?> feedback; // primary feedback per row
  final List<PipFeedback?> secondFeedback; // Duo: second feedback per row
  final List<PerDotFeedback?> perDotFeedback; // Easy: per-dot states per row
  final int activeRow;
  final GameResult? result;
  final Map<int, bool> notes;
  final int slots;
  final int colors;
  final int guesses;

  /// Hard mode: slot index → fixed correct color (1-indexed). The slot is
  /// pre-filled and uneditable. Empty for non-Hard modes.
  final Map<int, int> lockedSlots;

  /// Mystery mode: how many slots are visible/usable right now. Starts smaller
  /// than `slots` and grows as the player makes guesses.
  /// `null` for non-Mystery modes (full slot count visible always).
  final int? revealedSlots;

  /// Sudden Death: any submitted row with green==0 ends the game.
  final bool suddenDeath;

  final int? secondsRemaining; // Blitz / Time Trial countdown
  final DateTime? startedAt;

  const GameState({
    required this.code,
    required this.secondCode,
    required this.rows,
    required this.feedback,
    required this.secondFeedback,
    required this.perDotFeedback,
    required this.activeRow,
    required this.result,
    required this.notes,
    required this.slots,
    required this.colors,
    required this.guesses,
    required this.lockedSlots,
    required this.revealedSlots,
    required this.suddenDeath,
    this.secondsRemaining,
    this.startedAt,
  });

  factory GameState.initial({
    required List<int> code,
    required int slots,
    required int colors,
    required int guesses,
    List<int>? secondCode,
    Map<int, int>? lockedSlots,
    int? revealedSlots,
    bool suddenDeath = false,
    int? secondsRemaining,
  }) {
    final lockedColumns = lockedSlots ?? {};
    return GameState(
      code: code,
      secondCode: secondCode,
      rows: List.generate(guesses, (_) {
        // Pre-fill locked slots in every row.
        final row = List<int?>.filled(slots, null);
        lockedColumns.forEach((idx, color) => row[idx] = color);
        return row;
      }),
      feedback: List.filled(guesses, null),
      secondFeedback: List.filled(guesses, null),
      perDotFeedback: List.filled(guesses, null),
      activeRow: 0,
      result: null,
      notes: const {},
      slots: slots,
      colors: colors,
      guesses: guesses,
      lockedSlots: lockedColumns,
      revealedSlots: revealedSlots,
      suddenDeath: suddenDeath,
      secondsRemaining: secondsRemaining,
      startedAt: DateTime.now(),
    );
  }

  List<int?> get currentRow =>
      activeRow < rows.length ? rows[activeRow] : List.filled(slots, null);

  /// Effective slot count visible/playable in this state. For Mystery, this
  /// is [revealedSlots]; for everyone else, [slots].
  int get effectiveSlots => revealedSlots ?? slots;

  int get filled {
    var n = 0;
    final row = currentRow;
    for (var i = 0; i < effectiveSlots; i++) {
      if (row[i] != null) n++;
    }
    return n;
  }

  bool get isComplete => filled == effectiveSlots;

  bool get isFinished => result != null;

  PipFeedback? get lastFeedback =>
      activeRow > 0 ? feedback[activeRow - 1] : null;

  /// Returns guesses that have been submitted (i.e. have feedback).
  List<List<int>> get submittedGuesses {
    final out = <List<int>>[];
    for (var i = 0; i < rows.length; i++) {
      if (feedback[i] != null) {
        out.add(rows[i].map((c) => c ?? 0).toList());
      }
    }
    return out;
  }

  GameState copyWith({
    List<int>? code,
    List<int>? secondCode,
    List<List<int?>>? rows,
    List<PipFeedback?>? feedback,
    List<PipFeedback?>? secondFeedback,
    List<PerDotFeedback?>? perDotFeedback,
    int? activeRow,
    GameResult? result,
    bool clearResult = false,
    Map<int, bool>? notes,
    int? slots,
    int? colors,
    int? guesses,
    Map<int, int>? lockedSlots,
    int? revealedSlots,
    bool? suddenDeath,
    int? secondsRemaining,
    DateTime? startedAt,
  }) {
    return GameState(
      code: code ?? this.code,
      secondCode: secondCode ?? this.secondCode,
      rows: rows ?? this.rows,
      feedback: feedback ?? this.feedback,
      secondFeedback: secondFeedback ?? this.secondFeedback,
      perDotFeedback: perDotFeedback ?? this.perDotFeedback,
      activeRow: activeRow ?? this.activeRow,
      result: clearResult ? null : (result ?? this.result),
      notes: notes ?? this.notes,
      slots: slots ?? this.slots,
      colors: colors ?? this.colors,
      guesses: guesses ?? this.guesses,
      lockedSlots: lockedSlots ?? this.lockedSlots,
      revealedSlots: revealedSlots ?? this.revealedSlots,
      suddenDeath: suddenDeath ?? this.suddenDeath,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

import 'package:flutter/foundation.dart';

import 'feedback.dart';

enum GameResult { win, loss }

@immutable
class GameState {
  final List<int> code; // secret sequence (1-indexed colors)
  final List<List<int?>> rows; // each row is a guess; null = empty slot
  final List<PipFeedback?> feedback; // one entry per row, null if not submitted
  final int activeRow;
  final GameResult? result;
  final Map<int, bool> notes; // colors marked as "ruled out"
  final int slots;
  final int colors;
  final int guesses;
  final int? secondsRemaining; // for blitz / time trial; null if no timer
  final DateTime? startedAt;

  const GameState({
    required this.code,
    required this.rows,
    required this.feedback,
    required this.activeRow,
    required this.result,
    required this.notes,
    required this.slots,
    required this.colors,
    required this.guesses,
    this.secondsRemaining,
    this.startedAt,
  });

  factory GameState.initial({
    required List<int> code,
    required int slots,
    required int colors,
    required int guesses,
    int? secondsRemaining,
  }) {
    return GameState(
      code: code,
      rows: List.generate(guesses, (_) => List.filled(slots, null)),
      feedback: List.filled(guesses, null),
      activeRow: 0,
      result: null,
      notes: const {},
      slots: slots,
      colors: colors,
      guesses: guesses,
      secondsRemaining: secondsRemaining,
      startedAt: DateTime.now(),
    );
  }

  List<int?> get currentRow =>
      activeRow < rows.length ? rows[activeRow] : List.filled(slots, null);

  int get filled => currentRow.where((c) => c != null).length;

  bool get isComplete => filled == slots;

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
    List<List<int?>>? rows,
    List<PipFeedback?>? feedback,
    int? activeRow,
    GameResult? result,
    bool clearResult = false,
    Map<int, bool>? notes,
    int? slots,
    int? colors,
    int? guesses,
    int? secondsRemaining,
    DateTime? startedAt,
  }) {
    return GameState(
      code: code ?? this.code,
      rows: rows ?? this.rows,
      feedback: feedback ?? this.feedback,
      activeRow: activeRow ?? this.activeRow,
      result: clearResult ? null : (result ?? this.result),
      notes: notes ?? this.notes,
      slots: slots ?? this.slots,
      colors: colors ?? this.colors,
      guesses: guesses ?? this.guesses,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

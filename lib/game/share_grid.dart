/// Wordle-style spoiler-free emoji grid, ported from
/// `game-engine.jsx::shareGrid`.
library;

import 'feedback.dart';

const _green = '🟢';
const _yellow = '🟡';
const _grey = '⚫';

/// Builds a multi-line emoji grid like Wordle. One line per submitted guess.
/// Within a line: greens first, then yellows, then greys.
String shareGrid({
  required List<List<int>> guesses,
  required List<PipFeedback?> feedbacks,
  required int slotCount,
}) {
  final lines = <String>[];
  for (var i = 0; i < guesses.length; i++) {
    final fb = feedbacks[i];
    if (fb == null) continue;
    final buf = StringBuffer();
    for (var k = 0; k < fb.green; k++) {
      buf.write(_green);
    }
    for (var k = 0; k < fb.yellow; k++) {
      buf.write(_yellow);
    }
    for (var k = 0; k < slotCount - fb.green - fb.yellow; k++) {
      buf.write(_grey);
    }
    lines.add(buf.toString());
  }
  return lines.join('\n');
}

/// Adds the standard header used by the Daily share format.
String shareDailyText({
  required int dailyNumber,
  required int? guessCount,
  required int maxGuesses,
  required int streak,
  required String body,
}) {
  final result =
      guessCount != null ? '$guessCount/$maxGuesses' : 'X/$maxGuesses';
  final headerLine = 'Guess the Dots · Daily #$dailyNumber · $result';
  final streakLine = streak > 0 ? '🔥 $streak-day streak' : '';
  final tag = '#GuessTheDots';
  return [
    headerLine,
    body,
    if (streakLine.isNotEmpty) streakLine,
    tag,
  ].join('\n');
}

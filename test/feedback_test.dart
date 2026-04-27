import 'package:flutter_test/flutter_test.dart';
import 'package:guess_the_dots/game/feedback.dart';

void main() {
  group('computeFeedback', () {
    test('all green when guess matches secret exactly', () {
      expect(
        computeFeedback([1, 2, 3, 4], [1, 2, 3, 4]),
        const PipFeedback(green: 4, yellow: 0),
      );
    });

    test('all yellow when guess is a permutation', () {
      expect(
        computeFeedback([4, 3, 2, 1], [1, 2, 3, 4]),
        const PipFeedback(green: 0, yellow: 4),
      );
    });

    test('mix of green and yellow', () {
      // secret: 1 2 3 4
      // guess:  1 3 2 5  → 1 green (idx 0), 2 yellow (3 and 2 swapped), 1 grey
      expect(
        computeFeedback([1, 3, 2, 5], [1, 2, 3, 4]),
        const PipFeedback(green: 1, yellow: 2),
      );
    });

    test('no match', () {
      expect(
        computeFeedback([5, 5, 5, 5], [1, 2, 3, 4]),
        const PipFeedback(green: 0, yellow: 0),
      );
    });

    test('duplicates in guess do not double-count', () {
      // secret has only one 1, guess has two 1s
      // secret: 1 2 3 4
      // guess:  1 1 1 1 → 1 green (idx 0), 0 yellow (no extra 1s in secret)
      expect(
        computeFeedback([1, 1, 1, 1], [1, 2, 3, 4]),
        const PipFeedback(green: 1, yellow: 0),
      );
    });

    test('duplicates in secret count once per matching guess color', () {
      // secret: 1 1 2 2
      // guess:  2 2 1 1 → 0 green, 4 yellow
      expect(
        computeFeedback([2, 2, 1, 1], [1, 1, 2, 2]),
        const PipFeedback(green: 0, yellow: 4),
      );
    });

    test('handles 3-slot puzzles', () {
      expect(
        computeFeedback([1, 2, 3], [3, 2, 1]),
        const PipFeedback(green: 1, yellow: 2),
      );
    });

    test('handles 6-slot Hard mode', () {
      expect(
        computeFeedback([1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1]),
        const PipFeedback(green: 0, yellow: 6),
      );
    });

    test('one green among repeated colors', () {
      // secret: 1 2 2 3
      // guess:  4 2 4 4 → 1 green (idx 1), 0 yellow
      expect(
        computeFeedback([4, 2, 4, 4], [1, 2, 2, 3]),
        const PipFeedback(green: 1, yellow: 0),
      );
    });

    test('asserts equal length', () {
      expect(
        () => computeFeedback([1, 2, 3], [1, 2, 3, 4]),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

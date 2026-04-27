import 'package:flutter_test/flutter_test.dart';
import 'package:guess_the_dots/game/seeded_rng.dart';

void main() {
  group('SeededRng', () {
    test('same seed produces same sequence', () {
      final a = SeededRng(42);
      final b = SeededRng(42);
      for (var i = 0; i < 100; i++) {
        expect(a.next(), b.next(),
            reason: 'sequences must match exactly for same seed');
      }
    });

    test('different seeds produce different sequences', () {
      final a = SeededRng(1);
      final b = SeededRng(2);
      var anyDifferent = false;
      for (var i = 0; i < 10; i++) {
        if (a.next() != b.next()) anyDifferent = true;
      }
      expect(anyDifferent, isTrue);
    });

    test('values are within [0, 1)', () {
      final rng = SeededRng(123);
      for (var i = 0; i < 1000; i++) {
        final v = rng.next();
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(1));
      }
    });

    test('nextInt covers the full range inclusively', () {
      final rng = SeededRng(7);
      final hits = <int>{};
      for (var i = 0; i < 1000; i++) {
        hits.add(rng.nextInt(1, 5));
      }
      expect(hits, containsAll([1, 2, 3, 4, 5]));
      expect(hits.every((v) => v >= 1 && v <= 5), isTrue);
    });
  });

  group('generateSecret', () {
    test('generates a sequence of the correct length', () {
      final secret = generateSecret(slots: 4, colors: 5, seed: 1);
      expect(secret.length, 4);
      expect(secret.every((c) => c >= 1 && c <= 5), isTrue);
    });

    test('seeded calls are deterministic', () {
      final a = generateSecret(slots: 4, colors: 5, seed: 99);
      final b = generateSecret(slots: 4, colors: 5, seed: 99);
      expect(a, equals(b));
    });

    test('handles 6-color Hard mode', () {
      final secret = generateSecret(slots: 6, colors: 6, seed: 1234);
      expect(secret.length, 6);
      expect(secret.every((c) => c >= 1 && c <= 6), isTrue);
    });
  });

  group('dailySeed', () {
    test('same value for any time on the same UTC day', () {
      final morning = DateTime.utc(2026, 6, 15, 6, 0);
      final evening = DateTime.utc(2026, 6, 15, 23, 30);
      expect(dailySeed(morning), equals(dailySeed(evening)));
    });

    test('changes between UTC days', () {
      final today = DateTime.utc(2026, 6, 15, 12, 0);
      final tomorrow = DateTime.utc(2026, 6, 16, 12, 0);
      expect(dailySeed(today), isNot(equals(dailySeed(tomorrow))));
    });
  });
}

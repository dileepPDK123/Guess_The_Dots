/// Deterministic seeded RNG (mulberry32) — ported from
/// `game-engine.jsx::seedRand`.
///
/// Used for daily/weekly puzzles so every player worldwide gets the same code.
library;

class SeededRng {
  int _state;

  SeededRng(int seed) : _state = seed & 0xFFFFFFFF;

  /// Returns a double in [0.0, 1.0). Each call advances the state.
  double next() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var r = _state;
    r = _mul32(r ^ (r >> 15), r | 1);
    r ^= (r + _mul32(r ^ (r >> 7), r | 61)) & 0xFFFFFFFF;
    final out = (r ^ (r >> 14)) & 0xFFFFFFFF;
    return out / 4294967296.0;
  }

  /// Returns an int in [min, max] inclusive.
  int nextInt(int min, int max) {
    return min + (next() * (max - min + 1)).floor();
  }

  /// Math.imul polyfill — multiplies two 32-bit ints and returns the low 32
  /// bits as a signed int (matches JS behavior).
  static int _mul32(int a, int b) {
    final aLow = a & 0xFFFF;
    final aHigh = (a >> 16) & 0xFFFF;
    final bLow = b & 0xFFFF;
    final bHigh = (b >> 16) & 0xFFFF;
    final low = aLow * bLow;
    final high = (aLow * bHigh + aHigh * bLow) & 0xFFFF;
    return (low + (high << 16)) & 0xFFFFFFFF;
  }
}

/// Generates a secret sequence of [slots] colors numbered 1..[colors].
/// If [seed] is provided, the result is deterministic.
List<int> generateSecret({
  required int slots,
  required int colors,
  int? seed,
}) {
  if (seed != null) {
    final rng = SeededRng(seed);
    return List.generate(slots, (_) => rng.nextInt(1, colors));
  }
  // Non-deterministic fallback (free-play modes)
  final rng = DateTime.now().microsecondsSinceEpoch;
  final r = SeededRng(rng);
  return List.generate(slots, (_) => r.nextInt(1, colors));
}

/// Daily seed: number of days since 2026-01-01 UTC.
/// Same value worldwide for the same calendar day in UTC.
int dailySeed([DateTime? now]) {
  final t = (now ?? DateTime.now()).toUtc();
  final epoch = DateTime.utc(2026, 1, 1);
  return t.difference(epoch).inDays;
}

/// Weekly seed: ISO week number since 2026-01-01.
int weeklySeed([DateTime? now]) => dailySeed(now) ~/ 7;

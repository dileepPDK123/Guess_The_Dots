/// Mastermind-style pip feedback computation, ported from
/// `design_handoff_guess_the_dots/game-engine.jsx::computeFeedback`.
library;

/// Result of comparing one [guess] against a [secret].
class PipFeedback {
  final int green; // exact position matches
  final int yellow; // right color, wrong slot

  const PipFeedback({required this.green, required this.yellow});

  bool get isWin => false; // caller computes win = green == secret.length

  @override
  bool operator ==(Object other) =>
      other is PipFeedback && other.green == green && other.yellow == yellow;

  @override
  int get hashCode => Object.hash(green, yellow);

  @override
  String toString() => 'PipFeedback(green: $green, yellow: $yellow)';
}

/// Computes Mastermind feedback. Each color in [secret] can be matched at most
/// once — duplicate colors in the [guess] beyond what [secret] contains do not
/// double-count.
///
/// Both arrays must have the same length. Colors are 1-indexed integers.
PipFeedback computeFeedback(List<int> guess, List<int> secret) {
  assert(guess.length == secret.length,
      'guess and secret must be the same length');
  final n = secret.length;
  var green = 0;
  final secretRemaining = <int>[];
  final guessRemaining = <int>[];

  for (var i = 0; i < n; i++) {
    if (guess[i] == secret[i]) {
      green++;
    } else {
      secretRemaining.add(secret[i]);
      guessRemaining.add(guess[i]);
    }
  }

  var yellow = 0;
  for (final g in guessRemaining) {
    final idx = secretRemaining.indexOf(g);
    if (idx >= 0) {
      yellow++;
      secretRemaining.removeAt(idx);
    }
  }

  return PipFeedback(green: green, yellow: yellow);
}

/// Per-dot feedback used by Easy mode. One string per slot:
///   'exact' | 'misplaced' | 'absent'
typedef PerDotFeedback = List<String>;

/// Per-dot feedback for Easy mode. Each guess slot returns:
///   'exact'     — that slot matches the secret
///   'misplaced' — that color is in the secret but at a different slot
///   'absent'    — that color isn't in the secret (after consuming exacts)
///
/// Yellow assignment uses the same "consume secret-remaining once" rule as
/// [computeFeedback] so the two are always consistent.
PerDotFeedback computePerDot(List<int> guess, List<int> secret) {
  assert(guess.length == secret.length);
  final n = secret.length;
  final out = List<String>.filled(n, 'absent');
  final remaining = <int, int>{};
  for (var i = 0; i < n; i++) {
    if (guess[i] == secret[i]) {
      out[i] = 'exact';
    } else {
      remaining[secret[i]] = (remaining[secret[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < n; i++) {
    if (out[i] == 'exact') continue;
    final left = remaining[guess[i]] ?? 0;
    if (left > 0) {
      out[i] = 'misplaced';
      remaining[guess[i]] = left - 1;
    }
  }
  return out;
}

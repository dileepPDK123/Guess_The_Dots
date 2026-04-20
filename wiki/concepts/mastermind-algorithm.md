---
title: Mastermind Algorithm
type: concept
---

# Mastermind Algorithm

Core guess evaluation logic. Returns exact matches and misplaced matches for each guess.

## Implementation
`_evaluate_guess(guess: Array[int]) -> Dictionary` in [[entities/Main]].

```gdscript
func _evaluate_guess(guess: Array[int]) -> Dictionary:
    var exact := 0
    var secret_counts := {}
    var guess_counts := {}

    for index in range(secret_sequence.size()):
        if guess[index] == secret_sequence[index]:
            exact += 1
        else:
            secret_counts[secret_sequence[index]] = secret_counts.get(secret_sequence[index], 0) + 1
            guess_counts[guess[index]] = guess_counts.get(guess[index], 0) + 1

    var misplaced := 0
    for ci in guess_counts.keys():
        misplaced += min(guess_counts[ci], secret_counts.get(ci, 0))

    return {"exact": exact, "misplaced": misplaced}
```

## Feedback Display
| Pip | Meaning | Cyberpunk label |
|-----|---------|----------------|
| Green ◆ | Exact match — right color, right slot | LOCKED |
| Yellow ◆ | Misplaced — right color, wrong slot | SIGNAL |
| (empty) | No match | NULL SIGNAL |

## Win Condition
`exact == slots_needed` — all positions correct.

## Hard Mode Extension
In HARD mode: slots confirmed exact are locked. Player cannot change them in subsequent guesses. Implemented in [[entities/Main]] as locked slot state tracking.

## Notes
- The algorithm handles **duplicate colors** correctly via frequency tables
- Order of feedback pips does not correspond to order of slots (standard Mastermind convention)

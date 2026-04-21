---
title: Mastermind Algorithm
type: concept
---

# Mastermind Algorithm

Core guess evaluation logic. Returns exact matches and misplaced matches for each guess.

## Implementation (Updated 2026-04-20)
`_evaluate_guess(guess: Array[int]) -> Dictionary` in [[entities/Main]].

Now uses two-pass algorithm to also compute `per_dot` array:

```gdscript
func _evaluate_guess(guess: Array[int]) -> Dictionary:
    var exact := 0
    var per_dot: Array = []
    var secret_remaining := secret_sequence.duplicate()
    var guess_remaining  := guess.duplicate()
    # Pass 1: exact
    for i in range(guess.size()):
        if guess[i] == secret_sequence[i]:
            exact += 1
            per_dot.append("exact")
            secret_remaining[i] = -1
            guess_remaining[i]  = -1
        else:
            per_dot.append("absent")
    # Pass 2: misplaced
    var misplaced := 0
    for i in range(guess.size()):
        if guess_remaining[i] == -1: continue
        var found := secret_remaining.find(guess_remaining[i])
        if found != -1:
            misplaced += 1
            per_dot[i] = "misplaced"
            secret_remaining[found] = -1
    return {"exact": exact, "misplaced": misplaced, "per_dot": per_dot}
```

## Feedback Display
| Pip | Meaning |
|-----|---------|
| Green pip | Exact match — right color, right slot |
| Yellow pip | Misplaced — right color, wrong slot |
| (count-only) | Classic/Blitz/Hard/Zen/Campaign: total counts shown as pips |
| Colored ring | Easy mode: per-dot ring (green=exact, yellow=misplaced) |

## Win Condition
`exact == slots_needed` — all positions correct.

## Hard Mode Extension
In HARD mode: slots confirmed exact are locked. Player cannot change them in subsequent guesses. Implemented in [[entities/Main]] as locked slot state tracking.

## Notes
- The algorithm handles **duplicate colors** correctly via frequency tables
- Order of feedback pips does not correspond to order of slots (standard Mastermind convention)

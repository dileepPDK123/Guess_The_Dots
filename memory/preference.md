---
name: Preferences
description: User and project preferences — coding style, tooling choices, workflow habits
type: feedback
---

# Preferences

## Format

**Preference title**
- **Rule:** The preference itself
- **Why:** Reason given or inferred
- **How to apply:** When this kicks in

---

## Big-picture planning before implementation

- **Rule:** Create comprehensive plan.md documents before implementing. User wants
  brainstorming, feature lists, phased roadmaps, and visual maps of ad placements.
- **Why:** User thinks at a product/design level and wants alignment before coding begins.
- **How to apply:** When given a large multi-feature request, write the plan document
  first. Only start coding individual features when the plan is approved.

## Futuristic / cyberpunk aesthetic

- **Rule:** All UI design decisions should align with the "NEURAL GRID" cyberpunk theme —
  neon cyan accents, void black backgrounds, uppercase labels, monospaced counters,
  technical vocabulary.
- **Why:** This is the chosen brand identity for the game.
- **How to apply:** Any new UI elements, labels, or screens must match this language.
  Refer to plan.md Part 1 for full style spec.

## Ambitious scope is welcome

- **Rule:** User wants bold ideas and extensive feature suggestions. Don't trim ideas
  to be conservative — include stretch goals with clear labeling.
- **Why:** "do brainstorming and create a wonderful game" — user explicitly wants big thinking.
- **How to apply:** When planning, include stretch goals labeled as such. Mark phases.
  Don't self-censor "too ambitious" ideas — just tier them properly.

## Keep code concise and GDScript idiomatic

- **Rule:** New GDScript should follow existing patterns in the codebase:
  typed variables (`var x: int`), `@onready`, consistent comment headers,
  autoload singletons for cross-scene state.
- **Why:** Existing code is clean — match the style.
- **How to apply:** Before writing any new script, read an existing one for style reference.

## Delegate implementation approach when user says "do as you like"

- **Rule:** When user says "do as u like, the best way" or similar, make all
  design/architecture decisions independently and implement without seeking approval.
- **Why:** User trusts Claude's judgment for implementation details and doesn't
  want back-and-forth on specifics.
- **How to apply:** Only check back if there's a genuine design fork with significant
  gameplay implications (e.g., removing a whole feature vs. adding one).

---

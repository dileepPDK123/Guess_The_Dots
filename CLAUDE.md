# Claude Instructions — Guess the Dots (Godot)

## Session Start

At the beginning of every session, read these files before doing anything else:

1. `memory/user.md` — who the user is, their background and working style
2. `memory/preference.md` — workflow and coding preferences, things to do/avoid
3. `memory/decisions.md` — past design and technical decisions
4. `memory/people.md` — people involved in the project
5. `memory/changelog.md` — recent changes and current change number

Greet the user with a one-line summary of what you recall about the current state of the project (latest changelog entry), so they know context has been loaded.

## Session End

When the session is wrapping up (user says goodbye, thanks, or the task is clearly done), update the memory files with anything new learned:

- `memory/user.md` — any new info about the user's background, preferences, or goals
- `memory/preference.md` — any new preferences confirmed or corrected
- `memory/decisions.md` — any decisions made this session
- `memory/people.md` — any new people or role changes
- `memory/changelog.md` — append a new entry for every meaningful change made (see format below)

Also mirror key facts to the built-in memory files at:
`C:/Users/potha/.claude/projects/D--Guess-the-Dots-guess-the-dots-godot/memory/`

## Changelog Format

Every meaningful change to the project gets a new entry in `memory/changelog.md`:

```
## [CHG-###] YYYY-MM-DD — Short title

- **What changed:** Description of what was added, modified, or removed
- **Files affected:** List of files
- **Why:** Reason for the change
- **Revert notes:** What to undo if reverting this change
```

Increment the CHG number by 1 each time. Never reuse a number.

## General Rules

- Keep responses concise. No trailing summaries after completing a task.
- Do not add features, refactors, or comments beyond what was asked.
- Always read a file before editing it.
- Do not create new files unless strictly necessary.

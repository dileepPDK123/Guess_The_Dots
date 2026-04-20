---
title: SoundManager.gd
type: autoload
path: scripts/SoundManager.gd
lines: 145
extends: Node
singleton: true
---

# SoundManager.gd

Autoload singleton. Generates all game audio procedurally as 16-bit mono WAV at 44100 Hz. **No audio asset files needed.**

## Sound Catalog
| ID | Waveform | Frequency | Duration |
|----|----------|-----------|---------|
| `tap` | sine | 880 Hz | 60ms |
| `dot_place` | sine | 1200 Hz | 80ms |
| `dot_clear` | sine | 600 Hz | 60ms |
| `submit` | chord | 440+550 Hz | 120ms |
| `exact` | arpeggio | 523→659→784 Hz | 80ms/note |
| `misplace` | sine | 370 Hz | 70ms |
| `win` | arpeggio | 523→659→784→1047 Hz | 180ms/note |
| `lose` | descend | 440→349→262 Hz | 200ms/note |
| `level_up` | arpeggio | 392→523→659→880→1047 Hz | 220ms/note |
| `achievement` | chord | 523+659 Hz | 180ms |
| `coin` | arpeggio | 1047→1319 Hz | 100ms/note |
| `hint` | arpeggio | 440→659→880 Hz | 140ms/note |

## Key Variables
- `sfx_volume: float` — 0.0–1.0 (default 0.80)
- `sfx_enabled: bool` — master mute

## Channels
6 parallel `AudioStreamPlayer` nodes allow simultaneous overlapping sounds.

## Key Methods
- `play(sound_id)` — enqueue on next free channel
- `_sine_tone(freq, amplitude, duration)` → AudioStreamWAV
- `_chord(freqs, amplitude, duration)` — two simultaneous tones
- `_arpeggio(freqs, amplitude, note_duration)` — sequential notes
- `_make_wav(data, frame_count)` → AudioStreamWAV — construct raw WAV

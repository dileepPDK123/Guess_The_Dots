---
title: Pastel Theme (Visual System)
type: concept
status: planned
spec: docs/superpowers/specs/2026-04-19-ui-rework-design.md § Section 1
---

# Pastel Theme — Visual Design System

Replaces the dark NEURAL GRID cyberpunk theme. Soft, light, premium mobile aesthetic.

## Color Tokens
| Token | Value | Usage |
|-------|-------|-------|
| BG_GRADIENT | `#FFF1F9 → #FFF8F0 → #F0FFF8` (160deg) | Screen background (pink-to-mint) |
| PANEL | `rgba(255,255,255,0.75)` | Card/panel fill |
| PANEL_BORDER | `#FFD6E7` | Panel border (1px) |
| CTA_GRAD | `#F472B6 → #A78BFA` (135deg) | Submit, New Game, primary buttons |
| CTA_SHADOW | `rgba(244,114,182,0.35)` | Button drop shadow |
| TEXT_PRIMARY | `#6B4E71` | Headings, important labels |
| TEXT_SECONDARY | `#C084B8` | Subheadings, hints, secondary info |
| TEXT_ACTION | `#9B7BAB` | Secondary button text |
| PIP_EXACT | `#22C55E` | Exact match pip / ring |
| PIP_MISPLACE | `#FACC15` | Misplaced pip / ring |
| PIP_EMPTY | `rgba(200,180,220,0.25)` | No-match pip |
| ACTIVE_ROW | `rgba(244,114,182,0.07)` | Current guess row fill |
| ACTIVE_BORDER | `rgba(244,114,182,0.4)` | Current guess row border |

## Dot Colors (unchanged)
| Name | Hex |
|------|-----|
| Red | `#EF4444` |
| Blue | `#3B82F6` |
| Green | `#22C55E` |
| Yellow | `#FACC15` |
| Purple | `#A855F7` |
| Orange (Hard only) | `#F97316` |

## Component Rules
- **Panels:** `border-radius: 16px`, `1px solid #FFD6E7`, shadow `0 4px 16px rgba(167,114,182,0.10)`
- **Primary buttons:** CTA gradient, `border-radius: 14px`, shadow `0 4px 14px rgba(244,114,182,0.35)`, white bold text
- **Secondary buttons:** white glass fill, `#9B7BAB` text, `1px solid rgba(249,168,212,0.3)`
- **Slot shape:** Rounded squares (`border-radius: 8px`) — not circles
- **Palette dots:** Circles, `box-shadow: 0 2px 8px <color at 0.3 alpha>`, `border: 2px solid rgba(255,255,255,0.8)`
- **Selected palette dot:** scale 1.12, `outline: 2px solid <color at 0.4 alpha>`, `outline-offset: 3px`

## Removed from Old Theme
- `#051E28` dark background
- `#00E6FF` cyan neon borders
- `#FF006E` magenta accents
- Cyberpunk vocabulary (TRANSMIT/WIPE/REVERT/SCAN → SUBMIT/CLEAR/UNDO/HINT)
- Hex grid shader background

## Themes Available (XP Shop)
The old cyberpunk aesthetic lives on as purchasable themes:
- **Neon Core** — dark void + cyan neon (old default) — 1200 XP
- **Void Protocol** — deep black + electric blue — 1500 XP
- **Solar Flare** — amber + orange gradients — 1000 XP
- Season-exclusive themes (1 per 2-month season)

## Related
- [[entities/Main]] — `_apply_theme()`
- [[concepts/season-track]] — season-exclusive theme unlocks
- [[concepts/xp-shop]] — theme purchase

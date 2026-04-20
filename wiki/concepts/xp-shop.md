---
title: XP Shop
type: concept
status: planned
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 2a
---

# XP Shop

Players spend accumulated XP on consumable items and permanent cosmetics. Accessible via "Rewards" screen (tab 1).

## Catalog

### Consumables
| Item | Cost | Max Held | Effect |
|------|------|---------|--------|
| Hint Token ×3 | 150 XP | 10 | Skip rewarded ad for a Smart Hint |
| Second Chance Token | 200 XP | 5 | Skip ad for +3 guesses on loss |
| Extra Guess Token | 250 XP | 5 | +1 max guess before game starts |
| Streak Freeze | 300 XP | 2 | Auto-protects daily streak for 1 missed day |
| XP Boost ×1hr | 50 coins | — | All XP ×2 for 60 real minutes |

### Sound Packs (Permanent)
| Item | Cost | Description |
|------|------|-------------|
| Soft Piano | 600 XP | Piano-tone procedural audio |
| Nature | 600 XP | Chimes + soft percussion |
| Retro Arcade | 600 XP | Punchier 8-bit variants |

### Share Emoji Packs (Permanent)
| Item | Cost | Emojis |
|------|------|--------|
| Hearts | 400 XP | ❤️🧡🖤 |
| Space | 400 XP | 🌍🌙⭐ |
| Flowers | 400 XP | 🌸🌼🌑 |

### Board Skins (Permanent)
| Item | Cost | Description |
|------|------|-------------|
| Minimal | 700 XP | No grid lines, floating dots |
| Rounded | 700 XP | Pill-shaped slots |
| Diamond | 700 XP | Slots rotated 45° |

### Themes (Permanent)
| Item | Cost | Description |
|------|------|-------------|
| Neon Core | 1200 XP | Dark cyberpunk (old default) |
| Solar Flare | 1000 XP | Warm amber + orange |
| Void Protocol | 1500 XP | Deep black + electric blue |
| Season exclusives | — | Via [[concepts/season-track]] milestones |

### Dot Shapes (Permanent)
| Item | Cost |
|------|------|
| Hexagon | 500 XP |
| Diamond | 500 XP |
| Star | 500 XP |

## Purchase Flow
1. Tap item → confirmation sheet with cost
2. Insufficient XP: button disabled, link to earn more
3. On confirm: deduct from `SaveData.total_xp_earned`, add to inventory, haptic + coin sound

## Token Usage
- **Hint Tokens:** checked before showing rewarded ad — if held, hint is instant, no ad
- **Second Chance Tokens:** same — skips ad, applies 3 bonus guesses immediately
- **Extra Guess Tokens:** toggle on Mode Select ("Use token: +1 guess ✓")
- **Streak Freeze:** auto-consumed silently; toast: "Streak Freeze used 🧊 Streak preserved!"

## XP Deduction Rule
Spending XP deducts from `total_xp_earned` (lifetime pool), NOT from `xp` (level progress). Player never loses level progress by shopping.

## Related
- [[concepts/reward-system]] — how XP is earned
- [[concepts/season-track]] — season-exclusive items
- [[entities/ShopManager]] — implementation
- [[entities/SaveData]] — token inventory fields

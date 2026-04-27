/// Game mode catalog — ported from `game-engine.jsx::MODES`.
library;

import 'package:flutter/widgets.dart';

class GameMode {
  final String id;
  final String name;
  final String hook;
  final String emoji;
  final String iconName; // matches the icon registry in icons.dart
  final Color stripe;
  final int slots;
  final int colors;
  final int guesses;
  final int xp;
  final bool hero; // shown as a hero card on mode select
  final bool locked;
  final String? unlockLabel;
  final int? timerSeconds;

  const GameMode({
    required this.id,
    required this.name,
    required this.hook,
    required this.emoji,
    required this.iconName,
    required this.stripe,
    required this.slots,
    required this.colors,
    required this.guesses,
    required this.xp,
    this.hero = false,
    this.locked = false,
    this.unlockLabel,
    this.timerSeconds,
  });
}

abstract class GameModes {
  static const daily = GameMode(
    id: 'daily',
    name: 'Daily',
    hook: "Today's puzzle",
    emoji: '🔥',
    iconName: 'flame',
    stripe: Color(0xFFFF4D6D),
    slots: 4,
    colors: 5,
    guesses: 6,
    xp: 75,
    hero: true,
  );

  static const weekly = GameMode(
    id: 'weekly',
    name: 'Weekly',
    hook: "This week's challenge",
    emoji: '🏆',
    iconName: 'trophy',
    stripe: Color(0xFFFFB547),
    slots: 5,
    colors: 6,
    guesses: 8,
    xp: 200,
    hero: true,
  );

  static const classic = GameMode(
    id: 'classic',
    name: 'Classic',
    hook: 'The pure game',
    emoji: '🎯',
    iconName: 'target',
    stripe: Color(0xFFF43F8E),
    slots: 4,
    colors: 5,
    guesses: 10,
    xp: 40,
  );

  static const easy = GameMode(
    id: 'easy',
    name: 'Easy',
    hook: 'Per-dot color hints',
    emoji: '🌱',
    iconName: 'leaf',
    stripe: Color(0xFF3DDC97),
    slots: 4,
    colors: 5,
    guesses: 10,
    xp: 30,
  );

  static const blitz = GameMode(
    id: 'blitz',
    name: 'Blitz',
    hook: '90s against the clock',
    emoji: '⚡',
    iconName: 'zap',
    stripe: Color(0xFF4FC3FF),
    slots: 4,
    colors: 5,
    guesses: 99,
    xp: 60,
    timerSeconds: 90,
  );

  static const hard = GameMode(
    id: 'hard',
    name: 'Hard',
    hook: '6 colors · locked slots',
    emoji: '💀',
    iconName: 'skull',
    stripe: Color(0xFFB285FF),
    slots: 5,
    colors: 6,
    guesses: 8,
    xp: 90,
  );

  static const zen = GameMode(
    id: 'zen',
    name: 'Zen',
    hook: 'Unlimited. No pressure.',
    emoji: '🧘',
    iconName: 'sparkle',
    stripe: Color(0xFF8FE6E3),
    slots: 4,
    colors: 5,
    guesses: 999,
    xp: 20,
  );

  static const campaign = GameMode(
    id: 'campaign',
    name: 'Campaign',
    hook: '100 levels · 3 stars',
    emoji: '🗺️',
    iconName: 'map',
    stripe: Color(0xFFFFB547),
    slots: 4,
    colors: 5,
    guesses: 8,
    xp: 50,
  );

  static const mystery = GameMode(
    id: 'mystery',
    name: 'Mystery',
    hook: 'Hidden dot count',
    emoji: '🎭',
    iconName: 'mask',
    stripe: Color(0xFFFF7AC6),
    slots: 4,
    colors: 5,
    guesses: 10,
    xp: 80,
  );

  static const timetrial = GameMode(
    id: 'timetrial',
    name: 'Time Trial',
    hook: '5 puzzles back-to-back',
    emoji: '⏱️',
    iconName: 'clock',
    stripe: Color(0xFFFFD63A),
    slots: 4,
    colors: 5,
    guesses: 6,
    xp: 120,
  );

  static const duo = GameMode(
    id: 'duo',
    name: 'Duo',
    hook: 'Two codes, one guess',
    emoji: '👯',
    iconName: 'users',
    stripe: Color(0xFFC24DFF),
    slots: 4,
    colors: 5,
    guesses: 10,
    xp: 100,
  );

  static const sudden = GameMode(
    id: 'sudden',
    name: 'Sudden Death',
    hook: 'One wrong = over',
    emoji: '☠️',
    iconName: 'skull',
    stripe: Color(0xFFFF3B5C),
    slots: 4,
    colors: 5,
    guesses: 6,
    xp: 150,
    locked: true,
    unlockLabel: 'Lv 10',
  );

  static const sandbox = GameMode(
    id: 'sandbox',
    name: 'Sandbox',
    hook: 'Set your own secret',
    emoji: '🎨',
    iconName: 'paint',
    stripe: Color(0xFF6BFF5C),
    slots: 4,
    colors: 5,
    guesses: 10,
    xp: 10,
  );

  static const custom = GameMode(
    id: 'custom',
    name: 'Friend Code',
    hook: "Enter a friend's code",
    emoji: '🔗',
    iconName: 'link',
    stripe: Color(0xFF9BB0D9),
    slots: 4,
    colors: 5,
    guesses: 10,
    xp: 10,
  );

  /// Catalog in the order shown in the mode select.
  static const all = <GameMode>[
    daily,
    weekly,
    classic,
    easy,
    blitz,
    hard,
    zen,
    campaign,
    mystery,
    timetrial,
    duo,
    sudden,
    sandbox,
    custom,
  ];

  /// Modes excluding the hero ones (daily, weekly) and custom.
  static const grid = <GameMode>[
    classic,
    easy,
    blitz,
    hard,
    zen,
    campaign,
    mystery,
    timetrial,
    duo,
    sudden,
    sandbox,
  ];

  static GameMode? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}

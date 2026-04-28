import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/modes.dart';

/// Persistent player progression — XP, level, coins, streaks, per-mode stats.
/// Backed by SharedPreferences for the local store. Cloud sync happens later
/// via Firebase (mirrors these fields to Firestore on submit_save).
class PlayerState {
  final int totalXpEarned;
  final int level;
  final int coins;
  final int dailyStreak;
  final int dailyMaxStreak;
  final String dailyLastDate; // YYYY-MM-DD UTC
  final Map<String, ModeStats> perMode;
  final List<RecentGame> recentGames;
  final bool tutorialSeen;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool colorblindEnabled;
  final bool dailyReminderEnabled;

  const PlayerState({
    required this.totalXpEarned,
    required this.level,
    required this.coins,
    required this.dailyStreak,
    required this.dailyMaxStreak,
    required this.dailyLastDate,
    required this.perMode,
    required this.recentGames,
    required this.tutorialSeen,
    required this.hapticsEnabled,
    required this.soundEnabled,
    required this.colorblindEnabled,
    required this.dailyReminderEnabled,
  });

  factory PlayerState.empty() => const PlayerState(
        totalXpEarned: 0,
        level: 1,
        coins: 0,
        dailyStreak: 0,
        dailyMaxStreak: 0,
        dailyLastDate: '',
        perMode: {},
        recentGames: [],
        tutorialSeen: false,
        hapticsEnabled: true,
        soundEnabled: true,
        colorblindEnabled: false,
        dailyReminderEnabled: false,
      );

  /// Total XP needed to reach a given level. Curve: 100 * level^1.5
  static int xpForLevel(int lvl) {
    if (lvl <= 1) return 0;
    return (100 * (lvl - 1) * 1.0 + 50 * (lvl - 1) * (lvl - 1)).round();
  }

  /// XP into the current level / XP needed for the next level.
  ({int into, int needed}) levelProgress() {
    final base = xpForLevel(level);
    final next = xpForLevel(level + 1);
    return (into: totalXpEarned - base, needed: next - base);
  }

  int get totalGames =>
      perMode.values.fold(0, (sum, s) => sum + s.played);

  int get totalWins => perMode.values.fold(0, (sum, s) => sum + s.wins);

  double get winRate {
    final t = totalGames;
    if (t == 0) return 0;
    return totalWins / t;
  }

  PlayerState copyWith({
    int? totalXpEarned,
    int? level,
    int? coins,
    int? dailyStreak,
    int? dailyMaxStreak,
    String? dailyLastDate,
    Map<String, ModeStats>? perMode,
    List<RecentGame>? recentGames,
    bool? tutorialSeen,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? colorblindEnabled,
    bool? dailyReminderEnabled,
  }) {
    return PlayerState(
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      dailyMaxStreak: dailyMaxStreak ?? this.dailyMaxStreak,
      dailyLastDate: dailyLastDate ?? this.dailyLastDate,
      perMode: perMode ?? this.perMode,
      recentGames: recentGames ?? this.recentGames,
      tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      colorblindEnabled: colorblindEnabled ?? this.colorblindEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXpEarned': totalXpEarned,
        'level': level,
        'coins': coins,
        'dailyStreak': dailyStreak,
        'dailyMaxStreak': dailyMaxStreak,
        'dailyLastDate': dailyLastDate,
        'perMode':
            perMode.map((k, v) => MapEntry(k, v.toJson())),
        'recentGames':
            recentGames.map((g) => g.toJson()).toList(),
        'tutorialSeen': tutorialSeen,
        'hapticsEnabled': hapticsEnabled,
        'soundEnabled': soundEnabled,
        'colorblindEnabled': colorblindEnabled,
        'dailyReminderEnabled': dailyReminderEnabled,
      };

  factory PlayerState.fromJson(Map<String, dynamic> j) {
    return PlayerState(
      totalXpEarned: (j['totalXpEarned'] as int?) ?? 0,
      level: (j['level'] as int?) ?? 1,
      coins: (j['coins'] as int?) ?? 0,
      dailyStreak: (j['dailyStreak'] as int?) ?? 0,
      dailyMaxStreak: (j['dailyMaxStreak'] as int?) ?? 0,
      dailyLastDate: (j['dailyLastDate'] as String?) ?? '',
      perMode: ((j['perMode'] as Map?) ?? {}).map(
        (k, v) => MapEntry(k as String, ModeStats.fromJson(v as Map)),
      ),
      recentGames: ((j['recentGames'] as List?) ?? [])
          .map((g) => RecentGame.fromJson(g as Map))
          .toList(),
      tutorialSeen: (j['tutorialSeen'] as bool?) ?? false,
      hapticsEnabled: (j['hapticsEnabled'] as bool?) ?? true,
      soundEnabled: (j['soundEnabled'] as bool?) ?? true,
      colorblindEnabled: (j['colorblindEnabled'] as bool?) ?? false,
      dailyReminderEnabled: (j['dailyReminderEnabled'] as bool?) ?? false,
    );
  }
}

class ModeStats {
  final int played;
  final int wins;
  final int? minGuesses;
  final int? minTimeMs;
  final List<int> guessDist; // index 0..guesses-1: count of wins at that count

  const ModeStats({
    required this.played,
    required this.wins,
    required this.minGuesses,
    required this.minTimeMs,
    required this.guessDist,
  });

  factory ModeStats.empty() =>
      const ModeStats(played: 0, wins: 0, minGuesses: null, minTimeMs: null, guessDist: []);

  ModeStats record({required bool didWin, required int guesses, required int timeMs}) {
    final newDist = List<int>.from(guessDist);
    while (newDist.length < guesses + 1) {
      newDist.add(0);
    }
    if (didWin) {
      newDist[guesses] = newDist[guesses] + 1;
    }
    return ModeStats(
      played: played + 1,
      wins: wins + (didWin ? 1 : 0),
      minGuesses: didWin && (minGuesses == null || guesses < minGuesses!)
          ? guesses
          : minGuesses,
      minTimeMs: didWin && (minTimeMs == null || timeMs < minTimeMs!)
          ? timeMs
          : minTimeMs,
      guessDist: newDist,
    );
  }

  Map<String, dynamic> toJson() => {
        'played': played,
        'wins': wins,
        'minGuesses': minGuesses,
        'minTimeMs': minTimeMs,
        'guessDist': guessDist,
      };

  factory ModeStats.fromJson(Map j) => ModeStats(
        played: (j['played'] as int?) ?? 0,
        wins: (j['wins'] as int?) ?? 0,
        minGuesses: j['minGuesses'] as int?,
        minTimeMs: j['minTimeMs'] as int?,
        guessDist:
            ((j['guessDist'] as List?) ?? []).map((v) => v as int).toList(),
      );
}

class RecentGame {
  final String modeId;
  final bool won;
  final int guesses;
  final int timeMs;
  final DateTime when;

  const RecentGame({
    required this.modeId,
    required this.won,
    required this.guesses,
    required this.timeMs,
    required this.when,
  });

  Map<String, dynamic> toJson() => {
        'modeId': modeId,
        'won': won,
        'guesses': guesses,
        'timeMs': timeMs,
        'when': when.toUtc().toIso8601String(),
      };

  factory RecentGame.fromJson(Map j) => RecentGame(
        modeId: j['modeId'] as String,
        won: (j['won'] as bool?) ?? false,
        guesses: (j['guesses'] as int?) ?? 0,
        timeMs: (j['timeMs'] as int?) ?? 0,
        when: DateTime.tryParse(j['when'] as String? ?? '')
                ?.toLocal() ??
            DateTime.now(),
      );
}

// ── Provider ─────────────────────────────────────────────────────────────────

const _kPrefsKey = 'gtd.playerState.v1';

class PlayerNotifier extends Notifier<PlayerState> {
  SharedPreferences? _prefs;

  @override
  PlayerState build() {
    _load();
    return PlayerState.empty();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kPrefsKey);
    if (raw != null) {
      try {
        state = PlayerState.fromJson(json.decode(raw) as Map<String, dynamic>);
      } catch (_) {
        // leave default empty
      }
    }
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kPrefsKey, json.encode(state.toJson()));
  }

  /// Replace the state wholesale with a hydrated version (e.g. from cloud save).
  /// Triggers a save to keep local in sync.
  void hydrate(PlayerState newState) {
    state = newState;
    _save();
  }

  /// Award XP + recompute level. Returns the new level (caller may animate).
  int addXp(int amount) {
    final newTotal = state.totalXpEarned + amount;
    var newLevel = state.level;
    while (PlayerState.xpForLevel(newLevel + 1) <= newTotal) {
      newLevel++;
    }
    state = state.copyWith(totalXpEarned: newTotal, level: newLevel);
    _save();
    return newLevel;
  }

  void addCoins(int n) {
    state = state.copyWith(coins: state.coins + n);
    _save();
  }

  /// Records a finished game: per-mode stats + recent list.
  void recordGame({
    required GameMode mode,
    required bool didWin,
    required int guesses,
    required int timeMs,
  }) {
    final perMode = Map<String, ModeStats>.from(state.perMode);
    final stats = perMode[mode.id] ?? ModeStats.empty();
    perMode[mode.id] = stats.record(didWin: didWin, guesses: guesses, timeMs: timeMs);
    final recents = List<RecentGame>.from(state.recentGames);
    recents.insert(
      0,
      RecentGame(
        modeId: mode.id,
        won: didWin,
        guesses: guesses,
        timeMs: timeMs,
        when: DateTime.now(),
      ),
    );
    while (recents.length > 30) {
      recents.removeLast();
    }
    state = state.copyWith(perMode: perMode, recentGames: recents);
    _save();
  }

  /// Returns the new streak count after recording today's daily.
  int recordDaily({required bool didWin}) {
    final today = _todayUtc();
    if (state.dailyLastDate == today) return state.dailyStreak; // already done
    final yest = _yesterdayUtc();
    int newStreak;
    if (didWin) {
      newStreak = (state.dailyLastDate == yest || state.dailyLastDate.isEmpty)
          ? state.dailyStreak + 1
          : 1;
    } else {
      newStreak = 0;
    }
    final newMax = newStreak > state.dailyMaxStreak ? newStreak : state.dailyMaxStreak;
    state = state.copyWith(
      dailyStreak: newStreak,
      dailyMaxStreak: newMax,
      dailyLastDate: today,
    );
    _save();
    return newStreak;
  }

  bool isDailyDoneToday() => state.dailyLastDate == _todayUtc();

  void setTutorialSeen(bool v) {
    state = state.copyWith(tutorialSeen: v);
    _save();
  }

  void setSetting({
    bool? haptics,
    bool? sound,
    bool? colorblind,
    bool? dailyReminder,
  }) {
    state = state.copyWith(
      hapticsEnabled: haptics,
      soundEnabled: sound,
      colorblindEnabled: colorblind,
      dailyReminderEnabled: dailyReminder,
    );
    _save();
  }

  static String _todayUtc() {
    final t = DateTime.now().toUtc();
    return '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayUtc() {
    final t = DateTime.now().toUtc().subtract(const Duration(days: 1));
    return '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);


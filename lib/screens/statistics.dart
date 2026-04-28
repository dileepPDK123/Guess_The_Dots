import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../game/modes.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = context.velvet;
    final p = ref.watch(playerProvider);
    final winPct = p.totalGames == 0 ? 0 : (p.winRate * 100).round();
    final fastest = _fastest(p);
    final dist = _aggregatedDist(p);
    final maxBucket = dist.isEmpty ? 1 : dist.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: v.bg1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: v.text1),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text('Statistics', style: AppText.title(color: v.text1)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              _Stat(label: 'Played', value: '${p.totalGames}'),
              _Stat(label: 'Wins', value: '$winPct%'),
              _Stat(label: 'Streak', value: '${p.dailyStreak}'),
              _Stat(label: 'Fastest', value: fastest),
            ],
          ),
          const SizedBox(height: 22),
          Text('GUESS DISTRIBUTION', style: AppText.tag(color: v.text3)),
          const SizedBox(height: 12),
          if (dist.isEmpty || maxBucket == 0)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: v.bg2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child: Text('Win a game to see your distribution.',
                    style: AppText.caption(color: v.text2)),
              ),
            )
          else
            for (var i = 0; i < dist.length; i++)
              _DistRow(
                label: '${i + 1}',
                count: dist[i],
                max: maxBucket,
                isBest: dist[i] == maxBucket,
              ),
          const SizedBox(height: 22),
          Text('PER MODE', style: AppText.tag(color: v.text3)),
          const SizedBox(height: 12),
          if (p.perMode.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: v.bg2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child:
                    Text('No games yet.', style: AppText.caption(color: v.text2)),
              ),
            )
          else
            for (final entry in p.perMode.entries)
              _ModeRow(modeId: entry.key, stats: entry.value),
          const SizedBox(height: 22),
          Text('RECENT GAMES', style: AppText.tag(color: v.text3)),
          const SizedBox(height: 12),
          if (p.recentGames.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: v.bg2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child:
                    Text('No games yet.', style: AppText.caption(color: v.text2)),
              ),
            )
          else
            for (final r in p.recentGames.take(10))
              _RecentRow(recent: r),
        ],
      ),
    );
  }

  String _fastest(PlayerState p) {
    int? best;
    for (final s in p.perMode.values) {
      if (s.minTimeMs == null) continue;
      if (best == null || s.minTimeMs! < best) best = s.minTimeMs;
    }
    if (best == null) return '—';
    final secs = best ~/ 1000;
    return '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  /// Aggregates guess-distribution counts across all modes.
  List<int> _aggregatedDist(PlayerState p) {
    var maxLen = 0;
    for (final s in p.perMode.values) {
      if (s.guessDist.length > maxLen) maxLen = s.guessDist.length;
    }
    final out = List<int>.filled(maxLen, 0);
    for (final s in p.perMode.values) {
      for (var i = 0; i < s.guessDist.length; i++) {
        out[i] += s.guessDist[i];
      }
    }
    return out;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Container(
      decoration: BoxDecoration(
        color: v.bg2,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: AppText.displayM(color: v.text1).copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: AppText.tag(color: v.text3).copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _DistRow extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final bool isBest;

  const _DistRow({
    required this.label,
    required this.count,
    required this.max,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final pct = max > 0 ? count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 18,
              child:
                  Text(label, style: AppText.body(color: v.text2))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: v.bg2,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.05, 1.0),
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isBest ? v.accent : v.bg4,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text('$count',
                      style: AppText.caption(color: v.text1).copyWith(
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final String modeId;
  final ModeStats stats;
  const _ModeRow({required this.modeId, required this.stats});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final mode = GameModes.byId(modeId);
    final pct = stats.played == 0 ? 0 : (stats.wins / stats.played * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: v.bg2,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Text(mode?.emoji ?? '•', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mode?.name ?? modeId,
                style: AppText.body(color: v.text1)),
          ),
          Text('$pct% win',
              style: AppText.caption(color: v.text2)),
          const SizedBox(width: 12),
          Text(
              stats.minGuesses == null
                  ? '—'
                  : 'best ${stats.minGuesses}',
              style: AppText.caption(color: v.text3)),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final RecentGame recent;
  const _RecentRow({required this.recent});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final mode = GameModes.byId(recent.modeId);
    final df = DateFormat.yMd().add_jm();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: v.bg2,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(
            recent.won
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: recent.won ? v.pipGreen : v.text3,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mode?.name ?? recent.modeId,
                style: AppText.body(color: v.text1)),
          ),
          Text(
              recent.won ? '${recent.guesses}' : 'X',
              style: AppText.caption(color: v.text2)),
          const SizedBox(width: 12),
          Text(df.format(recent.when),
              style: AppText.caption(color: v.text3).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

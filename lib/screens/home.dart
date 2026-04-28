import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/modes.dart';
import '../game/seeded_rng.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/blended_list.dart';
import '../widgets/buttons.dart';
import 'game_board.dart';
import 'how_to_play.dart';
import 'mode_select.dart';
import 'rewards.dart';
import 'settings_sheet.dart';
import 'statistics.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = context.velvet;
    final player = ref.watch(playerProvider);
    final dailyDone = ref.read(playerProvider.notifier).isDailyDoneToday();
    final winPct = (player.winRate * 100).round();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'GTD',
                    style: AppText.displayM(color: v.text1).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => SettingsSheet.show(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: v.bg2,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child:
                          Icon(Icons.settings_rounded, color: v.text2, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  StatChip(
                    label: 'Lv ${player.level}',
                    icon: Icons.flash_on_rounded,
                  ),
                  const SizedBox(width: 8),
                  StatChip(
                    label: '${player.coins}',
                    icon: Icons.savings_rounded,
                    accent: v.accent2,
                  ),
                  const SizedBox(width: 8),
                  StatChip(
                    label: '${player.dailyStreak}-day',
                    icon: Icons.local_fire_department_rounded,
                    accent: const Color(0xFFFFB547),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'PLAY',
                height: 76,
                flexFill: true,
                leadingIcon: Icons.play_arrow_rounded,
                onPressed: () => _openModeSelect(context),
              ),
              const SizedBox(height: 16),
              _DailyTile(
                done: dailyDone,
                streak: player.dailyStreak,
                onPlay: dailyDone ? null : () => _startDaily(context),
              ),
              const SizedBox(height: 20),
              BlendedListContainer(
                rows: [
                  BlendedListRow(
                    icon: Icons.help_outline_rounded,
                    label: 'How to Play',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HowToPlayScreen()),
                    ),
                  ),
                  BlendedListRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Statistics',
                    trailing:
                        player.totalGames == 0 ? null : '$winPct% win',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const StatisticsScreen()),
                    ),
                  ),
                  BlendedListRow(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Rewards',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RewardsScreen()),
                    ),
                  ),
                  BlendedListRow(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    onTap: () => SettingsSheet.show(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openModeSelect(BuildContext context) {
    ModeSelectSheet.show(
      context,
      onPick: (mode, {seed}) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameBoardScreen(mode: mode, seed: seed),
          ),
        );
      },
    );
  }

  void _startDaily(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameBoardScreen(
        mode: GameModes.daily,
        seed: dailySeed(),
      ),
    ));
  }
}

class _DailyTile extends StatelessWidget {
  final bool done;
  final int streak;
  final VoidCallback? onPlay;
  const _DailyTile({
    required this.done,
    required this.streak,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onPlay,
        child: Opacity(
          opacity: done ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(v.accent, v.bg2, 0.78)!,
                  v.bg2,
                ],
              ),
              border: Border.all(color: v.accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY PUZZLE · #${dailySeed() + 1}',
                  style: AppText.tag(color: v.accent),
                ),
                const SizedBox(height: 10),
                Text("Today's dots await",
                    style: AppText.displayM(color: v.text1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: v.accent2, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      done
                          ? '✓ Done — come back tomorrow'
                          : streak > 0
                              ? 'Streak: $streak — keep it going!'
                              : 'Play today — start a streak',
                      style: AppText.caption(color: v.text2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

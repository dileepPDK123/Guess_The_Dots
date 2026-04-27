import 'package:flutter/material.dart';

import '../game/modes.dart';
import '../game/seeded_rng.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/blended_list.dart';
import '../widgets/buttons.dart';
import 'game_board.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: logo + settings
              Row(
                children: [
                  Text(
                    'GTD',
                    style: AppText.displayM(color: v.text1).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: v.bg2,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.settings_rounded, color: v.text2, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Stats chips
              Row(
                children: const [
                  StatChip(label: 'Lv 1', icon: Icons.flash_on_rounded),
                  SizedBox(width: 8),
                  StatChip(label: '0', icon: Icons.savings_rounded),
                  SizedBox(width: 8),
                  StatChip(label: '0-day', icon: Icons.local_fire_department_rounded),
                ],
              ),
              const SizedBox(height: 28),
              // Hero PLAY button
              PrimaryButton(
                label: 'PLAY',
                height: 76,
                flexFill: true,
                leadingIcon: Icons.play_arrow_rounded,
                onPressed: () => _startClassic(context),
              ),
              const SizedBox(height: 16),
              // Daily tile
              _DailyTile(
                onPlay: () => _startDaily(context),
              ),
              const SizedBox(height: 20),
              // Blended list — secondary actions
              BlendedListContainer(
                rows: [
                  BlendedListRow(
                    icon: Icons.help_outline_rounded,
                    label: 'How to Play',
                    onTap: () {},
                  ),
                  BlendedListRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Statistics',
                    trailing: '0% win',
                    onTap: () {},
                  ),
                  BlendedListRow(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Rewards',
                    onTap: () {},
                  ),
                  BlendedListRow(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startClassic(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const GameBoardScreen(mode: GameModes.classic),
    ));
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
  final VoidCallback onPlay;
  const _DailyTile({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onPlay,
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
                    'Play today — start a streak',
                    style: AppText.caption(color: v.text2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

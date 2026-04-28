import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/modes.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import 'game_board.dart';

/// Campaign — 100 deterministic levels, 5 columns, star ratings.
class CampaignScreen extends ConsumerWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = context.velvet;
    final p = ref.watch(playerProvider);
    final stars = p.campaignStars;
    final totalStars = stars.values.fold<int>(0, (a, b) => a + b);
    // Highest level the player has any score on; next one is unlocked too.
    var highest = 0;
    for (final lvl in stars.keys) {
      if (lvl > highest) highest = lvl;
    }
    final unlockedThrough = (highest + 1).clamp(1, 100);

    return Scaffold(
      backgroundColor: v.bg1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: v.text1),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text('CAMPAIGN', style: AppText.tag(color: v.text3)),
            Text('World 1 · Velvet Cove',
                style: AppText.title(color: v.text1).copyWith(fontSize: 16)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(v.accent2, v.bg2, 0.6)!,
                  v.bg2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: v.accent2.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: v.accent2, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$totalStars / 300 stars',
                        style: AppText.title(color: v.text1)),
                    const SizedBox(height: 2),
                    Text('Earn 3 stars per level',
                        style: AppText.caption(color: v.text2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 1; i <= 100; i++)
                _LevelTile(
                  level: i,
                  state: i == unlockedThrough && (stars[i] ?? 0) == 0
                      ? _LevelState.current
                      : i <= unlockedThrough
                          ? _LevelState.done
                          : _LevelState.locked,
                  stars: stars[i] ?? 0,
                  onTap: i <= unlockedThrough
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GameBoardScreen(
                                mode: GameModes.campaign,
                                seed: i * 1000003,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _LevelState { done, current, locked }

class _LevelTile extends StatelessWidget {
  final int level;
  final _LevelState state;
  final int stars;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.state,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final isCurrent = state == _LevelState.current;
    final isLocked = state == _LevelState.locked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrent ? null : (isLocked ? v.bg2 : v.bg3),
              gradient: isCurrent
                  ? LinearGradient(
                      colors: [v.accent, Color.lerp(v.accent, v.accent2, 0.4)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: isCurrent ? v.glowAccent : null,
            ),
            child: Opacity(
              opacity: isLocked ? 0.55 : 1,
              child: Center(
                child: isLocked
                    ? Icon(Icons.lock_rounded, size: 18, color: v.text3)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$level',
                              style: AppText.title(color: v.text1)
                                  .copyWith(fontSize: 16)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                              return Icon(
                                Icons.star_rounded,
                                size: 9,
                                color: i < stars
                                    ? v.accent2
                                    : Colors.white.withValues(alpha: 0.18),
                              );
                            }),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

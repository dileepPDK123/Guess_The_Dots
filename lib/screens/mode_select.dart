import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/modes.dart';
import '../game/seeded_rng.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';

/// Bottom sheet — "Pick Your Puzzle".
class ModeSelectSheet extends ConsumerWidget {
  final void Function(GameMode mode, {int? seed}) onPick;

  const ModeSelectSheet({super.key, required this.onPick});

  static Future<void> show(BuildContext context,
      {required void Function(GameMode mode, {int? seed}) onPick}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (_) => ModeSelectSheet(onPick: onPick),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = context.velvet;
    final player = ref.watch(playerProvider);
    final dailyDone = ref.read(playerProvider.notifier).isDailyDoneToday();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: v.bg2,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xxl),
            ),
            boxShadow: v.el3,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: v.lineStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text("Pick Your Puzzle",
                        style: AppText.displayM(color: v.text1)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: v.text2),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.zero,
                  children: [
                    // Daily hero
                    _HeroModeCard(
                      mode: GameModes.daily,
                      done: dailyDone,
                      streak: player.dailyStreak,
                      onTap: dailyDone
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onPick(GameModes.daily, seed: dailySeed());
                            },
                    ),
                    const SizedBox(height: 12),
                    // Weekly hero
                    _HeroModeCard(
                      mode: GameModes.weekly,
                      done: false,
                      streak: 0,
                      onTap: () {
                        Navigator.of(context).pop();
                        onPick(GameModes.weekly, seed: weeklySeed());
                      },
                    ),
                    const SizedBox(height: 22),
                    Text("More Ways to Play",
                        style: AppText.tag(color: v.text3)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.45,
                      children: [
                        for (final m in GameModes.grid)
                          _ModeCard(
                            mode: m,
                            unlocked:
                                !m.locked || player.level >= 10,
                            onTap: () {
                              Navigator.of(context).pop();
                              onPick(m);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.link_rounded, color: v.text2, size: 16),
                        label: Text("Enter a friend's puzzle code",
                            style: AppText.caption(color: v.text2)),
                        onPressed: () {
                          // future: friend code sheet
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroModeCard extends StatelessWidget {
  final GameMode mode;
  final bool done;
  final int streak;
  final VoidCallback? onTap;

  const _HeroModeCard({
    required this.mode,
    required this.done,
    required this.streak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final accent = mode.id == 'daily' ? v.accent : v.accent2;
    final accent2 = mode.id == 'daily' ? v.accent2 : v.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, v.bg2, 0.62)!,
                Color.lerp(accent2, v.bg3, 0.78)!,
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: done ? 0.55 : 1,
            child: Row(
              children: [
                Text(mode.emoji, style: const TextStyle(fontSize: 38)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.id == 'daily'
                            ? 'Daily Puzzle #${dailySeed() + 1}'
                            : 'Weekly Challenge #${weeklySeed() + 1}',
                        style: AppText.title(color: v.text1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done
                            ? "✓ Done — come back tomorrow"
                            : streak > 0
                                ? "🔥 Streak: $streak — keep it going!"
                                : mode.id == 'daily'
                                    ? "Same puzzle worldwide. Play once a day."
                                    : "5 dots · 8 guesses · +200 XP bonus",
                        style: AppText.caption(color: v.text2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        done
                            ? '—'
                            : mode.id == 'daily'
                                ? 'Play Today  →'
                                : 'Take On Weekly  →',
                        style: AppText.caption(color: accent.withValues(alpha: 0.9))
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final GameMode mode;
  final bool unlocked;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: unlocked ? onTap : null,
        child: Opacity(
          opacity: unlocked ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: v.bg3,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border(
                left: BorderSide(color: mode.stripe, width: 4),
                right: BorderSide(color: v.line, width: 1),
                top: BorderSide(color: v.line, width: 1),
                bottom: BorderSide(color: v.line, width: 1),
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(mode.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            mode.name,
                            style: AppText.title(color: v.text1)
                                .copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.hook,
                      style: AppText.caption(color: v.text2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (!unlocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: v.bg2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 10, color: v.text3),
                          const SizedBox(width: 3),
                          Text(mode.unlockLabel ?? 'Locked',
                              style: AppText.tag(color: v.text3)
                                  .copyWith(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

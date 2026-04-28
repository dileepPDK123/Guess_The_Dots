import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../game/game_state.dart';
import '../game/modes.dart';
import '../game/share_grid.dart';
import '../game/seeded_rng.dart';
import '../services/cloud_save.dart';
import '../services/leaderboard.dart';
import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/buttons.dart';
import '../widgets/dot_slot.dart';

/// Result sheet — shown after a game ends. Awards XP/coins, shows the secret,
/// share-grid, level progress, and Play Again / Menu actions.
class ResultSheet extends ConsumerStatefulWidget {
  final GameMode mode;
  final GameState gameState;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const ResultSheet({
    super.key,
    required this.mode,
    required this.gameState,
    required this.onPlayAgain,
    required this.onMenu,
  });

  static Future<void> show(
    BuildContext context, {
    required GameMode mode,
    required GameState gameState,
    required VoidCallback onPlayAgain,
    required VoidCallback onMenu,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ResultSheet(
        mode: mode,
        gameState: gameState,
        onPlayAgain: onPlayAgain,
        onMenu: onMenu,
      ),
    );
  }

  @override
  ConsumerState<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends ConsumerState<ResultSheet> {
  int _xpAwarded = 0;
  int _coinsAwarded = 0;
  int _newLevel = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _award());
  }

  void _award() {
    final p = ref.read(playerProvider.notifier);
    final won = widget.gameState.result == GameResult.win;
    final xp = won ? widget.mode.xp : widget.mode.xp ~/ 4;
    final coins = won ? 10 : 0;
    final lvl = p.addXp(xp);
    p.addCoins(coins);
    p.recordGame(
      mode: widget.mode,
      didWin: won,
      guesses: widget.gameState.activeRow + (won ? 1 : 0),
      timeMs: widget.gameState.startedAt != null
          ? DateTime.now().difference(widget.gameState.startedAt!).inMilliseconds
          : 0,
    );
    if (widget.mode.id == 'daily') {
      p.recordDaily(didWin: won);
      // Submit to leaderboard + push cloud save (silent).
      final today = _utcToday();
      final lb = ref.read(leaderboardProvider);
      lb.submitDaily(
        date: today,
        guessesUsed: widget.gameState.activeRow + (won ? 1 : 0),
        timeMs: widget.gameState.startedAt != null
            ? DateTime.now()
                .difference(widget.gameState.startedAt!)
                .inMilliseconds
            : 0,
        solved: won,
      );
    }
    ref.read(cloudSaveProvider).push();
    if (mounted) {
      setState(() {
        _xpAwarded = xp;
        _coinsAwarded = coins;
        _newLevel = lvl;
      });
    }
  }

  static String _utcToday() {
    final t = DateTime.now().toUtc();
    return '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final won = widget.gameState.result == GameResult.win;

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          if (won) const _Confetti(),
          DraggableScrollableSheet(
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: v.lineStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Secret reveal
                    _SecretReveal(code: widget.gameState.code),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        won ? 'Cracked it!' : 'So close!',
                        style: AppText.displayL(color: v.text1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        won
                            ? '${widget.gameState.activeRow + 1} guess${widget.gameState.activeRow == 0 ? "" : "es"} · ${widget.mode.name}'
                            : 'The secret was revealed above.',
                        style: AppText.caption(color: v.text2),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _XpCard(xp: _xpAwarded, level: _newLevel, ref: ref),
                    const SizedBox(height: 12),
                    _CoinsCard(coins: _coinsAwarded, ref: ref),
                    const SizedBox(height: 18),
                    if (widget.mode.id == 'daily')
                      _StreakCard(ref: ref)
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 18),
                    _ShareCard(
                      mode: widget.mode,
                      gameState: widget.gameState,
                      won: won,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Play Again',
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onPlayAgain();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlineButton(
                          label: 'Menu',
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onMenu();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SecretReveal extends StatelessWidget {
  final List<int> code;
  const _SecretReveal({required this.code});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Column(
      children: [
        Text('THE SECRET WAS', style: AppText.tag(color: v.text3)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(code.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DotSlot(color: code[i], size: 44)
                  .animate(delay: Duration(milliseconds: 60 * i))
                  .scale(
                    duration: const Duration(milliseconds: 320),
                    curve: const Cubic(0.2, 0.9, 0.3, 1.4),
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1, 1),
                  ),
            );
          }),
        ),
      ],
    );
  }
}

class _XpCard extends StatelessWidget {
  final int xp;
  final int level;
  final WidgetRef ref;
  const _XpCard({required this.xp, required this.level, required this.ref});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final p = ref.watch(playerProvider);
    final progress = p.levelProgress();
    final pct = progress.needed > 0 ? progress.into / progress.needed : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: v.bg3,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: v.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: v.accent, size: 20),
              const SizedBox(width: 6),
              Text('+$xp XP', style: AppText.title(color: v.text1)),
              const Spacer(),
              Text('Lv ${p.level} · ${progress.into}/${progress.needed}',
                  style: AppText.caption(color: v.text2)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: v.bg4,
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [v.accent, v.accent2],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinsCard extends StatelessWidget {
  final int coins;
  final WidgetRef ref;
  const _CoinsCard({required this.coins, required this.ref});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final p = ref.watch(playerProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: v.bg3,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: v.line),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [v.accent2, Color.lerp(v.accent2, v.accent, 0.4)!],
              ),
            ),
            child: Icon(Icons.savings_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('+$coins coins', style: AppText.title(color: v.text1)),
          const Spacer(),
          Text('Balance: ${p.coins}', style: AppText.caption(color: v.text2)),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final WidgetRef ref;
  const _StreakCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final p = ref.watch(playerProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: v.bg3,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: v.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: v.accent2, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.dailyStreak}-day streak',
                    style: AppText.title(color: v.text1)),
                const SizedBox(height: 2),
                Text(
                  p.dailyStreak > 0
                      ? 'Best: ${p.dailyMaxStreak} · Come back tomorrow!'
                      : 'Win tomorrow to start a streak.',
                  style: AppText.caption(color: v.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final GameMode mode;
  final GameState gameState;
  final bool won;
  const _ShareCard({
    required this.mode,
    required this.gameState,
    required this.won,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final grid = shareGrid(
      guesses: gameState.submittedGuesses,
      feedbacks: gameState.feedback,
      slotCount: gameState.slots,
    );
    final headline = mode.id == 'daily'
        ? shareDailyText(
            dailyNumber: dailySeed() + 1,
            guessCount: won ? gameState.activeRow + 1 : null,
            maxGuesses: gameState.guesses,
            streak: 0,
            body: grid,
          )
        : 'Guess the Dots · ${mode.name} · ${won ? "${gameState.activeRow + 1}/${gameState.guesses}" : "X/${gameState.guesses}"}\n\n$grid\n#GuessTheDots';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: v.bg3,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: v.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPOILER-FREE GRID', style: AppText.tag(color: v.text3)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: v.bg2,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              grid,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: v.text1,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Copy',
                  icon: Icons.content_copy_rounded,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: headline));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: GhostButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  onPressed: () async {
                    await SharePlus.instance.share(ShareParams(text: headline));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Confetti — light-weight, no extra package ────────────────────────────────
class _Confetti extends StatefulWidget {
  const _Confetti();
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _particles = List.generate(28, (i) => _Particle.random(r));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _ctrl.value, context.velvet),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double targetY;
  final double rot;
  final Color color;
  _Particle(
      {required this.startX,
      required this.targetY,
      required this.rot,
      required this.color});
  factory _Particle.random(Random r) {
    final palette = [
      const Color(0xFFFF4D6D),
      const Color(0xFFFFB547),
      const Color(0xFF3DDC97),
      const Color(0xFF4FC3FF),
      const Color(0xFFB285FF),
      const Color(0xFFFF7AC6),
    ];
    return _Particle(
      startX: r.nextDouble(),
      targetY: 0.6 + r.nextDouble() * 0.4,
      rot: r.nextDouble() * 6.28,
      color: palette[r.nextInt(palette.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final RoyalVelvet v;
  _ConfettiPainter(this.particles, this.t, this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final x = p.startX * size.width;
      final y = -10 + p.targetY * size.height * t;
      paint.color = p.color.withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 14),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

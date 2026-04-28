import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/buttons.dart';
import '../widgets/dot_slot.dart';

/// Resume prompt — shown on launch if there is a saved game in progress.
Future<bool?> showResumePrompt(
  BuildContext context, {
  required String modeName,
  required int guessesIn,
  required List<int> partialGuess,
}) {
  final v = context.velvet;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      backgroundColor: v.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GAME IN PROGRESS', style: AppText.tag(color: v.accent)),
            const SizedBox(height: 8),
            Text('Resume your $modeName game?',
                style: AppText.displayM(color: v.text1).copyWith(fontSize: 22),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('$guessesIn guess${guessesIn == 1 ? "" : "es"} in',
                style: AppText.caption(color: v.text2)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in partialGuess)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DotSlot(color: c, size: 28),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'New Game',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Resume',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Streak popup — shown once per day on launch when login streak ticks up.
Future<void> showStreakPopup(
  BuildContext context, {
  required int streak,
  required int coinsAwarded,
}) {
  final v = context.velvet;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _ConfettiPing(),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: v.bg2,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: v.glowAccent,
              border: Border.all(color: v.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text('Day $streak streak!',
                    style: AppText.displayM(color: v.text1).copyWith(fontSize: 26)),
                const SizedBox(height: 6),
                Text('+$coinsAwarded coins',
                    style: AppText.body(color: v.accent2)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (i) {
                    final filled = i < streak.clamp(0, 7);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? v.accent2 : v.bg4,
                          boxShadow: i == streak.clamp(0, 7) - 1 && filled
                              ? [
                                  BoxShadow(
                                      color: v.accent2.withValues(alpha: 0.65),
                                      blurRadius: 10),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Claim & play',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Account link sheet — invites the user to back up their progress.
Future<void> showAccountLinkSheet(
  BuildContext context, {
  required Future<void> Function() onGoogle,
  required Future<void> Function() onApple,
}) {
  final v = context.velvet;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: v.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: v.lineStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: v.bg3,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(Icons.lock_outline_rounded, size: 28, color: v.accent2),
          ),
          const SizedBox(height: 14),
          Text('Save your progress',
              style: AppText.displayM(color: v.text1).copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text('Sign in to back up your streak, level, and rewards across devices.',
              style: AppText.caption(color: v.text2),
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          _AuthButton(
            label: 'Continue with Google',
            background: Colors.white,
            foreground: const Color(0xFF333333),
            icon: Icons.account_circle,
            onTap: () async {
              Navigator.of(context).pop();
              await onGoogle();
            },
          ),
          const SizedBox(height: 10),
          _AuthButton(
            label: 'Continue with Apple',
            background: Colors.black,
            foreground: Colors.white,
            icon: Icons.apple,
            onTap: () async {
              Navigator.of(context).pop();
              await onApple();
            },
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: 'Not now',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

class _AuthButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

/// Top-of-screen offline toast.
class OfflineToast extends StatelessWidget {
  final VoidCallback? onDismiss;
  const OfflineToast({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: v.lineStrong),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: v.text2, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("You're offline",
                        style: AppText.body(color: v.text1).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Leaderboards & cloud save paused',
                        style: AppText.caption(color: v.text3)
                            .copyWith(fontSize: 11)),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close_rounded, color: v.text2),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPing extends StatefulWidget {
  const _ConfettiPing();
  @override
  State<_ConfettiPing> createState() => _ConfettiPingState();
}

class _ConfettiPingState extends State<_ConfettiPing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      child: SizedBox(
        width: 320,
        height: 320,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            return CustomPaint(
              painter: _Painter(_ctrl.value),
            );
          },
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final double t;
  _Painter(this.t);

  static final _palette = [
    const Color(0xFFFF4D6D),
    const Color(0xFFFFB547),
    const Color(0xFF3DDC97),
    const Color(0xFF4FC3FF),
    const Color(0xFFB285FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(7);
    final paint = Paint();
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (var i = 0; i < 24; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = 40 + r.nextDouble() * 100 * t;
      paint.color = _palette[i % _palette.length].withValues(alpha: 1 - t);
      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
        4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.t != t;
}

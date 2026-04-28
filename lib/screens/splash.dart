import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/cloud_save.dart';
import '../services/player_state.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/logo.dart';
import 'home.dart';
import 'tutorial.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Best-effort cloud bootstrap — never blocks navigation.
    final auth = ref.read(authServiceProvider);
    final cloud = ref.read(cloudSaveProvider);
    try {
      await auth.ensureAnonymous();
      await cloud.pull();
    } catch (_) {}

    // Always wait at least 1.6s so the splash actually splashes.
    final elapsed = _ctrl.duration!;
    await Future.delayed(elapsed);
    if (!mounted) return;
    final seen = ref.read(playerProvider).tutorialSeen;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => seen ? const HomeScreen() : const TutorialScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Scaffold(
      backgroundColor: v.bg0,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.5, -0.7),
            radius: 1.4,
            colors: [
              v.accent.withValues(alpha: 0.20),
              v.bg0,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const LogoB(size: 76),
              const SizedBox(height: 38),
              SizedBox(
                width: 140,
                height: 3,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: v.bg3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _ctrl.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                                colors: [v.accent, v.accent2]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'A PUZZLE A DAY',
                  style: AppText.tag(color: v.text3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/splash.dart';
import 'services/ads_service.dart';
import 'services/firebase_options.dart';
import 'services/iap_service.dart';
import 'services/player_state.dart';
import 'theme/build_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase init — silent on failure so the game runs offline.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Create the provider container before the widget tree so IAP callbacks
  // can update player state even if they fire during the splash animation.
  final container = ProviderContainer();
  final ads = container.read(adsProvider);

  // Wire IAP — fire-and-forget; the callbacks mutate player state when a
  // purchase (or restore) completes at any point during the session.
  unawaited(
    container.read(iapProvider).ensureInitialized(
      onRemoveAds: () {
        container.read(playerProvider.notifier).setRemoveAdsEntitled(true);
        ads.removeAdsEntitled = true;
      },
      onHintBundle: () {
        container.read(playerProvider.notifier).grantHints(10);
      },
    ),
  );

  runApp(UncontrolledProviderScope(
    container: container,
    child: const GuessTheDotsApp(),
  ));
}

class GuessTheDotsApp extends StatelessWidget {
  const GuessTheDotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guess the Dots',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

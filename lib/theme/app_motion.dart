import 'package:flutter/animation.dart';

/// Motion tokens from the design handoff.
abstract class AppMotion {
  // Durations
  static const Duration pop = Duration(milliseconds: 260);       // dot place
  static const Duration reveal = Duration(milliseconds: 380);    // submit
  static const Duration sheetSlide = Duration(milliseconds: 320);
  static const Duration shake = Duration(milliseconds: 360);
  static const Duration pulseRing = Duration(milliseconds: 1400);
  static const Duration logoLetterBounce = Duration(milliseconds: 3600);
  static const Duration logoDotWave = Duration(milliseconds: 1600);

  // Curves (cubic-bezier values from the handoff)
  static const Curve popCurve = Cubic(0.2, 0.9, 0.3, 1.4);       // overshoot
  static const Curve revealCurve = Cubic(0.2, 0.8, 0.25, 1.3);
  static const Curve sheetCurve = Curves.easeOut;
  static const Curve shakeCurve = Curves.ease;
  static const Curve pulseCurve = Curves.easeOut;
  static const Curve dotWaveCurve = Cubic(0.4, 0.0, 0.4, 1.0);
}

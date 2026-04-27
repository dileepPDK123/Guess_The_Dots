import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens from the design handoff.
///
/// - Display: Fraunces (serif, 600/700/800, opsz 144, SOFT 100, ls -0.03em)
/// - UI: Plus Jakarta Sans (400/500/600/700/800, ls -0.01em)
/// - Mono: JetBrains Mono (timers, codes, version strings)
abstract class AppText {
  static const double _lsTight = -0.01;
  static const double _lsDisplay = -0.03;

  static TextStyle displayXL({Color? color}) => GoogleFonts.fraunces(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: 44 * _lsDisplay,
        color: color,
        height: 1.05,
      );

  static TextStyle displayL({Color? color}) => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 32 * _lsDisplay,
        color: color,
        height: 1.1,
      );

  static TextStyle displayM({Color? color}) => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 24 * _lsDisplay,
        color: color,
        height: 1.2,
      );

  static TextStyle title({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 18 * _lsTight,
        color: color,
        height: 1.25,
      );

  static TextStyle body({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 15 * _lsTight,
        color: color,
        height: 1.4,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 13 * _lsTight,
        color: color,
        height: 1.35,
      );

  /// Section-tag style: tiny, uppercase, wide letter-spacing.
  static TextStyle tag({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.08 * 10,
        color: color,
        height: 1.2,
      );

  static TextStyle mono({Color? color, double size = 12}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  /// Big numeric/CTA on the primary PLAY button.
  static TextStyle ctaPrimary({Color? color}) => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 22 * _lsDisplay,
        color: color,
      );
}

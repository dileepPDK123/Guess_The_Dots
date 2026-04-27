import 'package:flutter/material.dart';

import 'royal_velvet.dart';

/// Builds the [ThemeData] used by `MaterialApp.theme`. Wires Royal Velvet
/// tokens into Material 3's `ColorScheme` and registers the [RoyalVelvet]
/// extension so any widget can read tokens via `context.velvet`.
ThemeData buildAppTheme() {
  const v = RoyalVelvet.royalVelvet;

  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: v.accent,
    onPrimary: Colors.white,
    secondary: v.accent2,
    onSecondary: v.bg0,
    surface: v.bg2,
    onSurface: v.text1,
    surfaceContainerHighest: v.bg3,
    error: const Color(0xFFFF4D6D),
    onError: Colors.white,
    outline: v.lineStrong,
    outlineVariant: v.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: v.bg1,
    splashFactory: NoSplash.splashFactory,
    extensions: const <ThemeExtension<dynamic>>[v],
  );
}

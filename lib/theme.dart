import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme derived from DESIGN.md
  
  static const Color primary = Color(0xffffb5a0);
  static const Color onPrimary = Color(0xff601400);
  static const Color primaryContainer = Color(0xffff5625);
  static const Color onPrimaryContainer = Color(0xff541100);
  
  static const Color secondary = Color(0xfffff9ef);
  static const Color secondaryContainer = Color(0xffffdb3c);
  
  static const Color background = Color(0xff131313);
  static const Color surface = Color(0xff131313);
  static const Color onSurface = Color(0xffe4e2e1);
  static const Color onSurfaceVariant = Color(0xffe7bdb2);
  
  static const Color surfaceContainerLowest = Color(0xff0e0e0e);
  static const Color surfaceContainerLow = Color(0xff1b1c1c);
  static const Color surfaceContainer = Color(0xff1f2020);
  static const Color surfaceContainerHigh = Color(0xff2a2a2a);
  static const Color surfaceContainerHighest = Color(0xff353535);
  
  static const Color outline = Color(0xffad887e);
  static const Color error = Color(0xffffb4ab);
  
  static ThemeData get tacticalTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        // ignore: deprecated_member_use
        background: background,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.02),
          displayMedium: const TextStyle(fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.02),
          headlineLarge: const TextStyle(fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.02),
          headlineMedium: const TextStyle(fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.02),
          titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: onSurface),
          titleMedium: const TextStyle(fontWeight: FontWeight.w700, color: onSurface),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w400, color: onSurface),
          bodyMedium: const TextStyle(fontWeight: FontWeight.w400, color: onSurfaceVariant),
          labelLarge: const TextStyle(fontWeight: FontWeight.w700, color: outline, letterSpacing: 1.5),
          labelMedium: const TextStyle(fontWeight: FontWeight.w700, color: outline, letterSpacing: 1.5),
          labelSmall: const TextStyle(fontWeight: FontWeight.w700, color: outline, letterSpacing: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(color: primary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: background, letterSpacing: 1.2);
          }
          return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: surfaceContainerHighest, letterSpacing: 1.2);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: background, size: 24);
          }
          return const IconThemeData(color: surfaceContainerHighest, size: 24);
        }),
      ),
    );
  }
}

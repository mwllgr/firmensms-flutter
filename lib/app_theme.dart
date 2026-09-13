import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const Color accent = Colors.orangeAccent;

  static final ThemeData light = _build(
    brightness: Brightness.light,
    scaffoldBackground: Colors.white,
    appBarBackground: Colors.blue,
    navigationBarIconBrightness: Brightness.dark,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    scaffoldBackground: Colors.black,
    appBarBackground: Colors.black,
    navigationBarIconBrightness: Brightness.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Brightness navigationBarIconBrightness,
  }) {
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
        secondary: accent,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarIconBrightness: navigationBarIconBrightness,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accent,
        selectionHandleColor: Colors.blue,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        floatingLabelStyle: TextStyle(color: Colors.grey),
        suffixIconColor: Colors.grey,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 1, color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 2, color: accent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
    );
  }
}

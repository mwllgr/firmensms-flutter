import 'package:flutter/material.dart';

class ThemeClass {
  static ThemeData lightTheme = ThemeData(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
      ),
      primaryTextTheme:
          const TextTheme(titleLarge: TextStyle(color: Colors.white)),
      textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.orangeAccent, selectionHandleColor: Colors.blue),
      inputDecorationTheme: const InputDecorationTheme(
          floatingLabelStyle: TextStyle(color: Colors.grey),
          suffixIconColor: Colors.grey,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 1, color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Colors.orangeAccent),
          )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent))
  );

  static ThemeData darkTheme = ThemeData(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
      ),
      textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.orangeAccent, selectionHandleColor: Colors.blue),
      inputDecorationTheme: const InputDecorationTheme(
          floatingLabelStyle: TextStyle(color: Colors.grey),
          suffixIconColor: Colors.grey,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 1, color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Colors.orangeAccent),
          )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent))
  );
}

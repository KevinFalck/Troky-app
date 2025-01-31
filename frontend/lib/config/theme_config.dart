import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: Color.fromARGB(255, 42, 149, 156),
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Color.fromARGB(255, 42, 149, 156),
      secondary: Colors.blue,
    ),
  );

  static final darkTheme = ThemeData(
    primaryColor: Color.fromARGB(255, 42, 149, 156),
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: Color.fromARGB(255, 42, 149, 156),
      secondary: Colors.blue,
      surface: Color(0xFF1E1E1E),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Color(0xFF2A2A2A),
      filled: true,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  // Récupère la préférence stockée pour le thème ou utilise le mode clair par défaut
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString('themeMode');
    if (storedTheme != null) {
      _themeMode = storedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // Passe en mode clair ou sombre selon l'argument
  void toggleTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark for District feel

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}

class FinMateTheme {
  static const Color zomatoRed = Color(0xFFCB202D);
  static const Color zomatoRedLight = Color(0xFFFDE8E9);
  
  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0A0A0A); // Very dark, deep black
  static const Color cardDark = Color(0xFF141414);
  static const Color textDark = Colors.white;
  static const Color textMutedDark = Color(0xFFAAAAAA);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardLight = Colors.white;
  static const Color textLight = Color(0xFF1A1A1A);
  static const Color textMutedLight = Color(0xFF666666);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: zomatoRed,
      primary: zomatoRed,
      brightness: Brightness.light,
      surface: backgroundLight,
      onSurface: textLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide.none,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: zomatoRed,
      primary: zomatoRed,
      brightness: Brightness.dark,
      surface: backgroundDark,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textDark),
      titleTextStyle: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}

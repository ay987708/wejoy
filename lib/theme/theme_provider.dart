import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Thèmes disponibles ─────────────────────────────────────────────────────
const List<Map<String, dynamic>> kThemes = [
  {'name': 'Rose / Violet', 'c1': Color(0xFFD63FBF), 'c2': Color(0xFF7C3AED)},
  {'name': 'Bleu',          'c1': Color(0xFF2563EB), 'c2': Color(0xFF0EA5E9)},
  {'name': 'Vert',          'c1': Color(0xFF16A34A), 'c2': Color(0xFF059669)},
  {'name': 'Orange',        'c1': Color(0xFFEA580C), 'c2': Color(0xFFF59E0B)},
  {'name': 'Rouge / Rose',  'c1': Color(0xFFDC2626), 'c2': Color(0xFFDB2777)},
  {'name': 'Cyan',          'c1': Color(0xFF0891B2), 'c2': Color(0xFF06B6D4)},
  {'name': 'Indigo',        'c1': Color(0xFF4338CA), 'c2': Color(0xFF6366F1)},
  {'name': 'Lime',          'c1': Color(0xFF65A30D), 'c2': Color(0xFF16A34A)},
  {'name': 'Ardoise',       'c1': Color(0xFF475569), 'c2': Color(0xFF334155)},
  {'name': 'Corail',        'c1': Color(0xFFF43F5E), 'c2': Color(0xFFEC4899)},
];

class ThemeProvider extends ChangeNotifier {
  static const _keyIndex   = 'theme_index';
  static const _keyDark    = 'theme_dark';

  Color _color1    = const Color(0xFFD63FBF);
  Color _color2    = const Color(0xFF7C3AED);
  bool  _isDark    = false;
  int   _themeIdx  = 0;

  Color get color1   => _color1;
  Color get color2   => _color2;
  bool  get isDark   => _isDark;
  int   get themeIdx => _themeIdx;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  // ── Charger depuis SharedPreferences ──────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx  = prefs.getInt(_keyIndex) ?? 0;
    final dark = prefs.getBool(_keyDark)  ?? false;
    _applyTheme(idx, dark, save: false);
  }

  // ── Appliquer un thème ─────────────────────────────────────────────────
  void applyTheme(int index, bool dark) {
    _applyTheme(index, dark, save: true);
  }

  void _applyTheme(int index, bool dark, {required bool save}) {
    _themeIdx = index.clamp(0, kThemes.length - 1);
    _color1   = kThemes[_themeIdx]['c1'] as Color;
    _color2   = kThemes[_themeIdx]['c2'] as Color;
    _isDark   = dark;
    notifyListeners();
    if (save) _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIndex, _themeIdx);
    await prefs.setBool(_keyDark,  _isDark);
  }

  // ── ThemeData clair ────────────────────────────────────────────────────
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _color1,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F0F1A),
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _color1,
      unselectedItemColor: const Color(0xFF64748B),
      backgroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _color1.withOpacity(0.15),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? _color1
              : const Color(0xFF64748B),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _color1,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _color1,
      foregroundColor: Colors.white,
    ),
  );

  // ── ThemeData sombre ───────────────────────────────────────────────────
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _color1,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _color1,
      unselectedItemColor: const Color(0xFF94A3B8),
      backgroundColor: const Color(0xFF1A1A2E),
    ),
    cardColor: const Color(0xFF1A1A2E),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _color1,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _color1,
      foregroundColor: Colors.white,
    ),
  );
}
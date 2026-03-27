import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isLoaded = false;

  // ─── Getters ──────────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isLoaded => _isLoaded;

  ThemeData get currentTheme =>
      isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

  IconData get themeIcon =>
      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;

  String getThemeName(bool isArabic) => isDark
      ? (isArabic ? 'الوضع الليلي' : 'Dark Mode')
      : (isArabic ? 'الوضع النهاري' : 'Light Mode');

  String getThemeIconEmoji() => isDark ? '🌙' : '☀️';

  ThemeProvider() {
    _loadTheme();
  }

  // ─── Load ─────────────────────────────────────────────────────
  Future<void> _loadTheme() async {
    try {
      // ✅ إصلاح: استخدام box مفتوحة إن وُجدت
      final box = Hive.isBoxOpen(AppConstants.settingsBoxName)
          ? Hive.box(AppConstants.settingsBoxName)
          : await Hive.openBox(AppConstants.settingsBoxName);

      final saved =
          box.get(AppConstants.themeKey, defaultValue: 'dark') as String;
      _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {
      _themeMode = ThemeMode.dark;
    } finally {
      _isLoaded = true;
      _updateSystemUI();
      notifyListeners();
    }
  }

  // ─── Toggle ───────────────────────────────────────────────────
  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _updateSystemUI();
    notifyListeners();
    await _saveTheme();
  }

  Future<void> setDark() async {
    if (isDark) return;
    _themeMode = ThemeMode.dark;
    _updateSystemUI();
    notifyListeners();
    await _saveTheme();
  }

  Future<void> setLight() async {
    if (isLight) return;
    _themeMode = ThemeMode.light;
    _updateSystemUI();
    notifyListeners();
    await _saveTheme();
  }

  // ─── Save ─────────────────────────────────────────────────────
  Future<void> _saveTheme() async {
    try {
      // ✅ إصلاح: استخدام box مفتوحة بدلاً من فتحها في كل استدعاء
      final box = Hive.isBoxOpen(AppConstants.settingsBoxName)
          ? Hive.box(AppConstants.settingsBoxName)
          : await Hive.openBox(AppConstants.settingsBoxName);
      await box.put(AppConstants.themeKey, isDark ? 'dark' : 'light');
    } catch (_) {}
  }

  // ─── System UI ────────────────────────────────────────────────
  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }
}

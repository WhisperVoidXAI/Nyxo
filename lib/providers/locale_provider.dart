import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  bool _isLoaded = false;
  bool _isFirstRun = true;

  // ─── Getters ──────────────────────────────────────────────────
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isLoaded => _isLoaded;
  bool get isFirstRun => _isFirstRun;
  bool get isRTL => isArabic;

  String get languageName => isArabic ? 'العربية' : 'English';
  String get languageFlag => isArabic ? '🇸🇦' : '🇺🇸';
  String get languageCode => _locale.languageCode;

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  LocaleProvider() {
    _loadLocale();
  }

  // ─── Load ─────────────────────────────────────────────────────
  Future<void> _loadLocale() async {
    try {
      // ✅ إصلاح: استخدام box مفتوحة أو فتحها بأمان
      final box = Hive.isBoxOpen(AppConstants.settingsBoxName)
          ? Hive.box(AppConstants.settingsBoxName)
          : await Hive.openBox(AppConstants.settingsBoxName);

      final saved = box.get(AppConstants.localeKey) as String?;

      if (saved != null && _isSupportedLocale(saved)) {
        _locale = Locale(saved);
        _isFirstRun = false; // ✅ إصلاح: إذا وُجد حفظ سابق، ليس أول تشغيل
      } else {
        _locale = const Locale('ar');
        _isFirstRun = true; // أول تشغيل حقيقي
      }
    } catch (_) {
      _locale = const Locale('ar');
      _isFirstRun = true;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ─── Set Locale ───────────────────────────────────────────────
  Future<void> setLocale(Locale locale) async {
    if (!_isSupportedLocale(locale.languageCode)) return;

    // ✅ إصلاح: منطق مُبسَّط وصحيح
    final isAlreadySet = _locale == locale && !_isFirstRun;
    if (isAlreadySet) return; // لا داعي لأي تغيير

    _locale = locale;
    _isFirstRun = false;
    notifyListeners();

    // احفظ دائماً بغض النظر عن isFirstRun
    try {
      final box = Hive.isBoxOpen(AppConstants.settingsBoxName)
          ? Hive.box(AppConstants.settingsBoxName)
          : await Hive.openBox(AppConstants.settingsBoxName);
      await box.put(AppConstants.localeKey, locale.languageCode);
    } catch (_) {}
  }

  Future<void> setArabic() => setLocale(const Locale('ar'));
  Future<void> setEnglish() => setLocale(const Locale('en'));

  Future<void> toggleLocale() async {
    await setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }

  // ─── Mark First Run Done ─────────────────────────────────────
  // ✅ إضافة: يُستدعى بعد إتمام الـ Onboarding
  Future<void> completeFirstRun() async {
    if (!_isFirstRun) return;
    _isFirstRun = false;
    notifyListeners();
    try {
      final box = Hive.isBoxOpen(AppConstants.settingsBoxName)
          ? Hive.box(AppConstants.settingsBoxName)
          : await Hive.openBox(AppConstants.settingsBoxName);
      await box.put(AppConstants.isFirstLaunchKey, false);
    } catch (_) {}
  }

  // ─── Helpers ──────────────────────────────────────────────────
  bool _isSupportedLocale(String code) => ['ar', 'en'].contains(code);

  String greeting(String name) {
    final now = DateTime.now().hour;
    if (isArabic) {
      if (now < 12) return 'صباح الخير، $name';
      if (now < 17) return 'مساء الخير، $name';
      return 'مساء النور، $name';
    } else {
      if (now < 12) return 'Good morning, $name';
      if (now < 17) return 'Good afternoon, $name';
      return 'Good evening, $name';
    }
  }

  static const List<Map<String, String>> supportedLocales = [
    {'code': 'ar', 'name': 'العربية', 'flag': ''},
    {'code': 'en', 'name': 'English', 'flag': ''},
  ];
}

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // ✅ إضافة: static helper آمن لا يتسبب بـ null crash
  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  final Map<String, Map<String, String>> _localizedValues = {
    // ─── App Identity ────────────────────────────────────────────
    'appName': {'ar': 'Beyond Silence', 'en': 'Beyond Silence'},
    'appTagline': {'ar': 'فكّر. دوّن. تذكّر.', 'en': 'Think. Write. Remember.'},
    'appTaglineSub': {
      'ar': 'مساعدك الذكي الخاص — يعمل بلا إنترنت',
      'en': 'Your private AI companion — works offline',
    },

    // ─── Language Selection ──────────────────────────────────────
    'chooseLanguage': {'ar': 'اختر لغتك', 'en': 'Choose Your Language'},
    'chooseLanguageSub': {
      'ar': 'يمكنك تغييرها لاحقاً من الإعدادات',
      'en': 'You can change it later from settings',
    },
    'arabic': {'ar': 'العربية', 'en': 'Arabic'},
    'english': {'ar': 'الإنجليزية', 'en': 'English'},
    'continueBtn': {'ar': 'متابعة', 'en': 'Continue'},

    // ─── Navigation ──────────────────────────────────────────────
    'notes': {'ar': 'المذكرات', 'en': 'Notes'},
    'assistant': {'ar': 'المساعد', 'en': 'Assistant'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},

    // ─── Home Screen ─────────────────────────────────────────────
    'newNote': {'ar': 'مذكرة جديدة', 'en': 'New Note'},
    'searchHint': {'ar': 'ابحث في مذكراتك...', 'en': 'Search your notes...'},
    'noNotes': {'ar': 'لا توجد مذكرات بعد', 'en': 'No notes yet'},
    'noNotesSubtitle': {
      'ar': 'اضغط ＋ لإضافة أول مذكرة',
      'en': 'Tap ＋ to add your first note'
    },
    'noSearchResults': {'ar': 'لا نتائج بحث', 'en': 'No results found'},
    'noSearchResultsSubtitle': {
      'ar': 'جرّب كلمات بحث مختلفة',
      'en': 'Try different keywords',
    },
    'totalNotes': {'ar': 'مذكرة', 'en': 'notes'},
    'todayNotes': {'ar': 'اليوم', 'en': 'today'},
    'goodMorning': {'ar': 'صباح الخير', 'en': 'Good Morning'},
    'goodAfternoon': {'ar': 'مساء الخير', 'en': 'Good Afternoon'},
    'goodEvening': {'ar': 'مساء النور', 'en': 'Good Evening'},

    // ─── Categories ──────────────────────────────────────────────
    'all': {'ar': 'الكل', 'en': 'All'},
    'personal': {'ar': 'شخصي', 'en': 'Personal'},
    'work': {'ar': 'عمل', 'en': 'Work'},
    'ideas': {'ar': 'أفكار', 'en': 'Ideas'},
    'health': {'ar': 'صحة', 'en': 'Health'},
    'travel': {'ar': 'سفر', 'en': 'Travel'},
    'other': {'ar': 'أخرى', 'en': 'Other'},
    'favorites': {'ar': 'المفضلة', 'en': 'Favorites'},

    // ─── Note Editor ─────────────────────────────────────────────
    'newNoteTitle': {'ar': 'مذكرة جديدة', 'en': 'New Note'},
    'editNote': {'ar': 'تعديل المذكرة', 'en': 'Edit Note'},
    'titleHint': {'ar': 'عنوان المذكرة...', 'en': 'Note title...'},
    'contentHint': {
      'ar': 'اكتب مذكرتك هنا...',
      'en': 'Write your note here...'
    },
    'markdownLabel': {'ar': 'محرر النص', 'en': 'Markdown'},
    'save': {'ar': 'حفظ', 'en': 'Save'},
    'saving': {'ar': 'جاري الحفظ...', 'en': 'Saving...'},
    'saved': {'ar': 'تم الحفظ ✓', 'en': 'Saved ✓'},
    'category': {'ar': 'الفئة', 'en': 'Category'},
    'mood': {'ar': 'كيف حالك؟', 'en': 'How are you?'},
    'tags': {'ar': 'الوسوم', 'en': 'Tags'},
    'newTag': {'ar': '＋ وسم جديد', 'en': '＋ New tag'},
    'contentRequired': {
      'ar': 'الرجاء كتابة محتوى المذكرة',
      'en': 'Please write note content'
    },
    'encrypted': {'ar': 'مشفّر', 'en': 'Encrypted'},
    'wordsCount': {'ar': 'كلمة', 'en': 'words'},
    'charsCount': {'ar': 'حرف', 'en': 'chars'},

    // ─── AI Suggest ──────────────────────────────────────────────
    'suggestTitle': {
      'ar': 'اقتراح عنوان بالذكاء الاصطناعي',
      'en': 'Suggest title with AI',
    },
    'aiImprove': {
      'ar': 'تحسين النص بالذكاء الاصطناعي',
      'en': 'Improve with AI'
    },
    'aiSummarize': {'ar': 'تلخيص بالذكاء الاصطناعي', 'en': 'Summarize with AI'},

    // ─── Note Detail ─────────────────────────────────────────────
    'talkWithAI': {
      'ar': 'تحدث مع AI عن هذه المذكرة',
      'en': 'Talk with AI about this note'
    },
    'deleteNote': {'ar': 'حذف المذكرة؟', 'en': 'Delete note?'},
    'deleteConfirm': {
      'ar': 'لا يمكن التراجع عن هذا الإجراء',
      'en': 'This action cannot be undone'
    },
    'delete': {'ar': 'حذف', 'en': 'Delete'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'share': {'ar': 'مشاركة', 'en': 'Share'},
    'edit': {'ar': 'تعديل', 'en': 'Edit'},
    'copyText': {'ar': 'نسخ النص', 'en': 'Copy text'},
    'noteDeleted': {'ar': 'تم حذف المذكرة', 'en': 'Note deleted'},
    'pin': {'ar': 'تثبيت', 'en': 'Pin'},
    'unpin': {'ar': 'إلغاء التثبيت', 'en': 'Unpin'},
    'favorite': {'ar': 'إضافة للمفضلة', 'en': 'Add to favorites'},
    'unfavorite': {'ar': 'إزالة من المفضلة', 'en': 'Remove from favorites'},

    // ─── Chat / AI ───────────────────────────────────────────────
    'aiAssistant': {'ar': 'المساعد الذكي', 'en': 'AI Assistant'},
    'generalChat': {'ar': 'محادثة عامة', 'en': 'General chat'},
    'talkingAbout': {'ar': 'تحدث عن:', 'en': 'Talking about:'},
    'chatHint': {'ar': 'اكتب رسالتك...', 'en': 'Write your message...'},
    'typing': {'ar': 'جاري الكتابة...', 'en': 'Typing...'},
    'thinking': {'ar': 'يفكر...', 'en': 'Thinking...'},
    'clearChat': {'ar': 'مسح المحادثة؟', 'en': 'Clear chat?'},
    'clearChatConfirm': {
      'ar': 'سيتم حذف كل الرسائل',
      'en': 'All messages will be deleted'
    },
    'clear': {'ar': 'مسح', 'en': 'Clear'},
    'aiGreeting': {
      'ar': 'مرحباً! كيف يمكنني مساعدتك؟',
      'en': 'Hello! How can I help you?'
    },
    'aiGreetingNote': {
      'ar': 'اسألني أي شيء عن هذه المذكرة',
      'en': 'Ask me anything about this note'
    },
    'aiGreetingGeneral': {
      'ar': 'اسألني أي شيء، أنا مساعدك الخاص',
      'en': 'Ask me anything, I\'m your personal assistant'
    },
    'modelNotReady': {
      'ar': 'النموذج غير جاهز. يرجى إعادة تشغيل التطبيق.',
      'en': 'Model not ready. Please restart the app.',
    },
    'copied': {'ar': 'تم نسخ الرسالة', 'en': 'Message copied'},
    'regenerate': {'ar': 'إعادة توليد', 'en': 'Regenerate'},
    'copyMessage': {'ar': 'نسخ الرسالة', 'en': 'Copy message'},
    'aiPrivacyNote': {
      'ar': '🔒 محادثتك خاصة تماماً — لا ترسل لأي خادم',
      'en': '🔒 Your chat is 100% private — never sent to any server',
    },

    // ─── Settings ────────────────────────────────────────────────
    'settingsTitle': {'ar': 'الإعدادات', 'en': 'Settings'},
    'appearance': {'ar': 'المظهر', 'en': 'Appearance'},
    'darkMode': {'ar': 'الوضع الغامق', 'en': 'Dark Mode'},
    'lightMode': {'ar': 'الوضع الفاتح', 'en': 'Light Mode'},
    'language': {'ar': 'اللغة', 'en': 'Language'},
    'changeLanguage': {'ar': 'تغيير اللغة', 'en': 'Change Language'},
    'privacySecurity': {'ar': 'الخصوصية والأمان', 'en': 'Privacy & Security'},
    'encryptNotes': {'ar': 'تشفير المذكرات', 'en': 'Encrypt Notes'},
    'encryptNotesSub': {
      'ar': 'تشفير قوي AES-256 لحماية بياناتك',
      'en': 'AES-256 encryption to protect your data'
    },
    'about': {'ar': 'حول التطبيق', 'en': 'About'},
    'aboutApp': {'ar': 'حول Beyond Silence', 'en': 'About Beyond Silence'},
    'version': {'ar': 'الإصدار', 'en': 'Version'},
    'developer': {'ar': 'المطور', 'en': 'Developer'},
    'privacyPolicy': {'ar': 'سياسة الخصوصية', 'en': 'Privacy Policy'},
    'aiModel': {'ar': 'نموذج الذكاء الاصطناعي', 'en': 'AI Model'},
    'modelReady': {'ar': 'النموذج جاهز ✓', 'en': 'Model ready ✓'},
    'modelNotDownloaded': {
      'ar': 'النموذج غير محمّل',
      'en': 'Model not downloaded'
    },
    'downloadModel': {'ar': 'تحميل النموذج', 'en': 'Download Model'},
    'deleteModel': {'ar': 'حذف النموذج', 'en': 'Delete Model'},

    // ─── Download Screen ─────────────────────────────────────────
    'downloadTitle': {
      'ar': 'تحميل الذكاء الاصطناعي',
      'en': 'Download AI Model'
    },
    'downloadSubtitle': {
      'ar': 'مرة واحدة فقط، ثم يعمل بلا إنترنت للأبد',
      'en': 'Only once, then works offline forever',
    },
    'downloadStart': {'ar': 'بدء التحميل', 'en': 'Start Download'},
    'downloading': {'ar': 'جاري التحميل...', 'en': 'Downloading...'},
    'downloadComplete': {
      'ar': 'اكتمل التحميل! 🎉',
      'en': 'Download complete! 🎉'
    },
    'downloadFailed': {'ar': 'فشل التحميل', 'en': 'Download failed'},
    'downloadRetry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'downloadPause': {'ar': 'إيقاف مؤقت', 'en': 'Pause'},
    'downloadResume': {'ar': 'استئناف', 'en': 'Resume'},
    'downloadCancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'downloadSize': {'ar': 'حجم النموذج', 'en': 'Model size'},
    'downloadSpeed': {'ar': 'سرعة التحميل', 'en': 'Download speed'},
    'downloadRemaining': {'ar': 'الوقت المتبقي', 'en': 'Time remaining'},

    // ─── Common ──────────────────────────────────────────────────
    'ok': {'ar': 'حسناً', 'en': 'OK'},
    'confirm': {'ar': 'تأكيد', 'en': 'Confirm'},
    'yes': {'ar': 'نعم', 'en': 'Yes'},
    'no': {'ar': 'لا', 'en': 'No'},
    'loading': {'ar': 'جاري التحميل...', 'en': 'Loading...'},
    'error': {'ar': 'خطأ', 'en': 'Error'},
    'success': {'ar': 'نجح الأمر', 'en': 'Success'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'close': {'ar': 'إغلاق', 'en': 'Close'},
    'done': {'ar': 'تم', 'en': 'Done'},
    'next': {'ar': 'التالي', 'en': 'Next'},
    'back': {'ar': 'رجوع', 'en': 'Back'},
    'skip': {'ar': 'تخطي', 'en': 'Skip'},
  };

  String translate(String key) {
    return _localizedValues[key]?[locale.languageCode] ??
        _localizedValues[key]?['en'] ??
        key;
  }

  // ✅ إضافة: alias مختصر
  String tr(String key) => translate(key);

  bool get isArabic => locale.languageCode == 'ar';
  bool get isRTL => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  // ✅ إصلاح جوهري: shouldReload يجب أن يُرجع true
  // لضمان إعادة تحميل الترجمات عند تغيير اللغة في Runtime
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

// ✅ إضافة: Extension مريح للاستخدام في كل مكان
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).translate(key);
}

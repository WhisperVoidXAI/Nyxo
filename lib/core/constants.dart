import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────────────────
  static const String appName = 'Beyond Silence';
  static const String appVersion = '1.0.0';

  // ─── Hive Boxes ───────────────────────────────────────────────
  static const String notesBoxName = 'notes';
  static const String chatsBoxName = 'chats';
  static const String tasksBoxName = 'tasks';
  static const String settingsBoxName = 'settings';

  // ─── Padding ──────────────────────────────────────────────────
  static const double padXS = 4.0;
  static const double padSM = 8.0;
  static const double padMD = 16.0;
  static const double padLG = 20.0;
  static const double padXL = 24.0;
  static const double padXXL = 32.0;

  // ─── Border Radius ────────────────────────────────────────────
  static const double radiusXS = 6.0;
  static const double radiusSM = 10.0;
  static const double radiusMD = 14.0;
  static const double radiusLG = 18.0;
  static const double radiusXL = 22.0;
  static const double radiusXXL = 28.0;

  // ─── Animation Durations ──────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animNormal = Duration(milliseconds: 320);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ─── UI Constants ─────────────────────────────────────────────
  static const double glassBlur = 14.0;
  static const double iconMD = 22.0;

  // ─── Task Priority Types ──────────────────────────────────────
  static const List<Map<String, String>> priorityTypes = [
    {'value': 'high', 'label': 'عالية', 'labelEn': 'High'},
    {'value': 'medium', 'label': 'متوسطة', 'labelEn': 'Medium'},
    {'value': 'low', 'label': 'منخفضة', 'labelEn': 'Low'},
  ];

  // ─── Note Categories ──────────────────────────────────────────
  static const List<Map<String, Object>> categories = [
    {
      'value': 'personal',
      'label': 'شخصي',
      'labelEn': 'Personal',
      'emoji': '📔',
      'color': Color(0xFF6C63FF),
    },
    {
      'value': 'work',
      'label': 'عمل',
      'labelEn': 'Work',
      'emoji': '💼',
      'color': Color(0xFF00D4FF),
    },
    {
      'value': 'ideas',
      'label': 'أفكار',
      'labelEn': 'Ideas',
      'emoji': '💡',
      'color': Color(0xFFFFD700),
    },
    {
      'value': 'health',
      'label': 'صحة',
      'labelEn': 'Health',
      'emoji': '❤️',
      'color': Color(0xFFFF6B8A),
    },
    {
      'value': 'travel',
      'label': 'سفر',
      'labelEn': 'Travel',
      'emoji': '✈️',
      'color': Color(0xFF4ECDC4),
    },
  ];

  // ─── Note Moods ───────────────────────────────────────────────
  // NOTE: mood list must support indexing [2] and map lookup by 'value'.
  static const List<Map<String, Object>> moods = [
    {
      'value': 'happy',
      'label': 'سعيد',
      'labelEn': 'Happy',
      'emoji': '😊',
      'color': Color(0xFFFFD700),
    },
    {
      'value': 'excited',
      'label': 'متحمس',
      'labelEn': 'Excited',
      'emoji': '🤩',
      'color': Color(0xFFFF6B8A),
    },
    {
      'value': 'neutral',
      'label': 'محايد',
      'labelEn': 'Neutral',
      'emoji': '😐',
      'color': Color(0xFF9E9E9E),
    },
    {
      'value': 'sad',
      'label': 'حزين',
      'labelEn': 'Sad',
      'emoji': '😢',
      'color': Color(0xFF1976D2),
    },
    {
      'value': 'stressed',
      'label': 'متوتر',
      'labelEn': 'Stressed',
      'emoji': '😰',
      'color': Color(0xFFFF8A65),
    },
    {
      'value': 'grateful',
      'label': 'ممتن',
      'labelEn': 'Grateful',
      'emoji': '🙏',
      'color': Color(0xFF388E3C),
    },
    {
      'value': 'inspired',
      'label': 'ملهم',
      'labelEn': 'Inspired',
      'emoji': '✨',
      'color': Color(0xFFCE93D8),
    },
    {
      'value': 'tired',
      'label': 'متعب',
      'labelEn': 'Tired',
      'emoji': '😴',
      'color': Color(0xFF546E7A),
    },
  ];

  // ─── Limits ──────────────────────────────────────────────────
  static const int maxChatHistory = 12;
  static const int maxTagsPerNote = 8;
  static const int maxNoteTitle = 48;

  // ─── Locale Keys ─────────────────────────────────────────────
  static const String localeKey = 'locale';
  static const String isFirstLaunchKey = 'isFirstLaunch';
  static const String themeKey = 'theme';
  static const String lastRouteKey = 'last_route';
  static const String appLockEnabledKey = 'app_lock_enabled';
  static const String appLockPinKey = 'app_lock_pin';
  static const String noteEditorDraftKey = 'note_editor_draft';

  // ─── Splash ───────────────────────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 250);

  // ─── Model Download ────────────────────────────────────────────
  static const String modelName = 'Qwen 2.5 (1.5B)';
  static const String modelFileName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';
  static const String modelDownloadUrl =
      'https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';
  static const double modelSizeGB = 1.0;

  static const int downloadChunkSize = 1024 * 1024;
  static const int maxDownloadRetries = 3;

  // ─── Encryption ───────────────────────────────────────────────
  static const String encryptionKeyName = 'smart_diary_encryption_key';
}

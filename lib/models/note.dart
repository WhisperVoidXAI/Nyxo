import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String category;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  String? mood;

  @HiveField(9)
  bool isEncrypted;

  @HiveField(10)
  bool isPinned;

  @HiveField(11)
  int colorIndex;

  Note({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.category = 'personal',
    this.isFavorite = false,
    List<String>? tags,
    this.mood,
    this.isEncrypted = true,
    this.isPinned = false,
    this.colorIndex = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  // ─── Content Helpers ──────────────────────────────────────────
  String get preview {
    final clean = content
        .replaceAll(RegExp(r'[#*`_>~\[\]()]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= 130) return clean;
    return '${clean.substring(0, 130)}...';
  }

  String get shortPreview {
    final clean = content
        .replaceAll(RegExp(r'[#*`_>~\[\]()]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= 60) return clean;
    return '${clean.substring(0, 60)}...';
  }

  // ✅ إصلاح: حساب دقيق للكلمات
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    // ✅ تنظيف Markdown أولاً ثم العدّ
    final cleaned = content
        .replaceAll(RegExp(r'[#*`_>~\[\]()\-=+|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 0;
    return cleaned
        .split(' ')
        .where((w) => w.trim().isNotEmpty && w.trim().length > 1)
        .length;
  }

  int get charCount => content.length;
  int get readingMinutes => (wordCount / 200).ceil().clamp(1, 999);

  String get readingLabel {
    if (readingMinutes == 1) return '1 دقيقة قراءة';
    return '$readingMinutes دقائق قراءة';
  }

  String getReadingLabel(bool isArabic) {
    if (isArabic) return readingLabel;
    if (readingMinutes == 1) return '1 min read';
    return '$readingMinutes mins read';
  }

  bool get isNew => DateTime.now().difference(createdAt).inHours < 24;
  bool get isModified => updatedAt.difference(createdAt).inMinutes > 2;
  bool get isLong => wordCount > 300;
  bool get isEmpty => content.trim().isEmpty;
  bool get hasTitle => title.trim().isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get hasMood => mood != null && mood!.isNotEmpty;

  String get categoryEmoji {
    switch (category) {
      case 'work':
        return '💼';
      case 'ideas':
        return '💡';
      case 'personal':
        return '📔';
      case 'health':
        return '❤️';
      case 'travel':
        return '✈️';
      default:
        return '📝';
    }
  }

  String getCategoryLabel(bool isArabic) {
    final cat = AppConstants.categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => AppConstants.categories.last,
    );
    return isArabic ? cat['label'] as String : cat['labelEn'] as String;
  }

  String get moodEmoji {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'excited':
        return '🤩';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😢';
      case 'stressed':
        return '😰';
      case 'grateful':
        return '🙏';
      case 'inspired':
        return '✨';
      case 'tired':
        return '😴';
      default:
        return '';
    }
  }

  String getMoodLabel(bool isArabic) {
    if (mood == null) return '';
    final m = AppConstants.moods.firstWhere(
      (m) => m['value'] == mood,
      orElse: () => AppConstants.moods[2],
    );
    return isArabic ? m['label'] as String : m['labelEn'] as String;
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  String getFormattedDate(bool isArabic) {
    if (!isArabic) {
      final now = DateTime.now();
      final diff = now.difference(updatedAt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${updatedAt.month}/${updatedAt.day}/${updatedAt.year}';
    }
    return formattedDate;
  }

  String get fullCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        ' ${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  static const List<int> availableColors = [0, 1, 2, 3, 4, 5];

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        content.toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q)) ||
        (mood?.toLowerCase().contains(q) ?? false);
  }

  static const _unset = Object();

  Note copyWith({
    String? title,
    String? content,
    String? category,
    bool? isFavorite,
    List<String>? tags,
    Object? mood = _unset,
    bool? isPinned,
    int? colorIndex,
    bool? isEncrypted,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? List.from(this.tags),
      mood: identical(mood, _unset) ? this.mood : mood as String?,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isPinned: isPinned ?? this.isPinned,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  @override
  String toString() => 'Note(id: ${id.substring(0, 8)}, title: $title, '
      'category: $category, words: $wordCount)';
}

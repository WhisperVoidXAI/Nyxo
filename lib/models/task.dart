import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart' show Icons, IconData, Color;
import '../core/theme.dart';

part 'task.g.dart';

// ─── Priority ─────────────────────────────────────────────────────
enum TaskPriority { low, medium, high }

// ─────────────────────────────────────────────────────────────────
@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? notes;

  @HiveField(3)
  String? noteId;

  @HiveField(4)
  bool isDone;

  @HiveField(5)
  String priority; // 'low' | 'medium' | 'high'

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime? dueDate;

  @HiveField(8)
  String? emoji;

  @HiveField(9)
  int colorIndex;

  @HiveField(10)
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.notes,
    this.noteId,
    this.isDone = false,
    this.priority = 'medium',
    DateTime? createdAt,
    this.dueDate,
    this.emoji,
    this.colorIndex = 0,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toLocal();

  // ─── Priority Helpers ─────────────────────────────────────────
  TaskPriority get priorityLevel {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  String getPriorityLabel(bool isArabic) {
    switch (priority) {
      case 'high':
        return isArabic ? 'عالية' : 'High';
      case 'low':
        return isArabic ? 'منخفضة' : 'Low';
      default:
        return isArabic ? 'متوسطة' : 'Medium';
    }
  }

  Color get priorityColor {
    switch (priorityLevel) {
      case TaskPriority.high:
        return AppColors.rose;
      case TaskPriority.low:
        return AppColors.mint;
      default:
        return AppColors.gold;
    }
  }

  IconData get priorityIcon {
    switch (priorityLevel) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
      default:
        return Icons.remove_rounded;
    }
  }

  // ─── Due Date Helpers ─────────────────────────────────────────
  bool get hasDueDate => dueDate != null;

  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  String getFormattedDueDate(bool isArabic) {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final diff = dueDate!.difference(now);
    final hour = dueDate!.hour.toString().padLeft(2, '0');
    final minute = dueDate!.minute.toString().padLeft(2, '0');
    final timeText = '$hour:$minute';

    if (isArabic) {
      if (isDueToday) return 'اليوم $timeText';
      if (diff.inDays == 1) return 'غداً $timeText';
      if (diff.inDays == -1) return 'أمس $timeText';
      if (diff.inDays > 1 && diff.inDays < 7) return 'بعد ${diff.inDays} أيام $timeText';
      return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year} $timeText';
    } else {
      if (isDueToday) return 'Today $timeText';
      if (diff.inDays == 1) return 'Tomorrow $timeText';
      if (diff.inDays == -1) return 'Yesterday $timeText';
      if (diff.inDays > 1 && diff.inDays < 7) return 'In ${diff.inDays} days $timeText';
      return '${dueDate!.month}/${dueDate!.day}/${dueDate!.year} $timeText';
    }
  }

  // ─── CopyWith ─────────────────────────────────────────────────
  static const _unset = Object();

  Task copyWith({
    String? title,
    Object? notes = _unset,
    Object? noteId = _unset,
    bool? isDone,
    String? priority,
    Object? dueDate = _unset,
    String? emoji,
    int? colorIndex,
    Object? completedAt = _unset,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      noteId: identical(noteId, _unset) ? this.noteId : noteId as String?,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
      emoji: emoji ?? this.emoji,
      colorIndex: colorIndex ?? this.colorIndex,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  @override
  String toString() =>
      'Task(title: $title, done: $isDone, priority: $priority)';
}

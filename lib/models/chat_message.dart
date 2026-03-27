import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'chat_message.g.dart';

// ─── Enums ────────────────────────────────────────────────────────
enum MessageRole { user, assistant }

enum MessageStatus {
  sent,
  loading,
  done,
  error,
}

// ─────────────────────────────────────────────────────────────────
@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String role; // 'user' | 'assistant'

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? noteId;

  @HiveField(5)
  bool isLoading;

  @HiveField(6)
  bool hasError;

  @HiveField(7)
  int? tokensUsed;

  /// For general chat (noteId == null): separates threads (e.g. `general`, `conv_173...`).
  /// For note-scoped chat: leave null; [noteId] is enough.
  @HiveField(8)
  final String? conversationId;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.noteId,
    this.isLoading = false,
    this.hasError = false,
    this.tokensUsed,
    this.conversationId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  // ─── Role Helpers ─────────────────────────────────────────────
  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  MessageRole get messageRole =>
      isUser ? MessageRole.user : MessageRole.assistant;

  // ─── Status ───────────────────────────────────────────────────
  // ✅ إصلاح جوهري: الترتيب الصحيح للأولوية
  // كان content.isEmpty يُرجع loading حتى لو isLoading=false
  MessageStatus get status {
    if (hasError) return MessageStatus.error;
    if (isLoading) return MessageStatus.loading;
    // ✅ إصلاح: فقط للمساعد — content فارغ + isLoading=false = error
    if (isAssistant && content.isEmpty) return MessageStatus.error;
    return MessageStatus.done;
  }

  // ─── Content Helpers ──────────────────────────────────────────
  bool get isEmpty => content.trim().isEmpty;
  bool get isNotEmpty => content.trim().isNotEmpty;

  int get wordCount =>
      isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  int get charCount => content.length;

  String get preview {
    if (content.length <= 60) return content;
    return '${content.substring(0, 60)}...';
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  // ─── Factory Constructors ─────────────────────────────────────
  factory ChatMessage.user(
    String content, {
    String? noteId,
    String? conversationId,
  }) =>
      ChatMessage(
        content: content,
        role: 'user',
        noteId: noteId,
        conversationId: conversationId,
      );

  factory ChatMessage.assistant(
    String content, {
    String? noteId,
    String? conversationId,
    int? tokensUsed,
  }) =>
      ChatMessage(
        content: content,
        role: 'assistant',
        noteId: noteId,
        conversationId: conversationId,
        tokensUsed: tokensUsed,
      );

  factory ChatMessage.loading({String? noteId, String? conversationId}) =>
      ChatMessage(
        content: '',
        role: 'assistant',
        noteId: noteId,
        conversationId: conversationId,
        isLoading: true,
      );

  factory ChatMessage.error({String? noteId, String? conversationId}) =>
      ChatMessage(
        content: '',
        role: 'assistant',
        noteId: noteId,
        conversationId: conversationId,
        hasError: true,
      );

  // ─── CopyWith ─────────────────────────────────────────────────
  // ✅ إصلاح: استخدام Sentinel لتمييز null المقصود
  static const _unset = Object();

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    bool? hasError,
    int? tokensUsed,
    Object? noteId = _unset,
    Object? conversationId = _unset,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      noteId: identical(noteId, _unset) ? this.noteId : noteId as String?,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      conversationId: identical(conversationId, _unset)
          ? this.conversationId
          : conversationId as String?,
    );
  }

  @override
  String toString() =>
      'ChatMessage(role: $role, preview: $preview, status: $status)';
}

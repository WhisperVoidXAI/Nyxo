import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../core/constants.dart';
import 'encryption_service.dart';

class DatabaseService {
  // ─── Singleton ────────────────────────────────────────────────
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _encryption = EncryptionService();

  // ─── Boxes ────────────────────────────────────────────────────
  late Box<Note> _notesBox;
  late Box<ChatMessage> _chatsBox;
  late Box<Task> _tasksBox;
  late Box _settingsBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ─── Initialize ───────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(NoteAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TaskAdapter());
    }

    _notesBox = await Hive.openBox<Note>(AppConstants.notesBoxName);
    _chatsBox = await Hive.openBox<ChatMessage>(AppConstants.chatsBoxName);
    _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);

    _initialized = true;
  }

  // ─── Guard ────────────────────────────────────────────────────
  void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
          'DatabaseService not initialized. Call initialize() first.');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  NOTES
  // ══════════════════════════════════════════════════════════════

  Future<void> saveNote(Note note) async {
    _assertInitialized();
    try {
      await _notesBox.put(note.id, _encryptNote(note));
    } catch (e) {
      await _notesBox.put(note.id, note);
    }
  }

  Future<void> updateNote(Note note) => saveNote(note);

  Future<void> deleteNote(String id) async {
    _assertInitialized();
    await _notesBox.delete(id);
    await clearMessages(noteId: id);
    await deleteTasksForNote(id);
  }

  Future<void> deleteAllNotes() async {
    _assertInitialized();
    await _notesBox.clear();
    await _chatsBox.clear();
  }

  List<Note> getAllNotes() {
    _assertInitialized();
    return _notesBox.values.map(_decryptNote).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Note> getFavoriteNotes() =>
      getAllNotes().where((n) => n.isFavorite).toList();

  List<Note> getPinnedNotes() =>
      getAllNotes().where((n) => n.isPinned).toList();

  List<Note> getNotesByCategory(String category) =>
      getAllNotes().where((n) => n.category == category).toList();

  List<Note> searchNotes(String query) {
    if (query.trim().isEmpty) return getAllNotes();
    return getAllNotes().where((n) => n.matchesSearch(query)).toList();
  }

  Note? getNoteById(String id) {
    _assertInitialized();
    final note = _notesBox.get(id);
    return note == null ? null : _decryptNote(note);
  }

  int get notesCount {
    if (!_initialized) return 0;
    return _notesBox.length;
  }

  // ══════════════════════════════════════════════════════════════
  //  CHAT MESSAGES
  // ══════════════════════════════════════════════════════════════

  Future<void> saveMessage(ChatMessage message) async {
    _assertInitialized();
    await _chatsBox.put(message.id, message);
  }

  /// Note-scoped: [noteId] set, [conversationId] ignored.
  /// General chat: [noteId] null — filter by [conversationId] (`general`, `conv_…`).
  List<ChatMessage> getChatMessages({
    String? noteId,
    String? conversationId,
  }) {
    _assertInitialized();
    if (noteId != null) {
      return _chatsBox.values.where((m) => m.noteId == noteId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    final cid = conversationId ?? 'general';
    return _chatsBox.values
        .where((m) {
          if (m.noteId != null) return false;
          return (m.conversationId ?? 'general') == cid;
        })
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> clearMessages({
    String? noteId,
    String? conversationId,
  }) async {
    _assertInitialized();
    if (noteId != null) {
      final toDelete = _chatsBox.values
          .where((m) => m.noteId == noteId)
          .map((m) => m.id)
          .toList();
      await _chatsBox.deleteAll(toDelete);
      return;
    }
    final cid = conversationId ?? 'general';
    final toDelete = _chatsBox.values
        .where((m) {
          if (m.noteId != null) return false;
          return (m.conversationId ?? 'general') == cid;
        })
        .map((m) => m.id)
        .toList();
    await _chatsBox.deleteAll(toDelete);
  }

  /// Distinct thread ids for general chat (noteId null), e.g. `general`, `conv_…`
  List<String> getGeneralConversationIds() {
    _assertInitialized();
    final ids = <String>{};
    for (final m in _chatsBox.values) {
      if (m.noteId != null) continue;
      ids.add(m.conversationId ?? 'general');
    }
    if (ids.isEmpty) return ['general'];
    return ids.toList()
      ..sort((a, b) {
        if (a == 'general') return -1;
        if (b == 'general') return 1;
        return a.compareTo(b);
      });
  }

  Future<void> clearAllMessages() async {
    _assertInitialized();
    await _chatsBox.clear();
  }

  int get messagesCount {
    if (!_initialized) return 0;
    return _chatsBox.length;
  }

  // ══════════════════════════════════════════════════════════════
  //  TASKS
  // ══════════════════════════════════════════════════════════════

  Future<void> saveTask(Task task) async {
    _assertInitialized();
    await _tasksBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) => saveTask(task);

  Future<void> deleteTask(String id) async {
    _assertInitialized();
    await _tasksBox.delete(id);
  }

  Future<void> deleteTasksForNote(String noteId) async {
    _assertInitialized();
    final toDelete = _tasksBox.values
        .where((t) => t.noteId == noteId)
        .map((t) => t.id)
        .toList();
    await _tasksBox.deleteAll(toDelete);
  }

  List<Task> getAllTasks() {
    _assertInitialized();
    return _tasksBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Task> getPendingTasks() =>
      getAllTasks().where((t) => !t.isDone).toList();

  List<Task> getTasksForNote(String noteId) =>
      getAllTasks().where((t) => t.noteId == noteId).toList();

  Task? getTaskById(String id) {
    if (!_initialized) return null;
    return _tasksBox.get(id);
  }

  int get tasksCount {
    if (!_initialized) return 0;
    return _tasksBox.length;
  }

  // ══════════════════════════════════════════════════════════════
  //  SETTINGS
  // ══════════════════════════════════════════════════════════════

  Future<void> saveSetting(String key, dynamic value) async {
    _assertInitialized();
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    if (!_initialized) return defaultValue;
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    _assertInitialized();
    await _settingsBox.delete(key);
  }

  bool hasSetting(String key) {
    if (!_initialized) return false;
    return _settingsBox.containsKey(key);
  }

  // ══════════════════════════════════════════════════════════════
  //  ENCRYPTION
  // ══════════════════════════════════════════════════════════════

  Note _encryptNote(Note note) {
    if (!_encryption.isInitialized) return note;
    return note.copyWith(
      title: _encryption.encrypt(note.title),
      content: _encryption.encrypt(note.content),
    );
  }

  Note _decryptNote(Note note) {
    return note.copyWith(
      title: _tryDecrypt(note.title),
      content: _tryDecrypt(note.content),
    );
  }

  String _tryDecrypt(String text) {
    if (!_encryption.isInitialized) return text;
    try {
      return _encryption.decrypt(text);
    } catch (_) {
      return text;
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  STATS
  // ══════════════════════════════════════════════════════════════

  Map<String, int> get stats => {
        'notes': notesCount,
        'messages': messagesCount,
        'tasks': tasksCount,
        'favorites': getFavoriteNotes().length,
        'pinned': getPinnedNotes().length,
      };

  int get totalWords {
    if (!_initialized) return 0;
    return getAllNotes().fold(0, (sum, n) => sum + n.wordCount);
  }

  // ══════════════════════════════════════════════════════════════
  //  COMPACT / CLOSE
  // ══════════════════════════════════════════════════════════════

  Future<void> compact() async {
    if (!_initialized) return;
    await _notesBox.compact();
    await _chatsBox.compact();
    await _tasksBox.compact();
  }

  Future<void> closeAll() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
  }
}

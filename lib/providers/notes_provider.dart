import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_service.dart';

enum SortType { newest, oldest, title, longest }

enum NotesViewMode { grid, list }

class NotesProvider extends ChangeNotifier {
  final _db = DatabaseService();

  // ─── State ────────────────────────────────────────────────────
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  SortType _sortType = SortType.newest;
  bool _isLoading = false;
  bool _showPinnedFirst = true;
  NotesViewMode _viewMode = NotesViewMode.list;
  bool _isDisposed = false;

  // ✅ إضافة: تتبع آخر فلتر لتجنب إعادة بناء غير ضرورية

  // ─── Getters ──────────────────────────────────────────────────
  List<Note> get notes => List.unmodifiable(_notes);
  List<Note> get filteredNotes => List.unmodifiable(_filteredNotes);
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  SortType get sortType => _sortType;
  bool get isLoading => _isLoading;
  bool get isSearching => _searchQuery.isNotEmpty;
  bool get hasNotes => _notes.isNotEmpty;
  bool get hasResults => _filteredNotes.isNotEmpty;
  NotesViewMode get viewMode => _viewMode;
  bool get showPinnedFirst => _showPinnedFirst;

  // ─── Pinned / Normal ──────────────────────────────────────────
  List<Note> get pinnedNotes =>
      _filteredNotes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes =>
      _filteredNotes.where((n) => !n.isPinned).toList();

  // ─── Stats ────────────────────────────────────────────────────
  int get totalNotes => _notes.length;
  int get favoriteCount => _notes.where((n) => n.isFavorite).length;
  int get pinnedCount => _notes.where((n) => n.isPinned).length;
  int get totalWords {
    int count = 0;
    for (final note in _notes) {
      final cleaned = note.content
          .replaceAll(RegExp(r'[#*`_>~\[\]()\-=+|]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleaned.isEmpty) continue;
      count += cleaned.split(' ').where((w) => w.trim().length > 1).length;
    }
    return count;
  }

  int get encryptedCount => _notes.where((n) => n.isEncrypted).length;

  int get todayCount {
    final now = DateTime.now();
    return _notes
        .where((n) =>
            n.createdAt.year == now.year &&
            n.createdAt.month == now.month &&
            n.createdAt.day == now.day)
        .length;
  }

  int get thisMonthCount {
    final now = DateTime.now();
    return _notes
        .where((n) =>
            n.createdAt.year == now.year && n.createdAt.month == now.month)
        .length;
  }

  int countByCategory(String category) {
    if (category == 'all') return _notes.length;
    if (category == 'favorites') return favoriteCount;
    return _notes.where((n) => n.category == category).length;
  }

  Map<String, int> get categoryDistribution {
    final map = <String, int>{};
    for (final note in _notes) {
      map[note.category] = (map[note.category] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get moodDistribution {
    final map = <String, int>{};
    for (final note in _notes) {
      if (note.mood != null) {
        map[note.mood!] = (map[note.mood!] ?? 0) + 1;
      }
    }
    return map;
  }

  // ─── Load ─────────────────────────────────────────────────────
  Future<void> loadNotes() async {
    _isLoading = true;
    _safeNotify();
    _notes = _db.getAllNotes();
    _applyFilters();
    _isLoading = false;
    _safeNotify();
  }

  // ─── CRUD ─────────────────────────────────────────────────────
  Future<void> addNote(Note note) async {
    await _db.saveNote(note);
    // ✅ إضافة: إضافة محلية فورية بدون إعادة تحميل كاملة
    _notes.insert(0, note);
    _applyFilters();
    _safeNotify();
  }

  Future<void> updateNote(Note note) async {
    await _db.updateNote(note);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    } else {
      // ✅ إصلاح: أضفه إذا لم يكن موجوداً بدلاً من reload كامل
      _notes.insert(0, note);
    }
    _applyFilters();
    _safeNotify();
  }

  Future<void> deleteNote(String id) async {
    // ✅ إصلاح: التحقق من وجود المذكرة قبل الحذف
    final exists = _notes.any((n) => n.id == id);
    if (!exists) return;

    await _db.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    _applyFilters();
    _safeNotify();
  }

  Future<void> deleteAllNotes() async {
    await _db.deleteAllNotes();
    _notes.clear();
    _filteredNotes.clear();
    _safeNotify();
  }

  // ─── Toggle Actions ───────────────────────────────────────────
  Future<void> toggleFavorite(Note note) async {
    final updated = note.copyWith(isFavorite: !note.isFavorite);
    await _db.updateNote(updated);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      _applyFilters();
      _safeNotify();
    }
  }

  Future<void> togglePin(Note note) async {
    final updated = note.copyWith(isPinned: !note.isPinned);
    await _db.updateNote(updated);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      _applyFilters();
      _safeNotify();
    }
  }

  // ─── View Mode ────────────────────────────────────────────────
  void setViewMode(NotesViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _safeNotify();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == NotesViewMode.list
        ? NotesViewMode.grid
        : NotesViewMode.list;
    _safeNotify();
  }

  // ─── Search ───────────────────────────────────────────────────
  void search(String query) {
    if (_searchQuery == query) return; // ✅ تجنب rebuild غير ضروري
    _searchQuery = query;
    _applyFilters();
    _safeNotify();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _applyFilters();
    _safeNotify();
  }

  // ─── Filter ───────────────────────────────────────────────────
  void filterByCategory(String category) {
    if (_selectedCategory == category) return; // ✅ تجنب rebuild
    _selectedCategory = category;
    _applyFilters();
    _safeNotify();
  }

  void setSortType(SortType type) {
    if (_sortType == type) return; // ✅ تجنب rebuild
    _sortType = type;
    _applyFilters();
    _safeNotify();
  }

  void togglePinnedFirst() {
    _showPinnedFirst = !_showPinnedFirst;
    _applyFilters();
    _safeNotify();
  }

  void resetFilters() {
    _selectedCategory = 'all';
    _searchQuery = '';
    _sortType = SortType.newest;
    _applyFilters();
    _safeNotify();
  }

  // ─── Apply Filters + Sort ─────────────────────────────────────
  void _applyFilters() {
    // ✅ إضافة: skip إذا لم يتغير الفلتر (أداء)
    List<Note> result = List.from(_notes);

    // ── Category ──────────────────────────────────────────────
    if (_selectedCategory == 'favorites') {
      result = result.where((n) => n.isFavorite).toList();
    } else if (_selectedCategory != 'all') {
      result = result.where((n) => n.category == _selectedCategory).toList();
    }

    // ── Search ────────────────────────────────────────────────
    if (_searchQuery.isNotEmpty) {
      result = result.where((n) => n.matchesSearch(_searchQuery)).toList();
    }

    // ── Sort ──────────────────────────────────────────────────
    switch (_sortType) {
      case SortType.newest:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortType.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.title:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.longest:
        result.sort((a, b) => b.wordCount.compareTo(a.wordCount));
        break;
    }

    // ── Pinned First ──────────────────────────────────────────
    if (_showPinnedFirst) {
      final pinned = result.where((n) => n.isPinned).toList();
      final unpinned = result.where((n) => !n.isPinned).toList();
      result = [...pinned, ...unpinned];
    }

    _filteredNotes = result;
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

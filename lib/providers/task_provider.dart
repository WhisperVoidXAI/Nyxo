import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_service.dart';

enum TaskFilter { all, pending, done, today, overdue }

class TaskProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isDisposed = false;
  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  bool isArabic = true;

  // ─── Getters ──────────────────────────────────────────────────
  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  TaskFilter get currentFilter => _currentFilter;
  bool get hasTasks => _tasks.isNotEmpty;

  List<Task> get pendingTasks => _tasks.where((t) => !t.isDone).toList();
  List<Task> get doneTasks => _tasks.where((t) => t.isDone).toList();
  List<Task> get todayTasks => _tasks.where((t) => t.isDueToday).toList();
  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  int get totalCount => _tasks.length;
  int get pendingCount => pendingTasks.length;
  int get doneCount => doneTasks.length;
  int get overdueCount => overdueTasks.length;

  List<Task> get filteredTasks {
    List<Task> base;
    switch (_currentFilter) {
      case TaskFilter.pending:
        base = pendingTasks;
        break;
      case TaskFilter.done:
        base = doneTasks;
        break;
      case TaskFilter.today:
        base = todayTasks;
        break;
      case TaskFilter.overdue:
        base = overdueTasks;
        break;
      case TaskFilter.all:
        base = _tasks;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.notes?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // ترتيب: غير مكتملة أولاً، ثم حسب الأولوية، ثم حسب التاريخ
    base.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final pa = priorityOrder[a.priority] ?? 1;
      final pb = priorityOrder[b.priority] ?? 1;
      if (pa != pb) return pa.compareTo(pb);
      return b.createdAt.compareTo(a.createdAt);
    });

    return base;
  }

  // ─── Load ─────────────────────────────────────────────────────
  Future<void> loadTasks() async {
    _setLoading(true);
    try {
      _tasks = _db.getAllTasks();
      _setLoading(false);
    } catch (e) {
      debugPrint('TaskProvider.loadTasks error: $e');
      _setLoading(false);
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────────
  Future<bool> addTask(Task task) async {
    try {
      await _db.saveTask(task);
      _tasks.add(task);
      _safeNotify();
      return true;
    } catch (e) {
      debugPrint('TaskProvider.addTask error: $e');
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await _db.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _safeNotify();
      }
      return true;
    } catch (e) {
      debugPrint('TaskProvider.updateTask error: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _db.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      _safeNotify();
      return true;
    } catch (e) {
      debugPrint('TaskProvider.deleteTask error: $e');
      return false;
    }
  }

  Future<void> toggleDone(Task task) async {
    final updated = task.copyWith(
      isDone: !task.isDone,
      completedAt: !task.isDone ? DateTime.now() : null,
    );
    await updateTask(updated);
  }

  Future<void> deleteTasksForNote(String noteId) async {
    final toDelete =
        _tasks.where((t) => t.noteId == noteId).map((t) => t.id).toList();
    for (final id in toDelete) {
      await _db.deleteTask(id);
    }
    _tasks.removeWhere((t) => t.noteId == noteId);
    _safeNotify();
  }

  // ─── Filter & Search ──────────────────────────────────────────
  void setFilter(TaskFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _safeNotify();
  }

  void search(String query) {
    _searchQuery = query;
    _safeNotify();
  }

  void clearSearch() {
    _searchQuery = '';
    _safeNotify();
  }

  void setLanguage(bool isArabic) {
    isArabic = isArabic;
  }

  // ─── Helpers ──────────────────────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    _safeNotify();
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

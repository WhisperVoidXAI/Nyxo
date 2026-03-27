import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/note.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../core/constants.dart';

enum ChatState { idle, generating, error }

class ChatProvider extends ChangeNotifier {
  final _aiService = AiService();
  final _db = DatabaseService();
  // ✅ أضف في أعلى الـ class بعد المتغيرات الموجودة:

// ─── نظام المحادثات المتعددة ───────────────────────────────────
  final Map<String, List<ChatMessage>> _allConversations = {};
  final Map<String, String> _conversationTitles = {};
  String _activeConversationId = 'general';

  List<String> get conversationIds {
    final ids = _allConversations.keys.toList();
    if (!ids.contains('general')) ids.insert(0, 'general');
    return ids;
  }

  String get activeConversationId => _activeConversationId;

  String getConversationTitle(String id, bool isArabic) {
    if (_conversationTitles.containsKey(id)) {
      return _conversationTitles[id]!;
    }
    if (id == 'general') {
      return isArabic ? 'محادثة عامة' : 'General Chat';
    }
    return isArabic ? 'محادثة جديدة' : 'New Chat';
  }

  void switchConversation(String id) {
    if (_activeConversationId == id) return;

    if (isGenerating) {
      _generationSub?.cancel();
      _generationSub = null;
      _aiService.stopGeneration();
    }

    _allConversations[_activeConversationId] = List.from(_messages);

    _streamingText = '';
    _errorMessage = '';

    _activeConversationId = id;
    var next = List<ChatMessage>.from(_allConversations[id] ?? []);
    if (next.isEmpty && _contextNote == null) {
      next = List<ChatMessage>.from(
        _db.getChatMessages(noteId: null, conversationId: id),
      );
    }
    _messages = next;
    _allConversations[id] = List.from(_messages);

    _setState(ChatState.idle);
  }

  void newConversation() {
    // ✅ إصلاح: حفظ الحالية أولاً
    _allConversations[_activeConversationId] = List.from(_messages);

    // إنشاء ID جديد فريد
    final newId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    _allConversations[newId] = [];
    _conversationTitles[newId] = '';

    // ✅ تصفير كامل قبل التبديل — يمنع ظهور رسائل قديمة
    _messages = [];
    _streamingText = '';
    _errorMessage = '';
    _contextNote = null;
    _activeConversationId = newId;

    _setState(ChatState.idle);
  }

  Future<void> deleteConversation(String id) async {
    if (id == 'general' && _allConversations.length <= 1) {
      _allConversations['general'] = [];
      await _db.clearMessages(noteId: null, conversationId: 'general');
      if (_activeConversationId == 'general') {
        _messages = [];
        _safeNotify();
      }
      return;
    }
    await _db.clearMessages(noteId: null, conversationId: id);
    _allConversations.remove(id);
    _conversationTitles.remove(id);
    if (_activeConversationId == id) {
      _activeConversationId = _allConversations.keys.firstOrNull ?? 'general';
      _messages = List.from(_allConversations[_activeConversationId] ?? []);
      if (_messages.isEmpty && _activeConversationId != 'general') {
        _messages = List<ChatMessage>.from(
          _db.getChatMessages(
            noteId: null,
            conversationId: _activeConversationId,
          ),
        );
      }
    }
    _safeNotify();
  }

  // ─── State ────────────────────────────────────────────────────
  List<ChatMessage> _messages = [];
  ChatState _chatState = ChatState.idle;
  Note? _contextNote;
  String _streamingText = '';
  String _errorMessage = '';
  bool _isArabic = true;
  int _totalTokens = 0;
  bool _isDisposed = false;

  // ✅ إضافة: StreamSubscription لإمكانية إلغاء الـ stream فعلياً
  StreamSubscription<String>? _generationSub;
  DateTime _lastUiPush = DateTime.fromMillisecondsSinceEpoch(0);

  // ─── Getters ──────────────────────────────────────────────────
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatState get chatState => _chatState;
  Note? get contextNote => _contextNote;
  String get streamingText => _streamingText;
  String get errorMessage => _errorMessage;
  int get totalTokens => _totalTokens;

  bool get isGenerating => _chatState == ChatState.generating;
  bool get hasError => _chatState == ChatState.error;
  bool get isIdle => _chatState == ChatState.idle;
  bool get hasMessages => _messages.isNotEmpty;
  int get messageCount => _messages.length;
  int get userMessageCount => _messages.where((m) => m.isUser).length;

  ChatMessage? get lastAssistantMessage => _messages
      .cast<ChatMessage?>()
      .lastWhere((m) => m?.isAssistant ?? false, orElse: () => null);

  bool get hasContext => _contextNote != null;

  String get chatTitle {
    if (_contextNote != null) {
      return _contextNote!.title.isNotEmpty
          ? _contextNote!.title
          : (_isArabic ? 'مذكرة' : 'Note');
    }
    return _isArabic ? 'محادثة عامة' : 'General Chat';
  }

  // ─── Language ─────────────────────────────────────────────────
  void setLanguage(bool isArabic) {
    _isArabic = isArabic;
    _aiService.setLanguage(isArabic);
  }

  // ─── Load ─────────────────────────────────────────────────────
  Future<void> loadMessages({Note? note}) async {
    if (isGenerating) {
      await _generationSub?.cancel();
      _generationSub = null;
      _aiService.stopGeneration();
    }

    _streamingText = '';
    _errorMessage = '';
    _chatState = ChatState.idle;
    _contextNote = note;

    final String targetConvId;
    if (note != null) {
      targetConvId = note.id;
    } else {
      if (_activeConversationId.isEmpty ||
          (!(_activeConversationId == 'general' ||
              _activeConversationId.startsWith('conv_')))) {
        _activeConversationId = 'general';
      }
      targetConvId = _activeConversationId;
    }

    if (_activeConversationId != targetConvId) {
      _allConversations[_activeConversationId] = List.from(_messages);
    }
    _activeConversationId = targetConvId;

    if (note == null) {
      for (final id in _db.getGeneralConversationIds()) {
        _allConversations.putIfAbsent(id, () => []);
      }
    }

    final fromDb = _db.getChatMessages(
      noteId: note?.id,
      conversationId: note == null ? targetConvId : null,
    );
    _messages = List.from(fromDb);
    _allConversations[targetConvId] = List.from(_messages);

    _safeNotify();
  }

  // ─── Send ─────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isGenerating) return;
    if (trimmed.length > AppConstants.maxChatHistory * 100) return;

    _clearError();

    final conv = _contextNote == null ? _activeConversationId : null;

    // ── 1. رسالة المستخدم ──────────────────────────────────────
    final userMsg = ChatMessage.user(
      trimmed,
      noteId: _contextNote?.id,
      conversationId: conv,
    );
    _messages.add(userMsg);
    await _db.saveMessage(userMsg);

    // ── 2. Placeholder للمساعد ─────────────────────────────────
    final loadingMsg = ChatMessage.loading(
      noteId: _contextNote?.id,
      conversationId: conv,
    );
    _messages.add(loadingMsg);

    _streamingText = '';
    _setState(ChatState.generating);

    // ── 3. السياق التاريخي ─────────────────────────────────────
    // ✅ إصلاح: استثناء رسائل loading و الرسالة الحالية من السياق
    final history = _messages
        .where((m) =>
            !m.isLoading &&
            !m.hasError &&
            m.id != userMsg.id &&
            m.id != loadingMsg.id &&
            m.isNotEmpty)
        .take(AppConstants.maxChatHistory)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // ── 4. Stream من AI ────────────────────────────────────────
    final completer = Completer<void>();

    // ✅ إصلاح: استخدام StreamSubscription لإلغاء فعلي
    _generationSub = _aiService
        .chat(
      userMessage: trimmed,
      history: history,
      noteContext: _contextNote?.content,
      isArabic: _isArabic,
    )
        .listen(
      (chunk) {
        if (_isDisposed) return;
        _streamingText += chunk;
        final now = DateTime.now();
        final shouldPush = now.difference(_lastUiPush).inMilliseconds >= 35;
        if (_messages.isNotEmpty && shouldPush) {
          _messages.last = loadingMsg.copyWith(
            content: _streamingText,
            isLoading: false,
          );
          _lastUiPush = now;
          _safeNotify();
        }
      },
      onDone: () async {
        if (_isDisposed) {
          completer.complete();
          return;
        }

        // ── 5. الرسالة النهائية ──────────────────────────────
        if (_streamingText.isNotEmpty) {
          final finalMsg = ChatMessage.assistant(
            _streamingText,
            noteId: _contextNote?.id,
            conversationId: conv,
          );
          if (_messages.isNotEmpty) _messages.last = finalMsg;
          await _db.saveMessage(finalMsg);
          _totalTokens += finalMsg.charCount ~/ 4;
        } else {
          // ✅ إضافة: معالجة stream فارغ
          if (_messages.isNotEmpty) {
            _messages.last = ChatMessage.error(
              noteId: _contextNote?.id,
              conversationId: conv,
            );
          }
        }

        _streamingText = '';
        _setState(ChatState.idle);
        completer.complete();
      },
      onError: (Object e) async {
        if (_isDisposed) {
          completer.complete();
          return;
        }
        _handleGenerationError(e.toString());
        completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  void _handleGenerationError(String error) {
    final conv = _contextNote == null ? _activeConversationId : null;
    if (_messages.isNotEmpty) {
      _messages.last = ChatMessage(
        content: _isArabic
            ? '⚠️ حدث خطأ، يرجى المحاولة مجدداً'
            : '⚠️ An error occurred, please try again',
        role: 'assistant',
        noteId: _contextNote?.id,
        conversationId: conv,
        hasError: true,
      );
    }
    _errorMessage = error;
    _setState(ChatState.error);
  }

  // ─── Retry ────────────────────────────────────────────────────
  Future<void> retryLast() async {
    if (_messages.length < 2) return;

    // ✅ إصلاح: احذف آخر رسالة فقط إذا كانت خطأ فعلاً
    if (_messages.last.hasError) {
      _messages.removeLast();
    } else {
      return; // لا تحذف رسائل صحيحة
    }

    // ابحث عن آخر رسالة مستخدم
    ChatMessage? lastUser;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        lastUser = _messages[i];
        _messages.removeAt(i);
        break;
      }
    }

    if (lastUser == null || lastUser.isEmpty) return;

    _safeNotify();
    await sendMessage(lastUser.content);
  }

  // ─── Clear ────────────────────────────────────────────────────
  Future<void> clearMessages() async {
    await _generationSub?.cancel();
    _generationSub = null;
    await _db.clearMessages(
      noteId: _contextNote?.id,
      conversationId: _contextNote == null ? _activeConversationId : null,
    );
    _messages.clear();
    _streamingText = '';
    _totalTokens = 0;
    _setState(ChatState.idle);
  }

  // ─── Stop ─────────────────────────────────────────────────────
  Future<void> stopGeneration() async {
    if (!isGenerating) return;

    // ✅ إصلاح: إلغاء StreamSubscription فعلياً
    await _generationSub?.cancel();
    _generationSub = null;

    _aiService.stopGeneration();

    // احفظ ما تم توليده حتى الآن
    if (_streamingText.isNotEmpty && _messages.isNotEmpty) {
      final partial = ChatMessage.assistant(
        _streamingText,
        noteId: _contextNote?.id,
        conversationId: _contextNote == null ? _activeConversationId : null,
      );
      _messages.last = partial;
      await _db.saveMessage(partial);
    } else if (_messages.isNotEmpty && _messages.last.isLoading) {
      // ✅ إضافة: أزل الـ loading bubble إذا لم ينتج نص
      _messages.removeLast();
    }

    _streamingText = '';
    _setState(ChatState.idle);
  }

  // ─── AI Helpers ───────────────────────────────────────────────

  /// اقتراح عنوان للمذكرة
  Future<String?> suggestTitle(String content) async {
    if (content.trim().isEmpty || _isDisposed) return null;
    try {
      final prompt = _isArabic
          ? 'اقترح عنواناً مناسباً قصيراً (أقل من 8 كلمات) لهذا النص:\n$content'
          : 'Suggest a short title (less than 8 words) for this text:\n$content';

      return await _collectStream(prompt);
    } catch (_) {
      return null;
    }
  }

  /// تحسين نص المذكرة
  Future<String?> improveText(String content) async {
    if (content.trim().isEmpty || _isDisposed) return null;
    try {
      final prompt = _isArabic
          ? 'حسّن هذا النص لغوياً وأسلوبياً مع الحفاظ على المعنى:\n$content'
          : 'Improve this text grammatically and stylistically while preserving the meaning:\n$content';

      return await _collectStream(prompt);
    } catch (_) {
      return null;
    }
  }

  /// تلخيص المذكرة
  Future<String?> summarize(String content) async {
    if (content.trim().isEmpty || _isDisposed) return null;
    try {
      final prompt = _isArabic
          ? 'لخّص هذا النص في ٣ نقاط رئيسية:\n$content'
          : 'Summarize this text in 3 main points:\n$content';

      return await _collectStream(prompt);
    } catch (_) {
      return null;
    }
  }

  // ✅ إضافة: helper مشترك لجمع Stream إلى String
  Future<String?> _collectStream(String prompt) async {
    if (_isDisposed) return null;
    final buffer = StringBuffer();
    await for (final chunk in _aiService.chat(
      userMessage: prompt,
      history: [],
      isArabic: _isArabic,
    )) {
      if (_isDisposed) return null;
      buffer.write(chunk);
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result.replaceAll(RegExp(r'''['""]'''), '');
  }

  // ─── Helpers ──────────────────────────────────────────────────
  void _setState(ChatState state) {
    _chatState = state;
    _safeNotify();
  }

  void _clearError() {
    _errorMessage = '';
    if (_chatState == ChatState.error) {
      _chatState = ChatState.idle;
    }
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _generationSub?.cancel();
    _aiService.dispose();
    super.dispose();
  }
}

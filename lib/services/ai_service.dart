import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart';
import 'download_service.dart';

enum AiStatus { notLoaded, loading, ready, generating, error }

class AiService {
  // ─── Singleton ────────────────────────────────────────────────
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // ─── Engine ───────────────────────────────────────────────────
  final _downloadService = DownloadService();
  LlamaEngine? _engine;

  // ─── State ────────────────────────────────────────────────────
  AiStatus _status = AiStatus.notLoaded;
  String? _errorMessage;
  bool _isArabic = true;
  bool _stopRequested = false;
  int _generationCount = 0;

  AiStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == AiStatus.ready;
  bool get isLoading => _status == AiStatus.loading;
  bool get isGenerating => _status == AiStatus.generating;
  bool get hasError => _status == AiStatus.error;
  bool get isNotLoaded => _status == AiStatus.notLoaded;
  int get generationCount => _generationCount;

  // ─── Listeners ────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];
  void addStatusListener(VoidCallback l) => _listeners.add(l);
  void removeStatusListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in List.of(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  // ─── Language ─────────────────────────────────────────────────
  void setLanguage(bool isArabic) {
    _isArabic = isArabic;
  }

  // ─── Load Model ───────────────────────────────────────────────
  // ─── Load Model ───────────────────────────────────────────────
  Future<bool> loadModel() async {
    if (isReady) return true;
    try {
      _setStatus(AiStatus.loading);

      final isDownloaded = await _downloadService.isModelDownloaded();
      if (!isDownloaded) {
        _errorMessage = _isArabic
            ? 'النموذج غير موجود، يرجى تنزيله أولاً'
            : 'Model not found, please download it first';
        _setStatus(AiStatus.error);
        return false;
      }

      final modelPath = await _downloadService.getModelPath();

      // ✅ إعدادات أداء لتحميل أسرع واستجابات أكثر ثباتاً.
      // نستخدم CPU فقط لضمان التوافق على كل أجهزة Android.
      final backend = LlamaBackend();
      _engine = LlamaEngine(backend);
      await _engine!.setLogLevel(LlamaLogLevel.none);

      await _engine!.loadModel(
        modelPath,
        modelParams: ModelParams(
          contextSize: 512, // أقل = تحميل أسرع وذاكرة أقل
          gpuLayers: 0,
          preferredBackend: GpuBackend.cpu,
          numberOfThreads: 6, // استغلال أفضل للمعالج
          numberOfThreadsBatch: 6,
          batchSize: 128, // batch أصغر = استجابة أسرع للرسالة الأولى
          microBatchSize: 128,
        ),
      );

      _errorMessage = null;
      _setStatus(AiStatus.ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _engine = null;
      _setStatus(AiStatus.error);
      return false;
    }
  }

  // ─── Reload ───────────────────────────────────────────────────
  Future<bool> reload() async {
    await _disposeEngine();
    return loadModel();
  }

  // ─── Chat Stream ──────────────────────────────────────────────
  Stream<String> chat({
    required String userMessage,
    required List<Map<String, String>> history,
    String? noteContext,
    bool isArabic = true,
  }) async* {
    if (!isReady || _engine == null) {
      yield isArabic
          ? 'النموذج غير جاهز. يرجى إعادة تشغيل التطبيق.'
          : 'Model not ready. Please restart the app.';
      return;
    }

    _stopRequested = false;
    _setStatus(AiStatus.generating);
    _generationCount++;

    try {
      final responseArabic = _detectArabicQuestion(userMessage);
      final fullMessage = _buildMessage(
        userMessage: userMessage,
        history: history,
        noteContext: noteContext,
        isArabic: responseArabic,
      );

      // 🟢 بعد — أضف حد أقصى للرد:
      int totalChars = 0;
      bool sentenceEnded = false;

      final genParams = GenerationParams(
        maxTokens: 260,
        temp: 0.25,
        topK: 30,
        topP: 0.88,
        penalty: 1.1,
        stopSequences: const ['\n\n\n', '###', 'User:', 'Assistant:'],
      );

      final session = ChatSession(
        _engine!,
        systemPrompt: responseArabic ? _SystemPrompts.arabic : _SystemPrompts.english,
      );

      String lastVisible = '';
      await for (final chunk in session.create(
        [LlamaTextContent(fullMessage)],
        params: genParams,
        enableThinking: false,
      )) {
        if (_stopRequested) break;
        final text = chunk.choices.first.delta.content;
        if (text != null && text.isNotEmpty) {
          // ✅ تصفية الإيموجي/الرموز غير المرغوبة + ضبط اللغة
          final filtered =
              _filterUnwantedContent(text, isArabic: responseArabic);
          if (filtered.isNotEmpty) {
            yield filtered;
            totalChars += filtered.length;
            final trimmed = filtered.trimRight();
            if (trimmed.isNotEmpty) {
              lastVisible = trimmed.substring(trimmed.length - 1);
            }
          }
          // ✅ وقف عند طول مناسب بعد اكتمال جملة.
          if (totalChars >= 900) break;
          if (totalChars > 220 && !sentenceEnded) {
            final current = filtered;
            if (current.contains(RegExp(r'[.!?؟]\s*$'))) {
              sentenceEnded = true;
              break;
            }
          }
        }
      }

      if (totalChars > 0 && !RegExp(r'[.!?؟]').hasMatch(lastVisible)) {
        yield responseArabic ? '.' : '.';
      }
    } catch (e) {
      yield isArabic ? '\n⚠️ خطأ: $e' : '\n⚠️ Error: $e';
    } finally {
      _stopRequested = false;
      if (_status == AiStatus.generating) {
        _setStatus(AiStatus.ready);
      }
    }
  }

  bool _detectArabicQuestion(String text) {
    final arabicMatches = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]')
        .allMatches(text)
        .length;
    final latinMatches = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (arabicMatches == 0 && latinMatches == 0) return _isArabic;
    return arabicMatches >= latinMatches;
  }

  String _buildMessage({
    required String userMessage,
    required List<Map<String, String>> history,
    String? noteContext,
    required bool isArabic,
  }) {
    final historyLabel = isArabic ? 'السياق' : 'Conversation';
    final userLabel = isArabic ? 'المستخدم' : 'User';
    final assistantLabel = isArabic ? 'المساعد' : 'Assistant';

    final historyText = history.take(8).map((m) {
      final role = m['role'];
      final label = role == 'assistant' ? assistantLabel : userLabel;
      final content = m['content'] ?? '';
      return '$label: $content';
    }).join('\n');

    final historyBlock =
        historyText.isEmpty ? '' : '$historyLabel:\n$historyText\n\n';

    if (noteContext == null || noteContext.trim().isEmpty) {
      return '$historyBlock$userMessage';
    }

    return isArabic
        ? '$historyBlockالمذكرة الحالية:\n"""\n$noteContext\n"""\n\nسؤالي: $userMessage'
        : '${historyBlock}Current note:\n"""\n$noteContext\n"""\n\nMy question: $userMessage';
  }

  String _filterUnwantedContent(String chunk, {required bool isArabic}) {
    // إزالة الأحرف غير المرئية
    var text = chunk.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]'), '');

    if (isArabic) {
      // في وضع العربية: احتفظ بالعربية والأرقام وعلامات الترقيم فقط
      text = text.replaceAll(
        RegExp(
          r"[^0-9\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s\.\,\!\?\:\;\-\(\)\[\]\n\r«»،؛؟]",
        ),
        '',
      );
    } else {
      // في وضع الإنجليزية: احتفظ بالإنجليزية والأرقام وعلامات الترقيم فقط
      // واحذف أي نص عربي يظهر عن طريق الخطأ
      text = text.replaceAll(
        RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]'),
        '',
      );
      text = text.replaceAll(
        RegExp(r"[^0-9A-Za-z\u00C0-\u024F\s\.\,\!\?\:\;\-\(\)\[\]\n\r']"),
        '',
      );
    }

    return text;
  }

  // ─── Stop Generation ──────────────────────────────────────────
  void stopGeneration() => _stopRequested = true;

  // ─── Suggest Title ────────────────────────────────────────────
  Future<String> suggestTitle(
    String content, {
    bool isArabic = true,
  }) async {
    if (!isReady || _engine == null) return '';
    _setStatus(AiStatus.generating);
    try {
      final session = _buildTempSession(
        isArabic
            ? 'أنت مساعد يقترح عناوين قصيرة للمذكرات. أجب بالعنوان فقط بدون أي شرح.'
            : 'You suggest short note titles. Reply with the title ONLY, no explanation.',
      );
      final prompt = isArabic
          ? 'اقترح عنواناً قصيراً (3-5 كلمات) لهذه المذكرة:\n$content'
          : 'Suggest a short title (3-5 words) for this note:\n$content';
      final result = await _streamToString(session, prompt, maxLength: 80);
      return result
          .replaceAll(RegExp(r'[*#\"\n]'), '')
          .replaceAll("'", '')
          .split('\n')
          .first
          .trim();
    } catch (_) {
      return '';
    } finally {
      _safeSetReady();
    }
  }

  // ─── Summarize ────────────────────────────────────────────────
  Future<String> summarizeNote(
    String content, {
    bool isArabic = true,
  }) async {
    if (!isReady || _engine == null) return '';
    _setStatus(AiStatus.generating);
    try {
      final session = _buildTempSession(
        isArabic
            ? 'أنت مساعد يلخص المذكرات بإيجاز. أجب بالتلخيص فقط دون مقدمة.'
            : 'You summarize diary notes concisely. Reply with the summary only, no introduction.',
      );
      final prompt = isArabic
          ? 'لخّص هذه المذكرة في جملتين أو ثلاث:\n$content'
          : 'Summarize this note in 2-3 sentences:\n$content';
      return await _streamToString(session, prompt, maxLength: 500);
    } catch (_) {
      return '';
    } finally {
      _safeSetReady();
    }
  }

  // ─── Improve Text ─────────────────────────────────────────────
  Future<String> improveText(
    String content, {
    bool isArabic = true,
  }) async {
    if (!isReady || _engine == null) return content;
    _setStatus(AiStatus.generating);
    try {
      final session = _buildTempSession(
        isArabic
            ? 'أنت مساعد يحسّن أسلوب الكتابة. أعد الكتابة فقط بدون أي تعليق أو مقدمة.'
            : 'You improve writing style. Rewrite ONLY without any comment or introduction.',
      );
      final prompt = isArabic
          ? 'حسّن أسلوب هذا النص مع الحفاظ التام على المعنى:\n$content'
          : 'Improve the style of this text keeping the exact meaning:\n$content';
      final result = await _streamToString(session, prompt, maxLength: 2000);
      return result.isEmpty ? content : result;
    } catch (_) {
      return content;
    } finally {
      _safeSetReady();
    }
  }

  // ─── Suggest Tags ─────────────────────────────────────────────
  Future<List<String>> suggestTags(
    String content, {
    bool isArabic = true,
  }) async {
    if (!isReady || _engine == null) return [];
    _setStatus(AiStatus.generating);
    try {
      final session = _buildTempSession(
        isArabic
            ? 'أنت مساعد يقترح وسوماً. أجب بالوسوم مفصولة بفواصل فقط، بدون أي نص آخر.'
            : 'You suggest tags. Reply with tags separated by commas ONLY, nothing else.',
      );
      final prompt = isArabic
          ? 'اقترح 3 وسوم قصيرة لهذه المذكرة:\n$content'
          : 'Suggest 3 short tags for this note:\n$content';
      final result = await _streamToString(session, prompt, maxLength: 150);
      return result
          .split(',')
          .map((t) => t.trim().replaceAll(RegExp(r'[#*"\n\r]'), '').trim())
          .where((t) => t.isNotEmpty && t.length < 25)
          .take(3)
          .toList();
    } catch (_) {
      return [];
    } finally {
      _safeSetReady();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────
  ChatSession _buildTempSession(String systemPrompt) =>
      ChatSession(_engine!, systemPrompt: systemPrompt);

  Future<String> _streamToString(
    ChatSession session,
    String prompt, {
    int maxLength = 300,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in session.create([LlamaTextContent(prompt)])) {
      if (_stopRequested) break;
      final text = chunk.choices.first.delta.content;
      if (text != null) {
        buffer.write(text);
        // ✅ وقف مبكر عند أول نقطة أو سطر جديد بعد 100 حرف
        if (buffer.length >= maxLength) break;
        if (buffer.length > 100) {
          final s = buffer.toString();
          if (s.endsWith('.\n') || s.endsWith('!\n') || s.endsWith('؟\n')) {
            break;
          }
        }
      }
    }
    return buffer.toString().trim();
  }

  void _setStatus(AiStatus s) {
    if (_status == s) return;
    _status = s;
    _notify();
  }

  void _safeSetReady() {
    if (_status == AiStatus.generating) {
      _setStatus(AiStatus.ready);
    }
  }

  Future<void> _disposeEngine() async {
    try {
      await _engine?.dispose();
    } catch (_) {}
    _engine = null;
    _status = AiStatus.notLoaded;
  }

  Future<void> dispose() async {
    _stopRequested = true;
    await _disposeEngine();
    _listeners.clear();
  }
}

// ─────────────────────────────────────────────────────────────────
//  System Prompts
// ─────────────────────────────────────────────────────────────────
class _SystemPrompts {
  static const String arabic = '''
أنت مساعد مذكرات شخصي.
قواعد الرد:
1) أجب بالعربية الفصحى فقط.
2) أكمل المعنى بجمل طبيعية ومترابطة.
3) اجعل الرد مختصراً وواضحاً (2-5 جمل).
4) لا تستخدم إيموجي ولا Markdown.
''';

  static const String english = '''
You are a personal diary assistant.
Reply rules:
1) Answer in English only.
2) Complete ideas with natural full sentences.
3) Keep responses concise and clear (2-5 sentences).
4) No emojis and no Markdown.
''';
}

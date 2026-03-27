import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ai_model_info.dart';
import '../services/ai_service.dart';
import '../services/download_service.dart' show DownloadService;

enum ModelState {
  checking,
  needsDownload,
  connecting,
  downloading,
  paused,
  verifying,
  loading,
  ready,
  error,
}

class ModelProvider extends ChangeNotifier {
  final _aiService = AiService();
  final _downloadService = DownloadService();

  ModelState _state = ModelState.checking;
  DownloadState _downloadState = DownloadState.initial();
  String _errorMessage = '';
  bool _isArabic = true;
  bool _isDisposed = false;

  // ✅ إصلاح: retryCount منفصل لكل جلسة تنزيل
  int _sessionRetryCount = 0;

  ModelState get state => _state;
  DownloadState get downloadState => _downloadState;
  String get errorMessage => _errorMessage;
  bool get isArabic => _isArabic;

  bool get isReady => _state == ModelState.ready;
  bool get isDownloading => _state == ModelState.downloading;
  bool get isConnecting => _state == ModelState.connecting;
  bool get isLoading => _state == ModelState.loading;
  bool get isPaused => _state == ModelState.paused;
  bool get isVerifying => _state == ModelState.verifying;
  bool get hasError => _state == ModelState.error;
  bool get needsDownload => _state == ModelState.needsDownload;
  bool get isChecking => _state == ModelState.checking;
  bool get isActive => isDownloading || isConnecting || isVerifying;

  double get downloadProgress => _downloadState.progress;
  String get progressPercent =>
      '${(_downloadState.progress * 100).toStringAsFixed(1)}%';
  String get speedText => _downloadState.speedText;
  String get etaText => _downloadState.remainingTimeText;
  String get sizeProgressText =>
      '${_downloadState.downloadedText} / ${_downloadState.totalText}';
  bool get isSlowConnection => _downloadState.isSlowConnection;

  // ✅ إصلاح: retryCount يُظهر فقط عدد محاولات الجلسة الحالية
  int get retryCount => _sessionRetryCount;

  void setLanguage(bool isArabic) {
    _isArabic = isArabic;
    _aiService.setLanguage(isArabic);
    _downloadService.setLanguage(isArabic);
  }

  Future<void> checkModel() async {
    if (_isDisposed) return;
    // إذا كان النموذج محملاً بالفعل في AiService، تجنب فحوصات I/O السريعة
    // لتقليل زمن الـ Initialization عند الرجوع للتطبيق.
    if (_aiService.isReady) {
      _setState(ModelState.ready);
      return;
    }
    _setState(ModelState.checking);
    try {
      final isDownloaded = await _downloadService.isModelDownloaded();
      if (_isDisposed) return;

      if (!isDownloaded) {
        _setState(ModelState.needsDownload);
        return;
      }

      final isValid = await _downloadService.verifyModelFile();
      if (_isDisposed) return;

      if (!isValid) {
        await _downloadService.deleteModel();
        _errorMessage = _isArabic
            ? 'الملف تالف، يرجى إعادة التحميل'
            : 'File corrupted, please re-download';
        _setState(ModelState.needsDownload);
        return;
      }
      await _loadModel();
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString();
      _setState(ModelState.error);
    }
  }

  // ✅ إصلاح: startDownload يُصفِّر كل شيء
  Future<void> startDownload() async {
    // reset كامل قبل البدء
    _sessionRetryCount = 0;
    _downloadState = DownloadState.initial();
    _errorMessage = '';

    // تأكد من عدم وجود ملف جزئي قديم
    final isPartial = await _downloadService.isModelDownloaded();
    if (!_isDisposed && !isPartial) {
      // ابدأ من صفر
      await _attemptDownload(mirrorIndex: 0);
    } else if (!_isDisposed) {
      // هناك ملف — تحقق منه أولاً
      await checkModel();
    }
  }

  Future<void> _attemptDownload({
    int mirrorIndex = 0,
  }) async {
    if (_isDisposed) return;

    _setState(ModelState.connecting);
    _downloadState = _downloadState.copyWith(
      status: DownloadStatus.connecting,
      currentMirrorIndex: mirrorIndex,
    );
    _safeNotify();

    _setState(ModelState.downloading);

    await _downloadService.downloadModel(
      mirrorIndex: mirrorIndex,
      onProgress: (progress, speedBps, downloadedBytes, totalBytes) {
        if (_isDisposed) return;

        // ✅ إصلاح: تجاهل تحديثات السرعة المتذبذبة
        // فقط نحدّث إذا التقدم حقيقي (زيادة فعلية)
        final currentDownloaded = _downloadState.downloadedBytes;
        if (downloadedBytes < currentDownloaded) return;

        _downloadState = _downloadState.copyWith(
          status: DownloadStatus.downloading,
          progress: progress,
          speedBps: speedBps,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        );
        _safeNotify();
      },
      onComplete: (_) async {
        if (_isDisposed) return;
        await _onDownloadComplete();
      },
      onError: (error) async {
        if (_isDisposed) return;
        await _onDownloadError(error, mirrorIndex);
      },
    );
  }

  Future<void> _onDownloadComplete() async {
    if (_isDisposed) return;

    _setState(ModelState.verifying);
    _downloadState = _downloadState.copyWith(
      status: DownloadStatus.verifying,
      isVerifying: true,
      progress: 1.0,
    );
    _safeNotify();

    await Future.delayed(const Duration(milliseconds: 500));
    if (_isDisposed) return;

    final isValid = await _downloadService.verifyModelFile();
    if (_isDisposed) return;

    if (!isValid) {
      await _downloadService.deleteModel();
      await _onDownloadError(
        _isArabic ? 'فشل التحقق من الملف' : 'File verification failed',
        _downloadState.currentMirrorIndex,
      );
      return;
    }

    // ✅ نجح التحميل — صفّر العداد
    _sessionRetryCount = 0;

    _downloadState = _downloadState.copyWith(
      status: DownloadStatus.done,
      isVerifying: false,
    );
    _safeNotify();

    // ✅ بعد اكتمال التحميل والتهيئة، أوقف أي اتصالات Dio لتطبيق خصوصية "بدون إنترنت بعد التحميل".
    await _downloadService.closeConnection();
    await _loadModel();
  }

  Future<void> _onDownloadError(String error, int currentMirrorIndex) async {
    if (_isDisposed) return;

    // ✅ لا تعالج الخطأ إذا كان الـ state paused أو cancelled
    if (isPaused || _state == ModelState.needsDownload) return;

    _sessionRetryCount++;

    final model = AiModelInfo.defaultModel;
    final maxMirrors = model.allDownloadUrls.length;
    const maxAutoRetries = 3;

    if (_sessionRetryCount <= maxAutoRetries) {
      final nextMirror =
          currentMirrorIndex < maxMirrors - 1 ? currentMirrorIndex + 1 : 0;

      _errorMessage = _isArabic
          ? 'إعادة المحاولة $_sessionRetryCount/$maxAutoRetries...'
          : 'Retry $_sessionRetryCount/$maxAutoRetries...';

      _downloadState = _downloadState.copyWith(
        status: DownloadStatus.downloading,
        errorMessage: _errorMessage,
        retryCount: _sessionRetryCount,
        currentMirrorIndex: nextMirror,
      );
      _safeNotify();

      await Future.delayed(Duration(seconds: _sessionRetryCount * 2));
      if (_isDisposed || isPaused || _state == ModelState.needsDownload) {
        return;
      }

      await _attemptDownload(mirrorIndex: nextMirror);
    } else {
      _errorMessage = _isArabic
          ? 'تعذّر التحميل. اضغط "إعادة المحاولة".'
          : 'Download failed. Press "Retry".';

      _downloadState = DownloadState.failure(
        _errorMessage,
        retryCount: _sessionRetryCount,
      );
      _setState(ModelState.error);
    }
  }

  void pauseDownload() {
    if (!isDownloading && !isConnecting) return;

    // ✅ غيّر الـ state أولاً قبل أي شيء
    _setState(ModelState.paused);
    _downloadState = _downloadState.copyWith(
      status: DownloadStatus.paused,
    );
    _safeNotify();

    // ✅ ثم أوقف الـ service
    _downloadService.pauseDownload();
  }

  Future<void> resumeDownload() async {
    if (!isPaused) return;

    // ✅ لا تغيّر الـ state هنا — اتركه للـ onProgress
    // فقط غيّر الـ downloadState
    _downloadState = _downloadState.copyWith(
      status: DownloadStatus.downloading,
    );
    _safeNotify();

    // ✅ استأنف من نفس الـ mirror
    final mirrorIndex = _downloadState.currentMirrorIndex;

    // ✅ غيّر الـ state بعد التأكد
    _setState(ModelState.downloading);

    await _downloadService.resumeDownload(
      onProgress: (progress, speedBps, downloadedBytes, totalBytes) {
        if (_isDisposed) return;
        if (_state != ModelState.downloading) return;

        // ✅ لا تتجاهل البيانات عند الاستئناف
        _downloadState = _downloadState.copyWith(
          status: DownloadStatus.downloading,
          progress: progress,
          speedBps: speedBps,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          retryCount: _sessionRetryCount,
        );
        _safeNotify();
      },
      onComplete: (_) async {
        if (_isDisposed) return;
        await _onDownloadComplete();
      },
      onError: (error) async {
        if (_isDisposed) return;
        // ✅ لا تعالج الخطأ إذا كان الـ state paused
        if (isPaused) return;
        await _onDownloadError(error, mirrorIndex);
      },
    );
  }

  Future<void> cancelDownload() async {
    // 1. أوقف الـ service أولاً
    _downloadService.cancelDownload();

    // 2. انتظر قليلاً للتأكد من إيقاف callbacks
    await Future.delayed(const Duration(milliseconds: 200));
    if (_isDisposed) return;

    // 3. reset كامل لكل شيء
    _sessionRetryCount = 0;
    _errorMessage = '';
    _downloadState = DownloadState.initial();

    // 4. احذف الملف الجزئي لضمان بدء نظيف
    await _downloadService.deleteModel();
    if (_isDisposed) return;

    // 5. انتقل لحالة needsDownload
    _setState(ModelState.needsDownload);
  }

  Future<void> _loadModel() async {
    if (_isDisposed) return;
    _setState(ModelState.loading);
    try {
      final success = await _aiService.loadModel();
      if (_isDisposed) return;
      if (success) {
        _setState(ModelState.ready);
      } else {
        _errorMessage = _aiService.errorMessage ??
            (_isArabic ? 'فشل تهيئة النموذج' : 'Failed to initialize model');
        _setState(ModelState.error);
      }
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString();
      _setState(ModelState.error);
    }
  }

  // ✅ إصلاح: retry يُصفِّر عداد الجلسة
  Future<void> retry() async {
    _errorMessage = '';
    _sessionRetryCount = 0;
    _downloadState = DownloadState.initial();
    await checkModel();
  }

  Future<void> redownload() async {
    cancelDownload();
    await _downloadService.deleteModel();
    _sessionRetryCount = 0;
    _downloadState = DownloadState.initial();
    _setState(ModelState.needsDownload);
  }

  Future<void> deleteModel() async {
    await _downloadService.deleteModel();
    _downloadState = DownloadState.initial();
    _setState(ModelState.needsDownload);
  }

  void _setState(ModelState newState) {
    _state = newState;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _downloadService.dispose();
    super.dispose();
  }
}

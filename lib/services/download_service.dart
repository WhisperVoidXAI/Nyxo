import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';
import '../models/ai_model_info.dart';

enum DownloadStatus {
  idle,
  connecting,
  downloading,
  paused,
  verifying,
  completed,
  cancelled,
  error,
}

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  Dio _dio = Dio();
  CancelToken? _cancelToken;
  DownloadStatus _status = DownloadStatus.idle;
  bool _isArabic = true;
  int _currentMirrorIndex = 0;
  bool _resumeFromTmp = true;

  DownloadStatus get status => _status;
  bool get isDownloading => _status == DownloadStatus.downloading;
  bool get isPaused => _status == DownloadStatus.paused;
  bool get isCompleted => _status == DownloadStatus.completed;
  bool get isIdle => _status == DownloadStatus.idle;
  bool get hasError => _status == DownloadStatus.error;
  bool get isConnecting => _status == DownloadStatus.connecting;
  bool get isVerifying => _status == DownloadStatus.verifying;

  void setLanguage(bool isArabic) => _isArabic = isArabic;

  // ─── Paths ────────────────────────────────────────────────────
  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'models', AppConstants.modelFileName);
  }

  Future<String> _getTmpPath() async {
    final modelPath = await getModelPath();
    return '$modelPath.tmp';
  }

  // ─── Check ────────────────────────────────────────────────────
  Future<bool> isModelDownloaded() async {
    try {
      final path = await getModelPath();
      final file = File(path);
      if (!await file.exists()) return false;
      final size = await file.length();
      final expected = (AppConstants.modelSizeGB * 1024 * 1024 * 1024).toInt();
      return size >= (expected * 0.85);
    } catch (_) {
      return false;
    }
  }

  // ─── Verify ───────────────────────────────────────────────────
  Future<bool> verifyModelFile() async {
    try {
      final path = await getModelPath();
      final file = File(path);
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size < 50 * 1024 * 1024) return false;
      final raf = await file.open();
      try {
        final header = await raf.read(4);
        if (header.length < 4) return false;
        // GGUF magic bytes
        return header[0] == 0x47 &&
            header[1] == 0x47 &&
            header[2] == 0x55 &&
            header[3] == 0x46;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  // ─── Download ─────────────────────────────────────────────────
  Future<void> downloadModel({
    int mirrorIndex = 0,
    required void Function(double, double, int, int) onProgress,
    required void Function(String) onComplete,
    required void Function(String) onError,
  }) async {
    try {
      // Reset temporary mode after a fresh start/retry.
      if (!_resumeFromTmp) {
        _resumeFromTmp = true;
      }
      _currentMirrorIndex = mirrorIndex;
      final modelPath = await getModelPath();
      final tmpPath = await _getTmpPath();

      // إنشاء المجلد
      final modelDir = Directory(p.dirname(modelPath));
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      // ✅ تحقق من الملف النهائي أولاً
      final mainFile = File(modelPath);
      if (await mainFile.exists()) {
        final size = await mainFile.length();
        final expected =
            (AppConstants.modelSizeGB * 1024 * 1024 * 1024).toInt();
        if (size >= (expected * 0.85) && await verifyModelFile()) {
          _status = DownloadStatus.completed;
          onComplete(modelPath);
          return;
        }
        await mainFile.delete();
      }

      // ✅ قراءة الـ bytes الموجودة في الملف المؤقت
      final tmpFile = File(tmpPath);
      int existingBytes = 0;
      if (_resumeFromTmp) {
        existingBytes = await tmpFile.exists() ? await tmpFile.length() : 0;
      } else {
        // عند الإلغاء: نبدأ من الصفر ولا نستخدم tmp القديم
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
        existingBytes = 0;
      }

      // ✅ إنشاء Dio جديد لكل عملية تحميل
      _dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(hours: 4),
        sendTimeout: const Duration(minutes: 3),
        followRedirects: true,
        maxRedirects: 8,
        headers: {
          'User-Agent': 'BeyondSilence/1.0',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
        },
      ));

      // ✅ CancelToken جديد لكل عملية
      _cancelToken = CancelToken();
      _status = DownloadStatus.downloading;

      final model = AiModelInfo.defaultModel;
      final urls = model.allDownloadUrls;
      final url = urls[mirrorIndex.clamp(0, urls.length - 1)];

      await _startDownload(
        url: url,
        tmpPath: tmpPath,
        modelPath: modelPath,
        existingBytes: existingBytes,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );
    } catch (e) {
      if (_status != DownloadStatus.paused &&
          _status != DownloadStatus.cancelled) {
        _status = DownloadStatus.error;
        onError(_isArabic ? 'خطأ غير متوقع: $e' : 'Unexpected error: $e');
      }
    }
  }

  Future<void> _startDownload({
    required String url,
    required String tmpPath,
    required String modelPath,
    required int existingBytes,
    required void Function(double, double, int, int) onProgress,
    required void Function(String) onComplete,
    required void Function(String) onError,
  }) async {
    try {
      final startTime = DateTime.now();
      int lastReportedBytes = existingBytes;
      DateTime lastSpeedCalcTime = startTime;
      final List<double> speedSamples = [];

      await _dio.download(
        url,
        tmpPath,
        cancelToken: _cancelToken,
        deleteOnError: false,
        options: Options(
          headers: {
            if (existingBytes > 0) 'Range': 'bytes=$existingBytes-',
          },
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(hours: 4),
        ),
        onReceiveProgress: (received, total) {
          if (_status == DownloadStatus.paused ||
              _status == DownloadStatus.cancelled) {
            return;
          }

          final fullReceived = received + existingBytes;
          final int fullTotal = total > 0
              ? total + existingBytes
              : (AppConstants.modelSizeGB * 1024 * 1024 * 1024).toInt();

          final progress =
              fullTotal > 0 ? (fullReceived / fullTotal).clamp(0.0, 1.0) : 0.0;

          final now = DateTime.now();
          final elapsedMs = now.difference(lastSpeedCalcTime).inMilliseconds;

          double currentSpeedBps = 0;
          if (elapsedMs >= 500) {
            final bytesDiff = fullReceived - lastReportedBytes;
            if (bytesDiff > 0) {
              currentSpeedBps = bytesDiff / (elapsedMs / 1000.0);
              speedSamples.add(currentSpeedBps);
              if (speedSamples.length > 5) {
                speedSamples.removeAt(0);
              }
            }
            lastReportedBytes = fullReceived;
            lastSpeedCalcTime = now;
          } else if (speedSamples.isNotEmpty) {
            currentSpeedBps =
                speedSamples.reduce((a, b) => a + b) / speedSamples.length;
          } else {
            final totalSec = now.difference(startTime).inMilliseconds / 1000.0;
            if (totalSec > 0) {
              currentSpeedBps = (fullReceived - existingBytes) / totalSec;
            }
          }

          onProgress(progress, currentSpeedBps, fullReceived, fullTotal);
        },
      );

      // ✅ تحقق من الملف المؤقت بعد اكتمال التحميل
      if (_status == DownloadStatus.paused ||
          _status == DownloadStatus.cancelled) {
        return; // الملف المؤقت محفوظ
      }

      final tmpFile = File(tmpPath);
      if (!await tmpFile.exists()) {
        _status = DownloadStatus.error;
        onError(_isArabic
            ? 'فشل التحميل، حاول مجدداً'
            : 'Download failed, try again');
        return;
      }

      final tmpSize = await tmpFile.length();
      final expected = (AppConstants.modelSizeGB * 1024 * 1024 * 1024).toInt();

      if (tmpSize >= (expected * 0.85)) {
        // ✅ نقل الملف المؤقت إلى الملف النهائي
        await tmpFile.rename(modelPath);
        _status = DownloadStatus.completed;
        onComplete(modelPath);
      } else {
        _status = DownloadStatus.error;
        onError(_isArabic
            ? 'الملف غير مكتمل (${_fmt(tmpSize)} من ${_fmt(expected)}). حاول مجدداً.'
            : 'Incomplete file (${_fmt(tmpSize)} of ${_fmt(expected)}). Try again.');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // ✅ إيقاف مؤقت أو إلغاء — الملف المؤقت محفوظ
        if (_status == DownloadStatus.paused) return;
        if (_status == DownloadStatus.cancelled) return;
        _status = DownloadStatus.cancelled;
        return;
      }
      _status = DownloadStatus.error;
      onError(_buildError(e));
    } catch (e) {
      if (_status == DownloadStatus.paused ||
          _status == DownloadStatus.cancelled) {
        return;
      }
      _status = DownloadStatus.error;
      onError(_isArabic ? 'خطأ: $e' : 'Error: $e');
    }
  }

  // ─── Pause ────────────────────────────────────────────────────
  void pauseDownload() {
    if (!isDownloading && !isConnecting) return;
    _status = DownloadStatus.paused;
    _resumeFromTmp = true;
    // ✅ إلغاء بعد تأخير قصير لإغلاق الـ stream بأمان
    final token = _cancelToken;
    _cancelToken = CancelToken(); // جديد للاستئناف
    Future.delayed(const Duration(milliseconds: 400), () {
      token?.cancel('paused');
    });
  }

  // ─── Resume ───────────────────────────────────────────────────
  Future<void> resumeDownload({
    required void Function(double, double, int, int) onProgress,
    required void Function(String) onComplete,
    required void Function(String) onError,
  }) async {
    if (!isPaused) return;
    _status = DownloadStatus.idle; // ✅ reset قبل الاستئناف
    _resumeFromTmp = true;
    await downloadModel(
      mirrorIndex: _currentMirrorIndex,
      onProgress: onProgress,
      onComplete: onComplete,
      onError: onError,
    );
  }

  // ─── Cancel ───────────────────────────────────────────────────
  void cancelDownload() {
    _status = DownloadStatus.cancelled;
    _resumeFromTmp = false;
    _cancelToken?.cancel('cancelled by user');
    _cancelToken = CancelToken(); // ✅ جديد للمحاولة التالية
  }

  // ─── Delete ───────────────────────────────────────────────────
  Future<void> deleteModel() async {
    try {
      final path = await getModelPath();
      final file = File(path);
      if (await file.exists()) await file.delete();

      final tmpFile = File('$path.tmp');
      if (await tmpFile.exists()) await tmpFile.delete();

      _status = DownloadStatus.idle;
    } catch (_) {}
  }

  // ─── Progress ─────────────────────────────────────────────────
  Future<double> getDownloadedSizeMB() async {
    try {
      final path = await getModelPath();
      final tmpFile = File('$path.tmp');
      if (await tmpFile.exists()) {
        return await tmpFile.length() / 1024 / 1024;
      }
      final file = File(path);
      if (!await file.exists()) return 0;
      return await file.length() / 1024 / 1024;
    } catch (_) {
      return 0;
    }
  }

  Future<double> getDownloadProgress() async {
    final mb = await getDownloadedSizeMB();
    const total = AppConstants.modelSizeGB * 1024;
    return total <= 0 ? 0 : (mb / total).clamp(0.0, 1.0);
  }

  // ─── Helpers ──────────────────────────────────────────────────
  String _fmt(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _buildError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return _isArabic
            ? 'انتهت مهلة الاتصال. تحقق من الإنترنت.'
            : 'Connection timeout. Check internet.';
      case DioExceptionType.receiveTimeout:
        return _isArabic
            ? 'الاتصال بطيء جداً. حاول مجدداً.'
            : 'Too slow. Try again.';
      case DioExceptionType.connectionError:
        return _isArabic
            ? 'لا يوجد اتصال بالإنترنت.'
            : 'No internet connection.';
      case DioExceptionType.badResponse:
        return _isArabic
            ? 'خطأ من الخادم (${e.response?.statusCode}).'
            : 'Server error (${e.response?.statusCode}).';
      default:
        return _isArabic
            ? 'خطأ في الاتصال: ${e.message ?? "غير معروف"}'
            : 'Connection error: ${e.message ?? "unknown"}';
    }
  }

  Future<void> closeConnection() async {
    try {
      _dio.close(force: false);
    } catch (_) {}
  }

  void dispose() {
    _cancelToken?.cancel('disposed');
    try {
      _dio.close(force: true);
    } catch (_) {}
  }
}

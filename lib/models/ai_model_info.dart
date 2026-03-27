import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class AiModelInfo {
  final String name;
  final String nameEn;
  final String fileName;
  final String downloadUrl;
  final double sizeGB;
  final String description;
  final String descriptionEn;
  final String license;
  final bool supportsArabic;
  final bool supportsEnglish;
  final int parameters;
  final String quantization;
  final int contextWindow;
  final List<String> mirrorUrls;

  const AiModelInfo({
    required this.name,
    required this.nameEn,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeGB,
    required this.description,
    required this.descriptionEn,
    required this.license,
    required this.supportsArabic,
    required this.supportsEnglish,
    this.parameters = 3,
    this.quantization = 'Q4_K_M',
    this.contextWindow = 2048,
    this.mirrorUrls = const [],
  });

  String get sizeText => '${sizeGB.toStringAsFixed(2)} GB';
  String get sizeMBText => '${(sizeGB * 1024).toStringAsFixed(0)} MB';
  String get parametersText => '${parameters}B';

  List<String> get supportedLanguages => [
        if (supportsArabic) 'العربية',
        if (supportsEnglish) 'English',
      ];

  List<String> get allDownloadUrls => [downloadUrl, ...mirrorUrls];

  String get qualityLabel {
    switch (quantization) {
      case 'Q8_0':
        return 'جودة عالية جداً';
      case 'Q4_K_M':
        return 'جودة عالية';
      case 'Q4_K_S':
        return 'جودة متوازنة';
      case 'Q2_K':
        return 'حجم صغير';
      default:
        return quantization;
    }
  }

  String get qualityLabelEn {
    switch (quantization) {
      case 'Q8_0':
        return 'Ultra Quality';
      case 'Q4_K_M':
        return 'High Quality';
      case 'Q4_K_S':
        return 'Balanced';
      case 'Q2_K':
        return 'Small Size';
      default:
        return quantization;
    }
  }

  Color get accentColor => AppColors.primary;
  IconData get icon => Icons.psychology_rounded;

  String getDescription(bool isArabic) =>
      isArabic ? description : descriptionEn;
  String getName(bool isArabic) => isArabic ? name : nameEn;
  String getQualityLabel(bool isArabic) =>
      isArabic ? qualityLabel : qualityLabelEn;

  List<Map<String, String>> getFeatures(bool isArabic) => [
        {
          'icon': '🔒',
          'title': isArabic ? 'خصوصية تامة' : 'Full Privacy',
          'desc': isArabic
              ? 'لا ترسل بياناتك لأي خادم'
              : 'Your data never leaves the device',
        },
        {
          'icon': '⚡',
          'title': isArabic ? 'يعمل بلا إنترنت' : 'Works Offline',
          'desc':
              isArabic ? 'بعد التحميل مرة واحدة' : 'After one-time download',
        },
        {
          'icon': '🧠',
          'title': isArabic ? 'ذكاء متطور' : 'Advanced AI',
          'desc':
              isArabic ? '$parametersText معامل' : '$parametersText parameters',
        },
        {
          'icon': '💾',
          'title': isArabic ? 'حجم مناسب' : 'Compact Size',
          'desc': sizeText,
        },
      ];

  static const int chunkSizeBytes = AppConstants.downloadChunkSize;
  static const int maxRetries = AppConstants.maxDownloadRetries;
  static const int connectTimeoutSec = 30;
  static const int receiveTimeoutSec = 60;
  static const int minAcceptableSpeedBps = 10 * 1024;

  static const AiModelInfo defaultModel = AiModelInfo(
    name: 'كوين 2.5 (1.5B)',
    nameEn: 'Qwen 2.5 (1.5B)',
    fileName: AppConstants.modelFileName,
    downloadUrl: AppConstants.modelDownloadUrl,
    sizeGB: AppConstants.modelSizeGB,
    description:
        'نموذج Qwen 2.5 Instruct (~1.0GB) — أسرع في الاستجابة ويدعم العربية والإنجليزية بشكل قوي',
    descriptionEn:
        'Qwen 2.5 Instruct (~1.0GB) — faster responses with strong Arabic and English support',
    license: 'Apache-2.0',
    supportsArabic: true,
    supportsEnglish: true,
    parameters: 1,
    quantization: 'Q4_K_M',
    contextWindow: 2048,
    mirrorUrls: [
      'https://hf-mirror.com/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf',
    ],
  );

  @override
  String toString() => 'AiModelInfo($nameEn · $parametersText · $quantization)';
}

// ─────────────────────────────────────────────────────────────────
//  DOWNLOAD STATE
// ─────────────────────────────────────────────────────────────────
class DownloadState {
  final DownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final double speedBps;
  final String? errorMessage;
  final int retryCount;
  final int currentMirrorIndex;
  final bool isVerifying;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBps = 0,
    this.errorMessage,
    this.retryCount = 0,
    this.currentMirrorIndex = 0,
    this.isVerifying = false,
  });

  bool get isActive => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isDone => status == DownloadStatus.done;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isIdle => status == DownloadStatus.idle;
  bool get isConnecting => status == DownloadStatus.connecting;

  String get speedText {
    if (speedBps <= 0) return '-- KB/s';
    if (speedBps < 1024) {
      return '${speedBps.toStringAsFixed(0)} B/s';
    }
    if (speedBps < 1024 * 1024) {
      return '${(speedBps / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speedBps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String get remainingTimeText {
    if (speedBps <= 0) return '--:--';
    if (totalBytes <= 0) return '--:--';
    final remaining = totalBytes - downloadedBytes;
    if (remaining <= 0) return '00:00';
    final seconds = (remaining / speedBps).round();
    if (seconds < 0) return '--:--';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes < 60) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  String get downloadedText {
    if (downloadedBytes < 1024 * 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get totalText {
    if (totalBytes <= 0) return '--';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isSlowConnection =>
      isActive && speedBps > 0 && speedBps < AiModelInfo.minAcceptableSpeedBps;

  static const _unset = Object();

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    double? speedBps,
    Object? errorMessage = _unset,
    int? retryCount,
    int? currentMirrorIndex,
    bool? isVerifying,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBps: speedBps ?? this.speedBps,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      retryCount: retryCount ?? this.retryCount,
      currentMirrorIndex: currentMirrorIndex ?? this.currentMirrorIndex,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }

  factory DownloadState.initial() => const DownloadState();

  factory DownloadState.failure(String message, {int retryCount = 0}) =>
      DownloadState(
        status: DownloadStatus.failed,
        errorMessage: message,
        retryCount: retryCount,
      );

  @override
  String toString() =>
      'DownloadState($status · ${(progress * 100).toStringAsFixed(1)}% · $speedText)';
}

enum DownloadStatus {
  idle,
  connecting,
  downloading,
  paused,
  verifying,
  done,
  failed,
}

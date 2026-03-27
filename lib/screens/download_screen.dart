import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/router.dart';
import '../core/constants.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';
import '../core/glass_widget.dart';
import '../providers/model_provider.dart';
import '../models/ai_model_info.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _orbitCtrl;
  // ✅ إضافة: تتبع إذا تم التنقل مسبقاً لمنع استدعاء مزدوج
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  /// إلغاء كامل مع reset تام — يضمن بدء تحميل نظيف في المرة القادمة
  void _cancelAndReset(BuildContext context, ModelProvider provider) {
    provider.cancelDownload();
    // reset حالة الـ navigation لو احتجنا
    _hasNavigated = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildAnimatedBg(),
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.darkBackground),
          ),
          SafeArea(
            child: Consumer<ModelProvider>(
              builder: (context, provider, _) {
                if (provider.state == ModelState.ready && !_hasNavigated) {
                  _hasNavigated = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, AppRouter.home);
                    }
                  });
                }
                // ✅ إصلاح الانحراف: LayoutBuilder + Center يضمن التمركز على جميع الشاشات
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 28),
                                _buildHeader(context, loc, provider),
                                const SizedBox(height: 28),
                                _buildContent(context, loc, provider),
                                const SizedBox(height: 24),
                                _buildFooter(context, loc, provider),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBg() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) => Stack(
        children: [
          PositionedDirectional(
            top: -100 + _bgCtrl.value * 40,
            end: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: 0.05 + _bgCtrl.value * 0.03),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -80 + _bgCtrl.value * 30,
            start: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan
                    .withValues(alpha: 0.03 + _bgCtrl.value * 0.02),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations loc,
    ModelProvider provider,
  ) {
    final isActive = provider.isDownloading ||
        provider.isPaused ||
        provider.isConnecting ||
        provider.isVerifying;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _orbitCtrl.value * 6.2832,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            GlowPulse(
              glowColor: AppColors.primary,
              blurRadius: 40,
              active: isActive,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: AppGradients.aurora,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.50),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.22),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getStateIcon(provider),
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            if (isActive)
              SizedBox(
                width: 138,
                height: 138,
                child: CircularProgressIndicator(
                  value: provider.isConnecting || provider.isVerifying
                      ? null
                      : provider.downloadProgress,
                  strokeWidth: 2.5,
                  backgroundColor: AppColors.darkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    provider.isVerifying ? AppColors.mint : AppColors.cyan,
                  ),
                ),
              ),
          ],
        ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
        const SizedBox(height: 28),
        ShaderMask(
          shaderCallback: (b) => AppGradients.primary.createShader(b),
          child: Text(
            _getStateTitle(loc, provider),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
        const SizedBox(height: 8),
        Text(
          loc.translate('downloadSubtitle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 320.ms),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _FeatureBadge(
              label: loc.isArabic ? '🔒 خصوصية تامة' : '🔒 Full Privacy',
              color: AppColors.mint,
            ),
            _FeatureBadge(
              label: loc.isArabic ? '⚡ بلا إنترنت' : '⚡ Offline',
              color: AppColors.primary,
            ),
            _FeatureBadge(
              label: loc.isArabic ? '🧠 ذكاء اصطناعي' : '🧠 AI Powered',
              color: AppColors.gold,
            ),
            _FeatureBadge(
              label: '${AppConstants.modelSizeGB} GB',
              color: AppColors.rose,
            ),
          ],
        ).animate().fadeIn(delay: 440.ms),
      ],
    );
  }

  IconData _getStateIcon(ModelProvider provider) {
    if (provider.isConnecting) return Icons.wifi_rounded;
    if (provider.isVerifying) return Icons.verified_rounded;
    if (provider.isLoading) return Icons.memory_rounded;
    if (provider.hasError) return Icons.error_outline_rounded;
    return Icons.auto_awesome_rounded;
  }

  String _getStateTitle(AppLocalizations loc, ModelProvider provider) {
    if (provider.isConnecting) {
      return loc.isArabic ? 'جاري الاتصال...' : 'Connecting...';
    }
    if (provider.isVerifying) {
      return loc.isArabic ? 'التحقق من الملف...' : 'Verifying file...';
    }
    if (provider.isLoading) {
      return loc.isArabic ? 'تهيئة الذكاء الاصطناعي...' : 'Initializing AI...';
    }
    if (provider.hasError) {
      return loc.isArabic ? 'حدث خطأ' : 'An error occurred';
    }
    return loc.translate('downloadTitle');
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations loc,
    ModelProvider provider,
  ) {
    switch (provider.state) {
      case ModelState.needsDownload:
        return _buildModelCard(context, loc, provider)
            .animate()
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.08);
      case ModelState.connecting:
        return _buildConnectingState(context, loc).animate().fadeIn();
      case ModelState.downloading:
      case ModelState.paused:
        return _buildDownloadProgress(context, loc, provider)
            .animate()
            .fadeIn();
      case ModelState.verifying:
        return _buildVerifyingState(context, loc).animate().fadeIn();
      case ModelState.loading:
        return _buildLoadingState(context, loc).animate().fadeIn();
      case ModelState.error:
        return _buildErrorState(context, loc, provider).animate().fadeIn();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildModelCard(
    BuildContext context,
    AppLocalizations loc,
    ModelProvider provider,
  ) {
    const model = AiModelInfo.defaultModel;
    final isArabic = loc.isArabic;

    return PremiumGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppConstants.radiusXL,
      borderGradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.cyan, AppColors.mint],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.padMD),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x1A6C63FF), Colors.transparent],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusXL - 1.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppGradients.aurora,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.40),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.getName(isArabic),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryDark,
                                ),
                      ),
                      Text(
                        '${model.parametersText} · ${model.quantization} · ${model.sizeText}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHintDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.mint, AppColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    model.getQualityLabel(isArabic),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.darkBorder.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.padMD),
            child: Column(
              children: model.getFeatures(isArabic).asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ModelFeatureRow(
                    emoji: e.value['icon']!,
                    title: e.value['title']!,
                    desc: e.value['desc']!,
                    index: e.key,
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppConstants.radiusXL - 1.2),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.isArabic
                        ? 'يتطلب اتصالاً بالإنترنت مرة واحدة فقط لتحميل النموذج (${model.sizeText})'
                        : 'Requires internet once to download the model (${model.sizeText})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gold,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingState(BuildContext context, AppLocalizations loc) {
    return GlassCard(
      borderRadius: AppConstants.radiusXL,
      padding: const EdgeInsets.all(AppConstants.padLG),
      child: Column(
        children: [
          PulseWidget(
            active: true,
            glowColor: AppColors.cyan,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_rounded,
                  color: AppColors.cyan, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.isArabic
                ? 'جاري الاتصال بالخادم...'
                : 'Connecting to server...',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.cyan),
          ),
          const SizedBox(height: 8),
          Text(
            loc.isArabic
                ? 'يتحقق من أسرع مسار متاح'
                : 'Finding the fastest available path',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    AppLocalizations loc,
    ModelProvider provider,
  ) {
    return Column(
      children: [
        PremiumGlassCard(
          padding: const EdgeInsets.all(AppConstants.padLG),
          borderRadius: AppConstants.radiusXL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isSlowConnection)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.slow_motion_video_rounded,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.isArabic
                              ? 'الاتصال بطيء — سنحاول Mirror بديل تلقائياً'
                              : 'Slow connection — will try a mirror automatically',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.progressPercent,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        provider.sizeProgressText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        provider.speedText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    widthFactor: provider.downloadProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: provider.isPaused
                            ? const LinearGradient(
                                colors: [AppColors.gold, AppColors.gold])
                            : AppGradients.primary,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: (provider.isPaused
                                    ? AppColors.gold
                                    : AppColors.primary)
                                .withValues(alpha: 0.50),
                            blurRadius: 8,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        provider.isPaused
                            ? Icons.pause_circle_rounded
                            : Icons.timer_rounded,
                        size: 13,
                        color: provider.isPaused
                            ? AppColors.gold
                            : AppColors.textHintDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        provider.isPaused
                            ? (loc.isArabic ? 'متوقف مؤقتاً' : 'Paused')
                            : '${loc.translate('downloadRemaining')}: ${provider.etaText}',
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.isPaused
                              ? AppColors.gold
                              : AppColors.textHintDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (provider.retryCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        loc.isArabic
                            ? 'محاولة ${provider.retryCount}'
                            : 'Retry ${provider.retryCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.rose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingState(BuildContext context, AppLocalizations loc) {
    return GlassCard(
      borderRadius: AppConstants.radiusXL,
      padding: const EdgeInsets.all(AppConstants.padLG),
      child: Column(
        children: [
          PulseWidget(
            active: true,
            glowColor: AppColors.mint,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppColors.mint, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.isArabic
                ? 'التحقق من سلامة الملف...'
                : 'Verifying file integrity...',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.mint),
          ),
          const SizedBox(height: 8),
          Text(
            loc.isArabic
                ? 'لحظة واحدة للتأكد من اكتمال التحميل'
                : 'A moment to confirm the download is complete',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        borderRadius: AppConstants.radiusXL,
        padding: const EdgeInsets.all(AppConstants.padLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GlowPulse(
              glowColor: AppColors.primary,
              blurRadius: 28,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.memory_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => AppGradients.primary.createShader(
                Rect.fromLTWH(0, 0, 300, 40),
              ),
              child: Text(
                loc.isArabic
                    ? 'جاري تهيئة الذكاء الاصطناعي...'
                    : 'Initializing AI...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.isArabic
                  ? 'قد يستغرق هذا لحظة واحدة'
                  : 'This might take a moment',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations loc,
    ModelProvider provider,
  ) {
    return GlassCard(
      borderRadius: AppConstants.radiusXL,
      padding: const EdgeInsets.all(AppConstants.padLG),
      showGlow: true,
      glowColor: AppColors.rose,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.rose.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.rose, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            loc.isArabic ? 'فشل التحميل' : 'Download failed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.rose,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (provider.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkElevated,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Text(
                provider.errorMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.rose.withValues(alpha: 0.85),
                      height: 1.55,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations loc,
    ModelProvider provider,
  ) {
    switch (provider.state) {
      case ModelState.needsDownload:
        return Column(
          children: [
            _GradientButton(
              label: loc.translate('downloadStart'),
              icon: Icons.download_rounded,
              onTap: () => provider.startDownload(),
              gradient: AppGradients.primary,
            ).animate().fadeIn(delay: 520.ms).slideY(begin: 0.1),
            const SizedBox(height: 14),
            Text(
              loc.isArabic
                  ? '⚡ يعمل عبر Mirror سريع عند الحاجة'
                  : '⚡ Uses fast mirror when needed',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textHintDark),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 620.ms),
          ],
        );

      case ModelState.downloading:
        return _OutlineButton(
          label: loc.isArabic ? 'إلغاء التحميل' : 'Cancel Download',
          icon: Icons.cancel_outlined,
          color: AppColors.rose,
          onTap: () => _cancelAndReset(context, provider),
        ).animate().fadeIn();

      case ModelState.paused:
        return _OutlineButton(
          label: loc.isArabic ? 'إلغاء التحميل' : 'Cancel Download',
          icon: Icons.cancel_outlined,
          color: AppColors.rose,
          onTap: () => _cancelAndReset(context, provider),
        ).animate().fadeIn();

      case ModelState.error:
        return Column(
          children: [
            _GradientButton(
              label: loc.isArabic ? 'إعادة المحاولة' : 'Retry',
              icon: Icons.refresh_rounded,
              onTap: () => provider.startDownload(),
              gradient: AppGradients.primary,
            ),
            const SizedBox(height: 12),
            _OutlineButton(
              label: loc.isArabic ? 'إلغاء التحميل' : 'Cancel Download',
              icon: Icons.cancel_outlined,
              color: AppColors.rose,
              onTap: () => _cancelAndReset(context, provider),
            ),
          ],
        ).animate().fadeIn();

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Gradient Button ──────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final LinearGradient gradient;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.42),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outline Button ───────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: color.withValues(alpha: 0.38),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Badge ────────────────────────────────────────────────
class _FeatureBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _FeatureBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Model Feature Row ────────────────────────────────────────────
class _ModelFeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final int index;

  const _ModelFeatureRow({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
              ),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
          delay: Duration(milliseconds: 100 + index * 60),
        );
  }
}

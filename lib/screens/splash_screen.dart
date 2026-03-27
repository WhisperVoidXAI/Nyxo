import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/router.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';
import '../core/constants.dart';
import '../providers/model_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/app_lock_provider.dart';
import '../services/database_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _rotateCtrl2;
  late AnimationController _shimmerCtrl;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.darkBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _rotateCtrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _initialize();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _rotateCtrl2.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  bool _navigationDone = false;

  Future<void> _initialize() async {
    final localeProvider = context.read<LocaleProvider>();

    // انتظر تحميل اللغة
    while (!localeProvider.isLoaded) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    // الحد الأدنى لوقت العرض
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted || _navigationDone) return;

    // ✅ إذا كان قفل التطبيق مفعّلاً، امنع الدخول قبل أي تنقل.
    final lock = context.read<AppLockProvider>();
    if (lock.isEnabled && lock.hasPin) {
      await _showLockDialog();
      if (!mounted || _navigationDone) return;
    }

    final lastRoute = DatabaseService().getSetting<String>(
      AppConstants.lastRouteKey,
      defaultValue: AppRouter.home,
    );
    final nextRoute =
        _isSupportedRestoreRoute(lastRoute) ? lastRoute! : AppRouter.home;

    final modelProvider = context.read<ModelProvider>();

    // ✅ إذا النموذج جاهز بالفعل في الذاكرة — انتقل فوراً بدون I/O
    if (modelProvider.isReady) {
      _navigateTo(nextRoute);
      return;
    }

    // فحص النموذج مرة واحدة فقط
    await modelProvider.checkModel();
    if (!mounted || _navigationDone) return;

    if (modelProvider.isReady) {
      _navigateTo(nextRoute);
    } else {
      _navigateTo(AppRouter.download);
    }
  }

  Future<void> _showLockDialog() async {
    if (!mounted || _navigationDone) return;

    final pinCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Beyond Silence'),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: 'Enter PIN',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final appLock = context.read<AppLockProvider>();
                if (appLock.verify(pinCtrl.text.trim())) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
  }

  bool _isSupportedRestoreRoute(String? route) {
    return route == AppRouter.home ||
        route == AppRouter.chat ||
        route == AppRouter.tasks;
  }

  void _navigateTo(String route) {
    if (_navigationDone || !mounted) return;
    _navigationDone = true;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final loc = AppLocalizations(localeProvider.locale);
    final localeCode = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      // ✅ إصلاح: SizedBox.expand لملء الشاشة كاملاً
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.darkBackground,
          ),
          child: Stack(
            children: [
              _buildBackground(),
              // ✅ إصلاح: Center لتمركز المحتوى على جميع الشاشات
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          _buildLogo(),
                          const SizedBox(height: 40),
                          _buildTitleSection(context, loc, localeCode),
                          const SizedBox(height: 60),
                          _buildLoadingSection(context, loc, localeCode),
                          const SizedBox(height: 56),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        PositionedDirectional(
          top: -120,
          end: -120,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.05 + _pulseCtrl.value * 0.04,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: -100,
          start: -80,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(
                  alpha: 0.03 + _pulseCtrl.value * 0.025,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 120,
          start: 40,
          child: FloatWidget(
            amplitude: 10,
            child: _buildFloatingOrb(AppColors.primary, 6, 0.4),
          ),
        ),
        PositionedDirectional(
          top: 200,
          end: 60,
          child: FloatWidget(
            amplitude: 8,
            period: const Duration(seconds: 4),
            child: _buildFloatingOrb(AppColors.cyan, 5, 0.35),
          ),
        ),
        PositionedDirectional(
          top: 380,
          start: 90,
          child: FloatWidget(
            amplitude: 12,
            period: const Duration(seconds: 5),
            child: _buildFloatingOrb(AppColors.gold, 4, 0.30),
          ),
        ),
        PositionedDirectional(
          bottom: 220,
          end: 50,
          child: FloatWidget(
            amplitude: 9,
            period: const Duration(seconds: 3),
            child: _buildFloatingOrb(AppColors.primary, 5, 0.40),
          ),
        ),
        PositionedDirectional(
          bottom: 320,
          start: 50,
          child: FloatWidget(
            amplitude: 11,
            period: const Duration(seconds: 4),
            child: _buildFloatingOrb(AppColors.rose, 4, 0.30),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _rotateCtrl2,
            builder: (_, __) => Transform.rotate(
              angle: -_rotateCtrl2.value * 2 * pi,
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingOrb(Color color, double size, double opacity) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        width: size + _pulseCtrl.value * 2,
        height: size + _pulseCtrl.value * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity + _pulseCtrl.value * 0.12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FloatWidget(
      amplitude: 6,
      period: const Duration(seconds: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotateCtrl.value * 2 * pi,
              child: child,
            ),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 148 + _pulseCtrl.value * 10,
              height: 148 + _pulseCtrl.value * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.05 + _pulseCtrl.value * 0.04,
                ),
              ),
            ),
          ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              gradient: AppGradients.aurora,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.60),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.25),
                  blurRadius: 22,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 56,
            ),
          )
              .animate()
              .scale(
                duration: 700.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTitleSection(
    BuildContext context,
    AppLocalizations loc,
    String localeCode,
  ) {
    return Column(
      // ✅ إصلاح: تمركز كامل لجميع العناصر
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Beyond Silence',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                fontSize: 32,
              ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          softWrap: true,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.06),
        const SizedBox(height: 10),
        Text(
          loc.tr('appTagline'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                letterSpacing: 2.5,
                color: AppColors.textSecondaryDark,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 580.ms),
        const SizedBox(height: 28),
        // ✅ إصلاح: Wrap بدلاً من Row لتجنب overflow
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: [
            _FeaturePill(
              icon: Icons.lock_rounded,
              label: localeCode == 'ar' ? 'خصوصية تامة' : 'Full Privacy',
              color: AppColors.mint,
            ),
            _FeaturePill(
              icon: Icons.wifi_off_rounded,
              label: localeCode == 'ar' ? 'بلا إنترنت' : 'Offline',
              color: AppColors.primary,
            ),
            const _FeaturePill(
              icon: Icons.psychology_rounded,
              label: 'AI',
              color: AppColors.gold,
            ),
            const _FeaturePill(
              icon: Icons.language_rounded,
              label: 'AR · EN',
              color: AppColors.rose,
            ),
          ],
        ).animate().fadeIn(delay: 760.ms).slideY(begin: 0.08),
      ],
    );
  }

  Widget _buildLoadingSection(
    BuildContext context,
    AppLocalizations loc,
    String localeCode,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.darkElevated,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) => LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withValues(
                    alpha: 0.6 + _shimmerCtrl.value * 0.4,
                  ),
                ),
                minHeight: 3,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 1000.ms),
        const SizedBox(height: 20),
        _LoadingDots(
          text: localeCode == 'ar' ? 'جاري التهيئة' : 'Initializing',
        ).animate().fadeIn(delay: 1100.ms),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    AppConstants.modelName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textHintDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: const TextStyle(
                      color: AppColors.textHintDark,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 1250.ms),
      ],
    );
  }
}

// ─── Dashed Circle Painter ────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 28;
    const gap = 0.22;

    for (int i = 0; i < dashCount; i++) {
      final start = i * 2 * pi / dashCount;
      const sweep = (2 * pi / dashCount) - gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

// ─── Feature Pill ─────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.24),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading Dots ─────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  final String text;
  const _LoadingDots({required this.text});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final dots = (_ctrl.value * 3).ceil() % 4;
        return Text(
          '${widget.text}${'.' * dots}',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

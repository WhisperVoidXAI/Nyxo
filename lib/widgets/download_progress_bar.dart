import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../core/animations_helper.dart';
import '../core/app_gradients.dart';
import '../core/constants.dart';
import '../models/ai_model_info.dart';

class DownloadProgressBar extends StatelessWidget {
  final double progress;
  final double speedMBps;
  final String eta;
  final double modelSizeGB;
  final bool isPaused;
  final int retryCount;
  final bool isSlowConnection;

  const DownloadProgressBar({
    super.key,
    required this.progress,
    required this.speedMBps,
    required this.eta,
    required this.modelSizeGB,
    this.isPaused = false,
    this.retryCount = 0,
    this.isSlowConnection = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadedGB = progress * modelSizeGB;
    final percent = (progress * 100).clamp(0.0, 100.0);

    return Column(
      children: [
        _buildCircularProgress(context, percent, isDark)
            .animate()
            .scale(duration: 700.ms, curve: Curves.elasticOut)
            .fadeIn(),
        const SizedBox(height: 28),
        _buildLinearProgress(isDark)
            .animate()
            .fadeIn(delay: 200.ms)
            .slideY(begin: 0.1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${downloadedGB.toStringAsFixed(2)} GB',
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? AppColors.textHintDark : AppColors.textHintLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${modelSizeGB.toStringAsFixed(2)} GB',
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? AppColors.textHintDark : AppColors.textHintLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 260.ms),
        const SizedBox(height: 20),
        if (isSlowConnection && !isPaused)
          _buildSlowConnectionWarning(context, loc)
              .animate()
              .fadeIn(delay: 280.ms),
        _buildInfoCards(context, loc, downloadedGB)
            .animate()
            .fadeIn(delay: 350.ms)
            .slideY(begin: 0.08),
        if (retryCount > 0)
          _buildRetryIndicator(context, loc).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildCircularProgress(
    BuildContext context,
    double percent,
    bool isDark,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isPaused ? 0.06 : 0.20,
                ),
                blurRadius: 55,
                spreadRadius: 12,
              ),
              BoxShadow(
                color: AppColors.cyan.withValues(
                  alpha: isPaused ? 0.03 : 0.10,
                ),
                blurRadius: 35,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        CircularPercentIndicator(
          radius: 92,
          lineWidth: 11,
          percent: progress.clamp(0.0, 1.0),
          backgroundColor:
              isDark ? AppColors.darkElevated : AppColors.lightElevated,
          linearGradient: isPaused
              ? LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.60),
                    AppColors.gold.withValues(alpha: 0.40),
                  ],
                )
              : isSlowConnection
                  ? LinearGradient(
                      colors: [
                        AppColors.gold,
                        AppColors.gold.withValues(alpha: 0.70),
                      ],
                    )
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animateFromLastPercent: true,
          animationDuration: 700,
          center: _buildCircleCenter(context, percent),
        ),
      ],
    );
  }

  Widget _buildCircleCenter(BuildContext context, double percent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPaused) ...[
          const Icon(
            Icons.pause_circle_rounded,
            color: AppColors.gold,
            size: 22,
          ),
          const SizedBox(height: 4),
        ],
        ShaderMask(
          shaderCallback: (bounds) =>
              (isPaused ? AppGradients.ideas : AppGradients.primary)
                  .createShader(bounds),
          child: Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 5),
        isPaused
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_rounded,
                        size: 9, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text(
                      AppLocalizations.of(context).isArabic
                          ? 'متوقف'
                          : 'Paused',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : _SpeedBadge(speedMBps: speedMBps),
      ],
    );
  }

  Widget _buildLinearProgress(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkElevated : AppColors.lightElevated,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: isPaused
                      ? LinearGradient(colors: [
                          AppColors.gold.withValues(alpha: 0.65),
                          AppColors.gold.withValues(alpha: 0.45),
                        ])
                      : isSlowConnection
                          ? const LinearGradient(
                              colors: [AppColors.gold, AppColors.primary],
                            )
                          : AppGradients.primary,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: (isPaused ? AppColors.gold : AppColors.primary)
                          .withValues(alpha: isPaused ? 0.30 : 0.50),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlowConnectionWarning(
    BuildContext context,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
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
                  ? 'الاتصال بطيء — سنتحول لمسار أسرع تلقائياً'
                  : 'Slow connection — will auto-switch to a faster path',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.gold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(
    BuildContext context,
    AppLocalizations loc,
    double downloadedGB,
  ) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.speed_rounded,
            label: loc.translate('downloadSpeed'),
            value: _formatSpeed(speedMBps),
            color: AppColors.primary,
            isPaused: isPaused,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            icon: Icons.timer_outlined,
            label: loc.translate('downloadRemaining'),
            value: isPaused ? '--:--' : eta,
            color: AppColors.gold,
            isPaused: isPaused,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            icon: Icons.storage_rounded,
            label: loc.translate('downloadSize'),
            value:
                '${downloadedGB.toStringAsFixed(2)}/${modelSizeGB.toStringAsFixed(1)}G',
            color: AppColors.cyan,
            isPaused: isPaused,
          ),
        ),
      ],
    );
  }

  Widget _buildRetryIndicator(BuildContext context, AppLocalizations loc) {
    // ✅ إصلاح: استخدام AiModelInfo.maxRetries بدلاً من رقم ثابت
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.rose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(
          color: AppColors.rose.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.refresh_rounded, size: 13, color: AppColors.rose),
          const SizedBox(width: 6),
          Text(
            loc.isArabic
                ? 'إعادة المحاولة $retryCount/${AiModelInfo.maxRetries}'
                : 'Retry $retryCount/${AiModelInfo.maxRetries}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.rose,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double mbps) {
    if (mbps <= 0) return '-- KB/s';
    if (mbps < 1) return '${(mbps * 1024).toStringAsFixed(0)} KB/s';
    return '${mbps.toStringAsFixed(1)} MB/s';
  }
}

// ─── Speed Badge ──────────────────────────────────────────────────
class _SpeedBadge extends StatelessWidget {
  final double speedMBps;
  const _SpeedBadge({required this.speedMBps});

  @override
  Widget build(BuildContext context) {
    final isActive = speedMBps > 0.01;
    return PulseWidget(
      active: isActive,
      glowColor: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isActive ? AppGradients.primary : null,
          color: isActive ? null : AppColors.darkElevated,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              color: isActive ? Colors.white : AppColors.textHintDark,
              size: 11,
            ),
            const SizedBox(width: 4),
            Text(
              speedMBps <= 0
                  ? '-- KB/s'
                  : speedMBps < 1
                      ? '${(speedMBps * 1024).toStringAsFixed(0)} KB/s'
                      : '${speedMBps.toStringAsFixed(1)} MB/s',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textHintDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isPaused;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAlpha = isPaused ? 0.5 : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: isPaused ? 0.04 : 0.09)
                : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: color.withValues(alpha: isPaused ? 0.10 : 0.22),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isPaused ? 0.03 : 0.08),
                blurRadius: 10,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isPaused ? 0.06 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color.withValues(alpha: effectiveAlpha),
                  size: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color:
                      isDark ? AppColors.textHintDark : AppColors.textHintLight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color.withValues(alpha: effectiveAlpha),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

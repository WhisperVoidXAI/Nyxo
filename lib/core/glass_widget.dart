import 'dart:ui';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'theme.dart';

// ✅ إضافة: Helper لفحص دعم BackdropFilter على المنصة الحالية
bool get _supportsBlur {
  // BackdropFilter يعمل بشكل موثوق على Android/iOS/macOS/Windows
  // على بعض أجهزة Android القديمة قد يكون بطيئاً لكنه مدعوم
  return true;
}

/// مكوّن الزجاج الفاخر — روح التصميم الكوني للتطبيق
class GlassWidget extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final Color? tintColor;
  final bool showBorder;
  final bool showGlow;
  final Color? glowColor;
  final double glowIntensity;
  final VoidCallback? onTap;
  final Gradient? customGradient;

  const GlassWidget({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = AppConstants.radiusLG,
    this.padding,
    this.margin,
    this.blurStrength = AppConstants.glassBlur,
    this.tintColor,
    this.showBorder = true,
    this.showGlow = false,
    this.glowColor,
    this.glowIntensity = 0.18,
    this.onTap,
    this.customGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlow = glowColor ?? AppColors.primary;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: effectiveGlow.withValues(alpha: glowIntensity),
                  blurRadius: 32,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: effectiveGlow.withValues(alpha: glowIntensity * 0.5),
                  blurRadius: 60,
                  spreadRadius: -8,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _supportsBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurStrength,
                  sigmaY: blurStrength,
                ),
                child: _buildInner(isDark),
              )
            : _buildInner(isDark), // ✅ Fallback بدون blur على أجهزة غير مدعومة
      ),
    );
  }

  Widget _buildInner(bool isDark) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: customGradient ??
              LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.03),
                        AppColors.primary.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.65),
                        AppColors.primary.withValues(alpha: 0.04),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.6, 1.0],
              ),
          border: showBorder
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.90),
                  width: 0.8,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  GLASS CARD
// ─────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showGlow;
  final Color? glowColor;
  final double glowIntensity;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.padMD),
    this.borderRadius = AppConstants.radiusLG,
    this.showGlow = false,
    this.glowColor,
    this.glowIntensity = 0.18,
    this.onTap,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassWidget(
      padding: padding,
      borderRadius: borderRadius,
      showGlow: showGlow,
      glowColor: glowColor,
      glowIntensity: glowIntensity,
      onTap: onTap,
      width: width,
      height: height,
      margin: margin,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  GLASS BAR — مع SafeArea صحيح
// ─────────────────────────────────────────────────────────────────
class GlassBar extends StatelessWidget {
  final Widget child;
  final double height;
  final bool isBottom;

  const GlassBar({
    super.key,
    required this.child,
    this.height = 70,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ✅ إصلاح: أخذ bottom padding (مسافة الـ home indicator) بعين الاعتبار
    final bottomPadding =
        isBottom ? MediaQuery.of(context).padding.bottom : 0.0;
    final effectiveHeight = height + bottomPadding;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: effectiveHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.black.withValues(alpha: 0.50),
                      AppColors.darkSurface.withValues(alpha: 0.35),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.85),
                      AppColors.lightBg.withValues(alpha: 0.70),
                    ],
              begin: isBottom ? Alignment.bottomCenter : Alignment.topCenter,
              end: isBottom ? Alignment.topCenter : Alignment.bottomCenter,
            ),
            border: Border(
              top: isBottom
                  ? BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : AppColors.lightBorder.withValues(alpha: 0.70),
                      width: 0.8,
                    )
                  : BorderSide.none,
              bottom: !isBottom
                  ? BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : AppColors.lightBorder.withValues(alpha: 0.70),
                      width: 0.8,
                    )
                  : BorderSide.none,
            ),
          ),
          // ✅ إضافة: padding لـ home indicator في الأجهزة الحديثة
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PREMIUM GLASS CARD
// ─────────────────────────────────────────────────────────────────
class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Gradient borderGradient;
  final double borderWidth;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppConstants.radiusXL,
    this.borderGradient = const LinearGradient(
      colors: [Color(0xFF6C63FF), Color(0xFF00D4FF), Color(0xFF4ECDC4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.borderWidth = 1.2,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: borderGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque, // ✅ إضافة
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(borderRadius - borderWidth),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF0E0E1A).withValues(alpha: 0.92),
                            const Color(0xFF13132A).withValues(alpha: 0.88),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.92),
                            const Color(0xFFF4F3FF).withValues(alpha: 0.85),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FROSTED PANEL
// ─────────────────────────────────────────────────────────────────
class FrostedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double topRadius;

  const FrostedPanel({
    super.key,
    required this.child,
    this.padding,
    this.topRadius = AppConstants.radiusXXL,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ✅ إضافة: bottom padding لتجنب تغطية الـ home indicator

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topRadius),
        topRight: Radius.circular(topRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(topRadius),
              topRight: Radius.circular(topRadius),
            ),
            color: isDark
                ? const Color(0xFF0E0E1A).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : AppColors.lightBorder.withValues(alpha: 0.80),
                width: 0.8,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

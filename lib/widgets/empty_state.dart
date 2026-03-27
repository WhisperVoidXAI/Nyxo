import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/animations_helper.dart';
import '../core/constants.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final Widget? customIcon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconSection(context, color, isDark)
                .animate()
                .scale(duration: 700.ms, curve: Curves.elasticOut)
                .fadeIn(),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [color, AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.7,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 320.ms),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 40),
              _buildButton(context, color)
                  .animate()
                  .fadeIn(delay: 450.ms)
                  .slideY(begin: 0.15)
                  .scale(delay: 450.ms, curve: Curves.elasticOut),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection(
    BuildContext context,
    Color color,
    bool isDark,
  ) {
    return FloatWidget(
      amplitude: 7,
      period: const Duration(seconds: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (i) {
            final size = 76.0 + (i * 32);
            final alpha = 0.14 - (i * 0.04);
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: alpha),
                  width: 1,
                ),
              ),
            );
          }),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.22),
                      color.withValues(alpha: 0.06),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                ),
                child: customIcon ?? Icon(icon, size: 42, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, Color color) {
    return PressScale(
      onTap: onButtonPressed,
      child: Container(
        width: 240,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, AppColors.cyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.40),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              buttonText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

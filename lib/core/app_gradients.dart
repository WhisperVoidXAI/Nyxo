import 'package:flutter/material.dart';
import 'theme.dart';

/// مكتبة التدرجات اللونية الكونية الفاخرة
class AppGradients {
  AppGradients._();

  // ─── Primary Gradients ───────────────────────────────────────
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVertical = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42CC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient aurora = LinearGradient(
    colors: [
      Color(0xFF6C63FF),
      Color(0xFF9C6FFF),
      Color(0xFF00D4FF),
      Color(0xFF4ECDC4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  static const LinearGradient cosmic = LinearGradient(
    colors: [
      Color(0xFF1A0533),
      Color(0xFF6C63FF),
      Color(0xFF00D4FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient nebula = LinearGradient(
    colors: [
      Color(0xFF6C63FF),
      Color(0xFFFF6B8A),
      Color(0xFFFFD700),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient midnight = LinearGradient(
    colors: [
      Color(0xFF07070F),
      Color(0xFF0D0D1E),
      Color(0xFF13132A),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Background Gradients ────────────────────────────────────
  static const LinearGradient darkBackground = LinearGradient(
    colors: [
      Color(0xFF07070F),
      Color(0xFF0A0A18),
      Color(0xFF0D0D1E),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient lightBackground = LinearGradient(
    colors: [
      Color(0xFFF4F3FF),
      Color(0xFFEDE9FF),
      Color(0xFFE8E4FF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient background(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  // ─── Card Gradients ──────────────────────────────────────────
  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0x1C6C63FF), Color(0x0A9C6FFF), Color(0x0500D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient lightCard = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F6FF), Color(0xFFF0EEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient card(bool isDark) => isDark ? darkCard : lightCard;

  // ─── Premium Card Overlays ───────────────────────────────────
  static const LinearGradient premiumOverlay = LinearGradient(
    colors: [
      Color(0x226C63FF),
      Color(0x1100D4FF),
      Colors.transparent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient glassOverlay = LinearGradient(
    colors: [
      Color(0x18FFFFFF),
      Color(0x08FFFFFF),
      Color(0x04FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ─── Category Gradients ──────────────────────────────────────
  static const LinearGradient personal = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9C6FFF), Color(0xFFB8A0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient work = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0096C7), Color(0xFF005F8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient ideas = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF9500), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient health = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFFF4757), Color(0xFFCC2233)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient travel = LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D), Color(0xFF2D7D6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient other = LinearGradient(
    colors: [Color(0xFFB8B5FF), Color(0xFF8E8BCC), Color(0xFF6E6AAA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static LinearGradient forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return personal;
      case 'work':
        return work;
      case 'ideas':
        return ideas;
      case 'health':
        return health;
      case 'travel':
        return travel;
      default:
        return other;
    }
  }

  // ─── Mood Gradients ──────────────────────────────────────────
  static LinearGradient forMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF9500), Color(0xFFFF6B35)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'excited':
        return const LinearGradient(
          colors: [Color(0xFFFF6B8A), Color(0xFFFF4757), Color(0xFFFF2266)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'neutral':
        return const LinearGradient(
          colors: [Color(0xFF9E9E9E), Color(0xFF757575), Color(0xFF616161)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'sad':
        return const LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFF1976D2), Color(0xFF0D47A1)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'stressed':
        return const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFE64A19), Color(0xFFBF360C)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'grateful':
        return const LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFF388E3C), Color(0xFF1B5E20)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'inspired':
        return const LinearGradient(
          colors: [Color(0xFFCE93D8), Color(0xFF7B1FA2), Color(0xFF4A0072)],
          stops: [0.0, 0.55, 1.0],
        );
      case 'tired':
        return const LinearGradient(
          colors: [Color(0xFF90A4AE), Color(0xFF546E7A), Color(0xFF37474F)],
          stops: [0.0, 0.55, 1.0],
        );
      default:
        return primary;
    }
  }

  // ─── Special Effect Gradients ────────────────────────────────
  static const LinearGradient glowEffect = LinearGradient(
    colors: [Color(0x306C63FF), Color(0x1500D4FF), Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient shimmerDark = LinearGradient(
    colors: [
      Color(0xFF0E0E1A),
      Color(0xFF1A1A30),
      Color(0xFF0E0E1A),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.5, 0.0),
    end: Alignment(1.5, 0.0),
  );

  static const LinearGradient shimmerLight = LinearGradient(
    colors: [
      Color(0xFFEDE9FF),
      Color(0xFFF8F7FF),
      Color(0xFFEDE9FF),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.5, 0.0),
    end: Alignment(1.5, 0.0),
  );

  static LinearGradient shimmer(bool isDark) =>
      isDark ? shimmerDark : shimmerLight;

  static LinearGradient bottomFade(bool isDark) => LinearGradient(
        colors: [
          Colors.transparent,
          (isDark ? AppColors.darkBg : AppColors.lightBg)
              .withValues(alpha: 0.97),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static const LinearGradient headerOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC07070F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.3, 1.0],
  );

  static RadialGradient radialGlow(Color color) => RadialGradient(
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  static SweepGradient get sweepCosmic => const SweepGradient(
        colors: [
          Color(0xFF6C63FF),
          Color(0xFF00D4FF),
          Color(0xFF4ECDC4),
          Color(0xFFFF6B8A),
          Color(0xFF6C63FF),
        ],
      );
}

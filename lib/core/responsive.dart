import 'package:flutter/material.dart';

/// Helper للـ responsive design
class Responsive {
  static double _w = 0;
  static double _h = 0;
  static double _scale = 1.0;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _w = size.width;
    _h = size.height;
    // مقياس بناءً على عرض 390 (iPhone 14) كمرجع
    _scale = _w / 390.0;
  }

  /// عرض الشاشة
  static double get width => _w;

  /// ارتفاع الشاشة
  static double get height => _h;

  /// تحويل px إلى dp متناسب مع الشاشة
  static double sp(double size) => size * _scale.clamp(0.75, 1.35);

  /// padding متناسب
  static double pad(double size) => size * _scale.clamp(0.80, 1.20);

  /// هل الشاشة صغيرة (أقل من 360px)
  static bool get isSmall => _w < 360;

  /// هل الشاشة كبيرة (أكثر من 420px)
  static bool get isLarge => _w > 420;

  /// هل الشاشة tablet (أكثر من 600px)
  static bool get isTablet => _w > 600;
}

/// Extension مريح على BuildContext
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get topPadding => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  bool get isSmallScreen => MediaQuery.of(this).size.width < 360;
  bool get isLargeScreen => MediaQuery.of(this).size.width > 420;
}

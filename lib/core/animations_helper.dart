import 'dart:async';
import 'package:flutter/material.dart';
import 'constants.dart';

/// مكتبة الـ micro-animations — الفرق بين تطبيق عادي ومبهر
class AnimationsHelper {
  AnimationsHelper._();

  static const Curve smoothSpring = Curves.easeOutCubic;
  static const Curve bounceIn = Curves.elasticOut;
  static const Curve sharpOut = Curves.easeOutExpo;
  static const Curve gentleIn = Curves.easeInOut;
  static const Curve luxuryEase = Curves.fastLinearToSlowEaseIn;
  static const Curve cosmicSpring = Curves.easeOutBack;
}

// ─────────────────────────────────────────────────────────────────
//  FADE IN WIDGET — ظهور ناعم مع حركة
// ─────────────────────────────────────────────────────────────────
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset? slideOffset;

  const FadeInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppConstants.animNormal,
    this.slideOffset,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  Timer? _delayTimer; // ✅ إضافة: تتبع الـ Timer لإلغائه عند الحاجة

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.slideOffset ?? const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      // ✅ إصلاح: حفظ مرجع الـ Timer لإلغائه عند dispose
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer
        ?.cancel(); // ✅ إلغاء Timer قبل dispose لمنع setState after dispose
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STAGGERED LIST — قائمة متتابعة فاخرة
// ─────────────────────────────────────────────────────────────────
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Axis direction;
  // ✅ إضافة: خيار لتغليف الـ children داخل Column أو إعادتها مباشرة
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 70),
    this.itemDuration = AppConstants.animNormal,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    final animated = children.asMap().entries.map((entry) {
      return FadeInWidget(
        delay: itemDelay * entry.key,
        duration: itemDuration,
        slideOffset: direction == Axis.vertical
            ? const Offset(0, 0.06)
            : const Offset(0.06, 0),
        child: entry.value,
      );
    }).toList();

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: animated,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRESS SCALE WIDGET — تأثير ضغط فاخر
// ─────────────────────────────────────────────────────────────────
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.95,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppConstants.animFast,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque, // ✅ إضافة: لضمان استجابة اللمس بالكامل
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SHIMMER WIDGET — تأثير بريق التحميل
// ─────────────────────────────────────────────────────────────────
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppConstants.radiusMD,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF0E0E1A),
                      const Color(0xFF1A1A30),
                      const Color(0xFF0E0E1A),
                    ]
                  : [
                      const Color(0xFFEDE9FF),
                      const Color(0xFFF8F7FF),
                      const Color(0xFFEDE9FF),
                    ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_anim.value, -0.3),
              end: Alignment(_anim.value + 1.5, 0.3),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PULSE WIDGET — نبضة توهج فاخرة
// ─────────────────────────────────────────────────────────────────
class PulseWidget extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color? glowColor;

  const PulseWidget({
    super.key,
    required this.child,
    this.active = true,
    this.glowColor,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // ✅ إصلاح: تشغيل الـ animation فقط إذا كانت active
    if (widget.active) _ctrl.repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ إضافة: الاستجابة لتغيير خاصية active
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: Opacity(opacity: _opacity.value, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  GLOW PULSE — توهج خارجي نابض للعناصر المميزة
// ─────────────────────────────────────────────────────────────────
class GlowPulse extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final bool active;

  const GlowPulse({
    super.key,
    required this.child,
    required this.glowColor,
    this.blurRadius = 20,
    this.active = true,
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.active) {
      _ctrl.repeat(reverse: true); // ✅ إصلاح: نفس نمط PulseWidget
    }
    _glow = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(GlowPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: _glow.value * 0.4),
              blurRadius: widget.blurRadius,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  COUNTING NUMBER WIDGET — أرقام متحركة فاخرة
// ─────────────────────────────────────────────────────────────────
class CountingNumber extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const CountingNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = AppConstants.animSlow,
  });

  @override
  State<CountingNumber> createState() => _CountingNumberState();
}

class _CountingNumberState extends State<CountingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _countAnim = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CountingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // ✅ إصلاح: استخدام القيمة الحالية للـ animation كنقطة بداية
      final currentValue = _countAnim.value;
      _countAnim = IntTween(
        begin: currentValue,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _countAnim,
      builder: (_, __) => Text('${_countAnim.value}', style: widget.style),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FLOAT WIDGET — حركة عائمة ناعمة للعناصر الزخرفية
// ─────────────────────────────────────────────────────────────────
class FloatWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  const FloatWidget({
    super.key,
    required this.child,
    this.amplitude = 8.0,
    this.period = const Duration(seconds: 3),
  });

  @override
  State<FloatWidget> createState() => _FloatWidgetState();
}

class _FloatWidgetState extends State<FloatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: widget.amplitude).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -_float.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  ROTATE GLOW WIDGET — دوران بريق للنجوم والزخارف
// ─────────────────────────────────────────────────────────────────
class RotateGlow extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool clockwise;

  const RotateGlow({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 8),
    this.clockwise = true,
  });

  @override
  State<RotateGlow> createState() => _RotateGlowState();
}

class _RotateGlowState extends State<RotateGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
      builder: (_, child) => Transform.rotate(
        angle: (widget.clockwise ? 1 : -1) * _ctrl.value * 6.2832,
        child: child,
      ),
      child: widget.child,
    );
  }
}

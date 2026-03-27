import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFFB0A8FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  static const Color primaryDeep = Color(0xFF2D2680);

  static const Color cyan = Color(0xFF00D4FF);
  static const Color cyanDeep = Color(0xFF0096C7);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDeep = Color(0xFFCC9900);
  static const Color rose = Color(0xFFFF6B8A);
  static const Color roseDeep = Color(0xFFCC2244);
  static const Color mint = Color(0xFF4ECDC4);
  static const Color purple = Color(0xFF9C6FFF);

  static const Color darkBg = Color(0xFF07070F);
  static const Color darkSurface = Color(0xFF0B0B18);
  static const Color darkCard = Color(0xFF0E0E1A);
  static const Color darkElevated = Color(0xFF13132A);
  static const Color darkHighlight = Color(0xFF1A1A35);
  static const Color darkBorder = Color(0xFF252545);
  static const Color darkDivider = Color(0xFF1C1C38);

  static const Color lightBg = Color(0xFFF4F3FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF0EEFF);
  static const Color lightBorder = Color(0xFFE0DEFF);
  static const Color lightDivider = Color(0xFFECEAFF);

  static const Color textPrimaryDark = Color(0xFFF0EEFF);
  static const Color textSecondaryDark = Color(0xFF9490C8);
  static const Color textHintDark = Color(0xFF5A5785);
  static const Color textDisabledDark = Color(0xFF3A3760);

  static const Color textPrimaryLight = Color(0xFF0D0C1D);
  static const Color textSecondaryLight = Color(0xFF5A58A0);
  static const Color textHintLight = Color(0xFFAAABCC);
  static const Color textDisabledLight = Color(0xFFCCCCE8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [primary, purple, cyan, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF07070F), Color(0xFF0A0A18), Color(0xFF0D0D1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x1C6C63FF), Color(0x0A9C6FFF), Color(0x0500D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static Color glassLight = Colors.white.withValues(alpha: 0.07);
  static Color glassDark = Colors.white.withValues(alpha: 0.04);
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.15);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.08);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF2196F3);
}

// ─────────────────────────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // ✅ كل الـ styles تستخدم notoNaskhArabic لحل نقطتي الياء
  static TextStyle displayLarge(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        letterSpacing: -0.8,
        height: 1.15,
      );

  static TextStyle displayMedium(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        letterSpacing: -0.4,
        height: 1.25,
      );

  static TextStyle headlineLarge(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.3,
      );

  static TextStyle headlineMedium(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.4,
      );

  static TextStyle headlineSmall(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.4,
      );

  static TextStyle bodyLarge(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.75,
      );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        height: 1.65,
      );

  static TextStyle bodySmall(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
        height: 1.55,
      );

  static TextStyle labelLarge(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        letterSpacing: 0.15,
      );

  static TextStyle labelMedium(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        letterSpacing: 0.10,
      );

  static TextStyle labelSmall(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
        letterSpacing: 0.5,
      );

  static TextStyle gradient({double fontSize = 28}) =>
      GoogleFonts.notoNaskhArabic(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.primary, AppColors.cyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(0, 0, 250, 80)),
      );

  static TextStyle auroraGradient({double fontSize = 28}) =>
      GoogleFonts.notoNaskhArabic(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.purple,
              AppColors.cyan,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(0, 0, 280, 80)),
      );

  static TextStyle tagStyle(bool isDark) => GoogleFonts.notoNaskhArabic(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.3,
      );

  static TextStyle buttonStyle() => GoogleFonts.notoNaskhArabic(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      );

  static TextStyle monoStyle(bool isDark) => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        letterSpacing: 0.2,
      );
}

// ─────────────────────────────────────────────────────────────────
//  THEME DATA
// ─────────────────────────────────────────────────────────────────

// ✅ TextTheme مشترك لكلا الثيمين — نفس الخط notoNaskhArabic
const TextTheme _darkTextTheme = TextTheme(
  displayLarge: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
  ),
  displayMedium: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  ),
  displaySmall: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  headlineLarge: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  headlineMedium: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  ),
  headlineSmall: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  ),
  titleLarge: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  ),
  titleMedium: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  ),
  titleSmall: TextStyle(
    color: AppColors.textSecondaryDark,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  ),
  bodyLarge: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 16,
    height: 1.75,
  ),
  bodyMedium: TextStyle(
    color: AppColors.textSecondaryDark,
    fontSize: 14,
    height: 1.65,
  ),
  bodySmall: TextStyle(
    color: AppColors.textHintDark,
    fontSize: 12,
    height: 1.55,
  ),
  labelLarge: TextStyle(
    color: AppColors.textPrimaryDark,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  ),
  labelMedium: TextStyle(
    color: AppColors.textSecondaryDark,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  ),
  labelSmall: TextStyle(
    color: AppColors.textHintDark,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ),
);

const TextTheme _lightTextTheme = TextTheme(
  displayLarge: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
  ),
  displayMedium: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  ),
  displaySmall: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  headlineLarge: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  headlineMedium: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  ),
  headlineSmall: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  ),
  titleLarge: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  ),
  titleMedium: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  ),
  titleSmall: TextStyle(
    color: AppColors.textSecondaryLight,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  ),
  bodyLarge: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 16,
    height: 1.75,
  ),
  bodyMedium: TextStyle(
    color: AppColors.textSecondaryLight,
    fontSize: 14,
    height: 1.65,
  ),
  bodySmall: TextStyle(
    color: AppColors.textHintLight,
    fontSize: 12,
    height: 1.55,
  ),
  labelLarge: TextStyle(
    color: AppColors.textPrimaryLight,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  ),
  labelMedium: TextStyle(
    color: AppColors.textSecondaryLight,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  ),
  labelSmall: TextStyle(
    color: AppColors.textHintLight,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ),
);

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.darkElevated,
        secondary: AppColors.cyan,
        secondaryContainer: AppColors.darkHighlight,
        tertiary: AppColors.gold,
        tertiaryContainer: AppColors.darkElevated,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkHighlight,
        error: AppColors.rose,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: AppColors.lightSurface,
        onInverseSurface: AppColors.textPrimaryLight,
        inversePrimary: AppColors.primaryDark,
      ),
      // ✅ الحل الجذري: notoNaskhArabic لكلا الثيمين
      textTheme: GoogleFonts.notoNaskhArabicTextTheme(_darkTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.darkBg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme:
            const IconThemeData(color: AppColors.textPrimaryDark, size: 22),
        actionsIconTheme:
            const IconThemeData(color: AppColors.textPrimaryDark, size: 22),
        titleTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          side: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.7),
            width: 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevated.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
              color: AppColors.darkBorder.withValues(alpha: 0.8), width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
              color: AppColors.darkBorder.withValues(alpha: 0.8), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
        ),
        hintStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textHintDark,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.textHintDark,
        suffixIconColor: AppColors.textHintDark,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        extendedTextStyle: GoogleFonts.notoNaskhArabic(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkElevated,
        selectedColor: AppColors.primary.withValues(alpha: 0.22),
        disabledColor: AppColors.darkHighlight,
        labelStyle: GoogleFonts.notoNaskhArabic(
          fontSize: 12,
          color: AppColors.textSecondaryDark,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.notoNaskhArabic(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          side: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
        side: BorderSide(
          color: AppColors.darkBorder.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.notoNaskhArabic(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.notoNaskhArabic(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textHintDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textHintDark, size: 22);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHintDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider.withValues(alpha: 0.6),
        thickness: 0.8,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: AppConstants.iconMD,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: GoogleFonts.notoNaskhArabic(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: GoogleFonts.notoNaskhArabic(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.notoNaskhArabic(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 32,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          side: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.7),
            width: 0.8,
          ),
        ),
        titleTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        contentTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
          height: 1.65,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        modalBackgroundColor: AppColors.darkCard,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXXL),
          ),
        ),
        dragHandleColor: AppColors.darkBorder,
        dragHandleSize: const Size(36, 4),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkHighlight,
        contentTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          height: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          side: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppConstants.padMD),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.darkElevated,
        circularTrackColor: AppColors.darkElevated,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textHintDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.darkElevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(
          color: AppColors.darkBorder.withValues(alpha: 0.8),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.darkElevated,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 4,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppConstants.padMD, vertical: 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkCard,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          side: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.7),
            width: 0.8,
          ),
        ),
        textStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkHighlight,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          border: Border.all(
            color: AppColors.darkBorder.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        textStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryDark,
          fontSize: 12,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: Color(0xFFEDE9FF),
        secondary: AppColors.cyan,
        secondaryContainer: Color(0xFFE0F7FF),
        tertiary: AppColors.gold,
        tertiaryContainer: Color(0xFFFFF8E0),
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightElevated,
        error: AppColors.rose,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightDivider,
        shadow: Color(0x1A6C63FF),
        inverseSurface: AppColors.darkSurface,
        onInverseSurface: AppColors.textPrimaryDark,
        inversePrimary: AppColors.primaryLight,
      ),
      // ✅ الحل الجذري: نفس الخط للثيم الفاتح
      textTheme: GoogleFonts.notoNaskhArabicTextTheme(_lightTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.lightBg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme:
            const IconThemeData(color: AppColors.textPrimaryLight, size: 22),
        actionsIconTheme:
            const IconThemeData(color: AppColors.textPrimaryLight, size: 22),
        titleTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 1.0,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide:
              const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide:
              const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
        ),
        hintStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textHintLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.textHintLight,
        suffixIconColor: AppColors.textHintLight,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        extendedTextStyle: GoogleFonts.notoNaskhArabic(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightElevated,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.notoNaskhArabic(
          fontSize: 12,
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.notoNaskhArabic(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
        ),
        side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.notoNaskhArabic(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.notoNaskhArabic(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textHintLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textHintLight, size: 22);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHintLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 0.8,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: AppConstants.iconMD,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: GoogleFonts.notoNaskhArabic(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: GoogleFonts.notoNaskhArabic(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.notoNaskhArabic(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 16,
        shadowColor: AppColors.primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 1.0,
          ),
        ),
        titleTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        contentTextStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
          height: 1.65,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXXL),
          ),
        ),
        dragHandleColor: AppColors.lightBorder,
        dragHandleSize: Size(36, 4),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.notoNaskhArabic(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppConstants.padMD),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightElevated,
        circularTrackColor: AppColors.lightElevated,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textHintLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.lightElevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.lightElevated,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 4,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondaryLight,
        textColor: AppColors.textPrimaryLight,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.padMD,
          vertical: 4,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
        ),
        textStyle: GoogleFonts.notoNaskhArabic(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimaryLight.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
        textStyle: GoogleFonts.notoNaskhArabic(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  THEME NOTIFIER
// ─────────────────────────────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode);

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ValueChanged<ThemeMode>? onThemeChanged;

  void setDarkMode() {
    if (_themeMode == ThemeMode.dark) return;
    _themeMode = ThemeMode.dark;
    _updateSystemUI(dark: true);
    onThemeChanged?.call(ThemeMode.dark);
    notifyListeners();
  }

  void setLightMode() {
    if (_themeMode == ThemeMode.light) return;
    _themeMode = ThemeMode.light;
    _updateSystemUI(dark: false);
    onThemeChanged?.call(ThemeMode.light);
    notifyListeners();
  }

  void toggleTheme() => isDark ? setLightMode() : setDarkMode();

  void setThemeSilently(ThemeMode mode) {
    _themeMode = mode;
    _updateSystemUI(dark: mode == ThemeMode.dark);
  }

  void _updateSystemUI({required bool dark}) {
    SystemChrome.setSystemUIOverlayStyle(
      dark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: AppColors.darkBg,
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: Colors.transparent,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: AppColors.lightBg,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  GLASS DECORATION HELPER
// ─────────────────────────────────────────────────────────────────
class GlassDecoration {
  static BoxDecoration of({
    required bool isDark,
    double? borderRadius,
    Color? tint,
    bool showBorder = true,
    bool showGlow = false,
    Color? glowColor,
  }) {
    final radius = borderRadius ?? AppConstants.radiusLG;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.03),
                (tint ?? AppColors.primary).withValues(alpha: 0.04),
              ]
            : [
                Colors.white.withValues(alpha: 0.90),
                Colors.white.withValues(alpha: 0.70),
                (tint ?? AppColors.primary).withValues(alpha: 0.04),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      ),
      border: showBorder
          ? Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.90),
              width: 0.8,
            )
          : null,
      boxShadow: showGlow
          ? [
              BoxShadow(
                color: (glowColor ?? AppColors.primary)
                    .withValues(alpha: isDark ? 0.20 : 0.10),
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 20,
                spreadRadius: -6,
                offset: const Offset(0, 6),
              ),
            ],
    );
  }
}

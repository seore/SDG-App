import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens. Neutral surfaces, one brand accent, and SDG colours
/// used only as small accents (icons, chips, thin bars) – never as backgrounds.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF0F766E); // teal-700
  static const primaryDark = Color(0xFF115E59);
  static const primarySoft = Color(0xFFE6F2F1);

  // Semantic
  static const xp = Color(0xFFB45309); // amber-700, readable on white
  static const streak = Color(0xFFEA580C);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);

  // Neutrals
  static const background = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF1F3F5);
  static const border = Color(0xFFE4E7EC);
  static const divider = Color(0xFFEDEFF2);
  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Max content width so layouts don't stretch on tablets / web.
  static const double maxContentWidth = 560;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  /// Barely-there elevation for cards resting on the background.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F101828), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Lifted state (hover).
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0F101828), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A101828), blurRadius: 24, offset: Offset(0, 12)),
  ];
}

class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 600);
  static const spring = Duration(milliseconds: 550);
}

/// Spring physics shared by every animation, so motion feels consistent.
class AppMotion {
  AppMotion._();

  /// Responsive spring with a slight overshoot (stiffness 420, damping 24).
  static const SpringDescription snappy =
      SpringDescription(mass: 1, stiffness: 420, damping: 24);

  /// Softer spring for larger elements (cards, dialogs).
  static const SpringDescription gentle =
      SpringDescription(mass: 1, stiffness: 240, damping: 22);

  static final Curve spring = SpringCurve(snappy);
  static final Curve gentleSpring = SpringCurve(gentle);
}

/// A [Curve] driven by a real spring simulation. Lets implicit animations
/// (AnimatedScale, TweenAnimationBuilder…) use spring physics.
class SpringCurve extends Curve {
  final SpringDescription description;
  final double seconds;
  late final SpringSimulation _sim =
      SpringSimulation(description, 0, 1, 0);

  SpringCurve(this.description, {this.seconds = 0.55});

  @override
  double transformInternal(double t) => _sim.x(t * seconds);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );

    final text = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Level maths shared by every screen that shows progress.
class LevelInfo {
  static const int xpPerLevel = 100;

  final int xp;
  const LevelInfo(this.xp);

  int get level => xp ~/ xpPerLevel + 1;
  int get xpInLevel => xp % xpPerLevel;
  int get xpToNext => xpPerLevel - xpInLevel;
  double get progress => xpInLevel / xpPerLevel;
}

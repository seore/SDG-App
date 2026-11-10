import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// One set of colours for a brightness. SDG colours are the same in both.
class AppPalette {
  final Brightness brightness;
  final Color primary;
  final Color primaryDark; // text/icons on [primarySoft]
  final Color primarySoft;
  final Color xp;
  final Color streak;
  final Color success;
  final Color warning;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> raisedShadow;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.xp,
    required this.streak,
    required this.success,
    required this.warning,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.cardShadow,
    required this.raisedShadow,
  });

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E), // teal-700
    primaryDark: Color(0xFF115E59),
    primarySoft: Color(0xFFE6F2F1),
    xp: Color(0xFFB45309), // amber-700, readable on white
    streak: Color(0xFFEA580C),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    background: Color(0xFFF6F7F9),
    surface: Colors.white,
    surfaceMuted: Color(0xFFF1F3F5),
    border: Color(0xFFE4E7EC),
    divider: Color(0xFFEDEFF2),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF667085),
    textTertiary: Color(0xFF98A2B3),
    cardShadow: [
      BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F101828), blurRadius: 12, offset: Offset(0, 4)),
    ],
    raisedShadow: [
      BoxShadow(color: Color(0x0F101828), blurRadius: 4, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x1A101828), blurRadius: 24, offset: Offset(0, 12)),
    ],
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF2DB3A6), // lighter teal for contrast on dark
    primaryDark: Color(0xFF7FE0D5),
    primarySoft: Color(0xFF12302D),
    xp: Color(0xFFF5B83D),
    streak: Color(0xFFFB923C),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFF5B83D),
    background: Color(0xFF0E1116),
    surface: Color(0xFF171B22),
    surfaceMuted: Color(0xFF222731),
    border: Color(0xFF2A303B),
    divider: Color(0xFF232832),
    textPrimary: Color(0xFFECEFF4),
    textSecondary: Color(0xFFA2AABA),
    textTertiary: Color(0xFF6E7787),
    cardShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    raisedShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
    ],
  );
}

/// Central design tokens. Neutral surfaces, one brand accent, and SDG colours
/// used only as small accents (icons, chips, thin bars) – never as backgrounds.
///
/// Values come from the active [AppPalette]; switching palettes repaints the
/// whole app (see ThemeController).
class AppColors {
  AppColors._();

  static AppPalette current = AppPalette.light;

  static Color get primary => current.primary;
  static Color get primaryDark => current.primaryDark;
  static Color get primarySoft => current.primarySoft;
  static Color get xp => current.xp;
  static Color get streak => current.streak;
  static Color get success => current.success;
  static Color get warning => current.warning;
  static Color get background => current.background;
  static Color get surface => current.surface;
  static Color get surfaceMuted => current.surfaceMuted;
  static Color get border => current.border;
  static Color get divider => current.divider;
  static Color get textPrimary => current.textPrimary;
  static Color get textSecondary => current.textSecondary;
  static Color get textTertiary => current.textTertiary;
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
  static List<BoxShadow> get card => AppColors.current.cardShadow;

  /// Lifted state (hover).
  static List<BoxShadow> get raised => AppColors.current.raisedShadow;
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

  static ThemeData light() => build(AppPalette.light);
  static ThemeData dark() => build(AppPalette.dark);

  static ThemeData build(AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      primary: p.primary,
      surface: p.surface,
      brightness: p.brightness,
    );

    final base = p.isDark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;
    final text = GoogleFonts.interTextTheme(base).apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return ThemeData(
      brightness: p.brightness,
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
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
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
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
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primarySoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textTertiary),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
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

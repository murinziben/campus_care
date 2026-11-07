import 'package:flutter/material.dart';

/// One complete set of colours (a "mode").
class _Palette {
  const _Palette({
    required this.bg,
    required this.surface,
    required this.navBar,
    required this.primary,
    required this.onPrimary,
    required this.deep,
    required this.soft,
    required this.tint,
    required this.warm,
    required this.s950,
    required this.s700,
    required this.s500,
    required this.s400,
    required this.s300,
    required this.s200,
    required this.s100,
    required this.orange,
    required this.orange50,
    required this.amber,
    required this.amber50,
    required this.green,
    required this.green50,
    required this.red,
    required this.red50,
    required this.sky,
    required this.sky50,
    required this.shadow,
  });

  final Color bg, surface, navBar, primary, onPrimary, deep, soft, tint, warm;
  final Color s950, s700, s500, s400, s300, s200, s100;
  final Color orange, orange50, amber, amber50, green, green50;
  final Color red, red50, sky, sky50, shadow;
}

/// CampusCare design tokens.
///
/// Brand palette: aqua #46F0D2, navy #131321, cream #FBE2B4, white.
///  - Dark mode  : navy background, aqua primary, cream accent, white text.
///  - Light mode : soft white background, a deeper teal primary (aqua is too
///    pale to read on white), cream chips, navy text.
///
/// The active mode is switched with [AppColors.apply]. Because colours can
/// change at runtime, widgets must not use `const` with these tokens.
class AppColors {
  AppColors._();

  // Fixed brand colours (never change with the mode).
  static const aqua = Color(0xFF46F0D2);
  static const navy = Color(0xFF131321);
  static const cream = Color(0xFFFBE2B4);

  static const _dark = _Palette(
    bg: navy,
    surface: Color(0xFF1C1C30),
    navBar: Color(0xFF191929),
    primary: aqua,
    onPrimary: navy,
    deep: Color(0xFF1B4B4E),
    soft: Color(0xFF1D4447),
    tint: Color(0xFF192E36),
    warm: cream,
    s950: Color(0xFFFFFFFF),
    s700: Color(0xFFD6D6E4),
    s500: Color(0xFF9B9BB4),
    s400: Color(0xFF7A7A96),
    s300: Color(0xFF4A4A66),
    s200: Color(0xFF2D2D47),
    s100: Color(0xFF232338),
    orange: Color(0xFFFFA65C),
    orange50: Color(0xFF392B2A),
    amber: cream,
    amber50: Color(0xFF333036),
    green: Color(0xFF5EE6A8),
    green50: Color(0xFF1F3537),
    red: Color(0xFFFF6B6B),
    red50: Color(0xFF39212D),
    sky: Color(0xFF7CC8F0),
    sky50: Color(0xFF243042),
    shadow: Color(0x47000000),
  );

  static const _light = _Palette(
    bg: Color(0xFFF5F8F7),
    surface: Color(0xFFFFFFFF),
    navBar: Color(0xFFFFFFFF),
    primary: Color(0xFF0A8574),
    onPrimary: Color(0xFFFFFFFF),
    deep: Color(0xFF0F4F4B),
    soft: Color(0xFFCFF6EE),
    tint: Color(0xFFE6F8F4),
    warm: Color(0xFFC98A1B),
    s950: navy,
    s700: Color(0xFF3D3D55),
    s500: Color(0xFF6B6B85),
    s400: Color(0xFF9A9AB0),
    s300: Color(0xFFCFCFDD),
    s200: Color(0xFFE3E5EB),
    s100: Color(0xFFEEF0F4),
    orange: Color(0xFFD9661F),
    orange50: Color(0xFFFDEBDD),
    amber: Color(0xFF9A6410),
    amber50: cream,
    green: Color(0xFF178A56),
    green50: Color(0xFFDDF4E8),
    red: Color(0xFFD33F3F),
    red50: Color(0xFFFCE8E8),
    sky: Color(0xFF2B7A9B),
    sky50: Color(0xFFE3F1F6),
    shadow: Color(0x14131321),
  );

  static _Palette _p = _dark;

  static bool get isDark => identical(_p, _dark);

  /// Switch the active palette. Call before building the widget tree.
  static void apply(Brightness brightness) {
    _p = brightness == Brightness.dark ? _dark : _light;
  }

  // Semantic names.
  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get navBar => _p.navBar;

  /// Text / icons drawn on top of [forest] (the primary colour).
  static Color get ink => _p.onPrimary;

  // Brand (older names kept so existing widgets keep working).
  static Color get forest => _p.primary;
  static Color get deepGreen => _p.deep;
  static Color get offWhite => _p.bg;
  static Color get softGreen => _p.soft;
  static Color get lightGreen => _p.tint;
  static Color get warmOrange => _p.warm;

  // Neutrals: 950 is the strongest text colour, 100 the faintest fill.
  static Color get slate950 => _p.s950;
  static Color get slate700 => _p.s700;
  static Color get slate500 => _p.s500;
  static Color get slate400 => _p.s400;
  static Color get slate300 => _p.s300;
  static Color get slate200 => _p.s200;
  static Color get slate100 => _p.s100;
  static Color get slate50 => _p.bg;

  // Status colours: Submitted = orange, In Progress = cream, Resolved = green.
  static Color get orange => _p.orange;
  static Color get orange50 => _p.orange50;
  static Color get amber => _p.amber;
  static Color get amber50 => _p.amber50;
  static Color get green => _p.green;
  static Color get green50 => _p.green50;
  static Color get red => _p.red;
  static Color get red50 => _p.red50;

  // Category accent for water only (kept small and calm).
  static Color get sky => _p.sky;
  static Color get sky50 => _p.sky50;
}

class AppRadius {
  AppRadius._();
  static const double card = 18;
  static const double field = 14;
  static const double chip = 99;
}

class AppShadows {
  AppShadows._();

  /// Soft shadow so cards lift slightly off the background.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors._p.shadow,
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  /// Applies the matching palette and returns the Material theme for it.
  static ThemeData build(Brightness brightness) {
    AppColors.apply(brightness);
    final dark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: AppColors.aqua,
      primary: AppColors.forest,
      onPrimary: AppColors.ink,
      secondary: AppColors.warmOrange,
      onSecondary: dark ? AppColors.navy : Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.slate950,
      error: AppColors.red,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      dividerColor: AppColors.slate200,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.slate950,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.slate950,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14),
        border: border(AppColors.slate200),
        enabledBorder: border(AppColors.slate200),
        focusedBorder: border(AppColors.forest, 1.6),
        errorBorder: border(AppColors.red),
        focusedErrorBorder: border(AppColors.red, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: AppColors.slate500,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: BorderSide(color: AppColors.slate200),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.ink,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.forest,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: AppColors.slate200),
        checkmarkColor: AppColors.ink,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip)),
        labelStyle: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.slate700),
        secondaryLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.forest
                  : AppColors.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.slate700),
          side: WidgetStatePropertyAll(BorderSide(color: AppColors.slate200)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ink : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.forest
                : AppColors.slate300),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: AppColors.forest),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.slate100 : AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.softGreen,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.forest
                  : AppColors.slate500,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.forest : AppColors.slate500,
          );
        }),
      ),
    );
  }
}

/// Text styles used repeatedly (getters so they follow the active mode).
class AppText {
  AppText._();

  static TextStyle get h1 => TextStyle(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AppColors.slate950,
      );
  static TextStyle get h2 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.slate950,
      );
  static TextStyle get h3 => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.slate950,
      );
  static TextStyle get body => TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppColors.slate700,
      );
  static TextStyle get muted =>
      TextStyle(fontSize: 12.5, color: AppColors.slate500);
  static TextStyle get eyebrow => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: AppColors.forest,
      );
  static TextStyle get label => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.slate700,
      );
}

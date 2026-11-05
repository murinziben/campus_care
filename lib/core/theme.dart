import 'package:flutter/material.dart';

/// CampusCare design tokens (forest-green identity).
class AppColors {
  AppColors._();

  // Brand
  static const forest = Color(0xFF176B55);
  static const deepGreen = Color(0xFF124C3F);
  static const offWhite = Color(0xFFF6F7F2);
  static const softGreen = Color(0xFFDDF1E7);
  static const lightGreen = Color(0xFFE9F4ED);
  static const warmOrange = Color(0xFFE9A23B);

  // Neutrals
  static const slate950 = Color(0xFF14231F);
  static const slate700 = Color(0xFF3B4A45);
  static const slate500 = Color(0xFF66756F);
  static const slate400 = Color(0xFF93A09B);
  static const slate300 = Color(0xFFCBD5D0);
  static const slate200 = Color(0xFFE3E8E4);
  static const slate100 = Color(0xFFEFF2EE);
  static const slate50 = offWhite;

  // Status colours: Submitted = orange, In Progress = amber, Resolved = green.
  static const orange = Color(0xFFE2702A);
  static const orange50 = Color(0xFFFDEBDD);
  static const amber = Color(0xFFB27A0C);
  static const amber50 = Color(0xFFFCF1CF);
  static const green = Color(0xFF1B7F4B);
  static const green50 = Color(0xFFE1F3E8);
  static const red = Color(0xFFD33F3F);
  static const red50 = Color(0xFFFCE8E8);

  // Category accent for water only (kept small and calm).
  static const sky = Color(0xFF2B7A9B);
  static const sky50 = Color(0xFFE3F1F6);
}

class AppRadius {
  AppRadius._();
  static const double card = 18;
  static const double field = 14;
  static const double chip = 99;
}

class AppShadows {
  AppShadows._();

  /// Subtle card shadow (no heavy elevation anywhere).
  static final card = [
    BoxShadow(
      color: AppColors.deepGreen.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      onPrimary: Colors.white,
      surface: Colors.white,
      error: AppColors.red,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.offWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.offWhite,
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
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
        border: border(AppColors.slate200),
        enabledBorder: border(AppColors.slate200),
        focusedBorder: border(AppColors.forest, 1.6),
        errorBorder: border(AppColors.red),
        focusedErrorBorder: border(AppColors.red, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.forest,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.slate200),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.forest
                  : Colors.white),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.slate700),
          side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.slate200)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.forest
                : AppColors.slate300),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepGreen,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
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

/// Text styles used repeatedly.
class AppText {
  AppText._();

  static const h1 = TextStyle(
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppColors.slate950,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.slate950,
  );
  static const h3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.slate950,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AppColors.slate700,
  );
  static const muted = TextStyle(fontSize: 12.5, color: AppColors.slate500);
  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.3,
    color: AppColors.forest,
  );
  static const label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.slate700,
  );
}

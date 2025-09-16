import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme Colors
  static const Color _lightPrimaryColor = Color(0xFF6750A4);
  static const Color _lightBackgroundColor = Color(0xFFFEFBFF);
  static const Color _lightSurfaceColor = Color(0xFFFFFBFE);
  static const Color _lightOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color _lightOnBackgroundColor = Color(0xFF1C1B1F);
  static const Color _lightOnSurfaceColor = Color(0xFF1C1B1F);
  static const Color _lightErrorColor = Color(0xFFBA1A1A);
  static const Color _lightOnErrorColor = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color _darkPrimaryColor = Color(0xFFD0BCFF);
  static const Color _darkBackgroundColor = Color(0xFF141218);
  static const Color _darkSurfaceColor = Color(0xFF1C1B1F);
  static const Color _darkOnPrimaryColor = Color(0xFF381E72);
  static const Color _darkOnBackgroundColor = Color(0xFFE6E1E5);
  static const Color _darkOnSurfaceColor = Color(0xFFE6E1E5);
  static const Color _darkErrorColor = Color(0xFFFFB4AB);
  static const Color _darkOnErrorColor = Color(0xFF690005);

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightPrimaryColor,
      brightness: Brightness.light,
      primary: _lightPrimaryColor,
      onPrimary: _lightOnPrimaryColor,
      secondary: const Color(0xFF625B71),
      onSecondary: const Color(0xFFFFFFFF),
      error: _lightErrorColor,
      onError: _lightOnErrorColor,
      background: _lightBackgroundColor,
      onBackground: _lightOnBackgroundColor,
      surface: _lightSurfaceColor,
      onSurface: _lightOnSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackgroundColor,
      extensions: const <ThemeExtension<dynamic>>[
        AppGradients.light(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: _lightOnPrimaryColor,
        elevation: 4,
        shadowColor: _lightPrimaryColor.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          color: _lightOnPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(
          color: _lightOnPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightOnPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightOnPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimaryColor,
          side: BorderSide(color: _lightPrimaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightErrorColor, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkPrimaryColor,
      brightness: Brightness.dark,
      primary: _darkPrimaryColor,
      onPrimary: _darkOnPrimaryColor,
      secondary: const Color(0xFFCCC2DC),
      onSecondary: const Color(0xFF332D41),
      error: _darkErrorColor,
      onError: _darkOnErrorColor,
      background: _darkBackgroundColor,
      onBackground: _darkOnBackgroundColor,
      surface: _darkSurfaceColor,
      onSurface: _darkOnSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackgroundColor,
      extensions: const <ThemeExtension<dynamic>>[
        AppGradients.dark(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurfaceColor,
        foregroundColor: _darkOnSurfaceColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          color: _darkOnSurfaceColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(
          color: _darkOnSurfaceColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkOnPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkOnPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          side: BorderSide(color: _darkPrimaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkErrorColor, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Get theme based on brightness
  static ThemeData getThemeData(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  // Custom colors for specific UI elements
  static const Color lightSidebarGradientStart = Color(0xFF8E24AA);
  static const Color lightSidebarGradientMiddle = Color(0xFF7B1FA2);
  static const Color lightSidebarGradientEnd = Color(0xFF6A1B9A);

  static const Color darkSidebarGradientStart = Color(0xFF2D2438);
  static const Color darkSidebarGradientMiddle = Color(0xFF3A2F4A);
  static const Color darkSidebarGradientEnd = Color(0xFF4A3A5C);

  // Common colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
}

// Custom colors for specific UI elements
class AppColors {
  // Common colors (kept for compatibility; prefer ColorScheme)
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
}

class AppGradients extends ThemeExtension<AppGradients> {
  final Color sidebarStart;
  final Color sidebarMiddle;
  final Color sidebarEnd;

  const AppGradients({
    required this.sidebarStart,
    required this.sidebarMiddle,
    required this.sidebarEnd,
  });

  const AppGradients.light()
      : sidebarStart = const Color(0xFF8E24AA),
        sidebarMiddle = const Color(0xFF7B1FA2),
        sidebarEnd = const Color(0xFF6A1B9A);

  const AppGradients.dark()
      : sidebarStart = const Color(0xFF2D2438),
        sidebarMiddle = const Color(0xFF3A2F4A),
        sidebarEnd = const Color(0xFF4A3A5C);

  @override
  AppGradients copyWith({
    Color? sidebarStart,
    Color? sidebarMiddle,
    Color? sidebarEnd,
  }) {
    return AppGradients(
      sidebarStart: sidebarStart ?? this.sidebarStart,
      sidebarMiddle: sidebarMiddle ?? this.sidebarMiddle,
      sidebarEnd: sidebarEnd ?? this.sidebarEnd,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      sidebarStart: Color.lerp(sidebarStart, other.sidebarStart, t)!,
      sidebarMiddle: Color.lerp(sidebarMiddle, other.sidebarMiddle, t)!,
      sidebarEnd: Color.lerp(sidebarEnd, other.sidebarEnd, t)!,
    );
  }
}

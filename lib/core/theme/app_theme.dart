import 'package:flutter/material.dart';

/// Shared Material 3 themes for Stride.
///
/// An energetic green highlights activity actions while neutral surfaces keep
/// maps, metrics, and long activity histories easy to scan.
abstract final class AppTheme {
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF34C759), onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB8F5C8), onPrimaryContainer: Color(0xFF00210F),
    secondary: Color(0xFF356A52), onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB8F2D1), onSecondaryContainer: Color(0xFF002113),
    tertiary: Color(0xFF2A6B8E), onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC7E7FF), onTertiaryContainer: Color(0xFF001F2E),
    error: Color(0xFFBA1A1A), onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6), onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF7F7F7), onSurface: Color(0xFF191C1A),
    surfaceContainerHighest: Color(0xFFDDE5DD), onSurfaceVariant: Color(0xFF404941),
    outline: Color(0xFF707970), outlineVariant: Color(0xFFC0C9C0),
    shadow: Color(0xFF000000), scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E312E), onInverseSurface: Color(0xFFEFF1EC),
    inversePrimary: Color(0xFF34C759),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7DDBA1), onPrimary: Color(0xFF00391F),
    primaryContainer: Color(0xFF00522E), onPrimaryContainer: Color(0xFF9BF6BF),
    secondary: Color(0xFF9CD5B6), onSecondary: Color(0xFF003823),
    secondaryContainer: Color(0xFF1D513A), onSecondaryContainer: Color(0xFFB8F2D1),
    tertiary: Color(0xFF91CEEF), onTertiary: Color(0xFF00344D),
    tertiaryContainer: Color(0xFF104D6D), onTertiaryContainer: Color(0xFFC7E7FF),
    error: Color(0xFFFFB4AB), onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A), onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF161C2A), onSurface: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFF232A3B), onSurfaceVariant: Color(0xFFC2C7D0),
    outline: Color(0xFF8B93A0), outlineVariant: Color(0xFF353C4D),
    shadow: Color(0xFF000000), scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE2E8F0), onInverseSurface: Color(0xFF161C2A),
    inversePrimary: Color(0xFF006D3B),
  );

  static final ThemeData lightTheme = _buildTheme(_lightScheme);
  static final ThemeData darkTheme = _buildTheme(_darkScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final appBarBackground = isDark ? colorScheme.surface : Colors.white;
    final navigationBackground = isDark ? colorScheme.surface : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navigationBackground,
        elevation: 0,
        indicatorColor: isDark
            ? colorScheme.secondaryContainer
            : colorScheme.primary,
        iconTheme: isDark
            ? null
            : WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return IconThemeData(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                );
              }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected && !isDark
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      cardTheme: CardThemeData(
        // Elevated card background slightly lighter than #161C2A for depth
        color: isDark ? const Color(0xFF1E2538) : const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(colorScheme.outlineVariant),
        enabledBorder: _inputBorder(colorScheme.outlineVariant),
        focusedBorder: _inputBorder(colorScheme.primary, width: 2),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 2),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}

import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Professional Tailoring Business Theme
  static const primaryColor = Color(
    0xFF234E70,
  ); // Deep Navy Blue: Trust, Professionalism
  static const secondaryColor = Color(
    0xFF2A7B62,
  ); // Forest Green: Quality, Precision
  static const tertiaryColor = Color(0xFF8C4646); // Burgundy: Luxury, Tradition
  static const neutralColor = Color(0xFF2C3444); // Dark Slate: Sophistication

  // Supporting Colors
  static const successColor = Color(0xFF2A7B62); // Green: Success, Completion
  static const warningColor = Color(0xFFB87D3B); // Amber: Attention, Warning
  static const errorColor = Color(0xFF994D4D); // Deep Red: Errors, Important

  // Background Tones
  static const backgroundColor = Color(
    0xFFF8F9FC,
  ); // Off-White: Clean, Professional
  static const surfaceColor = Color(0xFFFFFFFF); // Pure White: Clarity
  static const containerColor = Color(0xFFF0F2F8); // Light Grey: Subtle Depth

  static final lightColorScheme = ColorScheme.light(
    // Primary Colors
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: primaryColor.withOpacity(0.08),
    onPrimaryContainer: primaryColor,

    // Secondary Colors
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: secondaryColor.withOpacity(0.08),
    onSecondaryContainer: secondaryColor,

    // Tertiary Colors
    tertiary: tertiaryColor,
    onTertiary: Colors.white,
    tertiaryContainer: tertiaryColor.withOpacity(0.08),
    onTertiaryContainer: tertiaryColor,

    // Status Colors
    error: errorColor,
    onError: Colors.white,
    errorContainer: errorColor.withOpacity(0.08),

    // Surface Colors
    surface: surfaceColor,
    onSurface: neutralColor,
    surfaceContainer: containerColor.withOpacity(0.7),
    surfaceContainerLow: containerColor.withOpacity(0.5),
    surfaceContainerHigh: containerColor.withOpacity(0.9),
    surfaceContainerHighest: containerColor,

    // Outline Colors
    outline: neutralColor.withOpacity(0.2),
    outlineVariant: neutralColor.withOpacity(0.1),

    shadow: neutralColor.withOpacity(0.08),
  );

  // Updated Dark Theme Colors
  static const darkBg = Color(0xFF161618); // Deep charcoal background
  static const darkSurface = Color(0xFF1E1E21); // Slightly lighter surface
  static const darkAccent = Color(0xFF82B1FF); // Bright blue accent
  static const darkSecondary = Color(0xFF98FB98); // Soft green
  static const darkText = Color(0xFFE8EAED); // Crisp white text

  static final darkColorScheme = ColorScheme.dark(
    // Main Colors
    primary: darkAccent,
    onPrimary: darkBg,
    primaryContainer: darkAccent.withOpacity(0.15),
    onPrimaryContainer: darkAccent,

    // Secondary Colors
    secondary: darkSecondary,
    onSecondary: darkBg,
    secondaryContainer: darkSecondary.withOpacity(0.15),
    onSecondaryContainer: darkSecondary,

    // Surface Colors
    surface: darkSurface,
    onSurface: darkText,
    surfaceContainer: const Color(0xFF222226),
    surfaceContainerLow: const Color(0xFF1E1E21),
    surfaceContainerHigh: const Color(0xFF27272B),
    surfaceContainerHighest: const Color(0xFF2A2A2E),

    // Error Colors
    error: const Color(0xFFFF8A8A),
    onError: darkBg,
    errorContainer: const Color(0xFF642626),
    onErrorContainer: const Color(0xFFFFCCCC),

    // Outline Colors
    outline: darkText.withOpacity(0.2),
    outlineVariant: darkText.withOpacity(0.1),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,

    // Typography
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: lightColorScheme.onSurface, fontSize: 16),
      bodyMedium: TextStyle(color: lightColorScheme.onSurface, fontSize: 14),
      labelLarge: TextStyle(
        color: lightColorScheme.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Component Themes
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: lightColorScheme.shadow,
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 1,
      shadowColor: lightColorScheme.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: containerColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: neutralColor.withOpacity(0.1), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Update FloatingActionButton theme for professional look
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Other components
    dividerTheme: DividerThemeData(
      color: lightColorScheme.outlineVariant,
      thickness: 1,
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,

    // Typography with simplified colors
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: darkText,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: darkText,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: darkText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: darkText.withOpacity(0.87), fontSize: 16),
      bodyMedium: TextStyle(color: darkText.withOpacity(0.87), fontSize: 14),
      labelLarge: TextStyle(
        color: darkAccent,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Component Themes
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: darkBg,
        backgroundColor: darkAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // FAB theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkAccent,
      foregroundColor: darkBg,
      elevation: 2,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkAccent;
        }
        return darkText.withOpacity(0.4);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkAccent.withOpacity(0.3);
        }
        return darkText.withOpacity(0.1);
      }),
    ),

    // Icon theme
    iconTheme: IconThemeData(color: darkText.withOpacity(0.87), size: 24),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: darkText.withOpacity(0.1),
      thickness: 1,
    ),

    // Navigation bar theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: darkAccent.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(color: darkText, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

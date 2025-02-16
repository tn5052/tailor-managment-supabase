import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Professional Tailoring Business Theme
  static const primaryColor = Color(0xFF234E70);    // Deep Navy Blue: Trust, Professionalism
  static const secondaryColor = Color(0xFF2A7B62);  // Forest Green: Quality, Precision
  static const tertiaryColor = Color(0xFF8C4646);   // Burgundy: Luxury, Tradition
  static const neutralColor = Color(0xFF2C3444);    // Dark Slate: Sophistication

  // Supporting Colors
  static const successColor = Color(0xFF2A7B62);    // Green: Success, Completion
  static const warningColor = Color(0xFFB87D3B);    // Amber: Attention, Warning
  static const errorColor = Color(0xFF994D4D);      // Deep Red: Errors, Important
  
  // Background Tones
  static const backgroundColor = Color(0xFFF8F9FC); // Off-White: Clean, Professional
  static const surfaceColor = Color(0xFFFFFFFF);    // Pure White: Clarity
  static const containerColor = Color(0xFFF0F2F8);  // Light Grey: Subtle Depth

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
      bodyLarge: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 14,
      ),
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

    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 1,
      shadowColor: lightColorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: neutralColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Update FloatingActionButton theme for professional look
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Other components
    dividerTheme: DividerThemeData(
      color: lightColorScheme.outlineVariant,
      thickness: 1,
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryDesignConfig {
  // Modern Minimalist Color Palette
  static const Color backgroundColor = Color(0xFFFCFCFD);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFBFC);
  static const Color surfaceAccent = Color(0xFFF7F8FA);

  // Primary Colors
  static const Color primaryColor = Color(0xFF1F2937);
  static const Color primaryLight = Color(0xFF374151);
  static const Color primaryAccent = Color(0xFF6366F1);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color.fromARGB(255, 3, 7, 16);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFFD1D5DB);

  // Border Colors
  static const Color borderPrimary = Color(0xFFE5E7EB);
  static const Color borderSecondary = Color(0xFFF3F4F6);
  static const Color borderAccent = Color(0xFFD1D5DB);

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Spacing & Sizing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // Border Radius
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  static var headlineSmall;

  // Typography Styles
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle get code => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );

  // Component Styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: borderSecondary, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration get buttonPrimaryDecoration => BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(radiusM),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get buttonSecondaryDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(radiusM),
    border: Border.all(color: borderPrimary, width: 1),
  );

  static BoxDecoration get inputDecoration => BoxDecoration(
    color: surfaceLight,
    borderRadius: BorderRadius.circular(radiusM),
    border: Border.all(color: borderSecondary, width: 1),
  );

  static BoxDecoration get inputFocusedDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(radiusM),
    border: Border.all(color: primaryAccent, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: primaryAccent.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static BoxDecoration get chipDecoration => BoxDecoration(
    color: surfaceAccent,
    borderRadius: BorderRadius.circular(radiusS),
    border: Border.all(color: borderSecondary, width: 1),
  );

  static BoxDecoration get chipSelectedDecoration => BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(radiusS),
  );

  // Helper Methods
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        return successColor;
      case 'warning':
      case 'pending':
        return warningColor;
      case 'error':
      case 'failed':
      case 'inactive':
        return errorColor;
      case 'info':
      case 'processing':
        return infoColor;
      default:
        return textTertiary;
    }
  }

  static Color typeColor(String type, int index) {
    final colors = [
      primaryAccent,
      successColor,
      warningColor,
      infoColor,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }
}

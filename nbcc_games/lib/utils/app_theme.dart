import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - Premium Corporate Colors
  static const primaryGold = Color(0xFFFFD700);
  static const secondaryBlue = Color(0xFF1E3A8A);
  static const accentGreen = Color(0xFF10B981);
  static const darkBg = Color(0xFF0F172A);
  static const cardBg = Color(0xFF1E293B);
  static const textLight = Color(0xFFF1F5F9);
  static const textGray = Color(0xFF94A3B8);
  
  // Gradient Colors
  static const gradientStart = Color(0xFF6366F1);
  static const gradientEnd = Color(0xFFA855F7);
  
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryGold,
      secondary: secondaryBlue,
      surface: cardBg,
      background: darkBg,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
    ),
    
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: textLight,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 42,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textLight,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        color: textLight,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        color: textGray,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        elevation: 8,
        shadowColor: primaryGold.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
  
  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

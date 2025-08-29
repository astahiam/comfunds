import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'ComFunds';
  static const String appTagline = 'Sharia-Compliant Cooperative Crowdfunding';
  static const String appDescription = 'Empowering cooperative members through transparent, Sharia-compliant profit-sharing investments';
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8080/api/v1';
  static const String apiVersion = 'v1';
  
  // App Version
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  
  // Contact Information
  static const String contactEmail = 'support@comfunds.com';
  static const String contactPhone = '+62 21 1234 5678';
  static const String contactAddress = 'Jakarta, Indonesia';
  
  // Social Media
  static const String facebookUrl = 'https://facebook.com/comfunds';
  static const String twitterUrl = 'https://twitter.com/comfunds';
  static const String instagramUrl = 'https://instagram.com/comfunds';
  static const String linkedinUrl = 'https://linkedin.com/company/comfunds';
}

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32); // Dark Green
  static const Color primaryLight = Color(0xFF4CAF50); // Light Green
  static const Color primaryDark = Color(0xFF1B5E20); // Darker Green
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFF6F00); // Orange
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  // Accent Colors
  static const Color accent = Color(0xFF1976D2); // Blue
  static const Color accentLight = Color(0xFF42A5F5);
  static const Color accentDark = Color(0xFF0D47A1);
  
  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFFE0E0E0);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Investment Colors
  static const Color profit = Color(0xFF4CAF50);
  static const Color loss = Color(0xFFF44336);
  static const Color pending = Color(0xFFFF9800);
  static const Color completed = Color(0xFF2196F3);
  
  // Sharia Compliance Colors
  static const Color halal = Color(0xFF4CAF50);
  static const Color haram = Color(0xFFF44336);
  static const Color neutral = Color(0xFF9E9E9E);
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 1.5,
  );
}

class AppSizes {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  
  // Button Heights
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  
  // Input Heights
  static const double inputHeightSmall = 32.0;
  static const double inputHeightMedium = 40.0;
  static const double inputHeightLarge = 48.0;
  
  // Card Padding
  static const double cardPadding = 16.0;
  static const double cardPaddingLarge = 24.0;
  
  // Screen Padding
  static const double screenPadding = 16.0;
  static const double screenPaddingLarge = 24.0;
}

class AppShadows {
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];
  
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
  
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [AppColors.secondary, AppColors.secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [AppColors.accent, AppColors.accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================
// constants.dart — App-wide colors, text styles, and routes
// ============================================================

import 'package:flutter/material.dart';

// ------ App Colors ------
class AppColors {
  // Primary emergency red palette
  static const Color sosRed = Color(0xFFD32F2F);
  static const Color sosRedDark = Color(0xFFB71C1C);
  static const Color sosRedLight = Color(0xFFFF5252);
  static const Color sosRedGlow = Color(0x55D32F2F);

  // Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Accent
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentOrange = Color(0xFFE65100);
  static const Color accentBlue = Color(0xFF1565C0);

  // Shadows
  static const Color shadowColor = Color(0x22000000);
}

// ------ App Text Styles ------
class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle sosLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
    letterSpacing: 0.5,
  );

  static const TextStyle countdownNumber = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
  );
}

// ------ Named Routes ------
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String contacts = '/contacts';
  static const String location = '/location';
  static const String history = '/history';
  static const String settings = '/settings';
}

// ------ App Strings ------
class AppStrings {
  static const String appName = 'Emergency Assistance';
  static const String appTagline = 'Your Safety, Our Priority';
  static const String sosButtonLabel = 'Press and hold for emergency';
  static const int defaultCountdown = 5;

  static const String emergencyMessageTemplate =
      'EMERGENCY! I need help. My current location is: {location}. '
      'Please contact me immediately.';

  // Demo mode message
  static const String demoModeLabel = '🟡 DEMO MODE';
  static const String demoModeNote =
      'Demo Mode is ON. SOS alert simulated – no real SMS sent.';
}

// ------ Decoration Helpers ------
class AppDecorations {
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get surfaceCard => BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      );
}

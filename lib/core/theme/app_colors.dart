import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B5BEF);
  static const Color primaryLight = Color(0xFF8E85FF);
  static const Color primaryDark = Color(0xFF3331A7);
  static const Color accent = Color(0xFF19BFA0);
  static const Color accentSoft = Color(0xFFE5FBF5);
  static const Color violet = Color(0xFF9B6DFF);
  static const Color sky = Color(0xFF4BA3FF);
  static const Color warning = Color(0xFFF4A340);
  static const Color error = Color(0xFFEA526F);
  static const Color success = Color(0xFF19BFA0);

  static const Color scaffoldBg = Color(0xFFF6F7FB);
  static const Color cardBg = Colors.white;
  static const Color elevatedSurface = Color(0xFFFBFBFE);
  static const Color darkScaffoldBg = Color(0xFF0A0F1F);
  static const Color darkCardBg = Color(0xFF141B2D);
  static const Color darkElevatedSurface = Color(0xFF1A2237);

  static const Color textPrimary = Color(0xFF151A2D);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);

  static const Color divider = Color(0xFFE8EAF2);
  static const Color darkDivider = Color(0xFF28334C);

  static const Color privateColor = Color(0xFFEF4444);
  static const Color friendsColor = Color(0xFFF59E0B);
  static const Color publicColor = Color(0xFF10B981);

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF3433A8), Color(0xFF625FF2), Color(0xFF907DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF12AA91), Color(0xFF4DD5B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF26345D).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.72),
      blurRadius: 0,
      offset: const Offset(0, -1),
    ),
  ];

  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: const Color(0xFF202A50).withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];
}

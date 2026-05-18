import 'package:flutter/material.dart';

/// Design tokens màu sắc — palette "honey enterprise":
/// vàng brand làm primary, nền/text dùng gray neutral chuẩn.
class AppColors {
  AppColors._();

  // ── Brand (giữ vàng BeeGuard, tinh chỉnh nhẹ cho contrast tốt hơn) ──
  static const Color primary = Color(0xFFF5B400);
  static const Color primaryDark = Color(0xFFD99800);
  static const Color primaryForeground = Color(0xFF1A1306);

  // Surface vàng nhạt (dùng cho chip, badge nhấn)
  static const Color secondary = Color(0xFFFFF7E0);
  static const Color secondaryForeground = Color(0xFF6B4F00);
  static const Color accent = Color(0xFFFFF1C2);
  static const Color accentForeground = Color(0xFF6B4F00);

  // ── Neutrals (Tailwind-style gray scale, đậm chuẩn enterprise) ──
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ── Surfaces / Text aliases (giữ tên cũ để không break 546 callers) ──
  static const Color background = gray50;            // app background
  static const Color foreground = gray900;           // primary text
  static const Color card = Colors.white;            // surface
  static const Color cardForeground = gray900;
  static const Color muted = gray100;                // subtle background
  static const Color mutedForeground = gray500;      // secondary text
  static const Color inputBackground = gray100;
  static const Color border = gray200;
  static const Color divider = gray200;

  // ── Semantic ──
  static const Color success = Color(0xFF16A34A);
  static const Color successForeground = Color(0xFFFFFFFF);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningForeground = Color(0xFFFFFFFF);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color destructiveSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // ── Chart palette (dùng cho insights) ──
  static const Color chart1 = Color(0xFFF5B400);  // honey
  static const Color chart2 = Color(0xFF16A34A);  // green
  static const Color chart3 = Color(0xFF2563EB);  // blue
  static const Color chart4 = Color(0xFFF97316);  // orange
  static const Color chart5 = Color(0xFF8B5CF6);  // purple

  // ── Switch ──
  static const Color switchBackground = gray300;
}

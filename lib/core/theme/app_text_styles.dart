import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Display — large financial figures, net worth headline
  static TextStyle displayLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w700, height: 1.1, color: _text(context));

  static TextStyle displayMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, color: _text(context));

  // Headings
  static TextStyle headingLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25, color: _text(context));

  static TextStyle headingMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: _text(context));

  static TextStyle headingSmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: _text(context));

  // Body
  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: _text(context));

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: _text(context));

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: _textSecondary(context));

  // Labels
  static TextStyle labelLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: _text(context));

  static TextStyle labelMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: _textSecondary(context));

  static TextStyle labelSmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, height: 1.4, color: _textTertiary(context));

  // Monospace — amounts, account numbers
  static TextStyle amount(BuildContext context, {double fontSize = 16}) =>
      GoogleFonts.interTight(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: _text(context),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Helpers
  static Color _text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText;

  static Color _textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  static Color _textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
}

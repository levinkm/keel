import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const royalBlue = Color(0xFF4169E1);
  static const royalBlueHover = Color(0xFF365CC5);
  static const royalBluePressed = Color(0xFF2F50B5);
  static const powderBlue = Color(0xFFDFE7F5);
  static const slateBlue = Color(0xFF8099D5);

  // Light theme surfaces
  static const lightBackground = Color(0xFFF4F7FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSecondary = Color(0xFFEDF1F8);
  static const lightBorder = Color(0xFFDFE7F5);

  // Dark theme surfaces
  static const darkBackground = Color(0xFF101827);
  static const darkSurface = Color(0xFF1B2638);
  static const darkSurfaceElevated = Color(0xFF222F43);
  static const darkBorder = Color(0xFF34435A);

  // Light typography
  static const lightText = Color(0xFF18243A);
  static const lightTextSecondary = Color(0xFF68758B);
  static const lightTextTertiary = Color(0xFF8793A7);
  static const lightTextInverse = Color(0xFFFFFFFF);
  static const lightTextLink = Color(0xFF2F50B5);
  static const lightTextDisabled = Color(0xFFA6AFBF);

  // Dark typography
  static const darkText = Color(0xFFEDF2FC);
  static const darkTextSecondary = Color(0xFFA8B4C8);
  static const darkTextTertiary = Color(0xFF8290A6);
  static const darkTextInverse = Color(0xFF101827);
  static const darkTextLink = Color(0xFF9BB3FF);
  static const darkTextDisabled = Color(0xFF65738A);

  // Status accents
  static const success = Color(0xFF668C87);
  static const warning = Color(0xFFB49A70);
  static const error = Color(0xFFB77D87);
  static const info = Color(0xFF8099D5);

  // Status surfaces — light
  static const successSurface = Color(0xFFE8F0ED);
  static const warningSurface = Color(0xFFF2EBDD);
  static const errorSurface = Color(0xFFF3E7E9);
  static const infoSurface = Color(0xFFE8EDFC);

  // Status surfaces — dark
  static const successSurfaceDark = Color(0xFF253B3A);
  static const warningSurfaceDark = Color(0xFF3D3529);
  static const errorSurfaceDark = Color(0xFF422D36);
  static const infoSurfaceDark = Color(0xFF273653);

  // Financial charts
  static const chartPrimary = royalBlue;
  static const chartSecondary = slateBlue;
  static const chartAssets = success;
  static const chartLiabilities = error;
  static const chartPlanned = warning;
  static const chartProjectionRange = powderBlue;

  // Interaction states
  static const focusRing = slateBlue;
  static const selectedSurface = infoSurface;
  static const disabledSurface = Color(0xFFE5EAF2);
  static const disabledForeground = Color(0xFF8793A7);
}

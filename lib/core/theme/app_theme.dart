import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textDisabled = isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.royalBlue,
      onPrimary: AppColors.lightTextInverse,
      primaryContainer: AppColors.powderBlue,
      onPrimaryContainer: AppColors.lightText,
      secondary: AppColors.slateBlue,
      onSecondary: AppColors.lightTextInverse,
      secondaryContainer: AppColors.infoSurface,
      onSecondaryContainer: AppColors.lightText,
      error: AppColors.error,
      onError: AppColors.lightTextInverse,
      errorContainer: isDark ? AppColors.errorSurfaceDark : AppColors.errorSurface,
      onErrorContainer: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      scrim: Colors.black54,
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.lightText : AppColors.darkText,
      inversePrimary: AppColors.slateBlue,
    );

    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: base,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabledSurface,
          disabledForegroundColor: textDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royalBlue,
          side: const BorderSide(color: AppColors.royalBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.royalBlue,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textDisabled),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: surface,
        selectedTileColor: isDark ? AppColors.infoSurfaceDark : AppColors.infoSurface,
        selectedColor: AppColors.royalBlue,
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceSecondary,
        selectedColor: AppColors.powderBlue,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: AppColors.royalBlue),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.royalBlue,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        indicatorColor: isDark ? AppColors.infoSurfaceDark : AppColors.infoSurface,
        useIndicator: true,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightText,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        barrierColor: Colors.black38,
      ),

      focusColor: AppColors.focusRing.withValues(alpha: 0.2),
      highlightColor: AppColors.royalBlue.withValues(alpha: 0.08),
      splashColor: AppColors.royalBlue.withValues(alpha: 0.12),
    );
  }
}

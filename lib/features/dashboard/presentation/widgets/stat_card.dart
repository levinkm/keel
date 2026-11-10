import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend; // e.g. '+3.2%'
  final bool? trendPositive;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendPositive,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final trendColor = trendPositive == null
        ? textSecondary
        : trendPositive!
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: textSecondary)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  trendPositive == true ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 11,
                  color: trendColor,
                ),
                const SizedBox(width: 3),
                Text(trend!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: trendColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

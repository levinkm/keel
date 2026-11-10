import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';

class BudgetStatusCard extends StatelessWidget {
  final List<BudgetLine> lines;
  final Map<String, int> actualByAccount;

  const BudgetStatusCard({
    super.key,
    required this.lines,
    required this.actualByAccount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 16),
          if (lines.isEmpty)
            Text('No budget set for this period',
                style: TextStyle(fontSize: 13, color: textTertiary))
          else
            ...lines.map((line) {
              final actual = actualByAccount[line.accountId] ?? 0;
              final ratio = line.plannedMinor == 0
                  ? 0.0
                  : (actual / line.plannedMinor).clamp(0.0, 1.0);
              final barColor = ratio >= 1.0
                  ? AppColors.error
                  : ratio >= 0.8
                      ? AppColors.warning
                      : AppColors.success;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(line.bucket,
                              style: TextStyle(fontSize: 12, color: textPrimary)),
                        ),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: trackColor,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmt(actual)} of ${_fmt(line.plannedMinor)}',
                      style: TextStyle(fontSize: 10, color: textTertiary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

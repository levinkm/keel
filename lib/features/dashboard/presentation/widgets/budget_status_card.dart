import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
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
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final totalPlanned = lines.fold(0, (s, l) => s + l.plannedMinor);
    final totalActual = lines.fold(0, (s, l) => s + (actualByAccount[l.accountId] ?? 0));
    final overallRatio = totalPlanned == 0 ? 0.0 : (totalActual / totalPlanned).clamp(0.0, 1.0);
    final overallColor = overallRatio >= 1.0 ? AppColors.error : overallRatio >= 0.8 ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Budget',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
              const Spacer(),
              if (totalPlanned > 0)
                Text(
                  '${(overallRatio * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: overallColor,
                  ),
                ),
            ],
          ),
          if (totalPlanned > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spent', style: TextStyle(fontSize: 10, color: textTertiary)),
                      const SizedBox(height: 2),
                      BlurredAmount(
                        text: _fmt(totalActual),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget', style: TextStyle(fontSize: 10, color: textTertiary)),
                      const SizedBox(height: 2),
                      BlurredAmount(
                        text: _fmt(totalPlanned),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textTertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remaining', style: TextStyle(fontSize: 10, color: textTertiary)),
                      const SizedBox(height: 2),
                      BlurredAmount(
                        text: _fmt((totalPlanned - totalActual).clamp(0, totalPlanned)),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: overallColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: overallRatio,
                minHeight: 6,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(overallColor),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (lines.isEmpty)
            Text('No budget set for this period',
                style: TextStyle(fontSize: 13, color: textTertiary))
          else
            ...lines.take(6).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final line = entry.value;
              final actual = actualByAccount[line.accountId] ?? 0;
              final ratio = line.plannedMinor == 0
                  ? 0.0
                  : (actual / line.plannedMinor).clamp(0.0, 1.0);
              final barColor = ratio >= 1.0
                  ? AppColors.error
                  : ratio >= 0.8
                      ? AppColors.warning
                      : AppColors.success;

              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: divider.withValues(alpha: 0.4), indent: 0, endIndent: 0),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                              '${_fmt(actual)} / ${_fmt(line.plannedMinor)}',
                              style: TextStyle(fontSize: 11, color: textTertiary,
                                  fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${(ratio * 100).toStringAsFixed(0)}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: barColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 4,
                            backgroundColor: trackColor,
                            valueColor: AlwaysStoppedAnimation(barColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

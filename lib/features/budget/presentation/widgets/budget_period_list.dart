import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';

class BudgetPeriodList extends StatelessWidget {
  final List<String> periods;
  final String selectedPeriod;
  final Map<String, BudgetPlan?> planCache;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewPeriod;

  const BudgetPeriodList({
    super.key,
    required this.periods,
    required this.selectedPeriod,
    required this.planCache,
    required this.onSelect,
    required this.onNewPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final selectedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    return Container(
      width: sidebarWidth(context),
      color: bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Text('Budget',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: onNewPeriod,
                  child: Icon(Icons.add, size: 18, color: AppColors.royalBlue),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: periods.length,
              itemBuilder: (context, i) {
                final period = periods[i];
                final isSelected = period == selectedPeriod;
                final plan = planCache[period];
                final totalBudgeted = plan?.lines.fold(0, (s, l) => s + l.plannedMinor) ?? 0;
                final lineCount = plan?.lines.length ?? 0;

                return GestureDetector(
                  onTap: () => onSelect(period),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.royalBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatPeriod(period),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? textPrimary : textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                plan == null
                                    ? 'No plan'
                                    : '$lineCount ${lineCount == 1 ? 'line' : 'lines'}',
                                style: TextStyle(fontSize: 11, color: textTertiary),
                              ),
                            ],
                          ),
                        ),
                        if (plan != null && totalBudgeted > 0)
                          Text(
                            _fmt(totalBudgeted),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatPeriod(String period) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final parts = period.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

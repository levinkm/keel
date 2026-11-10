import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';

class EnvelopeBar extends StatelessWidget {
  final int totalIncomeMinor;
  final int totalBudgetedMinor;

  const EnvelopeBar({
    super.key,
    required this.totalIncomeMinor,
    required this.totalBudgetedMinor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    if (totalIncomeMinor == 0) return const SizedBox.shrink();

    final allocated = totalBudgetedMinor.clamp(0, totalIncomeMinor);
    final unallocated = totalIncomeMinor - allocated;
    final ratio = allocated / totalIncomeMinor;
    final isOver = totalBudgetedMinor > totalIncomeMinor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Envelope',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary)),
              const Spacer(),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Over-allocated by ${_fmt(totalBudgetedMinor - totalIncomeMinor)}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error),
                  ),
                )
              else
                Text(
                  '${_fmt(unallocated)} unallocated',
                  style: TextStyle(fontSize: 11, color: textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(
                  isOver ? AppColors.error : AppColors.royalBlue),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(
                  label: 'Income',
                  value: _fmt(totalIncomeMinor),
                  color: textPrimary),
              const SizedBox(width: 16),
              _Chip(
                  label: 'Budgeted',
                  value: _fmt(totalBudgetedMinor),
                  color: isOver ? AppColors.error : AppColors.royalBlue),
              const SizedBox(width: 16),
              _Chip(
                  label: isOver ? 'Over' : 'Free',
                  value: _fmt((totalIncomeMinor - totalBudgetedMinor).abs()),
                  color: isOver ? AppColors.error : AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: textTertiary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}

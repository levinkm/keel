import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';

class LoanListTile extends StatelessWidget {
  final Loan loan;
  final LoanSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const LoanListTile({
    super.key,
    required this.loan,
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final selectedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightBorder;

    final isBorrowed = loan.direction == LoanDirection.borrowed;
    final directionColor = isBorrowed ? AppColors.error : AppColors.success;
    final paidRatio = loan.principalMinor == 0
        ? 0.0
        : 1.0 - (summary.outstandingMinor / loan.principalMinor).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
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
              height: 40,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loan.counterparty,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: loan.status == LoanStatus.active
                                ? textPrimary
                                : textTertiary,
                          ),
                        ),
                      ),
                      // Direction arrow
                      Icon(
                        isBorrowed ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 11,
                        color: directionColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmt(summary.outstandingMinor),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: paidRatio,
                      minHeight: 3,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation(
                        loan.status == LoanStatus.active
                            ? (summary.isOverdue ? AppColors.error : AppColors.royalBlue)
                            : textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${(paidRatio * 100).toStringAsFixed(0)}% paid',
                        style: TextStyle(fontSize: 10, color: textTertiary),
                      ),
                      const Spacer(),
                      if (summary.isOverdue)
                        _Badge(
                          label: '${summary.daysOverdue}d overdue',
                          color: AppColors.error,
                        )
                      else if (loan.status == LoanStatus.settled)
                        _Badge(label: 'Settled', color: AppColors.success)
                      else if (loan.status == LoanStatus.writtenOff)
                        _Badge(label: 'Written off', color: textTertiary)
                      else if (loan.isSalaryDeducted)
                        _Badge(label: 'Salary', color: AppColors.info),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      );
}

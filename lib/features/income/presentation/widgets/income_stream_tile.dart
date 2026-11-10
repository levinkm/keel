import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';

class IncomeStreamTile extends StatelessWidget {
  final IncomeStream stream;
  final int receivedMinor;
  final bool isSelected;
  final VoidCallback onTap;

  const IncomeStreamTile({
    super.key,
    required this.stream,
    required this.receivedMinor,
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

    final ratio = stream.amountMinor == 0
        ? 0.0
        : (receivedMinor / stream.amountMinor).clamp(0.0, 1.0);
    final barColor = ratio >= 1.0
        ? AppColors.success
        : ratio >= 0.5
            ? AppColors.royalBlue
            : AppColors.warning;

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
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.royalBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon(stream.type), size: 15,
                  color: stream.isActive ? AppColors.royalBlue : textTertiary),
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
                          stream.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: stream.isActive ? textPrimary : textTertiary,
                          ),
                        ),
                      ),
                      Text(
                        _fmt(receivedMinor),
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
                      value: ratio,
                      minHeight: 3,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation(
                          stream.isActive ? barColor : textTertiary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt(receivedMinor)} of ${_fmt(stream.amountMinor)}  ${_freqLabel(stream.frequency)}',
                    style: TextStyle(fontSize: 10, color: textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(IncomeType t) => switch (t) {
        IncomeType.salary => Icons.work_outline,
        IncomeType.business => Icons.storefront_outlined,
        IncomeType.farming => Icons.grass_outlined,
        IncomeType.rent => Icons.home_outlined,
        IncomeType.dividends => Icons.trending_up,
        IncomeType.interest => Icons.account_balance_outlined,
        IncomeType.sideWork => Icons.handyman_outlined,
        IncomeType.oneOff => Icons.bolt_outlined,
      };

  String _freqLabel(IncomeFrequency f) => switch (f) {
        IncomeFrequency.monthly => 'Monthly',
        IncomeFrequency.weekly => 'Weekly',
        IncomeFrequency.irregular => 'Irregular',
        IncomeFrequency.scheduled => 'Scheduled',
      };

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';

class AmortizationTable extends StatelessWidget {
  final List<AmortizationRow> schedule;
  final bool isDark;

  const AmortizationTable({
    super.key,
    required this.schedule,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final paidBg = isDark ? AppColors.successSurfaceDark : AppColors.successSurface;
    final overdueBg = isDark ? AppColors.errorSurfaceDark : AppColors.errorSurface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Amortization schedule',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceSecondary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(0)),
            ),
            child: Row(
              children: [
                _Col('Mo.', 32, textTertiary, TextAlign.center),
                _Col('Due date', 90, textTertiary, TextAlign.left),
                _Col('Opening', 90, textTertiary, TextAlign.right),
                _Col('Principal', 90, textTertiary, TextAlign.right),
                _Col('Interest', 80, textTertiary, TextAlign.right),
                _Col('Instalment', 90, textTertiary, TextAlign.right),
                _Col('Closing', 90, textTertiary, TextAlign.right),
                const SizedBox(width: 60),
              ],
            ),
          ),
          Divider(height: 1, color: divider),
          ...schedule.map((row) {
            final rowBg = row.isPaid
                ? paidBg
                : row.isOverdue
                    ? overdueBg
                    : Colors.transparent;
            return Column(
              children: [
                Container(
                  color: rowBg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(
                    children: [
                      _Col('${row.month}', 32, textTertiary, TextAlign.center),
                      _Col(_fmtDate(row.dueDate), 90, textSecondary, TextAlign.left),
                      _Col(_fmt(row.openingBalanceMinor), 90, textPrimary, TextAlign.right),
                      _Col(_fmt(row.principalMinor), 90, AppColors.royalBlue, TextAlign.right),
                      _Col(_fmt(row.interestMinor), 80, AppColors.warning, TextAlign.right),
                      _Col(_fmt(row.instalmentMinor), 90, textPrimary, TextAlign.right,
                          bold: true),
                      _Col(_fmt(row.closingBalanceMinor), 90, textSecondary, TextAlign.right),
                      SizedBox(
                        width: 60,
                        child: row.isPaid
                            ? Icon(Icons.check_circle_outline,
                                size: 14, color: AppColors.success)
                            : row.isOverdue
                                ? Icon(Icons.warning_amber_outlined,
                                    size: 14, color: AppColors.error)
                                : null,
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: divider.withValues(alpha: 0.4)),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _Col extends StatelessWidget {
  final String text;
  final double width;
  final Color color;
  final TextAlign align;
  final bool bold;

  const _Col(this.text, this.width, this.color, this.align,
      {this.bold = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}

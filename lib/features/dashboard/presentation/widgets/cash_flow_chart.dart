import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/dashboard/presentation/bloc/dashboard_cubit.dart';

class CashFlowChart extends StatelessWidget {
  final List<MonthlyCashFlow> data;

  const CashFlowChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cash Flow',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary)),
              const Spacer(),
              _Legend(color: AppColors.chartPrimary, label: 'Income'),
              const SizedBox(width: 12),
              _Legend(color: AppColors.chartLiabilities, label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: data.isEmpty
                ? Center(
                    child: Text('No data',
                        style: TextStyle(fontSize: 12, color: textTertiary)))
                : CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _BarChartPainter(data: data, isDark: isDark),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data
                .map((d) => Text(
                      _shortMonth(d.period),
                      style: TextStyle(fontSize: 10, color: textTertiary),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _shortMonth(String period) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final parts = period.split('-');
    return months[int.parse(parts[1])];
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: textTertiary)),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MonthlyCashFlow> data;
  final bool isDark;

  _BarChartPainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold(0, (m, d) =>
        [m, d.incomeMinor, d.expensesMinor].reduce((a, b) => a > b ? a : b));
    if (maxVal == 0) return;

    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // 3 horizontal grid lines
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (1 - i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final groupWidth = size.width / data.length;
    final barWidth = groupWidth * 0.28;
    final gap = groupWidth * 0.06;

    final incomePaint = Paint()
      ..color = AppColors.chartPrimary.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final expensePaint = Paint()
      ..color = AppColors.chartLiabilities.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final centerX = groupWidth * i + groupWidth / 2;

      final incomeH = (d.incomeMinor / maxVal) * size.height;
      final expenseH = (d.expensesMinor / maxVal) * size.height;

      final incomeRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX - barWidth - gap / 2, size.height - incomeH, barWidth, incomeH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      final expenseRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX + gap / 2, size.height - expenseH, barWidth, expenseH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      canvas.drawRRect(incomeRect, incomePaint);
      canvas.drawRRect(expenseRect, expensePaint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.data != data || old.isDark != isDark;
}

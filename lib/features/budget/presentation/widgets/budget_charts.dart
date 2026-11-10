import 'dart:math';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';

class BudgetCharts extends StatelessWidget {
  final BudgetPlan plan;
  final Map<String, int> actuals;
  final Map<String, int> prevActuals;

  const BudgetCharts({
    super.key,
    required this.plan,
    required this.actuals,
    required this.prevActuals,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final lines = plan.lines;
    if (lines.isEmpty) return const SizedBox.shrink();

    final totalActual = lines.fold(0, (s, l) => s + (actuals[l.accountId] ?? 0));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pie chart
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spend breakdown',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _PiePainter(
                          slices: lines.map((l) => (
                            actuals[l.accountId] ?? 0,
                            _colorForIndex(lines.indexOf(l)),
                          )).toList(),
                          total: totalActual,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lines.asMap().entries.map((e) {
                          final line = e.value;
                          final spent = actuals[line.accountId] ?? 0;
                          final pct = totalActual == 0
                              ? 0.0
                              : spent / totalActual * 100;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _colorForIndex(e.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(line.bucket,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11, color: textSecondary)),
                                ),
                                Text('${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textTertiary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // MoM comparison
        Expanded(
          child: Container(
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
                    Text('vs last month',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary)),
                    const Spacer(),
                    _Legend(color: AppColors.royalBlue, label: 'This month', isDark: isDark),
                    const SizedBox(width: 10),
                    _Legend(color: AppColors.slateBlue.withValues(alpha: 0.4), label: 'Last month', isDark: isDark),
                  ],
                ),
                const SizedBox(height: 16),
                ...lines.map((line) {
                  final curr = actuals[line.accountId] ?? 0;
                  final prev = prevActuals[line.accountId] ?? 0;
                  final maxVal = [curr, prev, line.effectivePlanned].reduce(max);
                  final currRatio = maxVal == 0 ? 0.0 : curr / maxVal;
                  final prevRatio = maxVal == 0 ? 0.0 : prev / maxVal;
                  final diff = curr - prev;
                  final diffColor = diff > 0 ? AppColors.error : AppColors.success;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(line.bucket,
                                  style: TextStyle(
                                      fontSize: 11, color: textSecondary)),
                            ),
                            if (prev > 0)
                              Text(
                                '${diff >= 0 ? '+' : ''}${_fmt(diff)}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: diffColor),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            // Prev bar (background)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: prevRatio,
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : AppColors.lightSurfaceSecondary,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.slateBlue.withValues(alpha: 0.35)),
                              ),
                            ),
                            // Current bar (overlay)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: currRatio,
                                minHeight: 8,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.royalBlue.withValues(alpha: 0.8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _colorForIndex(int i) {
    const colors = [
      AppColors.royalBlue,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.slateBlue,
      AppColors.info,
      Color(0xFF7B68EE),
      Color(0xFF20B2AA),
    ];
    return colors[i % colors.length];
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _PiePainter extends CustomPainter {
  final List<(int, Color)> slices;
  final int total;

  _PiePainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) {
      final paint = Paint()
        ..color = AppColors.slateBlue.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 6, paint);
      return;
    }

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    double startAngle = -pi / 2;

    for (final slice in slices) {
      final sweep = slice.$1 / total * 2 * pi;
      final paint = Paint()
        ..color = slice.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.slices != slices || old.total != total;
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _Legend({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    return Row(
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textTertiary)),
      ],
    );
  }
}

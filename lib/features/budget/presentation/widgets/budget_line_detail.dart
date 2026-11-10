import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/presentation/bloc/budget_cubit.dart';

class BudgetLineDetail extends StatelessWidget {
  final BudgetLine line;
  final int actual;
  final int prevActual;
  final BudgetLineSparkline? sparkline;
  final List<Account> assetAccounts;
  final void Function(int amount, String description, Account fromAccount) onQuickSpend;

  const BudgetLineDetail({
    super.key,
    required this.line,
    required this.actual,
    required this.prevActual,
    required this.sparkline,
    required this.assetAccounts,
    required this.onQuickSpend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final effective = line.effectivePlanned;
    final remaining = effective - actual;
    final isOver = actual > effective;
    final diff = actual - prevActual;
    final momColor = diff > 0 ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _Mini(label: 'Planned', value: _fmt(line.plannedMinor),
                  color: textPrimary, isDark: isDark),
              if (line.rolloverMinor > 0) ...[
                const SizedBox(width: 16),
                _Mini(label: 'Rollover', value: '+${_fmt(line.rolloverMinor)}',
                    color: AppColors.success, isDark: isDark),
              ],
              const SizedBox(width: 16),
              _Mini(label: 'Spent', value: _fmt(actual),
                  color: isOver ? AppColors.error : textPrimary, isDark: isDark),
              const SizedBox(width: 16),
              _Mini(
                label: isOver ? 'Over by' : 'Remaining',
                value: _fmt(remaining.abs()),
                color: isOver ? AppColors.error : AppColors.success,
                isDark: isDark,
              ),
              const Spacer(),
              if (prevActual > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: momColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: momColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_fmt(diff.abs())} vs last month',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: momColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Sparkline
          if (sparkline != null && sparkline!.monthlyActuals.any((v) => v > 0)) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _SparklinePainter(
                  values: sparkline!.monthlyActuals,
                  planned: line.plannedMinor,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: sparkline!.periods.map((p) => Text(
                _shortMonth(p),
                style: TextStyle(fontSize: 9, color: textTertiary),
              )).toList(),
            ),
          ],

          // Notes
          if (line.notes != null && line.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.notes_outlined, size: 12, color: textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(line.notes!,
                      style: TextStyle(fontSize: 11, color: textTertiary)),
                ),
              ],
            ),
          ],

          // Quick spend button
          if (assetAccounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showQuickSpend(context, isDark, surface,
                    elevated, textPrimary, textSecondary),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Quick spend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.royalBlue,
                  side: BorderSide(
                      color: AppColors.royalBlue.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showQuickSpend(BuildContext context, bool isDark, Color surface,
      Color elevated, Color textPrimary, Color textSecondary) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: line.bucket);
    Account selectedAccount = assetAccounts.first;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 380,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick spend — ${line.bucket}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmt(actual)} spent of ${_fmt(line.effectivePlanned)} budgeted',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Text('Amount (KES)',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    placeholder: '0',
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    placeholderStyle:
                        TextStyle(fontSize: 14, color: textSecondary),
                    decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 12),
                  Text('Description',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: descCtrl,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    placeholderStyle:
                        TextStyle(fontSize: 14, color: textSecondary),
                    decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 12),
                  Text('Pay from',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Account>(
                        value: selectedAccount,
                        isExpanded: true,
                        dropdownColor: surface,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        items: assetAccounts
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setInner(() => selectedAccount = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text('Cancel',
                            style: TextStyle(
                                fontSize: 14, color: textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        color: AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          final amount =
                              double.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (amount <= 0) return;
                          Navigator.of(dialogContext).pop();
                          onQuickSpend(
                            (amount * 100).round(),
                            descCtrl.text.trim().isEmpty
                                ? line.bucket
                                : descCtrl.text.trim(),
                            selectedAccount,
                          );
                        },
                        child: const Text('Record',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortMonth(String period) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[int.parse(period.split('-')[1])];
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _Mini({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
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

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final int planned;
  final bool isDark;

  _SparklinePainter({required this.values, required this.planned, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [planned, ...values].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    // Planned line
    final plannedY = size.height * (1 - planned / maxVal);
    final dashedPaint = Paint()
      ..color = AppColors.slateBlue.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, plannedY), Offset(x + 4, plannedY), dashedPaint);
    }

    final barW = size.width / values.length * 0.55;
    for (int i = 0; i < values.length; i++) {
      final x = size.width / values.length * i + size.width / values.length / 2;
      final h = (values[i] / maxVal) * size.height;
      final color = values[i] > planned ? AppColors.error : AppColors.royalBlue;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barW / 2, size.height - h, barW, h),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.planned != planned;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/income/presentation/bloc/income_cubit.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';

class IncomeDetailPanel extends StatelessWidget {
  final IncomeStream stream;
  final int receivedMinor;
  final List<StreamActivity> sparkline;
  final List<JournalEntry> paymentHistory;
  final List<Account> incomeAccounts;
  final String period;
  final VoidCallback onEdit;
  final void Function(int amount, String note) onMarkReceived;
  final VoidCallback onToggleActive;

  const IncomeDetailPanel({
    super.key,
    required this.stream,
    required this.receivedMinor,
    required this.sparkline,
    required this.paymentHistory,
    required this.incomeAccounts,
    required this.period,
    required this.onEdit,
    required this.onMarkReceived,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final ratio = stream.amountMinor == 0
        ? 0.0
        : (receivedMinor / stream.amountMinor).clamp(0.0, 1.0);
    final pending = (stream.amountMinor - receivedMinor).clamp(0, stream.amountMinor);

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            stream.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _Tag(
                            label: _typeLabel(stream.type),
                            color: AppColors.royalBlue,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          if (!stream.isActive)
                            _Tag(label: 'Inactive', color: textTertiary, isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_freqLabel(stream.frequency)}  •  ${stream.currency}',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      onPressed: onEdit,
                      child: Text('Edit',
                          style: TextStyle(fontSize: 13, color: AppColors.royalBlue)),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      onPressed: onToggleActive,
                      child: Text(
                        stream.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                            fontSize: 13,
                            color: stream.isActive ? AppColors.error : AppColors.success),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // This period summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_periodLabel(period),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatItem(
                          label: 'Expected',
                          value: _fmt(stream.amountMinor),
                          color: textPrimary),
                      const SizedBox(width: 32),
                      _StatItem(
                          label: 'Received',
                          value: _fmt(receivedMinor),
                          color: AppColors.success),
                      const SizedBox(width: 32),
                      _StatItem(
                          label: 'Pending',
                          value: _fmt(pending),
                          color: pending > 0 ? AppColors.warning : textTertiary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor:
                          isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary,
                      valueColor: AlwaysStoppedAnimation(
                          ratio >= 1.0 ? AppColors.success : AppColors.royalBlue),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}% received',
                    style: TextStyle(fontSize: 11, color: textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mark received button
            if (stream.isActive && pending > 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showMarkReceivedDialog(context, pending),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text('Mark received  •  ${_fmt(pending)} pending'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            if (stream.isActive && pending > 0) const SizedBox(height: 12),

            // 6-month sparkline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('6-month history',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: sparkline.isEmpty
                        ? Center(
                            child: Text('No data',
                                style: TextStyle(fontSize: 12, color: textTertiary)))
                        : CustomPaint(
                            size: const Size(double.infinity, 80),
                            painter: _SparklinePainter(
                              data: sparkline,
                              expected: stream.amountMinor,
                              isDark: isDark,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: sparkline
                        .map((s) => Text(_shortMonth(s.period),
                            style: TextStyle(fontSize: 10, color: textTertiary)))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Payment history
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment history',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary)),
                  const SizedBox(height: 12),
                  if (paymentHistory.isEmpty)
                    Text('No payments recorded yet.',
                        style: TextStyle(fontSize: 13, color: textTertiary))
                  else
                    ...paymentHistory.asMap().entries.map((e) {
                      final i = e.key;
                      final entry = e.value;
                      final amount = entry.lines
                          .where((l) =>
                              l.accountId == stream.accountId &&
                              l.side == JournalSide.credit)
                          .fold(0, (s, l) => s + l.amountMinor);
                      return Column(
                        children: [
                          if (i > 0)
                            Divider(
                                height: 1,
                                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                    .withValues(alpha: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceElevated
                                        : AppColors.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.date.day}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: textSecondary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13, color: textPrimary)),
                                      Text(
                                        _formatDate(entry.date),
                                        style: TextStyle(
                                            fontSize: 11, color: textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${_fmt(amount)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                    fontFeatures: [FontFeature.tabularFigures()],
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
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkReceivedDialog(BuildContext context, int pendingMinor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final amountCtrl = TextEditingController(
        text: (pendingMinor / 100).toStringAsFixed(0));
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark as received',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text('This will post a journal entry crediting ${stream.name}.',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 20),
                Text('Amount (KES)',
                    style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                  decoration: BoxDecoration(
                      color: elevated, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                const SizedBox(height: 14),
                Text('Note (optional)',
                    style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: noteCtrl,
                  placeholder: 'e.g. October salary',
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                  decoration: BoxDecoration(
                      color: elevated, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancel',
                          style: TextStyle(fontSize: 14, color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        Navigator.of(dialogContext).pop();
                        onMarkReceived((amount * 100).round(), noteCtrl.text.trim());
                      },
                      child: const Text('Confirm',
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
    );
  }

  String _typeLabel(IncomeType t) => switch (t) {
        IncomeType.salary => 'Salary',
        IncomeType.business => 'Business',
        IncomeType.farming => 'Farming',
        IncomeType.rent => 'Rent',
        IncomeType.dividends => 'Dividends',
        IncomeType.interest => 'Interest',
        IncomeType.sideWork => 'Side work',
        IncomeType.oneOff => 'One-off',
      };

  String _freqLabel(IncomeFrequency f) => switch (f) {
        IncomeFrequency.monthly => 'Monthly',
        IncomeFrequency.weekly => 'Weekly',
        IncomeFrequency.irregular => 'Irregular',
        IncomeFrequency.scheduled => 'Scheduled',
      };

  String _periodLabel(String period) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final parts = period.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }

  String _shortMonth(String period) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[int.parse(period.split('-')[1])];
  }

  String _formatDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Sparkline painter ────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<StreamActivity> data;
  final int expected;
  final bool isDark;

  _SparklinePainter({required this.data, required this.expected, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [expected, ...data.map((d) => d.receivedMinor)]
        .reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    // Expected line
    final expectedY = size.height * (1 - expected / maxVal);
    final dashedPaint = Paint()
      ..color = AppColors.slateBlue.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashed(canvas, Offset(0, expectedY), Offset(size.width, expectedY), dashedPaint);

    // Bar chart
    final barWidth = size.width / data.length * 0.5;
    for (int i = 0; i < data.length; i++) {
      final x = size.width / data.length * i + size.width / data.length / 2;
      final h = (data[i].receivedMinor / maxVal) * size.height;
      final color = data[i].receivedMinor >= expected
          ? AppColors.success
          : AppColors.royalBlue;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barWidth / 2, size.height - h, barWidth, h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double distance = 0;
    final total = (end - start).distance;
    final dir = (end - start) / total;
    while (distance < total) {
      final from = start + dir * distance;
      final to = start + dir * (distance + dashWidth).clamp(0, total);
      canvas.drawLine(from, to, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.expected != expected;
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _Tag({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

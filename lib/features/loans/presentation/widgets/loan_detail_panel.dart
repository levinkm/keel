import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/loans/presentation/widgets/amortization_table.dart';

class LoanDetailPanel extends StatelessWidget {
  final Loan loan;
  final LoanSummary summary;
  final List<LoanEvent> events;
  final VoidCallback onEdit;
  final void Function(LoanEventType type, int amount, String note) onRecordEvent;
  final VoidCallback onSettle;
  final VoidCallback onWriteOff;
  final VoidCallback onReactivate;

  const LoanDetailPanel({
    super.key,
    required this.loan,
    required this.summary,
    required this.events,
    required this.onEdit,
    required this.onRecordEvent,
    required this.onSettle,
    required this.onWriteOff,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    final isBorrowed = loan.direction == LoanDirection.borrowed;
    final directionColor = isBorrowed ? AppColors.error : AppColors.success;
    final paidRatio = loan.principalMinor == 0
        ? 0.0
        : 1.0 - (summary.outstandingMinor / loan.principalMinor).clamp(0.0, 1.0);

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(loan.counterparty,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3)),
                          const SizedBox(width: 10),
                          _Tag(
                            label: isBorrowed ? 'Borrowed' : 'Lent',
                            color: directionColor,
                          ),
                          const SizedBox(width: 6),
                          _Tag(
                            label: _statusLabel(loan.status),
                            color: _statusColor(loan.status),
                          ),
                          if (loan.isSalaryDeducted) ...[
                            const SizedBox(width: 6),
                            _Tag(label: 'Salary deducted', color: AppColors.info),
                          ],
                          if (summary.isOverdue) ...[
                            const SizedBox(width: 6),
                            _Tag(
                              label: '${summary.daysOverdue}d overdue',
                              color: AppColors.error,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_methodLabel(loan.interestMethod)}  •  '
                        '${(loan.annualRateBp / 100).toStringAsFixed(1)}% p.a.  •  '
                        '${loan.termMonths} months  •  ${loan.currency}',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      onPressed: onEdit,
                      child: Text('Edit',
                          style: TextStyle(fontSize: 13, color: AppColors.royalBlue)),
                    ),
                    if (loan.status == LoanStatus.active) ...[
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        onPressed: onSettle,
                        child: Text('Settle',
                            style: TextStyle(fontSize: 13, color: AppColors.success)),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        onPressed: onWriteOff,
                        child: Text('Write off',
                            style: TextStyle(fontSize: 13, color: AppColors.error)),
                      ),
                    ] else
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        onPressed: onReactivate,
                        child: Text('Reactivate',
                            style: TextStyle(fontSize: 13, color: AppColors.warning)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Key metrics ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Metric(label: 'Principal', value: _fmt(loan.principalMinor),
                          color: textPrimary, isDark: isDark),
                      _Metric(label: 'Outstanding', value: _fmt(summary.outstandingMinor),
                          color: summary.outstandingMinor > 0 ? AppColors.error : AppColors.success,
                          isDark: isDark),
                      _Metric(label: 'Total paid', value: _fmt(summary.totalPaidMinor),
                          color: AppColors.success, isDark: isDark),
                      _Metric(label: 'Interest paid', value: _fmt(summary.interestPaidMinor),
                          color: AppColors.warning, isDark: isDark),
                      _Metric(label: 'Total interest', value: _fmt(summary.totalInterestMinor),
                          color: textSecondary, isDark: isDark),
                      _Metric(label: 'Instalment', value: _fmt(loan.instalmentMinor),
                          color: AppColors.royalBlue, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Metric(
                        label: 'Disbursed',
                        value: _fmtDate(loan.disbursementDate),
                        color: textSecondary,
                        isDark: isDark,
                      ),
                      _Metric(
                        label: 'First due',
                        value: _fmtDate(loan.firstDueDate),
                        color: textSecondary,
                        isDark: isDark,
                      ),
                      _Metric(
                        label: 'Next due',
                        value: summary.nextDueDate != null
                            ? _fmtDate(summary.nextDueDate!)
                            : '—',
                        color: summary.isOverdue ? AppColors.error : textSecondary,
                        isDark: isDark,
                      ),
                      _Metric(
                        label: 'Remaining months',
                        value: '${summary.remainingMonths}',
                        color: textPrimary,
                        isDark: isDark,
                      ),
                      _Metric(
                        label: 'Missed payments',
                        value: '${summary.missedPayments}',
                        color: summary.missedPayments > 0 ? AppColors.error : AppColors.success,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Repayment progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Repayment progress',
                              style: TextStyle(fontSize: 11, color: textTertiary)),
                          const Spacer(),
                          Text('${(paidRatio * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: paidRatio,
                          minHeight: 8,
                          backgroundColor: trackColor,
                          valueColor: AlwaysStoppedAnimation(
                            summary.isOverdue ? AppColors.error : AppColors.royalBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Action buttons ───────────────────────────────────────────────
            if (loan.status == LoanStatus.active)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showRecordDialog(
                          context, isDark, LoanEventType.instalment),
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Record payment'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecordDialog(
                          context, isDark, LoanEventType.prepayment),
                      icon: const Icon(Icons.fast_forward_outlined, size: 16),
                      label: const Text('Prepayment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(
                            color: AppColors.success.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecordDialog(
                          context, isDark, LoanEventType.fee),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Fee / Penalty'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(
                            color: AppColors.warning.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            if (loan.status == LoanStatus.active) const SizedBox(height: 12),

            // ── Amortization schedule ────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AmortizationTable(
                schedule: summary.schedule,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),

            // ── Payment history ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment history',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary)),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    Text('No payments recorded yet.',
                        style: TextStyle(fontSize: 13, color: textTertiary))
                  else
                    ...events.reversed.toList().asMap().entries.map((e) {
                      final i = e.key;
                      final event = e.value;
                      final eventColor = _eventColor(event.type);
                      return Column(
                        children: [
                          if (i > 0)
                            Divider(
                                height: 1,
                                color: (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: eventColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_eventIcon(event.type),
                                      size: 15, color: eventColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_eventLabel(event.type),
                                          style: TextStyle(
                                              fontSize: 13, color: textPrimary)),
                                      if (event.note != null)
                                        Text(event.note!,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: textTertiary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _fmt(event.amountMinor),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: eventColor,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    Text(_fmtDate(event.date),
                                        style: TextStyle(
                                            fontSize: 10, color: textTertiary)),
                                  ],
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

  void _showRecordDialog(
      BuildContext context, bool isDark, LoanEventType type) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final defaultAmount = type == LoanEventType.instalment
        ? (loan.instalmentMinor / 100).toStringAsFixed(0)
        : '';
    final amountCtrl = TextEditingController(text: defaultAmount);
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
                Text(_recordTitle(type),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 6),
                Text(loan.counterparty,
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 20),
                Text('Amount (${loan.currency})',
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
                  placeholder: 'e.g. October instalment',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancel',
                          style: TextStyle(fontSize: 14, color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        final amount =
                            double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (amount <= 0) return;
                        Navigator.of(dialogContext).pop();
                        onRecordEvent(
                            type, (amount * 100).round(), noteCtrl.text.trim());
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
    );
  }

  String _recordTitle(LoanEventType t) => switch (t) {
        LoanEventType.instalment => 'Record payment',
        LoanEventType.prepayment => 'Record prepayment',
        LoanEventType.fee => 'Record fee / penalty',
        _ => 'Record event',
      };

  Color _eventColor(LoanEventType t) => switch (t) {
        LoanEventType.instalment => AppColors.success,
        LoanEventType.prepayment => AppColors.royalBlue,
        LoanEventType.disbursement => AppColors.info,
        LoanEventType.fee || LoanEventType.penalty => AppColors.error,
        LoanEventType.topUp => AppColors.warning,
        _ => AppColors.slateBlue,
      };

  IconData _eventIcon(LoanEventType t) => switch (t) {
        LoanEventType.instalment => Icons.payments_outlined,
        LoanEventType.prepayment => Icons.fast_forward_outlined,
        LoanEventType.disbursement => Icons.account_balance_outlined,
        LoanEventType.fee => Icons.receipt_outlined,
        LoanEventType.penalty => Icons.warning_amber_outlined,
        LoanEventType.topUp => Icons.add_circle_outline,
        _ => Icons.swap_horiz,
      };

  String _eventLabel(LoanEventType t) => switch (t) {
        LoanEventType.instalment => 'Instalment payment',
        LoanEventType.prepayment => 'Prepayment',
        LoanEventType.disbursement => 'Disbursement',
        LoanEventType.fee => 'Fee',
        LoanEventType.penalty => 'Penalty',
        LoanEventType.topUp => 'Top-up',
        _ => 'Rate change',
      };

  String _statusLabel(LoanStatus s) => switch (s) {
        LoanStatus.active => 'Active',
        LoanStatus.settled => 'Settled',
        LoanStatus.writtenOff => 'Written off',
      };

  Color _statusColor(LoanStatus s) => switch (s) {
        LoanStatus.active => AppColors.success,
        LoanStatus.settled => AppColors.slateBlue,
        LoanStatus.writtenOff => AppColors.error,
      };

  String _methodLabel(InterestMethod m) => switch (m) {
        InterestMethod.reducingBalance => 'Reducing balance',
        InterestMethod.flatRate => 'Flat rate',
        InterestMethod.fixedFee => 'Fixed fee',
      };

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

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _Metric(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: textTertiary)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
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

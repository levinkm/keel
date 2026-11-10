import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';

class AccountDetailPanel extends StatelessWidget {
  final Account account;
  final int balanceMinor;
  final List<JournalEntry> history;
  final List<MonthlyBalance> sparkline;
  final List<Account> allAccounts;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final void Function(Account to, int amount, String desc) onTransfer;

  const AccountDetailPanel({
    super.key,
    required this.account,
    required this.balanceMinor,
    required this.history,
    required this.sparkline,
    required this.allAccounts,
    required this.onEdit,
    required this.onToggleActive,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final typeColor = _typeColor(account.type);

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(account.type), size: 20, color: typeColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(account.name,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3)),
                          const SizedBox(width: 8),
                          _Tag(label: _typeLabel(account.type), color: typeColor),
                          const SizedBox(width: 6),
                          _Tag(
                            label: _liquidityLabel(account.liquidity),
                            color: _liquidityColor(account.liquidity),
                          ),
                          if (!account.isActive) ...[
                            const SizedBox(width: 6),
                            _Tag(label: 'Inactive', color: AppColors.error),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(account.currency,
                          style: TextStyle(fontSize: 13, color: textSecondary)),
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
                        account.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                            fontSize: 13,
                            color: account.isActive ? AppColors.error : AppColors.success),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Balance card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current balance',
                      style: TextStyle(fontSize: 11, color: textTertiary)),
                  const SizedBox(height: 6),
                  Text(
                    _fmtFull(balanceMinor),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: balanceMinor < 0 ? AppColors.error : textPrimary,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (sparkline.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: CustomPaint(
                        size: const Size(double.infinity, 48),
                        painter: _SparklinePainter(
                            data: sparkline, isDark: isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: sparkline
                          .map((s) => Text(_shortMonth(s.period),
                              style: TextStyle(fontSize: 9, color: textTertiary)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Transfer button ──────────────────────────────────────────────
            if (account.isActive &&
                (account.type == AccountType.asset ||
                    account.type == AccountType.liability))
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showTransferDialog(context, isDark),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Transfer money'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            if (account.isActive &&
                (account.type == AccountType.asset ||
                    account.type == AccountType.liability))
              const SizedBox(height: 12),

            // ── Reconcile ────────────────────────────────────────────────────
            if (account.type == AccountType.asset ||
                account.type == AccountType.liability)
              _ReconcileCard(
                account: account,
                ledgerBalance: balanceMinor,
                isDark: isDark,
              ),
            if (account.type == AccountType.asset ||
                account.type == AccountType.liability)
              const SizedBox(height: 12),

            // ── Transaction history ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Transaction history',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary)),
                      const Spacer(),
                      Text('${history.length} entries',
                          style: TextStyle(fontSize: 11, color: textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    Text('No transactions yet.',
                        style: TextStyle(fontSize: 13, color: textTertiary))
                  else
                    ...history.asMap().entries.map((e) {
                      final i = e.key;
                      final entry = e.value;
                      // Find this account's line to determine debit/credit
                      final line = entry.lines.cast<JournalLine?>()
                          .firstWhere((l) => l?.accountId == account.id,
                              orElse: () => null);
                      final isDebit = line?.side == JournalSide.debit;
                      final amount = line?.amountMinor ?? 0;
                      final amountColor =
                          isDebit ? AppColors.success : AppColors.error;
                      final sign = isDebit ? '+' : '−';

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
                                    color: isDark
                                        ? AppColors.darkSurfaceElevated
                                        : AppColors.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('${entry.date.day}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: textSecondary)),
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
                                      Text(_fmtDate(entry.date),
                                          style: TextStyle(
                                              fontSize: 11, color: textTertiary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$sign${_fmtFull(amount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: amountColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
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

  void _showTransferDialog(BuildContext context, bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final targets = allAccounts
        .where((a) => a.id != account.id && a.isActive &&
            (a.type == AccountType.asset || a.type == AccountType.liability))
        .toList();
    if (targets.isEmpty) return;

    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Account selectedTarget = targets.first;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transfer money',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const SizedBox(height: 6),
                  Text('From: ${account.name}',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                  const SizedBox(height: 20),
                  Text('To account',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: elevated, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Account>(
                        value: selectedTarget,
                        isExpanded: true,
                        dropdownColor: surface,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        items: targets
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) set(() => selectedTarget = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Amount (${account.currency})',
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
                        color: elevated, borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 14),
                  Text('Description (optional)',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: descCtrl,
                    placeholder: 'e.g. Monthly savings transfer',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    placeholderStyle:
                        TextStyle(fontSize: 14, color: textSecondary),
                    decoration: BoxDecoration(
                        color: elevated, borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                            style:
                                TextStyle(fontSize: 14, color: textSecondary)),
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
                          onTransfer(selectedTarget, (amount * 100).round(),
                              descCtrl.text.trim());
                        },
                        child: const Text('Transfer',
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

  Color _typeColor(AccountType t) => switch (t) {
        AccountType.asset => AppColors.royalBlue,
        AccountType.liability => AppColors.error,
        AccountType.equity => AppColors.slateBlue,
        AccountType.income => AppColors.success,
        AccountType.expense => AppColors.warning,
      };

  IconData _typeIcon(AccountType t) => switch (t) {
        AccountType.asset => Icons.account_balance_wallet_outlined,
        AccountType.liability => Icons.credit_card_outlined,
        AccountType.equity => Icons.pie_chart_outline,
        AccountType.income => Icons.trending_up_outlined,
        AccountType.expense => Icons.receipt_long_outlined,
      };

  String _typeLabel(AccountType t) => switch (t) {
        AccountType.asset => 'Asset',
        AccountType.liability => 'Liability',
        AccountType.equity => 'Equity',
        AccountType.income => 'Income',
        AccountType.expense => 'Expense',
      };

  Color _liquidityColor(Liquidity l) => switch (l) {
        Liquidity.instant => AppColors.success,
        Liquidity.days => AppColors.warning,
        Liquidity.locked => AppColors.slateBlue,
      };

  String _liquidityLabel(Liquidity l) => switch (l) {
        Liquidity.instant => 'Instant',
        Liquidity.days => 'Days',
        Liquidity.locked => 'Locked',
      };

  String _shortMonth(String period) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[int.parse(period.split('-')[1])];
  }

  String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmtFull(int minor) {
    final v = minor / 100;
    final abs = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${v < 0 ? '−' : ''}KES $abs';
  }
}

// ── Reconcile card ────────────────────────────────────────────────────────────

class _ReconcileCard extends StatefulWidget {
  final Account account;
  final int ledgerBalance;
  final bool isDark;

  const _ReconcileCard({
    required this.account,
    required this.ledgerBalance,
    required this.isDark,
  });

  @override
  State<_ReconcileCard> createState() => _ReconcileCardState();
}

class _ReconcileCardState extends State<_ReconcileCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _statementMinor =>
      ((double.tryParse(_ctrl.text.replaceAll(',', '')) ?? 0) * 100).round();

  int get _difference => _statementMinor - widget.ledgerBalance;

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = widget.isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = widget.isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final hasStatement = _ctrl.text.isNotEmpty;
    final isBalanced = hasStatement && _difference == 0;
    final diffColor = !hasStatement
        ? textTertiary
        : isBalanced
            ? AppColors.success
            : _difference > 0
                ? AppColors.warning
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reconcile',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ledger balance',
                        style: TextStyle(fontSize: 11, color: textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      _fmtFull(widget.ledgerBalance),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statement balance',
                        style: TextStyle(fontSize: 11, color: textTertiary)),
                    const SizedBox(height: 4),
                    CupertinoTextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      placeholder: '0',
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                      ],
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      placeholderStyle:
                          TextStyle(fontSize: 14, color: textSecondary),
                      decoration: BoxDecoration(
                          color: elevated,
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasStatement) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isBalanced
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 14,
                  color: diffColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isBalanced
                      ? 'Balanced — ledger matches statement'
                      : _difference > 0
                          ? 'Statement KES ${_fmtAbs(_difference)} higher than ledger'
                          : 'Statement KES ${_fmtAbs(_difference)} lower than ledger',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: diffColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtFull(int minor) {
    final v = minor / 100;
    final abs = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${v < 0 ? '−' : ''}KES $abs';
  }

  String _fmtAbs(int minor) {
    final v = (minor / 100).abs();
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ── Sparkline painter ─────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<MonthlyBalance> data;
  final bool isDark;

  _SparklinePainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final values = data.map((d) => d.balanceMinor.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    if (range == 0) return;

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - minVal) / range * size.height;
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) { fillPath.lineTo(p.dx, p.dy); }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.royalBlue.withValues(alpha: 0.2),
            AppColors.royalBlue.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) { linePath.lineTo(points[i].dx, points[i].dy); }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.royalBlue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 3,
          Paint()..color = AppColors.royalBlue..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
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

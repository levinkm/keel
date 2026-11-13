import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';

class RecentTransactionsCard extends StatelessWidget {
  final List<JournalEntry> entries;
  final List<Account> accounts;

  const RecentTransactionsCard({
    super.key,
    required this.entries,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    final expenseIds = accounts.where((a) => a.type == AccountType.expense).map((a) => a.id).toSet();
    final incomeIds = accounts.where((a) => a.type == AccountType.income).map((a) => a.id).toSet();
    final assetIds = accounts.where((a) => a.type == AccountType.asset).map((a) => a.id).toSet();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent transactions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
              const Spacer(),
              Text('This month',
                  style: TextStyle(fontSize: 11, color: textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No transactions this period',
                  style: TextStyle(fontSize: 13, color: textTertiary)),
            )
          else
            ...entries.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value;
              final type = _entryType(entry, expenseIds, incomeIds, assetIds);
              final amount = _amount(entry, expenseIds, incomeIds, assetIds);

              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: divider.withValues(alpha: 0.4)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(_typeIcon(type), size: 16, color: _typeColor(type)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: textPrimary)),
                              Text(
                                _dateLabel(entry.date),
                                style: TextStyle(fontSize: 11, color: textTertiary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BlurredAmount(
                              text: '${type == _TxType.income ? '+' : type == _TxType.expense ? '-' : ''}${_fmt(amount)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: type == _TxType.income
                                    ? AppColors.success
                                    : type == _TxType.expense
                                        ? AppColors.error
                                        : textSecondary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: elevated,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                _typeLabel(type),
                                style: TextStyle(fontSize: 9, color: textTertiary),
                              ),
                            ),
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
    );
  }

  _TxType _entryType(JournalEntry entry, Set<String> expenseIds, Set<String> incomeIds, Set<String> assetIds) {
    final hasExpense = entry.lines.any((l) => expenseIds.contains(l.accountId));
    final hasIncome = entry.lines.any((l) => incomeIds.contains(l.accountId));
    final assetLines = entry.lines.where((l) => assetIds.contains(l.accountId)).toList();
    final hasDebitAsset = assetLines.any((l) => l.side == JournalSide.debit);
    final hasCreditAsset = assetLines.any((l) => l.side == JournalSide.credit);

    if (hasIncome) return _TxType.income;
    if (hasExpense) return _TxType.expense;
    if (hasDebitAsset && hasCreditAsset) return _TxType.transfer;
    return _TxType.other;
  }

  int _amount(JournalEntry entry, Set<String> expenseIds, Set<String> incomeIds, Set<String> assetIds) {
    for (final line in entry.lines) {
      if (expenseIds.contains(line.accountId) && line.side == JournalSide.debit) return line.amountMinor;
      if (incomeIds.contains(line.accountId) && line.side == JournalSide.credit) return line.amountMinor;
    }
    // Transfer: amount from credit asset line
    for (final line in entry.lines) {
      if (assetIds.contains(line.accountId) && line.side == JournalSide.credit) return line.amountMinor;
    }
    return entry.lines.isNotEmpty ? entry.lines.first.amountMinor : 0;
  }

  Color _typeColor(_TxType t) => switch (t) {
        _TxType.income => AppColors.success,
        _TxType.expense => AppColors.error,
        _TxType.transfer => AppColors.royalBlue,
        _TxType.other => AppColors.slateBlue,
      };

  IconData _typeIcon(_TxType t) => switch (t) {
        _TxType.income => Iconsax.money_recive,
        _TxType.expense => Iconsax.money_send,
        _TxType.transfer => Iconsax.convert,
        _TxType.other => Iconsax.document,
      };

  String _typeLabel(_TxType t) => switch (t) {
        _TxType.income => 'Income',
        _TxType.expense => 'Expense',
        _TxType.transfer => 'Transfer',
        _TxType.other => 'Entry',
      };

  String _dateLabel(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

enum _TxType { income, expense, transfer, other }

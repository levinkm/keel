import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Text('No transactions this period',
                style: TextStyle(fontSize: 13, color: textTertiary))
          else
            ...entries.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value;
              final amount = _netAmount(entry);
              final isExpense = amount < 0;

              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: divider.withValues(alpha: 0.5)),
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
                                _subtitle(entry),
                                style: TextStyle(
                                    fontSize: 11, color: textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isExpense ? '-' : '+'}${_fmt(amount.abs())}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isExpense ? AppColors.error : AppColors.success,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
    );
  }

  // Net amount = sum of debits on expense/asset accounts
  int _netAmount(JournalEntry entry) {
    final expenseAccounts = accounts
        .where((a) => a.type == AccountType.expense)
        .map((a) => a.id)
        .toSet();
    int debits = 0;
    int credits = 0;
    for (final line in entry.lines) {
      if (expenseAccounts.contains(line.accountId)) {
        if (line.side == JournalSide.debit) debits += line.amountMinor;
      } else {
        if (line.side == JournalSide.credit) credits += line.amountMinor;
      }
    }
    if (debits > 0) return -debits;
    return credits;
  }

  String _subtitle(JournalEntry entry) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[entry.date.month]} ${entry.date.day}  ${entry.lines.length} lines';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

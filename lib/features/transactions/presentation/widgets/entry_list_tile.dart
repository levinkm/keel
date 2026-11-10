import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';

class EntryListTile extends StatelessWidget {
  final JournalEntry entry;
  final List<Account> accounts;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const EntryListTile({
    super.key,
    required this.entry,
    required this.accounts,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  String _accountName(String id) {
    final match = accounts.firstWhere((a) => a.id == id, orElse: () => Account(
      id: id, name: '', type: AccountType.equity,
      currency: 'KES', liquidity: Liquidity.instant,
      isActive: true, createdAt: DateTime.now(),
    ));
    if (match.name.isNotEmpty) return match.name;
    if (id == 'opening-equity') return 'Opening Equity';
    return 'Unknown account';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final totalDebit = entry.lines
        .where((l) => l.side == JournalSide.debit)
        .fold(0, (sum, l) => sum + l.amountMinor);

    final isReversal = entry.reference != null && entry.description.startsWith('Reversal:');

    // First two account names for the subtitle
    final accountNames = entry.lines
        .map((l) => _accountName(l.accountId))
        .take(2)
        .join('  ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalBlue.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.royalBlue.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${entry.date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.royalBlue : textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthAbbr(entry.date.month),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.royalBlue : textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Description + accounts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.description,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (entry.isLocked)
                        Icon(Icons.lock_outline, size: 13, color: textTertiary),
                      if (isReversal)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.undo, size: 13, color: AppColors.warning),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accountNames,
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Amount
                  Text(
                    _fmt(totalDebit),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.royalBlue : textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  String _fmt(int minor) {
    final v = minor / 100;
    return 'KES ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}

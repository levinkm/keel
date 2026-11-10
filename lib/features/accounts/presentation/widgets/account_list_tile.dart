import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class AccountListTile extends StatelessWidget {
  final Account account;
  final int balanceMinor;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountListTile({
    super.key,
    required this.account,
    required this.balanceMinor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final typeColor = _typeColor(account.type);
    final isNegative = balanceMinor < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon(account.type), size: 15, color: typeColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: account.isActive ? textPrimary : textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _liquidityColor(account.liquidity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_liquidityLabel(account.liquidity)}  •  ${account.currency}',
                        style: TextStyle(fontSize: 10, color: textTertiary),
                      ),
                      if (!account.isActive) ...[
                        const SizedBox(width: 6),
                        Text('Inactive',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _fmt(balanceMinor),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isNegative ? AppColors.error : textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
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

  String _fmt(int minor) {
    final v = minor / 100;
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

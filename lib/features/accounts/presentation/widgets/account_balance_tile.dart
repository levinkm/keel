import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class AccountBalanceTile extends StatelessWidget {
  final Account account;
  final int balanceMinor;
  final bool isDark;

  const AccountBalanceTile({
    super.key,
    required this.account,
    required this.balanceMinor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final balance = balanceMinor / 100;
    final isNegative = balance < 0;
    final balanceColor = account.type == AccountType.liability
        ? AppColors.error
        : isNegative
            ? AppColors.error
            : (isDark ? AppColors.darkText : AppColors.lightText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(account.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _typeIcon(account.type),
              size: 18,
              color: _typeColor(account.type),
            ),
          ),
          const SizedBox(width: 12),

          // Name + tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Tag(
                      label: account.currency,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _Tag(
                      label: _liquidityLabel(account.liquidity),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Balance
          Text(
            _fmt(balance),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: balanceColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    final abs = value.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${value < 0 ? '−' : ''}KES $abs';
  }

  String _liquidityLabel(Liquidity l) => switch (l) {
        Liquidity.instant => 'Instant',
        Liquidity.days => 'Days',
        Liquidity.locked => 'Locked',
      };

  IconData _typeIcon(AccountType t) => switch (t) {
        AccountType.asset => Icons.account_balance_wallet_outlined,
        AccountType.liability => Icons.credit_card_outlined,
        AccountType.equity => Icons.pie_chart_outline,
        AccountType.income => Icons.trending_up_outlined,
        AccountType.expense => Icons.receipt_long_outlined,
      };

  Color _typeColor(AccountType t) => switch (t) {
        AccountType.asset => AppColors.royalBlue,
        AccountType.liability => AppColors.error,
        AccountType.equity => AppColors.slateBlue,
        AccountType.income => AppColors.success,
        AccountType.expense => AppColors.warning,
      };
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isDark;

  const _Tag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}

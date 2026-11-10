import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class AccountBalancesCard extends StatelessWidget {
  final List<Account> accounts;
  final Map<String, int> balances;

  const AccountBalancesCard({
    super.key,
    required this.accounts,
    required this.balances,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final displayAccounts = accounts
        .where((a) => a.type == AccountType.asset || a.type == AccountType.liability)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accounts',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 16),
          if (displayAccounts.isEmpty)
            Text('No accounts', style: TextStyle(fontSize: 13, color: textTertiary))
          else
            ...displayAccounts.asMap().entries.map((entry) {
              final i = entry.key;
              final account = entry.value;
              final balance = balances[account.id] ?? 0;
              final isLiability = account.type == AccountType.liability;
              final displayBalance = isLiability ? -balance : balance;
              final isNegative = displayBalance < 0;

              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: divider.withValues(alpha: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _liquidityColor(account.liquidity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(account.name,
                              style: TextStyle(fontSize: 13, color: textPrimary)),
                        ),
                        Text(
                          _fmt(displayBalance.abs()),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isNegative ? AppColors.error : textPrimary,
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

  Color _liquidityColor(Liquidity l) => switch (l) {
        Liquidity.instant => AppColors.success,
        Liquidity.days => AppColors.warning,
        Liquidity.locked => AppColors.slateBlue,
      };

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
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

    final assets = accounts.where((a) => a.type == AccountType.asset).toList();
    final liabilities = accounts.where((a) => a.type == AccountType.liability).toList();

    final totalAssets = assets.fold(0, (s, a) => s + (balances[a.id] ?? 0));
    final totalLiabilities = liabilities.fold(0, (s, a) => s + (balances[a.id] ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accounts',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 16),

          if (assets.isEmpty && liabilities.isEmpty)
            Text('No accounts', style: TextStyle(fontSize: 13, color: textTertiary))
          else ...[
            // Assets
            if (assets.isNotEmpty) ...[
              _SectionHeader('ASSETS', totalAssets, AppColors.success, textTertiary),
              const SizedBox(height: 8),
              ...assets.take(5).toList().asMap().entries.map((e) => _AccountRow(
                    account: e.value,
                    balance: balances[e.value.id] ?? 0,
                    isFirst: e.key == 0,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textTertiary: textTertiary,
                    divider: divider,
                  )),
            ],

            if (assets.isNotEmpty && liabilities.isNotEmpty)
              Divider(height: 20, color: divider.withValues(alpha: 0.5)),

            // Liabilities
            if (liabilities.isNotEmpty) ...[
              _SectionHeader('LIABILITIES', totalLiabilities, AppColors.error, textTertiary),
              const SizedBox(height: 8),
              ...liabilities.take(3).toList().asMap().entries.map((e) => _AccountRow(
                    account: e.value,
                    balance: balances[e.value.id] ?? 0,
                    isFirst: e.key == 0,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textTertiary: textTertiary,
                    divider: divider,
                    isLiability: true,
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int totalMinor;
  final Color color;
  final Color textColor;

  const _SectionHeader(this.label, this.totalMinor, this.color, this.textColor);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: textColor)),
          const Spacer(),
          BlurredAmount(
            text: _fmt(totalMinor),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final int balance;
  final bool isFirst;
  final bool isLiability;
  final bool isDark;
  final Color textPrimary;
  final Color textTertiary;
  final Color divider;

  const _AccountRow({
    required this.account,
    required this.balance,
    required this.isFirst,
    required this.isDark,
    required this.textPrimary,
    required this.textTertiary,
    required this.divider,
    this.isLiability = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayBalance = isLiability ? -balance : balance;
    final isNegative = displayBalance < 0;
    final valueColor = isNegative ? AppColors.error : textPrimary;

    return Column(
      children: [
        if (!isFirst)
          Divider(height: 1, color: divider.withValues(alpha: 0.4)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(
                _liquidityIcon(account.liquidity),
                size: 14,
                color: _liquidityColor(account.liquidity),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      account.liquidity.name,
                      style: TextStyle(fontSize: 10, color: textTertiary),
                    ),
                  ],
                ),
              ),
              BlurredAmount(
                text: _fmt(displayBalance.abs()),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _liquidityColor(Liquidity l) => switch (l) {
        Liquidity.instant => AppColors.success,
        Liquidity.days => AppColors.warning,
        Liquidity.locked => AppColors.slateBlue,
      };

  IconData _liquidityIcon(Liquidity l) => switch (l) {
        Liquidity.instant => Iconsax.flash,
        Liquidity.days => Iconsax.clock,
        Liquidity.locked => Iconsax.lock,
      };

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

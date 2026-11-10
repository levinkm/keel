import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:keel/features/accounts/presentation/widgets/account_detail_panel.dart';
import 'package:keel/features/accounts/presentation/widgets/account_list_tile.dart';
import 'package:keel/features/accounts/presentation/widgets/create_account_dialog.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
import 'package:keel/core/widgets/shimmer.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsCubit>()..loadAccounts(),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 4),
          error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (accounts, balances, filter, selectedAccountId,
              selectedHistory, selectedSparkline) {
            final cubit = context.read<AccountsCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
            final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            // Summary stats
            final totalAssets = accounts
                .where((a) => a.type == AccountType.asset)
                .fold(0, (s, a) => s + (balances[a.id] ?? 0));
            final totalLiabilities = accounts
                .where((a) => a.type == AccountType.liability)
                .fold(0, (s, a) => s + (balances[a.id] ?? 0));
            final netWorth = totalAssets - totalLiabilities;

            // Filtered list
            final filtered = accounts.where((a) => switch (filter) {
                  AccountFilter.all => true,
                  AccountFilter.asset => a.type == AccountType.asset,
                  AccountFilter.liability => a.type == AccountType.liability,
                  AccountFilter.income => a.type == AccountType.income,
                  AccountFilter.expense => a.type == AccountType.expense,
                }).toList();

            final selectedAccount = selectedAccountId == null
                ? null
                : accounts.cast<Account?>().firstWhere(
                    (a) => a?.id == selectedAccountId,
                    orElse: () => null);

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Column(
                children: [
                  // ── Top bar ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Accounts',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () =>
                                  showCreateAccountDialog(context),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add account'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.royalBlue,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Net worth stat cards
                        Row(
                          children: [
                            _StatCard(
                              label: 'TOTAL ASSETS',
                              value: _fmt(totalAssets),
                              color: AppColors.success,
                              surface: surface,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL LIABILITIES',
                              value: _fmt(totalLiabilities),
                              color: totalLiabilities > 0
                                  ? AppColors.error
                                  : textTertiary,
                              surface: surface,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'NET WORTH',
                              value: _fmt(netWorth),
                              color: netWorth >= 0
                                  ? AppColors.royalBlue
                                  : AppColors.error,
                              surface: surface,
                              large: true,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'ACCOUNTS',
                              value: '${accounts.where((a) => a.isActive).length}',
                              color: textPrimary,
                              surface: surface,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Split panel ────────────────────────────────────────────
                  Expanded(
                    child: Row(
                      children: [
                        // Left: account list
                        SizedBox(
                          width: listPanelWidth(context),
                          child: Container(
                            color: bg,
                            child: Column(
                              children: [
                                // Filter tabs
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: AccountFilter.values.map((f) {
                                        final isActive = f == filter;
                                        return GestureDetector(
                                          onTap: () => cubit.setFilter(f),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppColors.royalBlue
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _filterLabel(f),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: isActive
                                                    ? Colors.white
                                                    : textSecondary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No ${_filterLabel(filter).toLowerCase()} accounts.',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: textTertiary),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, i) {
                                            final account = filtered[i];
                                            return AccountListTile(
                                              account: account,
                                              balanceMinor:
                                                  balances[account.id] ?? 0,
                                              isSelected:
                                                  account.id == selectedAccountId,
                                              onTap: () => cubit.selectAccount(
                                                  account.id == selectedAccountId
                                                      ? null
                                                      : account.id),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VerticalDivider(width: 1, color: divider),

                        // Right: detail panel
                        Expanded(
                          child: selectedAccount == null
                              ? Center(
                                  child: Text(
                                    accounts.isEmpty
                                        ? 'Add an account to get started.'
                                        : 'Select an account to view details.',
                                    style: TextStyle(
                                        fontSize: 13, color: textTertiary),
                                  ),
                                )
                              : AccountDetailPanel(
                                  account: selectedAccount,
                                  balanceMinor:
                                      balances[selectedAccount.id] ?? 0,
                                  history: selectedHistory,
                                  sparkline: selectedSparkline,
                                  allAccounts: accounts,
                                  onEdit: () =>
                                      _showEditDialog(context, selectedAccount),
                                  onToggleActive: () =>
                                      cubit.toggleActive(selectedAccount),
                                  onTransfer: (to, amount, desc) =>
                                      cubit.transfer(
                                        from: selectedAccount,
                                        to: to,
                                        amountMinor: amount,
                                        description: desc,
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Account account) {
    showCreateAccountDialog(context, existing: account);
  }

  String _filterLabel(AccountFilter f) => switch (f) {
        AccountFilter.all => 'All',
        AccountFilter.asset => 'Assets',
        AccountFilter.liability => 'Liabilities',
        AccountFilter.income => 'Income',
        AccountFilter.expense => 'Expenses',
      };

  static String _fmt(int minor) {
    final v = minor / 100;
    if (v.abs() >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;
  final bool large;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: textSecondary)),
            const SizedBox(height: 6),
            BlurredAmount(
                text: value,
                style: TextStyle(
                  fontSize: large ? 20 : 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ],
        ),
      ),
    );
  }
}

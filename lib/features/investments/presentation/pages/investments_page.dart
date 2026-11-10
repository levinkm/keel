import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/investments/presentation/bloc/investments_cubit.dart';
import 'package:keel/features/investments/presentation/widgets/holding_detail_panel.dart';
import 'package:keel/features/investments/presentation/widgets/holding_dialog.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
import 'package:keel/core/widgets/shimmer.dart';

class InvestmentsPage extends StatelessWidget {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<InvestmentsCubit>()..load()),
        BlocProvider(create: (_) => getIt<AccountsCubit>()..loadAccounts()),
      ],
      child: const _InvestmentsView(),
    );
  }
}

class _InvestmentsView extends StatefulWidget {
  const _InvestmentsView();

  @override
  State<_InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends State<_InvestmentsView> {
  HoldingType? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvestmentsCubit, InvestmentsState>(
      listenWhen: (_, s) =>
          s.maybeMap(loaded: (l) => l.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error =
            state.maybeMap(loaded: (l) => l.validationError, orElse: () => null);
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        context.read<InvestmentsCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 6),
          error: (msg) =>
              Center(child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (holdings, selectedId, totalInvested, totalMarket, totalGain,
              totalRealisedGain, totalIncome, _) {
            final cubit = context.read<InvestmentsCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary =
                isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary =
                isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
            final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            return BlocBuilder<AccountsCubit, AccountsState>(
              builder: (context, accountsState) {
                final accounts = accountsState.maybeMap(
                    loaded: (s) => s.accounts, orElse: () => <Account>[]);

                final isGain = totalGain >= 0;
            final gainColor = isGain ? AppColors.success : AppColors.error;
            final gainPct = totalInvested > 0
                ? (totalGain / totalInvested * 100)
                : 0.0;

            final filtered = _filter == null
                ? holdings
                : holdings.where((h) => h.type == _filter).toList();

            final selected = selectedId == null
                ? null
                : holdings.cast<Holding?>()
                    .firstWhere((h) => h?.id == selectedId, orElse: () => null);

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
                        Row(children: [
                          Text('Investments',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                  color: textPrimary, letterSpacing: -0.3)),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => showHoldingDialog(
                              context: context,
                              accounts: accounts,
                              onSave: cubit.createHolding,
                              onCreateAccount: (account) =>
                                  context.read<AccountsCubit>().createAccount(account),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add holding'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Stat cards
                        Row(children: [
                          _StatCard(
                            label: 'TOTAL INVESTED',
                            value: _fmtMoney(totalInvested),
                            color: textPrimary,
                            surface: surface,
                            icon: Icons.savings_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'MARKET VALUE',
                            value: _fmtMoney(totalMarket),
                            color: AppColors.royalBlue,
                            surface: surface,
                            icon: Icons.show_chart_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: isGain ? 'UNREALISED GAIN' : 'UNREALISED LOSS',
                            value:
                                '${isGain ? '+' : ''}${_fmtMoney(totalGain)} (${gainPct.toStringAsFixed(1)}%)',
                            color: gainColor,
                            surface: surface,
                            icon: isGain
                                ? Icons.trending_up_outlined
                                : Icons.trending_down_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'HOLDINGS',
                            value:
                                '${holdings.where((h) => h.isActive).length} active',
                            color: textPrimary,
                            surface: surface,
                            icon: Icons.account_balance_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: totalRealisedGain >= 0
                                ? 'REALISED GAIN'
                                : 'REALISED LOSS',
                            value:
                                '${totalRealisedGain >= 0 ? '+' : ''}${_fmtMoney(totalRealisedGain)}',
                            color: totalRealisedGain >= 0
                                ? AppColors.success
                                : AppColors.error,
                            surface: surface,
                            icon: Icons.price_check_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'TOTAL INCOME',
                            value: '+${_fmtMoney(totalIncome)}',
                            color: AppColors.success,
                            surface: surface,
                            icon: Icons.payments_outlined,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Split panel ────────────────────────────────────────────
                  Expanded(
                    child: Row(
                      children: [
                        // Left: list
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
                                    child: Row(children: [
                                      _filterTab(null, 'All', _filter, textSecondary,
                                          () => setState(() => _filter = null)),
                                      ...HoldingType.values.map((t) => _filterTab(
                                          t, t.label, _filter, textSecondary,
                                          () => setState(() => _filter = t))),
                                    ]),
                                  ),
                                ),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text('No holdings.',
                                              style: TextStyle(
                                                  fontSize: 13, color: textTertiary)))
                                      : ListView.builder(
                                          padding:
                                              const EdgeInsets.symmetric(horizontal: 8),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, i) {
                                            final h = filtered[i];
                                            final isSelected = h.id == selectedId;
                                            return _HoldingTile(
                                              holding: h,
                                              isSelected: isSelected,
                                              isDark: isDark,
                                              onTap: () => cubit.selectHolding(
                                                  isSelected ? null : h.id),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VerticalDivider(width: 1, color: divider),

                        // Right: detail
                        Expanded(
                          child: selected == null
                              ? Center(
                                  child: Text(
                                    holdings.isEmpty
                                        ? 'Add a holding to get started.'
                                        : 'Select a holding to view details.',
                                    style: TextStyle(
                                        fontSize: 13, color: textTertiary),
                                  ),
                                )
                              : HoldingDetailPanel(
                                  holding: selected,
                                  accounts: accounts,
                                  onEdit: cubit.updateHolding,
                                  onCreateAccount: (account) =>
                                      context.read<AccountsCubit>().createAccount(account),
                                  onAddLot: (lot, sourceId) => cubit.addLot(
                                      lot, selected.accountId, sourceId),
                                  onDeleteLot: (lotId, accountId) =>
                                      cubit.deleteLot(lotId, selected.id, accountId),
                                  onUpdatePrice: (price) =>
                                      cubit.updateCurrentPrice(selected.id, price),
                                  onDeactivate: () =>
                                      cubit.deactivateHolding(selected.id),
                                  onRedeem: ({
                                    required units,
                                    required priceMinor,
                                    required feesMinor,
                                    required date,
                                    required destinationAccountId,
                                    required gainLossAccountId,
                                  }) =>
                                      cubit.recordRedemption(
                                        holding: selected,
                                        units: units,
                                        priceMinor: priceMinor,
                                        feesMinor: feesMinor,
                                        date: date,
                                        destinationAccountId: destinationAccountId,
                                        gainLossAccountId: gainLossAccountId,
                                      ),
                                  onRecordIncome: ({
                                    required amountMinor,
                                    required date,
                                    required incomeAccountId,
                                    required bankOrInvestmentAccountId,
                                    required isReinvested,
                                    required reinvestedUnits,
                                    required reinvestedPriceMinor,
                                  }) =>
                                      cubit.recordIncome(
                                        holding: selected,
                                        amountMinor: amountMinor,
                                        date: date,
                                        incomeAccountId: incomeAccountId,
                                        bankOrInvestmentAccountId:
                                            bankOrInvestmentAccountId,
                                        isReinvested: isReinvested,
                                        reinvestedUnits: reinvestedUnits,
                                        reinvestedPriceMinor: reinvestedPriceMinor,
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
      },
    );
  }

  Widget _filterTab(HoldingType? type, String label, HoldingType? active,
      Color textSecondary, VoidCallback onTap) {
    final isActive = type == active;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : textSecondary,
            )),
      ),
    );
  }

  static String _fmtMoney(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Holding tile ──────────────────────────────────────────────────────────────

class _HoldingTile extends StatelessWidget {
  final Holding holding;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _HoldingTile({
    required this.holding,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gain = holding.unrealisedGainMinor;
    final gainColor = gain >= 0 ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalBlue.withValues(alpha: 0.08)
              : surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_typeIcon(holding.type), size: 18, color: AppColors.royalBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(holding.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (!holding.isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('Closed',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                    ),
                  ],
                ]),
                Text(holding.type.label,
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmtMoney(holding.marketValueMinor),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text('${gain >= 0 ? '+' : ''}${_fmtMoney(gain)}',
                  style: TextStyle(fontSize: 11, color: gainColor)),
            ],
          ),
        ]),
      ),
    );
  }

  IconData _typeIcon(HoldingType t) => switch (t) {
        HoldingType.stock || HoldingType.etf => Icons.show_chart_outlined,
        HoldingType.unitTrust || HoldingType.moneyMarket => Icons.account_balance_outlined,
        HoldingType.fixedDeposit || HoldingType.bankSavings => Icons.savings_outlined,
        HoldingType.treasuryBill => Icons.receipt_long_outlined,
        HoldingType.sacco => Icons.groups_outlined,
        HoldingType.pension => Icons.elderly_outlined,
      };

  static String _fmtMoney(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration:
            BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        letterSpacing: 0.4, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                BlurredAmount(
                    text: value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

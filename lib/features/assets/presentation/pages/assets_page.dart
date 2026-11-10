import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/presentation/bloc/assets_cubit.dart';
import 'package:keel/features/assets/presentation/widgets/asset_detail_panel.dart';
import 'package:keel/features/assets/presentation/widgets/asset_dialog.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AssetsCubit>()..load(),
      child: const _AssetsView(),
    );
  }
}

class _AssetsView extends StatelessWidget {
  const _AssetsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetsCubit, AssetsState>(
      listenWhen: (_, s) => s.maybeMap(loaded: (l) => l.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error = state.maybeMap(loaded: (l) => l.validationError, orElse: () => null);
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
        context.read<AssetsCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 4),
          error: (msg) => Center(child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (assets, filter, selectedAssetId, totalCost, totalBook, insuredCount,
              linkedProjects, linkedSummaries, linkedEntries, attachments, _) {
            final cubit = context.read<AssetsCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
            final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            final gainLoss = totalBook - totalCost;
            final gainColor = gainLoss >= 0 ? AppColors.success : AppColors.error;
            final now = DateTime.now();

            final filtered = filter == AssetFilter.all
                ? assets
                : assets.where((a) => a.assetClass.name == filter.name).toList();

            final selectedAsset = selectedAssetId == null
                ? null
                : assets.cast<Asset?>().firstWhere((a) => a?.id == selectedAssetId, orElse: () => null);

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Assets',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                    color: textPrimary, letterSpacing: -0.3)),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => showAssetDialog(
                                context: context,
                                onSave: cubit.createAsset,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add asset'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.royalBlue,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stat cards
                        Row(children: [
                          _StatCard(
                            label: 'TOTAL COST',
                            value: _fmtMoney(totalCost),
                            color: textPrimary,
                            surface: surface,
                            icon: Icons.attach_money,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'BOOK VALUE',
                            value: _fmtMoney(totalBook),
                            color: AppColors.royalBlue,
                            surface: surface,
                            icon: Icons.account_balance_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: gainLoss >= 0 ? 'UNREALISED GAIN' : 'UNREALISED LOSS',
                            value: '${gainLoss >= 0 ? '+' : ''}${_fmtMoney(gainLoss)}',
                            color: gainColor,
                            surface: surface,
                            icon: gainLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'INSURED',
                            value: '$insuredCount / ${assets.length}',
                            color: insuredCount == assets.length && assets.isNotEmpty
                                ? AppColors.success
                                : AppColors.warning,
                            surface: surface,
                            icon: Icons.verified_outlined,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Split panel ──────────────────────────────────────────
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
                                    child: Row(
                                      children: [
                                        _filterTab(AssetFilter.all, 'All', filter, cubit, textSecondary),
                                        _filterTab(AssetFilter.vehicle, 'Vehicles', filter, cubit, textSecondary),
                                        _filterTab(AssetFilter.building, 'Buildings', filter, cubit, textSecondary),
                                        _filterTab(AssetFilter.land, 'Land', filter, cubit, textSecondary),
                                        _filterTab(AssetFilter.machinery, 'Machinery', filter, cubit, textSecondary),
                                        _filterTab(AssetFilter.investments, 'Investments', filter, cubit, textSecondary),
                                        _filterTab(AssetFilter.other, 'Other', filter, cubit, textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text('No assets.',
                                              style: TextStyle(fontSize: 13, color: textTertiary)))
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, i) {
                                            final a = filtered[i];
                                            final isSelected = a.id == selectedAssetId;
                                            return _AssetTile(
                                              asset: a,
                                              isSelected: isSelected,
                                              isDark: isDark,
                                              now: now,
                                              onTap: () => cubit.selectAsset(isSelected ? null : a.id),
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
                          child: selectedAsset == null
                              ? Center(
                                  child: Text(
                                    assets.isEmpty ? 'Add an asset to get started.' : 'Select an asset to view details.',
                                    style: TextStyle(fontSize: 13, color: textTertiary),
                                  ),
                                )
                              : AssetDetailPanel(
                                  asset: selectedAsset,
                                  linkedProjects: linkedProjects,
                                  linkedSummaries: linkedSummaries,
                                  linkedEntries: linkedEntries,
                                  attachments: attachments,
                                  accounts: const [],
                                  allAssets: assets,
                                  onEdit: cubit.updateAsset,
                                  onStatusChange: cubit.updateAsset,
                                  onCreateProject: (_) {},
                                  onEditProject: (_) {},
                                  onRefreshProjects: cubit.refreshLinkedProjects,
                                  onAddAttachment: (path, name, mime) =>
                                      cubit.addAttachment(selectedAsset.id, path, name, mime),
                                  onRemoveAttachment: cubit.removeAttachment,
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

  Widget _filterTab(AssetFilter f, String label, AssetFilter active, AssetsCubit cubit, Color textSecondary) {
    final isActive = f == active;
    return GestureDetector(
      onTap: () => cubit.setFilter(f),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }

  static String _fmtMoney(int minor) {
    final v = minor.abs() / 100;
    final prefix = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${prefix}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${prefix}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${prefix}KES ${v.toStringAsFixed(0)}';
  }
}

class _AssetTile extends StatelessWidget {
  final Asset asset;
  final bool isSelected;
  final bool isDark;
  final DateTime now;
  final VoidCallback onTap;

  const _AssetTile({
    required this.asset,
    required this.isSelected,
    required this.isDark,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gainLoss = asset.bookValue - asset.costMinor;
    final gainColor = gainLoss >= 0 ? AppColors.success : AppColors.error;

    final isInsured = asset.insuranceExpiry != null && asset.insuranceExpiry!.isAfter(now);
    final insuranceExpiringSoon = isInsured &&
        asset.insuranceExpiry!.isBefore(now.add(const Duration(days: 30)));
    final insuranceExpired = asset.insuranceExpiry != null && !isInsured;
    final showInsuranceWarning = insuranceExpiringSoon || insuranceExpired;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_classIcon(asset.assetClass), size: 18, color: AppColors.royalBlue),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(asset.name,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (asset.status != AssetStatus.inUse) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (asset.status == AssetStatus.sold
                                    ? AppColors.warning
                                    : AppColors.error)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            asset.status == AssetStatus.sold ? 'Sold' : 'Written Off',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: asset.status == AssetStatus.sold
                                  ? AppColors.warning
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(_classLabel(asset.assetClass),
                          style: TextStyle(fontSize: 11, color: textSecondary)),
                      if (showInsuranceWarning) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.shield_outlined,
                          size: 11,
                          color: insuranceExpired ? AppColors.error : AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          insuranceExpired ? 'Uninsured' : 'Expiring',
                          style: TextStyle(
                            fontSize: 10,
                            color: insuranceExpired ? AppColors.error : AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmtMoney(asset.bookValue),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                Text(
                  '${gainLoss >= 0 ? '+' : ''}${_fmtMoney(gainLoss)}',
                  style: TextStyle(fontSize: 11, color: gainColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _classIcon(AssetClass c) => switch (c) {
        AssetClass.cashAndBank => Icons.account_balance_outlined,
        AssetClass.investments => Icons.show_chart_outlined,
        AssetClass.vehicle => Icons.directions_car_outlined,
        AssetClass.machinery => Icons.precision_manufacturing_outlined,
        AssetClass.land => Icons.landscape_outlined,
        AssetClass.building => Icons.home_outlined,
        AssetClass.receivable => Icons.receipt_long_outlined,
        AssetClass.other => Icons.category_outlined,
      };

  String _classLabel(AssetClass c) => switch (c) {
        AssetClass.cashAndBank => 'Cash & Bank',
        AssetClass.investments => 'Investments',
        AssetClass.vehicle => 'Vehicle',
        AssetClass.machinery => 'Machinery',
        AssetClass.land => 'Land',
        AssetClass.building => 'Building',
        AssetClass.receivable => 'Receivable',
        AssetClass.other => 'Other',
      };

  static String _fmtMoney(int minor) {
    final v = minor.abs() / 100;
    final prefix = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${prefix}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${prefix}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${prefix}KES ${v.toStringAsFixed(0)}';
  }
}

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
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        letterSpacing: 0.4, color: textSecondary)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

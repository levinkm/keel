import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/investments/presentation/widgets/add_lot_dialog.dart';
import 'package:keel/features/investments/presentation/widgets/holding_dialog.dart';
import 'package:keel/features/investments/presentation/widgets/record_income_dialog.dart';
import 'package:keel/features/investments/presentation/widgets/record_redemption_dialog.dart';

class HoldingDetailPanel extends StatelessWidget {
  final Holding holding;
  final List<Account> accounts;
  final void Function(Holding) onEdit;
  final void Function(Account) onCreateAccount;
  final void Function(HoldingLot lot, String? sourceAccountId) onAddLot;
  final void Function(String lotId, String investmentAccountId) onDeleteLot;
  final void Function(int priceMinor) onUpdatePrice;
  final VoidCallback onDeactivate;
  final void Function({
    required double units,
    required int priceMinor,
    required int feesMinor,
    required DateTime date,
    required String destinationAccountId,
    required String gainLossAccountId,
  }) onRedeem;
  final void Function({
    required int amountMinor,
    required DateTime date,
    required String incomeAccountId,
    required String bankOrInvestmentAccountId,
    required bool isReinvested,
    required double reinvestedUnits,
    required int reinvestedPriceMinor,
  }) onRecordIncome;

  const HoldingDetailPanel({
    super.key,
    required this.holding,
    required this.accounts,
    required this.onEdit,
    required this.onCreateAccount,
    required this.onAddLot,
    required this.onDeleteLot,
    required this.onUpdatePrice,
    required this.onDeactivate,
    required this.onRedeem,
    required this.onRecordIncome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final gain = holding.unrealisedGainMinor;
    final gainPct = holding.unrealisedGainPct;
    final isGain = gain >= 0;
    final gainColor = isGain ? AppColors.success : AppColors.error;

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(holding.type), size: 20, color: AppColors.royalBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(holding.name,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                              color: textPrimary, letterSpacing: -0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        _tag(holding.type.label, AppColors.royalBlue),
                        const SizedBox(width: 6),
                        _tag(_liquidityLabel(holding.liquidity),
                            _liquidityColor(holding.liquidity)),
                        if (!holding.isActive) ...[
                          const SizedBox(width: 6),
                          _tag('Inactive', AppColors.error),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(holding.institution,
                          style: TextStyle(fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  onPressed: () => showHoldingDialog(
                      context: context, accounts: accounts,
                      existing: holding, onSave: onEdit,
                      onCreateAccount: onCreateAccount),
                  child: Text('Edit', style: TextStyle(fontSize: 13, color: AppColors.royalBlue)),
                ),
                if (holding.isActive)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () => showRedemptionDialog(
                      context: context,
                      holding: holding,
                      accounts: accounts,
                      onSave: onRedeem,
                    ),
                    child: Text('Redeem',
                        style: TextStyle(fontSize: 13, color: AppColors.warning)),
                  ),
                if (holding.isActive)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () => showRecordIncomeDialog(
                      context: context,
                      holding: holding,
                      accounts: accounts,
                      onSave: onRecordIncome,
                    ),
                    child: Text('Income',
                        style: TextStyle(fontSize: 13, color: AppColors.success)),
                  ),
                if (holding.isActive)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () => _confirmDeactivate(context, isDark),
                    child: Text('Close position',
                        style: TextStyle(fontSize: 13, color: AppColors.error)),
                  ),
            ]),
            const SizedBox(height: 20),

            // ── Market value card ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Market value', style: TextStyle(fontSize: 11, color: textTertiary)),
                  const SizedBox(height: 6),
                  Text(_fmtFull(holding.marketValueMinor),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                          color: textPrimary, letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cost basis', style: TextStyle(fontSize: 11, color: textTertiary)),
                              Text(_fmtShort(holding.totalCostBasisMinor),
                                  style: TextStyle(fontSize: 11, color: textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: holding.totalCostBasisMinor > 0
                                  ? (holding.marketValueMinor / holding.totalCostBasisMinor)
                                      .clamp(0.0, 2.0) / 2.0
                                  : 0,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation(gainColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${isGain ? '+' : ''}${gainPct.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: gainColor)),
                        Text('${isGain ? '+' : ''}${_fmtShort(gain)}',
                            style: TextStyle(fontSize: 12, color: gainColor)),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── KPI row ──────────────────────────────────────────────────────
            Row(children: [
              _kpi('COST BASIS', _fmtShort(holding.totalCostBasisMinor),
                  textPrimary, textSecondary, surface),
              const SizedBox(width: 10),
              if (holding.type.hasUnits) ...[
                _kpi('TOTAL UNITS', holding.totalUnits.toStringAsFixed(2),
                    textPrimary, textSecondary, surface),
                const SizedBox(width: 10),
                _kpi('AVG COST/UNIT',
                    holding.totalUnits > 0
                        ? _fmtShort((holding.totalCostBasisMinor / holding.totalUnits).round())
                        : '—',
                    textPrimary, textSecondary, surface),
              ] else
                _kpi('LOTS', '${holding.lots.length}', textPrimary, textSecondary, surface),
              const SizedBox(width: 10),
              _kpi(isGain ? 'UNREALISED GAIN' : 'UNREALISED LOSS',
                  '${isGain ? '+' : ''}${_fmtShort(gain)}',
                  gainColor, textSecondary, surface),
            ]),
            const SizedBox(height: 10),
            // Realised gain/loss + income row
            Row(children: [
              _kpi(
                holding.realisedGainMinor >= 0 ? 'REALISED GAIN' : 'REALISED LOSS',
                '${holding.realisedGainMinor >= 0 ? '+' : ''}${_fmtShort(holding.realisedGainMinor)}',
                holding.realisedGainMinor >= 0 ? AppColors.success : AppColors.error,
                textSecondary, surface,
              ),
              const SizedBox(width: 10),
              _kpi('TOTAL INCOME', '+${_fmtShort(holding.totalIncomeMinor)}',
                  AppColors.success, textSecondary, surface),
              const SizedBox(width: 10),
              _kpi('TOTAL REDEEMED', _fmtShort(holding.totalRedeemedMinor),
                  textSecondary, textSecondary, surface),
            ]),
            const SizedBox(height: 20),

            // ── Update price ─────────────────────────────────────────────────
            if (holding.type.hasUnits) ...[
              Row(children: [
                _sectionLabel('Current price', textTertiary),
                const SizedBox(width: 12),
                if (holding.currentPriceMinor != null)
                  Text(_fmtFull(holding.currentPriceMinor!),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showUpdatePriceDialog(context, isDark),
                  child: Row(children: [
                    const Icon(Icons.refresh, size: 14, color: AppColors.royalBlue),
                    const SizedBox(width: 4),
                    const Text('Update price',
                        style: TextStyle(fontSize: 12, color: AppColors.royalBlue,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            // ── Interest projection ──────────────────────────────────────────
            if (holding.hasInterestRate) ...[
              _sectionLabel('Interest projection', textTertiary),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rate + compounding
                    _projRow('Annual rate',
                        '${(holding.annualRateBp! / 100).toStringAsFixed(2)}% p.a.',
                        textPrimary, textSecondary),
                    _div(isDark),
                    _projRow('Compounding',
                        holding.compoundingFreq.label,
                        textPrimary, textSecondary),
                    _div(isDark),
                    // Daily accrual
                    _projRow('Daily accrual',
                        '+${_fmtShort(holding.dailyInterestMinor)}/day',
                        AppColors.success, textSecondary),
                    _div(isDark),
                    // Accrued so far
                    _projRow(
                        'Accrued so far (${holding.daysHeld} days)',
                        '+${_fmtShort(holding.accruedInterestMinor)}',
                        AppColors.success, textSecondary),
                    // Maturity section
                    if (holding.maturityDate != null) ...[
                      _div(isDark),
                      _projRow('Maturity date',
                          _fmtDate(holding.maturityDate!),
                          holding.daysToMaturity != null &&
                                  holding.daysToMaturity! < 0
                              ? AppColors.error
                              : textPrimary,
                          textSecondary),
                      if (holding.daysToMaturity != null) ...[
                        _div(isDark),
                        _projRow(
                          holding.daysToMaturity! >= 0
                              ? 'Days to maturity'
                              : 'Days overdue',
                          '${holding.daysToMaturity!.abs()} days',
                          holding.daysToMaturity! < 0
                              ? AppColors.error
                              : holding.daysToMaturity! <= 30
                                  ? AppColors.warning
                                  : textPrimary,
                          textSecondary,
                        ),
                      ],
                      if (holding.expectedInterestAtMaturityMinor != null) ...[
                        _div(isDark),
                        _projRow(
                            'Expected total interest',
                            '+${_fmtShort(holding.expectedInterestAtMaturityMinor!)}',
                            AppColors.success, textSecondary),
                        _div(isDark),
                        _projRow(
                            'Projected maturity value',
                            _fmtShort(holding.projectedMaturityValueMinor!),
                            AppColors.royalBlue, textSecondary),
                      ],
                      // Progress bar toward maturity
                      if (holding.totalTermDays != null &&
                          holding.totalTermDays! > 0) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Term progress',
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary)),
                            Text(
                              '${((holding.daysHeld / holding.totalTermDays!) * 100).clamp(0, 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (holding.daysHeld /
                                    holding.totalTermDays!)
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            valueColor: AlwaysStoppedAnimation(
                              holding.daysToMaturity != null &&
                                      holding.daysToMaturity! < 0
                                  ? AppColors.error
                                  : AppColors.royalBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    // Record accrued interest shortcut
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showRecordIncomeDialog(
                          context: context,
                          holding: holding,
                          accounts: accounts,
                          onSave: onRecordIncome,
                          prefillAmount: holding.accruedInterestMinor,
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(
                            'Record accrued interest (${_fmtShort(holding.accruedInterestMinor)})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: BorderSide(
                              color: AppColors.success.withValues(alpha: 0.4)),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Lots table ───────────────────────────────────────────────────
            Row(children: [
              _sectionLabel('Purchase history', textTertiary),
              const Spacer(),
              if (holding.isActive)
                GestureDetector(
                  onTap: () => showAddLotDialog(
                      context: context,
                      holding: holding,
                      accounts: accounts,
                      onSave: onAddLot),
                  child: Row(children: [
                    const Icon(Icons.add, size: 14, color: AppColors.royalBlue),
                    const SizedBox(width: 4),
                    const Text('Add purchase',
                        style: TextStyle(fontSize: 12, color: AppColors.royalBlue,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
            ]),
            const SizedBox(height: 10),

            if (holding.lots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                child: Text('No purchases recorded yet.',
                    style: TextStyle(fontSize: 13, color: textTertiary)),
              )
            else
              Container(
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 2, child: Text('Date',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: textTertiary))),
                        if (holding.type.hasUnits)
                          Expanded(child: Text('Units',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: textTertiary))),
                        Expanded(child: Text('Price',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: textTertiary))),
                        Expanded(child: Text('Cost',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: textTertiary))),
                        const SizedBox(width: 32),
                      ]),
                    ),
                    ...holding.lots.asMap().entries.map((e) {
                      final i = e.key;
                      final lot = e.value;
                      final isRedemption = lot.lotType == LotType.redemption;
                      final isIncome = lot.lotType == LotType.income;
                      final lotColor = isRedemption
                          ? AppColors.error
                          : isIncome
                              ? AppColors.success
                              : textPrimary;
                      final amountDisplay = isRedemption
                          ? _fmtShort(lot.proceedsMinor)
                          : isIncome
                              ? '+${_fmtShort(lot.incomeMinor)}'
                              : _fmtShort(lot.costBasisMinor);
                      return Column(children: [
                        if (i > 0)
                          Divider(height: 1,
                              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                  .withValues(alpha: 0.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Expanded(flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmtDate(lot.date),
                                        style: TextStyle(fontSize: 13, color: textPrimary)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: lotColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(lot.lotType.label,
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: lotColor)),
                                    ),
                                  ],
                                )),
                            if (holding.type.hasUnits)
                              Expanded(
                                  child: Text(
                                      isRedemption
                                          ? '-${lot.units.abs().toStringAsFixed(2)}'
                                          : lot.units > 0
                                              ? lot.units.toStringAsFixed(2)
                                              : '—',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 13, color: lotColor,
                                          fontFeatures: const [FontFeature.tabularFigures()]))),
                            Expanded(
                                child: Text(_fmtShort(lot.priceMinor),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 13, color: textPrimary,
                                        fontFeatures: const [FontFeature.tabularFigures()]))),
                            Expanded(
                                child: Text(amountDisplay,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                        color: lotColor,
                                        fontFeatures: const [FontFeature.tabularFigures()]))),
                            SizedBox(
                              width: 32,
                              child: isRedemption || isIncome
                                  ? const SizedBox()
                                  : GestureDetector(
                                      onTap: () => _confirmDeleteLot(context, lot, isDark),
                                      child: Icon(Icons.delete_outline, size: 14,
                                          color: textTertiary),
                                    ),
                            ),
                          ]),
                        ),
                      ]);
                    }),
                    // Total row
                    Divider(height: 1,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 2,
                            child: Text('Total',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: textSecondary))),
                        if (holding.type.hasUnits)
                          Expanded(
                              child: Text(holding.totalUnits.toStringAsFixed(2),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                      fontFeatures: const [FontFeature.tabularFigures()]))),
                        Expanded(child: const SizedBox()),
                        Expanded(
                            child: Text(_fmtShort(holding.totalCostBasisMinor),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.royalBlue,
                                    fontFeatures: [FontFeature.tabularFigures()]))),
                        const SizedBox(width: 32),
                      ]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUpdatePriceDialog(BuildContext context, bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fieldBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final ctrl = TextEditingController(
        text: holding.currentPriceMinor != null
            ? (holding.currentPriceMinor! / 100).toStringAsFixed(2)
            : '');

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update current price',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 4),
                Text('Price per unit in ${holding.currency}',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: ctrl,
                  autofocus: true,
                  placeholder: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: TextStyle(fontSize: 16, color: textPrimary),
                  placeholderStyle: TextStyle(fontSize: 16, color: textSecondary),
                  decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('Cancel', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final price = ((double.tryParse(ctrl.text) ?? 0) * 100).round();
                        if (price <= 0) return;
                        Navigator.pop(dialogCtx);
                        onUpdatePrice(price);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Close position?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text('This will mark "${holding.name}" as inactive. Historical data is preserved.',
                    style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('Cancel', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () { Navigator.pop(dialogCtx); onDeactivate(); },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('Close position'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteLot(BuildContext context, HoldingLot lot, bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete purchase?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text('This lot (${_fmtDate(lot.date)}, ${_fmtShort(lot.costBasisMinor)}) will be permanently removed.',
                    style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('Cancel', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () { Navigator.pop(dialogCtx); onDeleteLot(lot.id, holding.accountId); },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, Color valueColor, Color labelColor, Color surface) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: labelColor, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      );

  Widget _sectionLabel(String label, Color color) => Text(label.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.8));

  Widget _projRow(String label, String value, Color valueColor, Color labelColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 13, color: labelColor))),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );

  Widget _div(bool isDark) => Divider(
      height: 1,
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withValues(alpha: 0.5));

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  IconData _typeIcon(HoldingType t) => switch (t) {
        HoldingType.stock || HoldingType.etf => Icons.show_chart_outlined,
        HoldingType.unitTrust || HoldingType.moneyMarket => Icons.account_balance_outlined,
        HoldingType.fixedDeposit || HoldingType.bankSavings => Icons.savings_outlined,
        HoldingType.treasuryBill => Icons.receipt_long_outlined,
        HoldingType.sacco => Icons.groups_outlined,
        HoldingType.pension => Icons.elderly_outlined,
      };

  Color _liquidityColor(String l) => switch (l) {
        'instant' => AppColors.success,
        'days' => AppColors.warning,
        _ => AppColors.slateBlue,
      };

  String _liquidityLabel(String l) => switch (l) {
        'instant' => 'Instant',
        'days' => 'Days',
        _ => 'Locked',
      };

  String _fmtFull(int minor) {
    final v = minor / 100;
    final abs = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${v < 0 ? '−' : ''}KES $abs';
  }

  String _fmtShort(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

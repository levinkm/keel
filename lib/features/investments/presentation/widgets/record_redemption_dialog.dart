import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';

void showRedemptionDialog({
  required BuildContext context,
  required Holding holding,
  required List<Account> accounts,
  required void Function({
    required double units,
    required int priceMinor,
    required int feesMinor,
    required DateTime date,
    required String destinationAccountId,
    required String gainLossAccountId,
  }) onSave,
}) {
  showDialog(
    context: context,
    builder: (_) => _RedemptionDialog(
        holding: holding, accounts: accounts, onSave: onSave),
  );
}

class _RedemptionDialog extends StatefulWidget {
  final Holding holding;
  final List<Account> accounts;
  final void Function({
    required double units,
    required int priceMinor,
    required int feesMinor,
    required DateTime date,
    required String destinationAccountId,
    required String gainLossAccountId,
  }) onSave;

  const _RedemptionDialog({
    required this.holding,
    required this.accounts,
    required this.onSave,
  });

  @override
  State<_RedemptionDialog> createState() => _RedemptionDialogState();
}

class _RedemptionDialogState extends State<_RedemptionDialog> {
  final _unitsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _feesCtrl = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  String? _destinationAccountId;
  String? _gainLossAccountId;
  bool _redeemAll = false;

  bool get _hasUnits => widget.holding.type.hasUnits;
  double get _units => _redeemAll
      ? widget.holding.totalUnits
      : (double.tryParse(_unitsCtrl.text) ?? 0);
  int get _priceMinor => ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round();
  int get _feesMinor => ((double.tryParse(_feesCtrl.text) ?? 0) * 100).round();
  int get _proceedsMinor =>
      (_hasUnits ? (_units * _priceMinor).round() : _priceMinor) - _feesMinor;

  // Estimated realised gain based on avg cost
  int get _estimatedGain {
    final avgCost = widget.holding.totalUnits > 0
        ? widget.holding.totalCostBasisMinor / widget.holding.totalUnits
        : 0.0;
    final costOfRedeemed = (avgCost * _units).round();
    return _proceedsMinor - costOfRedeemed;
  }

  List<Account> get _assetAccounts =>
      widget.accounts.where((a) => a.type == AccountType.asset).toList();
  List<Account> get _gainLossAccounts => widget.accounts
      .where((a) =>
          a.type == AccountType.income || a.type == AccountType.expense)
      .toList();

  bool get _valid =>
      (_hasUnits ? _units > 0 : true) &&
      _priceMinor > 0 &&
      _destinationAccountId != null &&
      _gainLossAccountId != null;

  @override
  void dispose() {
    _unitsCtrl.dispose();
    _priceCtrl.dispose();
    _feesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fieldBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final isGain = _estimatedGain >= 0;
    final gainColor = isGain ? AppColors.success : AppColors.error;

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record redemption',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text(widget.holding.name,
                  style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(height: 24),

              // Date
              _label('Date', textSecondary),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: fieldBg, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: textTertiary),
                    const SizedBox(width: 8),
                    Text(_fmtDate(_date),
                        style: TextStyle(fontSize: 13, color: textPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Units
              if (_hasUnits) ...[
                Row(children: [
                  Expanded(child: _label('Units to redeem', textSecondary)),
                  GestureDetector(
                    onTap: () => setState(() {
                      _redeemAll = !_redeemAll;
                      if (_redeemAll) { _unitsCtrl.text =
                          widget.holding.totalUnits.toStringAsFixed(2); }
                    }),
                    child: Row(children: [
                      Icon(
                        _redeemAll
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank,
                        size: 14,
                        color: AppColors.royalBlue,
                      ),
                      const SizedBox(width: 4),
                      Text('Redeem all (${widget.holding.totalUnits.toStringAsFixed(2)} units)',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.royalBlue)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                _numField(_unitsCtrl, '0.00', textPrimary, textTertiary, fieldBg,
                    enabled: !_redeemAll,
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 16),
              ],

              // Price + Fees
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(
                          _hasUnits ? 'Redemption price/unit (KES)' : 'Proceeds (KES)',
                          textSecondary),
                      const SizedBox(height: 6),
                      _numField(_priceCtrl, '0.00', textPrimary, textTertiary,
                          fieldBg, onChanged: (_) => setState(() {})),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Fees (KES)', textSecondary),
                      const SizedBox(height: 6),
                      _numField(_feesCtrl, '0', textPrimary, textTertiary,
                          fieldBg, onChanged: (_) => setState(() {})),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Destination account
              _label('Proceeds paid to', textSecondary),
              const SizedBox(height: 6),
              _accountDropdown(_destinationAccountId, _assetAccounts,
                  'Select bank account', surface, textPrimary, textTertiary,
                  (v) => setState(() => _destinationAccountId = v)),
              const SizedBox(height: 16),

              // Gain/loss account
              _label('Gain / Loss account', textSecondary),
              const SizedBox(height: 6),
              _accountDropdown(_gainLossAccountId, _gainLossAccounts,
                  'Select income or expense account', surface, textPrimary,
                  textTertiary,
                  (v) => setState(() => _gainLossAccountId = v)),
              const SizedBox(height: 4),
              Text('Use an income account for gains, expense account for losses.',
                  style: TextStyle(fontSize: 11, color: textTertiary)),
              const SizedBox(height: 16),

              // Preview
              if (_proceedsMinor > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: gainColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(children: [
                    _previewRow('Proceeds', _fmtMoney(_proceedsMinor),
                        textPrimary, textSecondary),
                    const SizedBox(height: 6),
                    _previewRow(
                      isGain ? 'Est. realised gain' : 'Est. realised loss',
                      '${isGain ? '+' : ''}${_fmtMoney(_estimatedGain)}',
                      gainColor,
                      textSecondary,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    color: _valid ? AppColors.royalBlue : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid ? _save : null,
                    child: Text('Record redemption',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _valid
                                ? Colors.white
                                : AppColors.disabledForeground)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(context);
    widget.onSave(
      units: _units,
      priceMinor: _hasUnits ? _priceMinor : _priceMinor,
      feesMinor: _feesMinor,
      date: _date,
      destinationAccountId: _destinationAccountId!,
      gainLossAccountId: _gainLossAccountId!,
    );
  }

  Widget _accountDropdown(
    String? value,
    List<Account> accounts,
    String hint,
    Color surface,
    Color textPrimary,
    Color textTertiary,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration:
          BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: surface,
          hint: Text(hint,
              style: TextStyle(fontSize: 13, color: textTertiary)),
          style: TextStyle(fontSize: 13, color: textPrimary),
          items: accounts
              .map((a) => DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text(a.name),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String placeholder,
    Color textPrimary,
    Color textTertiary,
    Color fieldBg, {
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) =>
      CupertinoTextField(
        controller: ctrl,
        enabled: enabled,
        placeholder: placeholder,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: onChanged ?? (_) {},
        style: TextStyle(fontSize: 14, color: textPrimary),
        placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
        decoration: BoxDecoration(
            color: fieldBg, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _previewRow(
          String label, String value, Color valueColor, Color labelColor) =>
      Row(children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]);

  Widget _label(String text, Color color) => Text(text,
      style:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));

  String _fmtDate(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  String _fmtMoney(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

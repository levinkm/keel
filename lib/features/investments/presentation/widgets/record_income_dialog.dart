import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';

void showRecordIncomeDialog({
  required BuildContext context,
  required Holding holding,
  required List<Account> accounts,
  int prefillAmount = 0,
  required void Function({
    required int amountMinor,
    required DateTime date,
    required String incomeAccountId,
    required String bankOrInvestmentAccountId,
    required bool isReinvested,
    required double reinvestedUnits,
    required int reinvestedPriceMinor,
  }) onSave,
}) {
  showDialog(
    context: context,
    builder: (_) =>
        _RecordIncomeDialog(holding: holding, accounts: accounts,
            prefillAmount: prefillAmount, onSave: onSave),
  );
}

class _RecordIncomeDialog extends StatefulWidget {
  final Holding holding;
  final List<Account> accounts;
  final int prefillAmount;
  final void Function({
    required int amountMinor,
    required DateTime date,
    required String incomeAccountId,
    required String bankOrInvestmentAccountId,
    required bool isReinvested,
    required double reinvestedUnits,
    required int reinvestedPriceMinor,
  }) onSave;

  const _RecordIncomeDialog({
    required this.holding,
    required this.accounts,
    this.prefillAmount = 0,
    required this.onSave,
  });

  @override
  State<_RecordIncomeDialog> createState() => _RecordIncomeDialogState();
}

class _RecordIncomeDialogState extends State<_RecordIncomeDialog> {
  final _amountCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _incomeAccountId;
  String? _destinationAccountId;
  bool _isReinvested = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillAmount > 0) {
      _amountCtrl.text =
          (widget.prefillAmount / 100).toStringAsFixed(2);
    }
  }

  int get _amountMinor =>
      ((double.tryParse(_amountCtrl.text) ?? 0) * 100).round();
  double get _reinvestedUnits => double.tryParse(_unitsCtrl.text) ?? 0;
  int get _reinvestedPriceMinor =>
      ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round();

  bool get _hasUnits => widget.holding.type.hasUnits;

  List<Account> get _incomeAccounts =>
      widget.accounts.where((a) => a.type == AccountType.income).toList();
  List<Account> get _assetAccounts =>
      widget.accounts.where((a) => a.type == AccountType.asset).toList();

  bool get _valid {
    if (_amountMinor <= 0) return false;
    if (_incomeAccountId == null) return false;
    if (_isReinvested) return true; // reinvested goes to investment account
    return _destinationAccountId != null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _unitsCtrl.dispose();
    _priceCtrl.dispose();
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

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record income',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text(widget.holding.name,
                  style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(height: 24),

              // Income type toggle
              _label('Income type', textSecondary),
              const SizedBox(height: 8),
              Row(children: [
                _typeChip('Cash payout', !_isReinvested, fieldBg, textSecondary,
                    () => setState(() => _isReinvested = false)),
                const SizedBox(width: 8),
                _typeChip('Reinvested', _isReinvested, fieldBg, textSecondary,
                    () => setState(() => _isReinvested = true)),
              ]),
              const SizedBox(height: 4),
              Text(
                _isReinvested
                    ? 'Income was reinvested back into the fund (new units added).'
                    : 'Income was paid out to a bank account.',
                style: TextStyle(fontSize: 11, color: textTertiary),
              ),
              const SizedBox(height: 16),

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

              // Amount
              _label('Amount (KES)', textSecondary),
              const SizedBox(height: 6),
              _numField(_amountCtrl, '0.00', textPrimary, textTertiary, fieldBg,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),

              // Reinvested units (only for unit-based holdings)
              if (_isReinvested && _hasUnits) ...[
                _label('New units received', textSecondary),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: _numField(_unitsCtrl, 'Units', textPrimary,
                        textTertiary, fieldBg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Price per unit', textSecondary),
                        const SizedBox(height: 6),
                        _numField(_priceCtrl, '0.00', textPrimary, textTertiary,
                            fieldBg),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
              ],

              // Income account
              _label('Income account', textSecondary),
              const SizedBox(height: 6),
              _accountDropdown(
                _incomeAccountId,
                _incomeAccounts,
                'Select income account',
                surface, textPrimary, textTertiary,
                (v) => setState(() => _incomeAccountId = v),
              ),
              const SizedBox(height: 16),

              // Destination (cash payout only)
              if (!_isReinvested) ...[
                _label('Paid to account', textSecondary),
                const SizedBox(height: 6),
                _accountDropdown(
                  _destinationAccountId,
                  _assetAccounts,
                  'Select bank account',
                  surface, textPrimary, textTertiary,
                  (v) => setState(() => _destinationAccountId = v),
                ),
                const SizedBox(height: 16),
              ],

              // Preview
              if (_amountMinor > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Text('Income amount',
                        style: TextStyle(fontSize: 13, color: textSecondary)),
                    const Spacer(),
                    Text('+${_fmtMoney(_amountMinor)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            fontFeatures: [FontFeature.tabularFigures()])),
                  ]),
                ),
              const SizedBox(height: 24),

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
                    child: Text('Record income',
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
      amountMinor: _amountMinor,
      date: _date,
      incomeAccountId: _incomeAccountId!,
      bankOrInvestmentAccountId:
          _isReinvested ? widget.holding.accountId : _destinationAccountId!,
      isReinvested: _isReinvested,
      reinvestedUnits: _reinvestedUnits,
      reinvestedPriceMinor: _reinvestedPriceMinor,
    );
  }

  Widget _typeChip(String label, bool isSelected, Color fieldBg,
      Color textSecondary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalBlue.withValues(alpha: 0.12)
              : fieldBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.royalBlue : textSecondary,
            )),
      ),
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
    ValueChanged<String>? onChanged,
  }) =>
      CupertinoTextField(
        controller: ctrl,
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

  Widget _label(String text, Color color) => Text(text,
      style:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));

  String _fmtDate(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  String _fmtMoney(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:uuid/uuid.dart';

void showAddLotDialog({
  required BuildContext context,
  required Holding holding,
  required List<Account> accounts,
  required void Function(HoldingLot lot, String? sourceAccountId) onSave,
}) {
  showDialog(
    context: context,
    builder: (_) => _AddLotDialog(
        holding: holding, accounts: accounts, onSave: onSave),
  );
}

class _AddLotDialog extends StatefulWidget {
  final Holding holding;
  final List<Account> accounts;
  final void Function(HoldingLot lot, String? sourceAccountId) onSave;
  const _AddLotDialog(
      {required this.holding, required this.accounts, required this.onSave});

  @override
  State<_AddLotDialog> createState() => _AddLotDialogState();
}

class _AddLotDialogState extends State<_AddLotDialog> {
  final _unitsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _feesCtrl = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  String? _sourceAccountId;

  bool get _hasUnits => widget.holding.type.hasUnits;

  double get _units => double.tryParse(_unitsCtrl.text) ?? 0;
  int get _priceMinor => ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round();
  int get _feesMinor => ((double.tryParse(_feesCtrl.text) ?? 0) * 100).round();
  int get _totalMinor =>
      (_hasUnits ? (_units * _priceMinor).round() : _priceMinor) + _feesMinor;

  bool get _valid => _hasUnits ? (_units > 0 && _priceMinor > 0) : _priceMinor > 0;

  // Accounts that can be debited from (asset accounts excluding the investment account itself)
  List<Account> get _sourceAccounts => widget.accounts
      .where((a) =>
          a.type == AccountType.asset && a.id != widget.holding.accountId)
      .toList();

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

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record purchase',
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

              // Units + Price
              Row(children: [
                if (_hasUnits) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Units', textSecondary),
                        const SizedBox(height: 6),
                        _numField(_unitsCtrl, 'e.g. 1000', textPrimary,
                            textTertiary, fieldBg),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(
                          _hasUnits ? 'Price per unit (KES)' : 'Amount (KES)',
                          textSecondary),
                      const SizedBox(height: 6),
                      _numField(_priceCtrl, '0.00', textPrimary, textTertiary,
                          fieldBg, onChanged: (_) => setState(() {})),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Fees
              _label('Fees / Charges (KES)', textSecondary),
              const SizedBox(height: 6),
              _numField(_feesCtrl, '0', textPrimary, textTertiary, fieldBg,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),

              // Source account
              _label('Funded from', textSecondary),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _sourceAccountId,
                    isExpanded: true,
                    dropdownColor: surface,
                    hint: Text('Select source account (optional)',
                        style: TextStyle(fontSize: 13, color: textTertiary)),
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No source account',
                            style: TextStyle(fontSize: 13, color: textTertiary)),
                      ),
                      ..._sourceAccounts.map((a) => DropdownMenuItem<String?>(
                            value: a.id,
                            child: Text(a.name),
                          )),
                    ],
                    onChanged: (v) => setState(() => _sourceAccountId = v),
                  ),
                ),
              ),
              if (_sourceAccountId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 12, color: textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Will debit ${_sourceAccounts.firstWhere((a) => a.id == _sourceAccountId).name} '
                      'and credit the investment account.',
                      style: TextStyle(fontSize: 11, color: textTertiary),
                    ),
                  ]),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 12, color: textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'No journal entry will be posted without a source account.',
                      style: TextStyle(fontSize: 11, color: textTertiary),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),

              // Total preview
              if (_totalMinor > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Text('Total cost',
                        style: TextStyle(fontSize: 13, color: textSecondary)),
                    const Spacer(),
                    Text(
                      _fmtMoney(_totalMinor),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlue,
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
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
                    child: Text('Record',
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
      HoldingLot(
        id: const Uuid().v4(),
        holdingId: widget.holding.id,
        date: _date,
        units: _hasUnits ? _units : 1.0,
        priceMinor:
            _hasUnits ? _priceMinor : _totalMinor - _feesMinor,
        feesMinor: _feesMinor,
        currency: widget.holding.currency,
      ),
      _sourceAccountId,
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String placeholder,
    Color textPrimary,
    Color textTertiary,
    Color fieldBg, {
    ValueChanged<String>? onChanged,
  }) {
    return CupertinoTextField(
      controller: ctrl,
      placeholder: placeholder,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      onChanged: onChanged ?? (_) {},
      style: TextStyle(fontSize: 14, color: textPrimary),
      placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
      decoration:
          BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));

  String _fmtDate(DateTime d) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  String _fmtMoney(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

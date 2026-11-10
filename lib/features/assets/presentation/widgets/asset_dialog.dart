import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:uuid/uuid.dart';

Future<void> showAssetDialog({
  required BuildContext context,
  Asset? existing,
  required void Function(Asset) onSave,
}) {
  return showDialog(
    context: context,
    builder: (_) => _AssetDialog(existing: existing, onSave: onSave),
  );
}

class _AssetDialog extends StatefulWidget {
  final Asset? existing;
  final void Function(Asset) onSave;
  const _AssetDialog({this.existing, required this.onSave});

  @override
  State<_AssetDialog> createState() => _AssetDialogState();
}

class _AssetDialogState extends State<_AssetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _cost;
  late final TextEditingController _salvage;
  late final TextEditingController _currentValue;
  late final TextEditingController _annualRate;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late final TextEditingController _valuationSource;

  late AssetClass _class;
  late DateTime _acquisitionDate;
  DateTime? _valuationDate;
  DateTime? _insuranceExpiry;
  DepreciationMethod? _depMethod;
  AssetStatus _status = AssetStatus.inUse;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _name = TextEditingController(text: a?.name ?? '');
    _cost = TextEditingController(text: a != null ? (a.costMinor / 100).toStringAsFixed(2) : '');
    _salvage = TextEditingController(text: a != null ? (a.salvageMinor / 100).toStringAsFixed(2) : '0.00');
    _currentValue = TextEditingController(
        text: a?.currentValueMinor != null ? (a!.currentValueMinor! / 100).toStringAsFixed(2) : '');
    _annualRate = TextEditingController(
        text: a?.annualRateBp != null ? (a!.annualRateBp! / 100).toStringAsFixed(1) : '');
    _location = TextEditingController(text: a?.location ?? '');
    _notes = TextEditingController(text: a?.notes ?? '');
    _valuationSource = TextEditingController(text: a?.valuationSource ?? '');
    _class = a?.assetClass ?? AssetClass.other;
    _acquisitionDate = a?.acquisitionDate ?? DateTime.now();
    _valuationDate = a?.valuationDate;
    _insuranceExpiry = a?.insuranceExpiry;
    _depMethod = a?.depreciationMethod;
    _status = a?.status ?? AssetStatus.inUse;
  }

  @override
  void dispose() {
    for (final c in [_name, _cost, _salvage, _currentValue, _annualRate, _location, _notes, _valuationSource]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isEdit = widget.existing != null;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text(
                  isEdit ? 'Edit Asset' : 'Add Asset',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('Name', _name, required: true),
                      const SizedBox(height: 12),
                      _label('Class', textSecondary),
                      const SizedBox(height: 6),
                      _classDropdown(isDark, textPrimary),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field('Cost (KES)', _cost, numeric: true, required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Salvage Value', _salvage, numeric: true)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _datePicker('Acquisition Date', _acquisitionDate, isDark, textPrimary, textSecondary,
                            (d) => setState(() => _acquisitionDate = d))),
                        const SizedBox(width: 12),
                        Expanded(child: _statusDropdown(isDark, textPrimary, textSecondary)),
                      ]),
                      const SizedBox(height: 12),
                      _label('Depreciation', textSecondary),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _depMethodDropdown(isDark, textPrimary, textSecondary)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Annual Rate (%)', _annualRate, numeric: true,
                            enabled: _depMethod != null)),
                      ]),
                      const SizedBox(height: 12),
                      _label('Current Valuation', textSecondary),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _field('Current Value (KES)', _currentValue, numeric: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _datePicker('Valuation Date', _valuationDate, isDark, textPrimary, textSecondary,
                            (d) => setState(() => _valuationDate = d), nullable: true)),
                      ]),
                      const SizedBox(height: 12),
                      _field('Valuation Source', _valuationSource),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _datePicker('Insurance Expiry', _insuranceExpiry, isDark, textPrimary, textSecondary,
                            (d) => setState(() => _insuranceExpiry = d), nullable: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Location', _location)),
                      ]),
                      const SizedBox(height: 12),
                      _field('Notes', _notes, maxLines: 2),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(isEdit ? 'Save' : 'Add Asset'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) =>
      Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3));

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, bool numeric = false, int maxLines = 1, bool enabled = true}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _classDropdown(bool isDark, Color textPrimary) {
    return DropdownButtonFormField<AssetClass>(
      initialValue: _class,
      isDense: true,
      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: AssetClass.values.map((c) => DropdownMenuItem(value: c, child: Text(_classLabel(c)))).toList(),
      onChanged: (v) => setState(() => _class = v!),
    );
  }

  Widget _statusDropdown(bool isDark, Color textPrimary, Color textSecondary) {
    return DropdownButtonFormField<AssetStatus>(
      initialValue: _status,
      isDense: true,
      decoration: const InputDecoration(labelText: 'Status', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: AssetStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
      onChanged: (v) => setState(() => _status = v!),
    );
  }

  Widget _depMethodDropdown(bool isDark, Color textPrimary, Color textSecondary) {
    return DropdownButtonFormField<DepreciationMethod?>(
      initialValue: _depMethod,
      isDense: true,
      decoration: const InputDecoration(labelText: 'Method', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...DepreciationMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(_depLabel(m)))),
      ],
      onChanged: (v) => setState(() => _depMethod = v),
    );
  }

  Widget _datePicker(String label, DateTime? value, bool isDark, Color textPrimary, Color textSecondary,
      void Function(DateTime) onPicked, {bool nullable = false}) {
    final display = value != null ? _fmtDate(value) : (nullable ? '—' : _fmtDate(DateTime.now()));
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 14),
        ),
        child: Text(display, style: TextStyle(fontSize: 14, color: textPrimary)),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cost = (double.tryParse(_cost.text) ?? 0) * 100;
    final salvage = (double.tryParse(_salvage.text) ?? 0) * 100;
    final currentVal = _currentValue.text.trim().isNotEmpty
        ? ((double.tryParse(_currentValue.text) ?? 0) * 100).round()
        : null;
    final rate = _annualRate.text.trim().isNotEmpty
        ? ((double.tryParse(_annualRate.text) ?? 0) * 100).round()
        : null;

    final asset = Asset(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      assetClass: _class,
      acquisitionDate: _acquisitionDate,
      costMinor: cost.round(),
      currency: 'KES',
      ownershipShareBp: 10000,
      currentValueMinor: currentVal,
      valuationDate: _valuationDate,
      valuationSource: _valuationSource.text.trim().isEmpty ? null : _valuationSource.text.trim(),
      depreciationMethod: _depMethod,
      annualRateBp: rate,
      salvageMinor: salvage.round(),
      linkedLoanId: widget.existing?.linkedLoanId,
      insuranceExpiry: _insuranceExpiry,
      status: _status,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.pop(context);
    widget.onSave(asset);
  }

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

  String _statusLabel(AssetStatus s) => switch (s) {
        AssetStatus.inUse => 'In Use',
        AssetStatus.sold => 'Sold',
        AssetStatus.writtenOff => 'Written Off',
      };

  String _depLabel(DepreciationMethod m) => switch (m) {
        DepreciationMethod.straightLine => 'Straight Line',
        DepreciationMethod.reducingBalance => 'Reducing Balance',
      };

  String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

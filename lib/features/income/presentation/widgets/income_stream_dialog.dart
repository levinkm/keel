import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:uuid/uuid.dart';

void showIncomeStreamDialog({
  required BuildContext context,
  required List<Account> accounts,
  required IncomeStream? existing,
  required ValueChanged<IncomeStream> onSave,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => _IncomeStreamDialog(
      existing: existing,
      accounts: accounts,
      onSave: (stream) {
        Navigator.of(dialogContext).pop();
        onSave(stream);
      },
    ),
  );
}

class _IncomeStreamDialog extends StatefulWidget {
  final IncomeStream? existing;
  final List<Account> accounts;
  final ValueChanged<IncomeStream> onSave;

  const _IncomeStreamDialog({
    required this.existing,
    required this.accounts,
    required this.onSave,
  });

  @override
  State<_IncomeStreamDialog> createState() => _IncomeStreamDialogState();
}

class _IncomeStreamDialogState extends State<_IncomeStreamDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _reliableCtrl;
  late IncomeType _type;
  late IncomeFrequency _frequency;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _nameCtrl.addListener(() => setState(() {}));
    _amountCtrl = TextEditingController(
        text: e != null ? (e.amountMinor / 100).toStringAsFixed(0) : '');
    _reliableCtrl = TextEditingController(
        text: e?.reliableAmountMinor != null
            ? (e!.reliableAmountMinor! / 100).toStringAsFixed(0)
            : '');
    _type = e?.type ?? IncomeType.salary;
    _frequency = e?.frequency ?? IncomeFrequency.monthly;
    _accountId = e?.accountId.isEmpty ?? true ? null : e?.accountId;
    if (_accountId != null && !widget.accounts.any((a) => a.id == _accountId)) {
      _accountId = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _reliableCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _nameCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
              Text(widget.existing == null ? 'Add income stream' : 'Edit income stream',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 24),

              _Label('Name', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _nameCtrl,
                placeholder: 'e.g. Monthly Salary',
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              _Label('Type', textSecondary),
              const SizedBox(height: 6),
              _SegmentedPicker<IncomeType>(
                value: _type,
                options: const [
                  (IncomeType.salary, 'Salary'),
                  (IncomeType.business, 'Business'),
                  (IncomeType.farming, 'Farming'),
                  (IncomeType.rent, 'Rent'),
                  (IncomeType.dividends, 'Dividends'),
                  (IncomeType.interest, 'Interest'),
                  (IncomeType.sideWork, 'Side work'),
                  (IncomeType.oneOff, 'One-off'),
                ],
                onChanged: (v) => setState(() => _type = v),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              _Label('Frequency', textSecondary),
              const SizedBox(height: 6),
              _SegmentedPicker<IncomeFrequency>(
                value: _frequency,
                options: const [
                  (IncomeFrequency.monthly, 'Monthly'),
                  (IncomeFrequency.weekly, 'Weekly'),
                  (IncomeFrequency.irregular, 'Irregular'),
                  (IncomeFrequency.scheduled, 'Scheduled'),
                ],
                onChanged: (v) => setState(() => _frequency = v),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Expected amount (KES)', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0',
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                          decoration: BoxDecoration(
                              color: elevated, borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Reliable amount (optional)', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _reliableCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: 'Same as expected',
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                          decoration: BoxDecoration(
                              color: elevated, borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _Label('Deposit account (optional)', textSecondary),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: elevated, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _accountId,
                    isExpanded: true,
                    dropdownColor: surface,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    hint: Text('None', style: TextStyle(fontSize: 14, color: textSecondary)),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None', style: TextStyle(fontSize: 14, color: textSecondary)),
                      ),
                      ...widget.accounts.map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          )),
                    ],
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    color: _valid ? AppColors.royalBlue : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid ? _save : null,
                    child: const Text('Save',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
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
    final amount = (double.tryParse(_amountCtrl.text.trim()) ?? 0) * 100;
    final reliable = _reliableCtrl.text.trim().isEmpty
        ? null
        : (double.tryParse(_reliableCtrl.text.trim()) ?? 0) * 100;
    widget.onSave(IncomeStream(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      accountId: _accountId ?? '',
      frequency: _frequency,
      amountMinor: amount.round(),
      reliableAmountMinor: reliable?.round(),
      currency: 'KES',
      isActive: widget.existing?.isActive ?? true,
      startDate: widget.existing?.startDate,
      endDate: widget.existing?.endDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    ));
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 12, color: color));
}

class _SegmentedPicker<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool isDark;

  const _SegmentedPicker({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final isSelected = o.$1 == value;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.royalBlue
                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(o.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                )),
          ),
        );
      }).toList(),
    );
  }
}

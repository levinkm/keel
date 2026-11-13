import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/tariffs/domain/entities/tariff.dart';
import 'package:uuid/uuid.dart';

void showTariffDialog({
  required BuildContext context,
  required List<Account> accounts,
  required Tariff? existing,
  required ValueChanged<Tariff> onSave,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _TariffDialog(
      accounts: accounts,
      existing: existing,
      onSave: (t) {
        Navigator.of(ctx).pop();
        onSave(t);
      },
    ),
  );
}

class _TariffDialog extends StatefulWidget {
  final List<Account> accounts;
  final Tariff? existing;
  final ValueChanged<Tariff> onSave;
  const _TariffDialog({
    required this.accounts,
    required this.existing,
    required this.onSave,
  });

  @override
  State<_TariffDialog> createState() => _TariffDialogState();
}

class _TariffDialogState extends State<_TariffDialog> {
  late TextEditingController _providerCtrl;
  late TextEditingController _taxCtrl;
  late TariffOperation _operation;
  String? _accountId;
  String? _feeAccountId;
  late List<_TierRow> _tiers;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _providerCtrl = TextEditingController(text: e?.provider ?? '');
    _providerCtrl.addListener(() => setState(() {}));
    _taxCtrl = TextEditingController(
        text: e != null ? (e.taxRateBp / 100).toStringAsFixed(1) : '0.0');
    _operation = e?.operation ?? TariffOperation.withdrawal;
    _accountId = (e?.accountId.isEmpty ?? true) ? null : e?.accountId;
    _feeAccountId = e?.feeAccountId;
    _tiers = e != null
        ? e.tiers.map((t) => _TierRow.fromTier(t)).toList()
        : [_TierRow()];
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _taxCtrl.dispose();
    for (final t in _tiers) {
      t.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _providerCtrl.text.trim().isNotEmpty &&
      _accountId != null &&
      _tiers.isNotEmpty;

  List<Account> get _assetAccounts =>
      widget.accounts.where((a) => a.type == AccountType.asset).toList();
  List<Account> get _expenseAccounts =>
      widget.accounts.where((a) => a.type == AccountType.expense).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated =
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
        width: 540,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Add tariff rule' : 'Edit tariff rule',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure the fee schedule for a specific account and operation.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 24),

              _Label('Provider name', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _providerCtrl,
                placeholder: 'e.g. M-Pesa, KCB, Equity',
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                    color: elevated, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Account', textSecondary),
                        const SizedBox(height: 6),
                        _AccountDropdown(
                          value: _accountId,
                          accounts: _assetAccounts,
                          hint: 'Select account',
                          isDark: isDark,
                          onChanged: (v) => setState(() => _accountId = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Operation', textSecondary),
                        const SizedBox(height: 6),
                        _Segmented<TariffOperation>(
                          value: _operation,
                          options: const [
                            (TariffOperation.withdrawal, 'Withdraw'),
                            (TariffOperation.transfer, 'Transfer'),
                            (TariffOperation.deposit, 'Deposit'),
                          ],
                          onChanged: (v) => setState(() => _operation = v),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _Label('Post fee to expense account (optional)', textSecondary),
              const SizedBox(height: 6),
              _AccountDropdown(
                value: _feeAccountId,
                accounts: _expenseAccounts,
                hint: 'None — fee not posted to ledger',
                isDark: isDark,
                onChanged: (v) => setState(() => _feeAccountId = v),
                nullable: true,
              ),
              const SizedBox(height: 4),
              Text(
                'When set, a separate journal line is posted for the fee on every transaction.',
                style: TextStyle(fontSize: 11, color: textTertiary),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Excise / tax on fee (%)', textSecondary),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 120,
                        child: CupertinoTextField(
                          controller: _taxCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0.0',
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 14, color: textSecondary),
                          decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Text('Fee tiers',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _tiers.add(_TierRow())),
                    child: Row(
                      children: [
                        const Icon(Icons.add,
                            size: 14, color: AppColors.royalBlue),
                        const SizedBox(width: 4),
                        const Text('Add tier',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.royalBlue,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tiers are evaluated top-to-bottom. Leave "Up to" blank on the last tier to catch all amounts above.',
                style: TextStyle(fontSize: 11, color: textTertiary),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 130,
                        child: Text('Up to (KES)',
                            style:
                                TextStyle(fontSize: 11, color: textTertiary))),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 100,
                        child: Text('Fee %',
                            style:
                                TextStyle(fontSize: 11, color: textTertiary))),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 110,
                        child: Text('Fixed fee (KES)',
                            style:
                                TextStyle(fontSize: 11, color: textTertiary))),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              ..._tiers.asMap().entries.map((entry) {
                final i = entry.key;
                final tier = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: CupertinoTextField(
                          controller: tier.upToCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: 'Any',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textSecondary),
                          decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(7)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: CupertinoTextField(
                          controller: tier.feeBpCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0.0',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textSecondary),
                          decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(7)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: CupertinoTextField(
                          controller: tier.feeFixedCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textSecondary),
                          decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(7)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_tiers.length > 1)
                        GestureDetector(
                          onTap: () => setState(() {
                            _tiers[i].dispose();
                            _tiers.removeAt(i);
                          }),
                          child: const Icon(Icons.remove_circle_outline,
                              size: 16, color: AppColors.error),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style:
                            TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    color: _valid
                        ? AppColors.royalBlue
                        : AppColors.disabledSurface,
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
    final tiers = _tiers.map((t) {
      final upToRaw = double.tryParse(t.upToCtrl.text.trim());
      final feePct = double.tryParse(t.feeBpCtrl.text.trim()) ?? 0;
      final feeFixed = double.tryParse(t.feeFixedCtrl.text.trim()) ?? 0;
      return TariffTier(
        upToMinor: upToRaw != null ? (upToRaw * 100).round() : null,
        feeBp: (feePct * 100).round(),
        feeFixed: (feeFixed * 100).round(),
      );
    }).toList();

    final taxBp =
        ((double.tryParse(_taxCtrl.text.trim()) ?? 0) * 100).round();

    widget.onSave(Tariff(
      id: widget.existing?.id ?? const Uuid().v4(),
      provider: _providerCtrl.text.trim(),
      accountId: _accountId!,
      operation: _operation,
      tiers: tiers,
      taxRateBp: taxBp,
      feeAccountId: _feeAccountId,
      effectiveFrom: widget.existing?.effectiveFrom ?? DateTime.now(),
      effectiveTo: widget.existing?.effectiveTo,
    ));
  }
}

class _TierRow {
  final TextEditingController upToCtrl;
  final TextEditingController feeBpCtrl;
  final TextEditingController feeFixedCtrl;

  _TierRow()
      : upToCtrl = TextEditingController(),
        feeBpCtrl = TextEditingController(),
        feeFixedCtrl = TextEditingController();

  _TierRow.fromTier(TariffTier t)
      : upToCtrl = TextEditingController(
            text: t.upToMinor != null
                ? (t.upToMinor! / 100).toStringAsFixed(0)
                : ''),
        feeBpCtrl =
            TextEditingController(text: (t.feeBp / 100).toStringAsFixed(2)),
        feeFixedCtrl = TextEditingController(
            text: (t.feeFixed / 100).toStringAsFixed(0));

  void dispose() {
    upToCtrl.dispose();
    feeBpCtrl.dispose();
    feeFixedCtrl.dispose();
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

class _AccountDropdown extends StatelessWidget {
  final String? value;
  final List<Account> accounts;
  final String hint;
  final bool isDark;
  final ValueChanged<String?> onChanged;
  final bool nullable;

  const _AccountDropdown({
    required this.value,
    required this.accounts,
    required this.hint,
    required this.isDark,
    required this.onChanged,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) {
    final elevated =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration:
          BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: surface,
          style: TextStyle(fontSize: 13, color: textPrimary),
          hint: Text(hint, style: TextStyle(fontSize: 13, color: textSecondary)),
          items: [
            if (nullable)
              DropdownMenuItem<String>(
                value: null,
                child: Text('None',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
              ),
            ...accounts.map((a) =>
                DropdownMenuItem(value: a.id, child: Text(a.name))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool isDark;
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options.map((o) {
          final sel = o.$1 == value;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.royalBlue
                    : (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(o.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  )),
            ),
          );
        }).toList(),
      );
}

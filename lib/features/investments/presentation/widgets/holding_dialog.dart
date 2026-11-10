import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:uuid/uuid.dart';

void showHoldingDialog({
  required BuildContext context,
  required List<Account> accounts,
  Holding? existing,
  required ValueChanged<Holding> onSave,
  required ValueChanged<Account> onCreateAccount,
}) {
  showDialog(
    context: context,
    builder: (_) => _HoldingDialog(
      accounts: accounts,
      existing: existing,
      onSave: onSave,
      onCreateAccount: onCreateAccount,
    ),
  );
}

class _HoldingDialog extends StatefulWidget {
  final List<Account> accounts;
  final Holding? existing;
  final ValueChanged<Holding> onSave;
  final ValueChanged<Account> onCreateAccount;

  const _HoldingDialog({
    required this.accounts,
    this.existing,
    required this.onSave,
    required this.onCreateAccount,
  });

  @override
  State<_HoldingDialog> createState() => _HoldingDialogState();
}

class _HoldingDialogState extends State<_HoldingDialog> {
  final _nameCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  late HoldingType _type;
  late String _liquidity;
  late CompoundingFreq _compoundingFreq;
  DateTime? _maturityDate;
  String? _accountId;

  // Accounts created inline during this dialog session
  final List<Account> _newAccounts = [];

  bool get _isEdit => widget.existing != null;
  bool get _showRateFields =>
      _type != HoldingType.stock && _type != HoldingType.etf;

  List<Account> get _allAssetAccounts => [
        ...widget.accounts.where((a) => a.type == AccountType.asset),
        ..._newAccounts,
      ];

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _nameCtrl.text = h?.name ?? '';
    _institutionCtrl.text = h?.institution ?? '';
    _rateCtrl.text = h?.annualRateBp != null
        ? (h!.annualRateBp! / 100).toStringAsFixed(2)
        : '';
    _type = h?.type ?? HoldingType.unitTrust;
    _liquidity = h?.liquidity ?? 'days';
    _compoundingFreq = h?.compoundingFreq ?? CompoundingFreq.none;
    _maturityDate = h?.maturityDate;
    _accountId = h?.accountId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _institutionCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _institutionCtrl.text.trim().isNotEmpty &&
      _accountId != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fieldBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_isEdit ? 'Edit holding' : 'New holding',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(CupertinoIcons.xmark, size: 16, color: textSecondary),
                ),
              ]),
              const SizedBox(height: 24),

              // Type grid
              _label('Type', textSecondary),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HoldingType.values.map((t) {
                  final isSelected = t == _type;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.royalBlue.withValues(alpha: 0.12)
                            : fieldBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.royalBlue : textSecondary,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name
              _label('Name', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                placeholder: 'e.g. Britam Money Market Fund',
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Institution
              _label('Institution / Broker', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _institutionCtrl,
                placeholder: 'e.g. Britam Asset Managers',
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Account + Liquidity
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _label('Linked account', textSecondary),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showCreateAccountSheet(
                              context, isDark, fieldBg, textPrimary,
                              textSecondary, textTertiary, surface),
                          child: Row(children: [
                            const Icon(Icons.add, size: 13, color: AppColors.royalBlue),
                            const SizedBox(width: 3),
                            const Text('New account',
                                style: TextStyle(fontSize: 11,
                                    color: AppColors.royalBlue,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: fieldBg, borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _accountId,
                            isExpanded: true,
                            dropdownColor: surface,
                            hint: Text('Select account',
                                style: TextStyle(fontSize: 13, color: textTertiary)),
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            items: _allAssetAccounts.map((a) {
                              final isNew = _newAccounts.any((n) => n.id == a.id);
                              return DropdownMenuItem(
                                value: a.id,
                                child: Row(children: [
                                  Expanded(child: Text(a.name)),
                                  if (isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('New',
                                          style: TextStyle(fontSize: 10,
                                              color: AppColors.royalBlue,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                ]),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _accountId = v),
                          ),
                        ),
                      ),
                      if (_allAssetAccounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('No asset accounts yet — tap "New account" to create one.',
                              style: TextStyle(fontSize: 11, color: textTertiary)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Liquidity', textSecondary),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: fieldBg, borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _liquidity,
                            isExpanded: true,
                            dropdownColor: surface,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'instant', child: Text('Instant')),
                              DropdownMenuItem(value: 'days', child: Text('Days')),
                              DropdownMenuItem(value: 'locked', child: Text('Locked')),
                            ],
                            onChanged: (v) => setState(() => _liquidity = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              // Interest rate fields (not for stocks/ETFs)
              if (_showRateFields) ...[
                _label('Interest / Return rate (optional)', textSecondary),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _rateCtrl,
                      placeholder: 'e.g. 12.50',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text('% p.a.',
                            style: TextStyle(fontSize: 13, color: textTertiary)),
                      ),
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
                      decoration: BoxDecoration(
                          color: fieldBg, borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: fieldBg, borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CompoundingFreq>(
                              value: _compoundingFreq,
                              isExpanded: true,
                              dropdownColor: surface,
                              style: TextStyle(fontSize: 13, color: textPrimary),
                              items: CompoundingFreq.values
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f.label,
                                            style: const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _compoundingFreq = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Maturity date
                _label('Maturity date (optional)', textSecondary),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _maturityDate ?? DateTime.now().add(
                          const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _maturityDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: fieldBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        _maturityDate != null
                            ? _fmtDate(_maturityDate!)
                            : 'No maturity date (open-ended)',
                        style: TextStyle(
                            fontSize: 13,
                            color: _maturityDate != null
                                ? textPrimary
                                : textTertiary),
                      ),
                      const Spacer(),
                      if (_maturityDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _maturityDate = null),
                          child: Icon(Icons.close, size: 14, color: textTertiary),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
              ] else
                const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    color: _valid ? AppColors.royalBlue : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid ? _save : null,
                    child: Text(_isEdit ? 'Save' : 'Create holding',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _valid ? Colors.white : AppColors.disabledForeground)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAccountSheet(
    BuildContext context,
    bool isDark,
    Color fieldBg,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
    Color surface,
  ) {
    final nameCtrl = TextEditingController();
    AccountType type = AccountType.asset;
    Liquidity liquidity = Liquidity.instant;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('This account will be linked to the holding.',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const SizedBox(height: 20),

                  Text('Account name',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: textSecondary)),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: nameCtrl,
                    autofocus: true,
                    placeholder: 'e.g. Britam Investment Account',
                    onChanged: (_) => setInner(() {}),
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
                    decoration: BoxDecoration(
                        color: fieldBg, borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 16),

                  Text('Account type',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      (AccountType.asset, 'Asset'),
                      (AccountType.liability, 'Liability'),
                      (AccountType.equity, 'Equity'),
                    ].map((o) {
                      final isSelected = o.$1 == type;
                      return GestureDetector(
                        onTap: () => setInner(() => type = o.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.royalBlue
                                : fieldBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(o.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? Colors.white : textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Text('Liquidity',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      (Liquidity.instant, 'Instant'),
                      (Liquidity.days, 'Days'),
                      (Liquidity.locked, 'Locked'),
                    ].map((o) {
                      final isSelected = o.$1 == liquidity;
                      return GestureDetector(
                        onTap: () => setInner(() => liquidity = o.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.royalBlue : fieldBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(o.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? Colors.white : textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: TextStyle(color: textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: nameCtrl.text.trim().isEmpty
                            ? null
                            : () {
                                final account = Account(
                                  id: const Uuid().v4(),
                                  name: nameCtrl.text.trim(),
                                  type: type,
                                  currency: 'KES',
                                  liquidity: liquidity,
                                  isActive: true,
                                  createdAt: DateTime.now(),
                                );
                                Navigator.pop(ctx);
                                // Persist via callback
                                widget.onCreateAccount(account);
                                // Add to local list and auto-select
                                setState(() {
                                  _newAccounts.add(account);
                                  _accountId = account.id;
                                });
                              },
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.royalBlue,
                            foregroundColor: Colors.white),
                        child: const Text('Create & select'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(context);
    final rateBp = _rateCtrl.text.trim().isNotEmpty
        ? ((double.tryParse(_rateCtrl.text) ?? 0) * 100).round()
        : null;
    widget.onSave(Holding(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      institution: _institutionCtrl.text.trim(),
      accountId: _accountId!,
      currency: 'KES',
      liquidity: _liquidity,
      isActive: widget.existing?.isActive ?? true,
      currentPriceMinor: widget.existing?.currentPriceMinor,
      annualRateBp: rateBp,
      compoundingFreq: _showRateFields ? _compoundingFreq : CompoundingFreq.none,
      maturityDate: _showRateFields ? _maturityDate : null,
      lots: widget.existing?.lots ?? [],
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    ));
  }

  String _fmtDate(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));
}

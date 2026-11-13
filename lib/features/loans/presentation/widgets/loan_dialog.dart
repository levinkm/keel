import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:uuid/uuid.dart';

void showLoanDialog({
  required BuildContext context,
  required Loan? existing,
  required ValueChanged<Loan> onSave,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => _LoanDialog(
      existing: existing,
      onSave: (loan) {
        Navigator.of(dialogContext).pop();
        onSave(loan);
      },
    ),
  );
}

class _LoanDialog extends StatefulWidget {
  final Loan? existing;
  final ValueChanged<Loan> onSave;
  const _LoanDialog({required this.existing, required this.onSave});

  @override
  State<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<_LoanDialog> {
  late TextEditingController _counterpartyCtrl;
  late TextEditingController _principalCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _termCtrl;
  late LoanDirection _direction;
  late InterestMethod _method;
  late RatePeriod _ratePeriod;
  late bool _salaryDeducted;
  late DateTime _disbursementDate;
  late DateTime _firstDueDate;

  // Per-field error messages — set on save attempt
  String? _counterpartyError;
  String? _principalError;
  String? _rateError;
  String? _termError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _counterpartyCtrl = TextEditingController(text: e?.counterparty ?? '');
    _counterpartyCtrl.addListener(() => setState(() { _counterpartyError = null; }));
    _principalCtrl = TextEditingController(
        text: e != null ? (e.principalMinor / 100).toStringAsFixed(0) : '');
    _principalCtrl.addListener(() => setState(() { _principalError = null; }));
    _rateCtrl = TextEditingController(
        text: e != null ? (e.annualRateBp / 100).toStringAsFixed(1) : '');
    _rateCtrl.addListener(() => setState(() { _rateError = null; }));
    _termCtrl = TextEditingController(
        text: e != null ? '${e.termMonths}' : '');
    _termCtrl.addListener(() => setState(() { _termError = null; }));
    _direction = e?.direction ?? LoanDirection.borrowed;
    _method = e?.interestMethod ?? InterestMethod.reducingBalance;
    _ratePeriod = e?.ratePeriod ?? RatePeriod.annual;
    _salaryDeducted = e?.isSalaryDeducted ?? false;
    _disbursementDate = e?.disbursementDate ?? DateTime.now();
    _firstDueDate = e?.firstDueDate ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  }

  @override
  void dispose() {
    _counterpartyCtrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  /// Validates all fields, populates error strings, returns true if valid.
  bool _validate() {
    bool ok = true;
    setState(() {
      _counterpartyError = _counterpartyCtrl.text.trim().isEmpty
          ? 'Counterparty name is required'
          : null;
      final principal = double.tryParse(_principalCtrl.text.trim());
      _principalError = principal == null
          ? 'Enter a valid number'
          : principal <= 0
              ? 'Principal must be greater than zero'
              : null;
      final rate = double.tryParse(_rateCtrl.text.trim());
      _rateError = rate == null
          ? 'Enter a valid rate'
          : rate < 0
              ? 'Rate cannot be negative'
              : null;
      final term = int.tryParse(_termCtrl.text.trim());
      _termError = term == null
          ? 'Enter a whole number of months'
          : term <= 0
              ? 'Term must be at least 1 month'
              : null;
      _dateError = !_firstDueDate.isAfter(_disbursementDate)
          ? 'First due date must be after disbursement date'
          : null;
      ok = _counterpartyError == null &&
          _principalError == null &&
          _rateError == null &&
          _termError == null &&
          _dateError == null;
    });
    return ok;
  }

  int get _computedInstalment {
    final p = ((double.tryParse(_principalCtrl.text) ?? 0) * 100).round();
    final n = int.tryParse(_termCtrl.text) ?? 1;
    final rateBp = ((double.tryParse(_rateCtrl.text) ?? 0) * 100).round();
    // Build a temporary loan to reuse monthlyRate logic
    final tempLoan = Loan(
      id: '', direction: _direction, counterparty: '',
      principalMinor: p, currency: 'KES',
      interestMethod: _method, annualRateBp: rateBp, ratePeriod: _ratePeriod,
      termMonths: n, disbursementDate: _disbursementDate,
      firstDueDate: _firstDueDate, instalmentMinor: 0,
      isSalaryDeducted: false, status: LoanStatus.active,
      createdAt: DateTime.now(),
    );
    final r = tempLoan.monthlyRate;
    if (_method == InterestMethod.fixedFee || r == 0) return p ~/ n;
    if (_method == InterestMethod.flatRate) {
      final totalInterest = (p * r * n).round();
      return ((p + totalInterest) / n).round();
    }
    // Reducing balance
    double pow = 1;
    for (int i = 0; i < n; i++) { pow *= (1 + r); }
    return (p * r * pow / (pow - 1)).round();
  }

  bool get _canPreview =>
      (double.tryParse(_principalCtrl.text) ?? 0) > 0 &&
      (int.tryParse(_termCtrl.text) ?? 0) > 0;

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
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Add loan' : 'Edit loan',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 24),

              // Direction
              _Label('Direction', textSecondary),
              const SizedBox(height: 6),
              _Segmented<LoanDirection>(
                value: _direction,
                options: const [
                  (LoanDirection.borrowed, 'Borrowed (I owe)'),
                  (LoanDirection.lent, 'Lent (owed to me)'),
                ],
                onChanged: (v) => setState(() => _direction = v),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Counterparty
              _Label('Counterparty', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _counterpartyCtrl,
                placeholder: _direction == LoanDirection.borrowed
                    ? 'e.g. KCB Bank, SACCO'
                    : 'e.g. John Doe',
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(8),
                  border: _counterpartyError != null
                      ? Border.all(color: AppColors.error, width: 1)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              if (_counterpartyError != null) _ErrorText(_counterpartyError!),
              const SizedBox(height: 16),

              // Principal + Rate + Term
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Principal (KES)', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _principalCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0',
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                          decoration: BoxDecoration(
                            color: elevated,
                            borderRadius: BorderRadius.circular(8),
                            border: _principalError != null
                                ? Border.all(color: AppColors.error, width: 1)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        if (_principalError != null) _ErrorText(_principalError!),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label(
                          _ratePeriod == RatePeriod.monthly
                              ? 'Monthly rate (%)'
                              : 'Annual rate (%)',
                          textSecondary,
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _rateCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0.0',
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                          decoration: BoxDecoration(
                            color: elevated,
                            borderRadius: BorderRadius.circular(8),
                            border: _rateError != null
                                ? Border.all(color: AppColors.error, width: 1)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        if (_rateError != null) _ErrorText(_rateError!),
                        const SizedBox(height: 6),
                        // Rate period toggle inline under the rate field
                        _Segmented<RatePeriod>(
                          value: _ratePeriod,
                          options: const [
                            (RatePeriod.annual, 'Annual'),
                            (RatePeriod.monthly, 'Monthly'),
                          ],
                          onChanged: (v) => setState(() => _ratePeriod = v),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Term (months)', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _termCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '12',
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                          decoration: BoxDecoration(
                            color: elevated,
                            borderRadius: BorderRadius.circular(8),
                            border: _termError != null
                                ? Border.all(color: AppColors.error, width: 1)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        if (_termError != null) _ErrorText(_termError!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interest method
              _Label('Interest method', textSecondary),
              const SizedBox(height: 6),
              _Segmented<InterestMethod>(
                value: _method,
                options: const [
                  (InterestMethod.reducingBalance, 'Reducing balance'),
                  (InterestMethod.flatRate, 'Flat rate'),
                  (InterestMethod.fixedFee, 'Fixed fee'),
                ],
                onChanged: (v) => setState(() => _method = v),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Disbursement date', textSecondary),
                        const SizedBox(height: 6),
                        _DatePicker(
                          value: _disbursementDate,
                          isDark: isDark,
                          onChanged: (d) => setState(() {
                            _disbursementDate = d;
                            _dateError = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('First due date', textSecondary),
                        const SizedBox(height: 6),
                        _DatePicker(
                          value: _firstDueDate,
                          isDark: isDark,
                          onChanged: (d) => setState(() {
                            _firstDueDate = d;
                            _dateError = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 4),
                _ErrorText(_dateError!),
              ],
              const SizedBox(height: 16),

              // Salary deducted
              GestureDetector(
                onTap: () => setState(() => _salaryDeducted = !_salaryDeducted),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _salaryDeducted ? AppColors.royalBlue : Colors.transparent,
                        border: Border.all(
                          color: _salaryDeducted ? AppColors.royalBlue : AppColors.slateBlue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _salaryDeducted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text('Salary deducted',
                        style: TextStyle(fontSize: 13, color: textPrimary)),
                  ],
                ),
              ),

              // Computed instalment preview
              if (_canPreview) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined,
                          size: 14, color: AppColors.royalBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Computed instalment: KES ${_fmtMinor(_computedInstalment)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.royalBlue),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

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
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _save,
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
    if (!_validate()) return;
    final principal = ((double.tryParse(_principalCtrl.text) ?? 0) * 100).round();
    final rateBp = ((double.tryParse(_rateCtrl.text) ?? 0) * 100).round();
    final term = int.tryParse(_termCtrl.text) ?? 1;
    widget.onSave(Loan(
      id: widget.existing?.id ?? const Uuid().v4(),
      direction: _direction,
      counterparty: _counterpartyCtrl.text.trim(),
      principalMinor: principal,
      currency: 'KES',
      interestMethod: _method,
      annualRateBp: rateBp,
      ratePeriod: _ratePeriod,
      termMonths: term,
      disbursementDate: _disbursementDate,
      firstDueDate: _firstDueDate,
      instalmentMinor: _computedInstalment,
      isSalaryDeducted: _salaryDeducted,
      status: widget.existing?.status ?? LoanStatus.active,
      accountId: widget.existing?.accountId,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    ));
  }

  String _fmtMinor(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 11, color: AppColors.error)),
      );
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 12, color: color));
}

class _Segmented<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool isDark;
  const _Segmented(
      {required this.value,
      required this.options,
      required this.onChanged,
      required this.isDark});

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _DatePicker extends StatelessWidget {
  final DateTime value;
  final bool isDark;
  final ValueChanged<DateTime> onChanged;
  const _DatePicker(
      {required this.value, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: elevated, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${value.day} ${months[value.month]} ${value.year}',
                style: TextStyle(fontSize: 14, color: textPrimary),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 14,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
          ],
        ),
      ),
    );
  }
}

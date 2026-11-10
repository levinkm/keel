import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/contacts/domain/repositories/contact_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/projects/domain/entities/project.dart';

void showEditEntryDialog({
  required BuildContext context,
  required JournalEntry entry,
  required List<Account> accounts,
  required List<Project> projects,
  required List<Contact> contacts,
  required String? currentProjectId,
  required String? currentContactId,
  required ValueChanged<JournalEntry> onSave,
  required void Function({
    required String feeAccountId,
    required String paidFromAccountId,
    required int amountMinor,
    required String memo,
  }) onAddCost,
  required ValueChanged<String?> onRetag,
  required ValueChanged<String?> onRetagContact,
}) {
  showDialog(
    context: context,
    builder: (_) => _EditEntryDialog(
      entry: entry,
      accounts: accounts,
      projects: projects,
      contacts: contacts,
      currentProjectId: currentProjectId,
      currentContactId: currentContactId,
      onSave: onSave,
      onAddCost: onAddCost,
      onRetag: onRetag,
      onRetagContact: onRetagContact,
    ),
  );
}

class _EditEntryDialog extends StatefulWidget {
  final JournalEntry entry;
  final List<Account> accounts;
  final List<Project> projects;
  final List<Contact> contacts;
  final String? currentProjectId;
  final String? currentContactId;
  final ValueChanged<JournalEntry> onSave;
  final void Function({
    required String feeAccountId,
    required String paidFromAccountId,
    required int amountMinor,
    required String memo,
  }) onAddCost;
  final ValueChanged<String?> onRetag;
  final ValueChanged<String?> onRetagContact;

  const _EditEntryDialog({
    required this.entry,
    required this.accounts,
    required this.projects,
    required this.contacts,
    required this.currentProjectId,
    required this.currentContactId,
    required this.onSave,
    required this.onAddCost,
    required this.onRetag,
    required this.onRetagContact,
  });

  @override
  State<_EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<_EditEntryDialog> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _payeeCtrl;
  late final TextEditingController _refCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  final _tagCtrl = TextEditingController();
  late List<String> _tags;
  late DateTime _date;
  String? _projectId;
  String? _contactId;

  // Transaction cost fields
  bool _showCostForm = false;
  final _costAmountCtrl = TextEditingController();
  final _costMemoCtrl = TextEditingController();
  String? _feeAccountId;
  String? _paidFromAccountId;

  List<Account> get _expenseAccounts =>
      widget.accounts.where((a) => a.type == AccountType.expense).toList();
  List<Account> get _assetAccounts =>
      widget.accounts.where((a) => a.type == AccountType.asset).toList();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _descCtrl = TextEditingController(text: e.description);
    _payeeCtrl = TextEditingController(text: e.payee ?? '');
    _refCtrl = TextEditingController(text: e.reference ?? '');
    _locationCtrl = TextEditingController(text: e.location ?? '');
    _notesCtrl = TextEditingController(text: e.notes ?? '');
    _tags = List.of(e.tags);
    _date = e.date;
    _projectId = widget.currentProjectId;
    _contactId = widget.currentContactId;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _payeeCtrl.dispose();
    _refCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _tagCtrl.dispose();
    _costAmountCtrl.dispose();
    _costMemoCtrl.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tags = raw
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty && !_tags.contains(t))
        .toList();
    if (tags.isEmpty) return;
    setState(() { _tags.addAll(tags); _tagCtrl.clear(); });
  }

  void _save() {
    widget.onSave(JournalEntry(
      id: widget.entry.id,
      date: _date,
      description: _descCtrl.text.trim(),
      reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      payee: _payeeCtrl.text.trim().isEmpty ? null : _payeeCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      period: widget.entry.period,
      isLocked: widget.entry.isLocked,
      lines: widget.entry.lines,
      attachments: widget.entry.attachments,
      createdAt: widget.entry.createdAt,
      tags: List.of(_tags),
    ));
    // Retag project if changed
    if (_projectId != widget.currentProjectId) {
      widget.onRetag(_projectId);
    }
    if (_contactId != widget.currentContactId) {
      widget.onRetagContact(_contactId);
    }
    Navigator.of(context).pop();
  }

  void _submitCost() {
    final amount = ((double.tryParse(
                _costAmountCtrl.text.replaceAll(',', '')) ??
            0) *
        100).round();
    if (amount <= 0) return;
    // If accounts not selected, use first available as fallback
    final feeId = _feeAccountId ?? _expenseAccounts.firstOrNull?.id;
    final fromId = _paidFromAccountId ?? _assetAccounts.firstOrNull?.id;
    if (feeId == null || fromId == null) return;
    widget.onAddCost(
      feeAccountId: feeId,
      paidFromAccountId: fromId,
      amountMinor: amount,
      memo: _costMemoCtrl.text.trim().isEmpty
          ? 'Transaction fee'
          : _costMemoCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fieldBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Dialog(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text('Edit entry',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Icon(CupertinoIcons.xmark,
                        size: 16, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Editing metadata only. To correct amounts, use Reverse.',
                style: TextStyle(fontSize: 11, color: textTertiary),
              ),
              const SizedBox(height: 20),

              // Description
              _Label('Description', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _descCtrl,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 14),

              // Date + Payee
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Date', textSecondary),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                                color: fieldBg,
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 14, color: textTertiary),
                                const SizedBox(width: 8),
                                Text(_fmtDate(_date),
                                    style: TextStyle(
                                        fontSize: 13, color: textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Payee', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _payeeCtrl,
                          placeholder: 'Who was paid?',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
                          decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reference + Location
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Reference / Receipt no.', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _refCtrl,
                          placeholder: 'e.g. INV-001',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
                          decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Location', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _locationCtrl,
                          placeholder: 'e.g. Nairobi CBD',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
                          decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Notes
              _Label('Notes', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _notesCtrl,
                placeholder: 'Any additional details…',
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 13, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 14),

              // Tags
              _Label('Tags', textSecondary),
              const SizedBox(height: 6),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags
                      .map((t) => GestureDetector(
                            onTap: () => setState(() => _tags.remove(t)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.royalBlue,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.close,
                                      size: 11, color: AppColors.royalBlue),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
              ],
              CupertinoTextField(
                controller: _tagCtrl,
                placeholder: 'Add tags — press Enter',
                onSubmitted: _addTag,
                style: TextStyle(fontSize: 13, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 13, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 14),

              // Project retag
              if (widget.projects.isNotEmpty) ...[
                _Label('Project', textSecondary),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _projectId,
                  hint: Text('None',
                      style: TextStyle(fontSize: 13, color: textTertiary)),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('None',
                          style: TextStyle(
                              fontSize: 13, color: textSecondary)),
                    ),
                    ...widget.projects.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Row(
                            children: [
                              Icon(
                                p.isCapital
                                    ? Icons.construction_outlined
                                    : Icons.agriculture_outlined,
                                size: 13,
                                color: AppColors.royalBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(p.name,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _projectId = v),
                ),
                const SizedBox(height: 14),
              ],

              // Contact
              if (widget.contacts.isNotEmpty) ...[
                _Label('Contact', textSecondary),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _contactId,
                  hint: Text('None',
                      style: TextStyle(fontSize: 13, color: textTertiary)),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('None',
                          style: TextStyle(
                              fontSize: 13, color: textSecondary)),
                    ),
                    ...widget.contacts.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: AppColors.royalBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(c.initials,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(c.name,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _contactId = v),
                ),
                const SizedBox(height: 14),
              ],

              // Transaction cost section
              Divider(color: divider),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _showCostForm = !_showCostForm),
                child: Row(
                  children: [
                    Icon(
                      _showCostForm
                          ? Icons.expand_less
                          : Icons.add_circle_outline,
                      size: 16,
                      color: AppColors.royalBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add transaction cost (M-Pesa fee, bank charge…)',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.royalBlue,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (_showCostForm) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Fee account', textSecondary),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _feeAccountId,
                            hint: Text('e.g. Bank Charges',
                                style: TextStyle(
                                    fontSize: 12, color: textTertiary)),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _expenseAccounts
                                .map((a) => DropdownMenuItem(
                                      value: a.id,
                                      child: Text(a.name,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _feeAccountId = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Paid from', textSecondary),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _paidFromAccountId,
                            hint: Text('Asset account',
                                style: TextStyle(
                                    fontSize: 12, color: textTertiary)),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _assetAccounts
                                .map((a) => DropdownMenuItem(
                                      value: a.id,
                                      child: Text(a.name,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _paidFromAccountId = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Amount (KES)', textSecondary),
                          const SizedBox(height: 6),
                          CupertinoTextField(
                            controller: _costAmountCtrl,
                            placeholder: '0',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,.]'))
                            ],
                            style:
                                TextStyle(fontSize: 13, color: textPrimary),
                            placeholderStyle: TextStyle(
                                fontSize: 13, color: textTertiary),
                            decoration: BoxDecoration(
                                color: fieldBg,
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Memo', textSecondary),
                          const SizedBox(height: 6),
                          CupertinoTextField(
                            controller: _costMemoCtrl,
                            placeholder: 'e.g. M-Pesa fee',
                            style:
                                TextStyle(fontSize: 13, color: textPrimary),
                            placeholderStyle: TextStyle(
                                fontSize: 13, color: textTertiary),
                            decoration: BoxDecoration(
                                color: fieldBg,
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitCost,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Add cost & close'),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Actions
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
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _save,
                    child: const Text('Save changes',
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

  String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));
}

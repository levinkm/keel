import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/contacts/domain/repositories/contact_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/presentation/bloc/ledger_cubit.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/domain/repositories/project_repository.dart';
import 'package:uuid/uuid.dart';

enum _EntryType { expense, income, transfer }

void showQuickAddDialog(
    BuildContext context,
    List<Account> accounts,
    LedgerCubit cubit, {
  List<Project> projects = const [],
  List<Contact> contacts = const [],
  ProjectRepository? projectRepository,
  ContactRepository? contactRepository,
  AccountsRepository? accountsRepository,
}) {
  showDialog(
    context: context,
    builder: (_) => _QuickAddDialog(
      accounts: accounts,
      cubit: cubit,
      projects: projects,
      contacts: contacts,
      projectRepository: projectRepository,
      contactRepository: contactRepository,
      accountsRepository: accountsRepository,
    ),
  );
}

class _QuickAddDialog extends StatefulWidget {
  final List<Account> accounts;
  final LedgerCubit cubit;
  final List<Project> projects;
  final List<Contact> contacts;
  final ProjectRepository? projectRepository;
  final ContactRepository? contactRepository;
  final AccountsRepository? accountsRepository;

  const _QuickAddDialog({
    required this.accounts,
    required this.cubit,
    this.projects = const [],
    this.contacts = const [],
    this.projectRepository,
    this.contactRepository,
    this.accountsRepository,
  });

  @override
  State<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<_QuickAddDialog> {
  late List<Account> _accounts;
  _EntryType _type = _EntryType.expense;
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  String? _projectId;
  String? _contactId;
  String? _fromAccountId;
  String? _toAccountId;
  final DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _accounts = List.of(widget.accounts);
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  List<Account> get _assetAccounts =>
      _accounts.where((a) => a.type == AccountType.asset).toList();
  List<Account> get _expenseAccounts =>
      _accounts.where((a) => a.type == AccountType.expense).toList();
  List<Account> get _incomeAccounts =>
      _accounts.where((a) => a.type == AccountType.income).toList();

  List<Account> get _fromAccounts => _assetAccounts;
  List<Account> get _toAccounts => switch (_type) {
        _EntryType.expense =>
          _expenseAccounts.isNotEmpty ? _expenseAccounts : _assetAccounts,
        _EntryType.income =>
          _incomeAccounts.isNotEmpty ? _incomeAccounts : _assetAccounts,
        _EntryType.transfer => _assetAccounts,
      };

  AccountType get _toAccountType => switch (_type) {
        _EntryType.expense => AccountType.expense,
        _EntryType.income => AccountType.income,
        _EntryType.transfer => AccountType.asset,
      };

  bool get _valid {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    return _descController.text.trim().isNotEmpty &&
        amount > 0 &&
        _fromAccountId != null &&
        _toAccountId != null;
  }

  int get _amountMinor =>
      ((double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0) * 100)
          .round();

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final period = '${_date.year}-${_date.month.toString().padLeft(2, '0')}';
    final entryId = const Uuid().v4();

    final (debitId, creditId) = switch (_type) {
      _EntryType.expense => (_toAccountId!, _fromAccountId!),
      _EntryType.income => (_fromAccountId!, _toAccountId!),
      _EntryType.transfer => (_toAccountId!, _fromAccountId!),
    };

    final entry = JournalEntry(
      id: entryId,
      date: _date,
      description: _descController.text.trim(),
      period: period,
      isLocked: false,
      createdAt: now,
      tags: List.of(_tags),
      lines: [
        JournalLine(
          id: const Uuid().v4(),
          entryId: entryId,
          accountId: debitId,
          amountMinor: _amountMinor,
          currency: 'KES',
          side: JournalSide.debit,
        ),
        JournalLine(
          id: const Uuid().v4(),
          entryId: entryId,
          accountId: creditId,
          amountMinor: _amountMinor,
          currency: 'KES',
          side: JournalSide.credit,
        ),
      ],
    );

    await widget.cubit.postEntry(entry);
    if (_projectId != null && widget.projectRepository != null) {
      await widget.projectRepository!.tagEntry(_projectId!, entryId);
    }
    if (_contactId != null && widget.contactRepository != null) {
      await widget.contactRepository!.tagEntry(_contactId!, entryId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _addTag(String raw) {
    final tags = raw
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty && !_tags.contains(t))
        .toList();
    if (tags.isEmpty) return;
    setState(() {
      _tags.addAll(tags);
      _tagController.clear();
    });
  }

  Future<void> _createAccount(AccountType type) async {
    if (widget.accountsRepository == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (_) => _InlineCreateAccountDialog(
        isDark: isDark,
        defaultType: type,
        onSave: (account) async {
          await widget.accountsRepository!.createAccount(account);
          setState(() {
            _accounts.add(account);
            if (type == AccountType.asset) _fromAccountId = account.id;
            if (type == AccountType.expense || type == AccountType.income) {
              _toAccountId = account.id;
            }
          });
        },
      ),
    );
  }

  String get _descHint => switch (_type) {
        _EntryType.expense => 'e.g. Fuel — Rav4',
        _EntryType.income => 'e.g. Salary — October',
        _EntryType.transfer => 'e.g. Move to Etica',
      };

  String get _fromLabel => switch (_type) {
        _EntryType.expense => 'Paid from',
        _EntryType.income => 'Deposit account',
        _EntryType.transfer => 'From',
      };

  String get _toLabel => switch (_type) {
        _EntryType.expense => 'Expense account',
        _EntryType.income => 'Income account',
        _EntryType.transfer => 'To',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fieldBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    return Dialog(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + close
              Row(
                children: [
                  Text('New entry',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Icon(CupertinoIcons.xmark, size: 16, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type picker
              _SegmentedPicker(
                value: _type,
                options: const [
                  (_EntryType.expense, 'Expense'),
                  (_EntryType.income, 'Income'),
                  (_EntryType.transfer, 'Transfer'),
                ],
                onChanged: (v) => setState(() {
                  _type = v;
                  _fromAccountId = null;
                  _toAccountId = null;
                }),
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Description
              _FieldLabel('Description', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _descController,
                autofocus: true,
                placeholder: _descHint,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Amount
              _FieldLabel('Amount (KES)', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _amountController,
                placeholder: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Tags
              _FieldLabel('Tags (optional)', textSecondary),
              const SizedBox(height: 6),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags
                      .map((tag) => GestureDetector(
                            onTap: () => setState(() => _tags.remove(tag)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.royalBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(tag,
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
                controller: _tagController,
                placeholder: 'e.g. tyres, wiring — press Enter to add',
                onSubmitted: _addTag,
                style: TextStyle(fontSize: 13, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 13, color: textSecondary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Project (optional)
              if (widget.projects.isNotEmpty) ...[
                _FieldLabel('Tag to project (optional)', textSecondary),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _projectId,
                  hint: Text('None',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
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
                          style:
                              TextStyle(fontSize: 13, color: textSecondary)),
                    ),
                    ...widget.projects
                        .where((p) =>
                            p.status == ProjectStatus.active ||
                            p.status == ProjectStatus.planning)
                        .map((p) => DropdownMenuItem(
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
                const SizedBox(height: 16),
              ],

              // Contact (optional)
              if (widget.contacts.isNotEmpty) ...[
                _FieldLabel('Contact (optional)', textSecondary),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _contactId,
                  hint: Text('None',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
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
                const SizedBox(height: 16),
              ],

              // Account pickers
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(_fromLabel, textSecondary),
                        const SizedBox(height: 6),
                        _AccountPicker(
                          value: _fromAccountId,
                          accounts: _fromAccounts,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _fromAccountId = v),
                          onCreateAccount:
                              widget.accountsRepository != null
                                  ? () => _createAccount(AccountType.asset)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Icon(Icons.arrow_forward,
                        size: 16, color: textSecondary),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(_toLabel, textSecondary),
                        const SizedBox(height: 6),
                        _AccountPicker(
                          value: _toAccountId,
                          accounts: _toAccounts,
                          isDark: isDark,
                          onChanged: (v) => setState(() => _toAccountId = v),
                          onCreateAccount:
                              widget.accountsRepository != null
                                  ? () => _createAccount(_toAccountType)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    color: _valid ? AppColors.royalBlue : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid && !_saving ? _save : null,
                    child: _saving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text('Post entry',
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
}

// ── Inline account creation dialog ────────────────────────────────────────────

class _InlineCreateAccountDialog extends StatefulWidget {
  final bool isDark;
  final AccountType defaultType;
  final ValueChanged<Account> onSave;

  const _InlineCreateAccountDialog({
    required this.isDark,
    required this.defaultType,
    required this.onSave,
  });

  @override
  State<_InlineCreateAccountDialog> createState() =>
      _InlineCreateAccountDialogState();
}

class _InlineCreateAccountDialogState
    extends State<_InlineCreateAccountDialog> {
  final _nameCtrl = TextEditingController();
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fieldBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final valid = _nameCtrl.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New account',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text('This account will be saved to your chart of accounts.',
                  style: TextStyle(fontSize: 12, color: textTertiary)),
              const SizedBox(height: 20),

              Text('Name',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _nameCtrl,
                autofocus: true,
                placeholder: _type == AccountType.asset
                    ? 'e.g. M-Pesa, KCB Current'
                    : _type == AccountType.expense
                        ? 'e.g. Car Repairs, Fuel'
                        : 'e.g. Salary',
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              Text('Type',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AccountType.asset,
                  AccountType.expense,
                  AccountType.income,
                ].map((t) {
                  final isSelected = t == _type;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
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
                      child: Text(
                        t.name[0].toUpperCase() + t.name.substring(1),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? Colors.white : textSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style:
                            TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    color: valid
                        ? AppColors.royalBlue
                        : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: valid
                        ? () {
                            widget.onSave(Account(
                              id: const Uuid().v4(),
                              name: _nameCtrl.text.trim(),
                              type: _type,
                              currency: 'KES',
                              liquidity: Liquidity.instant,
                              isActive: true,
                              createdAt: DateTime.now(),
                            ));
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: Text('Create',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: valid
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
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _AccountPicker extends StatelessWidget {
  final String? value;
  final List<Account> accounts;
  final bool isDark;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onCreateAccount;

  const _AccountPicker({
    required this.value,
    required this.accounts,
    required this.isDark,
    required this.onChanged,
    this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    if (accounts.isEmpty) {
      return GestureDetector(
        onTap: onCreateAccount,
        child: Row(
          children: [
            Icon(Icons.add_circle_outline,
                size: 14, color: AppColors.royalBlue),
            const SizedBox(width: 6),
            Text('Create account',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.royalBlue,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text('Select…',
              style: TextStyle(fontSize: 13, color: textTertiary)),
          decoration: const InputDecoration(isDense: true),
          items: accounts
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
        if (onCreateAccount != null) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onCreateAccount,
            child: Text('＋ New account',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.royalBlue,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }
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
    return Row(
      children: options.map((o) {
        final isSelected = o.$1 == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.royalBlue
                    : (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                o.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:uuid/uuid.dart';

void showProjectDialog({
  required BuildContext context,
  required List<Account> accounts,
  List<Asset> assets = const [],
  String? preselectedAssetId,
  Project? existing,
  required ValueChanged<Project> onSave,
}) {
  showDialog(
    context: context,
    builder: (_) => _ProjectDialog(
      accounts: accounts,
      assets: assets,
      preselectedAssetId: preselectedAssetId,
      existing: existing,
      onSave: onSave,
    ),
  );
}

class _ProjectDialog extends StatefulWidget {
  final List<Account> accounts;
  final List<Asset> assets;
  final String? preselectedAssetId;
  final Project? existing;
  final ValueChanged<Project> onSave;

  const _ProjectDialog({
    required this.accounts,
    required this.assets,
    this.preselectedAssetId,
    this.existing,
    required this.onSave,
  });

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _revenueTargetCtrl;
  late ProjectType _type;
  late ProjectStatus _status;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _fundingAccountId;
  String? _assetAccountId;
  String? _linkedAssetId;
  final List<String> _tags = [];
  final _tagCtrl = TextEditingController();

  bool get _isEdit => widget.existing != null;

  List<Account> get _assetAccounts =>
      widget.accounts.where((a) => a.type == AccountType.asset).toList();

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _budgetCtrl = TextEditingController(
        text: p != null ? (p.budgetMinor / 100).toStringAsFixed(0) : '');
    _revenueTargetCtrl = TextEditingController(
        text: p?.revenueTargetMinor != null
            ? (p!.revenueTargetMinor! / 100).toStringAsFixed(0)
            : '');
    _type = p?.type ?? ProjectType.revenue;
    _status = p?.status ?? ProjectStatus.planning;
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate;
    _fundingAccountId = p?.fundingAccountId;
    _assetAccountId = p?.assetAccountId;
    _linkedAssetId = p?.assetId ?? widget.preselectedAssetId;
    if (p != null) _tags.addAll(p.tags);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _revenueTargetCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      (double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0) > 0;

  void _save() {
    if (!_valid) return;
    final budget =
        ((double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0) * 100)
            .round();
    final revenueTarget = _revenueTargetCtrl.text.trim().isEmpty
        ? null
        : ((double.tryParse(_revenueTargetCtrl.text.replaceAll(',', '')) ?? 0) *
                100)
            .round();

    widget.onSave(Project(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      type: _type,
      status: _status,
      budgetMinor: budget,
      revenueTargetMinor: _type == ProjectType.revenue ? revenueTarget : null,
      currency: 'KES',
      fundingAccountId: _fundingAccountId,
      assetAccountId: _type == ProjectType.capital ? _assetAccountId : null,
      assetId: _linkedAssetId,
      startDate: _startDate,
      endDate: _endDate,
      tags: List.of(_tags),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    ));
    Navigator.of(context).pop();
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
      _tagCtrl.clear();
    });
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
                  Text(_isEdit ? 'Edit project' : 'New project',
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
              const SizedBox(height: 24),

              // Type selector
              _Label('Project type', textSecondary),
              const SizedBox(height: 8),
              Row(
                children: ProjectType.values.map((t) {
                  final isSelected = t == _type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.royalBlue.withValues(alpha: 0.1)
                              : fieldBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  t == ProjectType.capital
                                      ? Icons.construction_outlined
                                      : Icons.agriculture_outlined,
                                  size: 14,
                                  color: isSelected
                                      ? AppColors.royalBlue
                                      : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(t.label,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.royalBlue
                                            : textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(t.description,
                                style: TextStyle(
                                    fontSize: 10, color: textTertiary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name
              _Label('Project name', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                placeholder: _type == ProjectType.capital
                    ? 'e.g. Car Restoration 2025'
                    : 'e.g. Maize Season 2025',
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Description
              _Label('Description (optional)', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _descCtrl,
                placeholder: 'What is this project about?',
                maxLines: 2,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Budget + revenue target
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Total budget (KES)', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _budgetCtrl,
                          placeholder: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]'))
                          ],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 14, color: textTertiary),
                          decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                  if (_type == ProjectType.revenue) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Revenue target (KES)', textSecondary),
                          const SizedBox(height: 6),
                          CupertinoTextField(
                            controller: _revenueTargetCtrl,
                            placeholder: '0',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,.]'))
                            ],
                            style:
                                TextStyle(fontSize: 14, color: textPrimary),
                            placeholderStyle:
                                TextStyle(fontSize: 14, color: textTertiary),
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
                ],
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Start date', textSecondary),
                        const SizedBox(height: 6),
                        _DatePicker(
                          value: _startDate,
                          isDark: isDark,
                        onChanged: (d) => setState(() => _startDate = d ?? _startDate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('End date (optional)', textSecondary),
                        const SizedBox(height: 6),
                        _DatePicker(
                          value: _endDate,
                          isDark: isDark,
                          placeholder: 'Open-ended',
                          onChanged: (d) => setState(() => _endDate = d),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Accounts
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Funding account', textSecondary),
                        const SizedBox(height: 6),
                        _AccountDropdown(
                          value: _fundingAccountId,
                          accounts: _assetAccounts,
                          hint: 'Select account',
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _fundingAccountId = v),
                        ),
                      ],
                    ),
                  ),
                  if (_type == ProjectType.capital) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Asset account', textSecondary),
                          const SizedBox(height: 6),
                          _AccountDropdown(
                            value: _assetAccountId,
                            accounts: _assetAccounts,
                            hint: 'Capitalise into',
                            isDark: isDark,
                            onChanged: (v) =>
                                setState(() => _assetAccountId = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Linked asset
              if (widget.assets.isNotEmpty) ...[
                _Label('Linked asset (optional)', textSecondary),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: fieldBg, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _linkedAssetId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                      hint: Text('No linked asset',
                          style: TextStyle(fontSize: 13, color: textTertiary)),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No linked asset',
                              style: TextStyle(fontSize: 13, color: textTertiary)),
                        ),
                        ...widget.assets.map((a) => DropdownMenuItem<String?>(
                              value: a.id,
                              child: Row(
                                children: [
                                  Icon(_assetIcon(a.assetClass), size: 14, color: AppColors.royalBlue),
                                  const SizedBox(width: 8),
                                  Text(a.name, style: TextStyle(fontSize: 13, color: textPrimary)),
                                ],
                              ),
                            )),
                      ],
                      onChanged: (v) => setState(() => _linkedAssetId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Status (edit only)
              if (_isEdit) ...[
                _Label('Status', textSecondary),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ProjectStatus.values.map((s) {
                    final isSelected = s == _status;
                    return GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _statusColor(s).withValues(alpha: 0.15)
                              : fieldBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(s.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? _statusColor(s)
                                    : textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Tags
              _Label('Tags (optional)', textSecondary),
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
                                color: AppColors.royalBlue
                                    .withValues(alpha: 0.12),
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
                controller: _tagCtrl,
                placeholder: 'e.g. car, restoration — press Enter to add',
                onSubmitted: _addTag,
                style: TextStyle(fontSize: 13, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 13, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        style:
                            TextStyle(fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    color: _valid ? AppColors.royalBlue : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid ? _save : null,
                    child: Text(_isEdit ? 'Save changes' : 'Create project',
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

  Color _statusColor(ProjectStatus s) => switch (s) {
        ProjectStatus.planning => AppColors.info,
        ProjectStatus.active => AppColors.success,
        ProjectStatus.onHold => AppColors.warning,
        ProjectStatus.completed => AppColors.royalBlue,
        ProjectStatus.cancelled => AppColors.error,
      };

  IconData _assetIcon(AssetClass c) => switch (c) {
        AssetClass.cashAndBank => Icons.account_balance_outlined,
        AssetClass.investments => Icons.show_chart_outlined,
        AssetClass.vehicle => Icons.directions_car_outlined,
        AssetClass.machinery => Icons.precision_manufacturing_outlined,
        AssetClass.land => Icons.landscape_outlined,
        AssetClass.building => Icons.home_outlined,
        AssetClass.receivable => Icons.receipt_long_outlined,
        AssetClass.other => Icons.category_outlined,
      };
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: color));
}

class _DatePicker extends StatelessWidget {
  final DateTime? value;
  final bool isDark;
  final String? placeholder;
  final ValueChanged<DateTime?> onChanged;

  const _DatePicker({
    required this.value,
    required this.isDark,
    this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fieldBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: fieldBg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: textTertiary),
            const SizedBox(width: 8),
            Text(
              value != null ? _fmt(value!) : (placeholder ?? 'Select date'),
              style: TextStyle(
                  fontSize: 13,
                  color: value != null ? textPrimary : textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

class _AccountDropdown extends StatelessWidget {
  final String? value;
  final List<Account> accounts;
  final String hint;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _AccountDropdown({
    required this.value,
    required this.accounts,
    required this.hint,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text('No asset accounts',
          style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary));
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      decoration: const InputDecoration(isDense: true),
      items: accounts
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Text(a.name, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

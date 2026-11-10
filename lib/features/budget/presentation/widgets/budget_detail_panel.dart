import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/presentation/bloc/budget_cubit.dart';
import 'package:keel/features/budget/presentation/widgets/budget_charts.dart';
import 'package:keel/features/budget/presentation/widgets/budget_line_detail.dart';
import 'package:keel/features/budget/presentation/widgets/envelope_bar.dart';
import 'package:uuid/uuid.dart';

class BudgetDetailPanel extends StatelessWidget {
  final String period;
  final BudgetPlan? plan;
  final Map<String, int> actuals;
  final Map<String, int> prevActuals;
  final List<Account> expenseAccounts;
  final int totalIncomeMinor;
  final List<BudgetPlan> templates;
  final List<BudgetLineSparkline> sparklines;
  final String? selectedLineId;
  final String activeStrategyName;
  final ValueChanged<String?> onSelectLine;
  final ValueChanged<BudgetLine> onUpsertLine;
  final ValueChanged<String> onDeleteLine;
  final Future<void> Function({required BudgetLine line, required int amountMinor, required String description, required Account fromAccount}) onQuickSpend;
  final VoidCallback onApplyRollover;
  final ValueChanged<String> onSaveAsTemplate;
  final ValueChanged<Map<String, double>> onApplyStrategy;
  final VoidCallback onEditStrategy;

  const BudgetDetailPanel({
    super.key,
    required this.period,
    required this.plan,
    required this.actuals,
    required this.prevActuals,
    required this.expenseAccounts,
    required this.totalIncomeMinor,
    required this.templates,
    required this.sparklines,
    required this.selectedLineId,
    required this.activeStrategyName,
    required this.onSelectLine,
    required this.onUpsertLine,
    required this.onDeleteLine,
    required this.onQuickSpend,
    required this.onApplyRollover,
    required this.onSaveAsTemplate,
    required this.onApplyStrategy,
    required this.onEditStrategy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    if (plan == null) return Container(color: bg);

    final lines = plan!.lines;
    final totalPlanned = lines.fold(0, (s, l) => s + l.effectivePlanned);
    final totalActual = lines.fold(0, (s, l) => s + (actuals[l.accountId] ?? 0));
    final allAccounts = expenseAccounts;

    return Container(
      color: bg,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatPeriod(period),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text('${lines.length} lines',
                        style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
                const Spacer(),
                // Strategy chip
                GestureDetector(
                  onTap: onEditStrategy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_outlined,
                            size: 12, color: AppColors.royalBlue),
                        const SizedBox(width: 5),
                        Text(activeStrategyName,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalBlue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: textSecondary, size: 18),
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  onSelected: (v) {
                    if (v == 'rollover') onApplyRollover();
                    if (v == 'template') _showSaveTemplateDialog(context, isDark);
                    if (v == 'strategy') _showStrategyDialog(context, isDark, totalIncomeMinor);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rollover',
                        child: Text('Apply rollover from last month',
                            style: TextStyle(fontSize: 13, color: textPrimary))),
                    PopupMenuItem(value: 'template',
                        child: Text('Save as template',
                            style: TextStyle(fontSize: 13, color: textPrimary))),
                    PopupMenuItem(value: 'strategy',
                        child: Text('Auto-allocate from income',
                            style: TextStyle(fontSize: 13, color: textPrimary))),
                  ],
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showLineDialog(context, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add line'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                // Envelope bar
                if (totalIncomeMinor > 0) ...[
                  EnvelopeBar(
                    totalIncomeMinor: totalIncomeMinor,
                    totalBudgetedMinor: totalPlanned,
                  ),
                  const SizedBox(height: 12),
                ],

                // Budget lines
                if (lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No budget lines yet. Add one to get started.',
                          style: TextStyle(fontSize: 13, color: textTertiary)),
                    ),
                  )
                else
                  ...lines.map((line) {
                    final actual = actuals[line.accountId] ?? 0;
                    final isSelected = line.id == selectedLineId;
                    final sparkline = sparklines.cast<BudgetLineSparkline?>().firstWhere(
                        (s) => s?.lineId == line.id, orElse: () => null);
                    return Column(
                      children: [
                        _BudgetLineRow(
                          line: line,
                          actual: actual,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => onSelectLine(isSelected ? null : line.id),
                          onEdit: () => _showLineDialog(context, line),
                          onDelete: () => onDeleteLine(line.id),
                        ),
                        if (isSelected)
                          BudgetLineDetail(
                            line: line,
                            actual: actual,
                            prevActual: prevActuals[line.accountId] ?? 0,
                            sparkline: sparkline,
                            assetAccounts: allAccounts,
                            onQuickSpend: (amount, desc, fromAccount) => onQuickSpend(
                              line: line,
                              amountMinor: amount,
                              description: desc,
                              fromAccount: fromAccount,
                            ),
                          ),
                      ],
                    );
                  }),

                // Charts
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  BudgetCharts(
                    plan: plan!,
                    actuals: actuals,
                    prevActuals: prevActuals,
                  ),
                ],
              ],
            ),
          ),

          // Summary footer
          if (lines.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  _SummaryChip(
                      label: 'Budgeted',
                      value: _fmt(totalPlanned),
                      color: AppColors.royalBlue,
                      isDark: isDark),
                  const SizedBox(width: 12),
                  _SummaryChip(
                      label: 'Spent',
                      value: _fmt(totalActual),
                      color: totalActual > totalPlanned
                          ? AppColors.error
                          : AppColors.success,
                      isDark: isDark),
                  const SizedBox(width: 12),
                  _SummaryChip(
                      label: totalActual > totalPlanned ? 'Over by' : 'Remaining',
                      value: _fmt((totalPlanned - totalActual).abs()),
                      color: totalActual > totalPlanned
                          ? AppColors.error
                          : AppColors.success,
                      isDark: isDark),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showSaveTemplateDialog(BuildContext context, bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final ctrl = TextEditingController(text: _formatPeriod(period));
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Save as template',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: ctrl,
                    autofocus: true,
                    onChanged: (_) => set(() {}),
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                    decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text('Cancel', style: TextStyle(fontSize: 14, color: textSecondary)),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: ctrl.text.trim().isEmpty ? AppColors.disabledSurface : AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: ctrl.text.trim().isEmpty ? null : () {
                          Navigator.of(dialogContext).pop();
                          onSaveAsTemplate(ctrl.text.trim());
                        },
                        child: const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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

  void _showStrategyDialog(BuildContext context, bool isDark, int incomeMinor) {
    if (expenseAccounts.isEmpty || incomeMinor == 0) return;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final controllers = {for (final a in expenseAccounts) a.id: TextEditingController()};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, set) {
          final total = controllers.values
              .fold(0.0, (s, c) => s + (double.tryParse(c.text) ?? 0));
          return Dialog(
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
                    Text('Auto-allocate from income',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('Income: ${_fmt(incomeMinor)}  •  Allocated: ${total.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: total > 100 ? AppColors.error : textSecondary)),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: expenseAccounts.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text(a.name, style: TextStyle(fontSize: 13, color: textPrimary))),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: CupertinoTextField(
                                    controller: controllers[a.id],
                                    keyboardType: TextInputType.number,
                                    placeholder: '0',
                                    onChanged: (_) => set(() {}),
                                    style: TextStyle(fontSize: 13, color: textPrimary),
                                    placeholderStyle: TextStyle(fontSize: 13, color: textSecondary),
                                    decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    suffix: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text('%', style: TextStyle(fontSize: 13, color: textSecondary)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text('Cancel', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          color: total > 100 ? AppColors.disabledSurface : AppColors.royalBlue,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: total > 100 ? null : () {
                            Navigator.of(dialogContext).pop();
                            final ratios = <String, double>{};
                            for (final a in expenseAccounts) {
                              final pct = double.tryParse(controllers[a.id]?.text ?? '') ?? 0;
                              if (pct > 0) ratios[a.id] = pct;
                            }
                            onApplyStrategy(ratios);
                          },
                          child: const Text('Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLineDialog(BuildContext context, BudgetLine? existing) {
    final cubit = context.read<BudgetCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => _BudgetLineDialog(
        existing: existing,
        expenseAccounts: expenseAccounts,
        planId: plan!.id,
        onCreateAccount: cubit.createExpenseAccount,
        onSave: (line) {
          Navigator.of(dialogContext).pop();
          onUpsertLine(line);
        },
      ),
    );
  }

  String _formatPeriod(String period) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final parts = period.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _BudgetLineRow extends StatelessWidget {
  final BudgetLine line;
  final int actual;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetLineRow({
    required this.line,
    required this.actual,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final selectedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    final ratio = line.plannedMinor == 0
        ? 0.0
        : (actual / line.plannedMinor).clamp(0.0, 1.0);
    final barColor = ratio >= 1.0
        ? AppColors.error
        : ratio >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(line.bucket,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textPrimary)),
                ),
                Text(
                  '${_fmt(actual)} / ${_fmt(line.plannedMinor)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit_outlined, size: 15, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(fontSize: 11, color: barColor),
                ),
                const Spacer(),
                Text(
                  '${_fmt((line.plannedMinor - actual).abs())} ${actual > line.plannedMinor ? 'over' : 'left'}',
                  style: TextStyle(fontSize: 11, color: textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}

class _BudgetLineDialog extends StatefulWidget {
  final BudgetLine? existing;
  final List<Account> expenseAccounts;
  final String planId;
  final Future<Account?> Function(String name) onCreateAccount;
  final ValueChanged<BudgetLine> onSave;

  const _BudgetLineDialog({
    required this.existing,
    required this.expenseAccounts,
    required this.planId,
    required this.onCreateAccount,
    required this.onSave,
  });

  @override
  State<_BudgetLineDialog> createState() => _BudgetLineDialogState();
}

class _BudgetLineDialogState extends State<_BudgetLineDialog> {
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late List<Account> _accounts;
  String? _selectedAccountId;
  bool _creatingAccount = false;

  @override
  void initState() {
    super.initState();
    _accounts = List.of(widget.expenseAccounts);
    final existing = widget.existing;
    _selectedAccountId = existing?.accountId.isEmpty ?? true
        ? null
        : existing?.accountId;
    if (_selectedAccountId != null &&
        !_accounts.any((a) => a.id == _selectedAccountId)) {
      _selectedAccountId = null;
    }
    _categoryController = TextEditingController(text: existing?.bucket ?? '');
    _categoryController.addListener(() => setState(() {}));
    _amountController = TextEditingController(
      text: existing != null ? (existing.plannedMinor / 100).toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

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
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Add budget line' : 'Edit budget line',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 20),

              // Category name
              Text('Category name',
                  style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _categoryController,
                placeholder: 'e.g. Groceries, Rent, Transport',
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Account picker (required)
              Row(
                children: [
                  Text('Expense account',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _creatingAccount ? null : _showNewAccountSheet,
                    child: Text(
                      '+ New account',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.royalBlue,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: surface,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    hint: Text(
                      _accounts.isEmpty
                          ? 'No accounts — create one above'
                          : 'Select account',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                    items: _accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              Text('Planned amount (KES)',
                  style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                placeholder: '0',
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle: TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
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
                    onPressed: _canSave ? _save : null,
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

  bool get _canSave =>
      _categoryController.text.trim().isNotEmpty && _selectedAccountId != null;

  void _showNewAccountSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final nameController = TextEditingController();

    final created = await showDialog<Account>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New expense account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: nameController,
                    placeholder: 'e.g. Food, Transport, Rent',
                    autofocus: true,
                    onChanged: (_) => setInner(() {}),
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    placeholderStyle:
                        TextStyle(fontSize: 14, color: textSecondary),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel',
                            style: TextStyle(
                                fontSize: 14, color: textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        color: nameController.text.trim().isEmpty
                            ? AppColors.disabledSurface
                            : AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: nameController.text.trim().isEmpty
                            ? null
                            : () async {
                                setState(() => _creatingAccount = true);
                                final account = await widget.onCreateAccount(
                                    nameController.text.trim());
                                if (ctx.mounted) Navigator.of(ctx).pop(account);
                              },
                        child: const Text('Create',
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
        ),
      ),
    );

    if (created != null && mounted) {
      setState(() {
        _accounts = [..._accounts, created];
        _selectedAccountId = created.id;
        // Auto-fill category from account name if empty
        if (_categoryController.text.trim().isEmpty) {
          _categoryController.text = created.name;
        }
        _creatingAccount = false;
      });
    } else if (mounted) {
      setState(() => _creatingAccount = false);
    }
  }

  void _save() {
    final category = _categoryController.text.trim();
    if (category.isEmpty || _selectedAccountId == null) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    widget.onSave(BudgetLine(
      id: widget.existing?.id ?? const Uuid().v4(),
      planId: widget.planId,
      accountId: _selectedAccountId!,
      bucket: category,
      plannedMinor: (amount * 100).round(),
      currency: 'KES',
      rolloverMinor: 0,
    ));
  }
}

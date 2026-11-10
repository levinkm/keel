import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:uuid/uuid.dart';

void showCreateAccountDialog(BuildContext context, {Account? existing}) {
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<AccountsCubit>(),
      child: _CreateAccountDialog(existing: existing),
    ),
  );
}

class _CreateAccountDialog extends StatefulWidget {
  final Account? existing;
  const _CreateAccountDialog({this.existing});

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  late final TextEditingController _nameController;
  late AccountType _type;
  late Liquidity _liquidity;
  bool _saving = false;

  bool get _valid => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _nameController.addListener(() => setState(() {}));
    _type = widget.existing?.type ?? AccountType.asset;
    _liquidity = widget.existing?.liquidity ?? Liquidity.instant;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    final account = Account(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      currency: 'KES',
      liquidity: _liquidity,
      isActive: widget.existing?.isActive ?? true,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing != null) {
      await context.read<AccountsCubit>().updateAccount(account);
    } else {
      await context.read<AccountsCubit>().createAccount(account);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Text(
                    widget.existing == null ? 'New account' : 'Edit account',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
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

              // Account name
              _FieldLabel('Account name', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _nameController,
                autofocus: true,
                placeholder: 'e.g. Co-op Bank',
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 14, color: textSecondary),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              // Type
              _FieldLabel('Account type', textSecondary),
              const SizedBox(height: 6),
              _SegmentedRow<AccountType>(
                value: _type,
                options: const [
                  (AccountType.asset, 'Asset'),
                  (AccountType.liability, 'Liability'),
                  (AccountType.equity, 'Equity'),
                  (AccountType.income, 'Income'),
                  (AccountType.expense, 'Expense'),
                ],
                onChanged: (v) => setState(() => _type = v),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Liquidity
              _FieldLabel('Liquidity', textSecondary),
              const SizedBox(height: 6),
              _SegmentedRow<Liquidity>(
                value: _liquidity,
                options: const [
                  (Liquidity.instant, 'Instant'),
                  (Liquidity.days, 'Days'),
                  (Liquidity.locked, 'Locked'),
                ],
                onChanged: (v) => setState(() => _liquidity = v),
                isDark: isDark,
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
                        style: TextStyle(
                            fontSize: 14, color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid && !_saving ? _save : null,
                    child: _saving
                        ? const CupertinoActivityIndicator(
                            color: Colors.white)
                        : const Text('Save',
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
}

// ── Segmented picker ─────────────────────────────────────────────────────────

class _SegmentedRow<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool isDark;

  const _SegmentedRow({
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.royalBlue
                  : (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceSecondary),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              o.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
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
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: color),
      );
}

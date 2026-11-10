import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:uuid/uuid.dart';

class CreateAccountSheet extends StatefulWidget {
  const CreateAccountSheet({super.key});

  @override
  State<CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<CreateAccountSheet> {
  final _nameController = TextEditingController();
  AccountType _type = AccountType.asset;
  Liquidity _liquidity = Liquidity.instant;
  // ignore: prefer_final_fields
  String _currency = 'KES';
  bool _saving = false;

  bool get _valid => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    final account = Account(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      currency: _currency,
      liquidity: _liquidity,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await context.read<AccountsCubit>().createAccount(account);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'New account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Name
          _Label('Account name', textSecondary),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. Co-op Bank'),
          ),
          const SizedBox(height: 16),

          // Type + Liquidity row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Type', textSecondary),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<AccountType>(
                      initialValue: _type,
                      decoration: const InputDecoration(),
                      items: AccountType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(_typeLabel(t),
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Liquidity', textSecondary),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Liquidity>(
                      initialValue: _liquidity,
                      decoration: const InputDecoration(),
                      items: Liquidity.values
                          .map((l) => DropdownMenuItem(
                                value: l,
                                child: Text(_liquidityLabel(l),
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _liquidity = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _valid && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save account'),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AccountType t) => switch (t) {
        AccountType.asset => 'Asset',
        AccountType.liability => 'Liability',
        AccountType.equity => 'Equity',
        AccountType.income => 'Income',
        AccountType.expense => 'Expense',
      };

  String _liquidityLabel(Liquidity l) => switch (l) {
        Liquidity.instant => 'Instant',
        Liquidity.days => 'Days',
        Liquidity.locked => 'Locked',
      };
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: color),
      );
}

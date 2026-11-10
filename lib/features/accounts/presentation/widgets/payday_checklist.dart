import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class PaydayChecklist extends StatefulWidget {
  final List<Account> accounts;
  final Map<String, int> balances;

  const PaydayChecklist({
    super.key,
    required this.accounts,
    required this.balances,
  });

  @override
  State<PaydayChecklist> createState() => _PaydayChecklistState();
}

class _PaydayChecklistState extends State<PaydayChecklist> {
  // Tracks which transfers have been ticked
  final Set<int> _done = {};

  // Derive suggested transfers: move money from instant accounts to locked/savings
  List<_Transfer> get _transfers {
    final instant = widget.accounts
        .where((a) =>
            a.type == AccountType.asset && a.liquidity == Liquidity.instant)
        .toList();
    final locked = widget.accounts
        .where((a) =>
            a.type == AccountType.asset && a.liquidity != Liquidity.instant)
        .toList();

    if (instant.isEmpty || locked.isEmpty) return [];

    // Placeholder: suggest moving 20% of each instant balance to locked accounts
    final transfers = <_Transfer>[];
    for (final src in instant) {
      final balance = widget.balances[src.id] ?? 0;
      if (balance <= 0) continue;
      for (final dst in locked) {
        final amount = (balance * 0.2).round();
        if (amount <= 0) continue;
        transfers.add(_Transfer(
          from: src,
          to: dst,
          amountMinor: amount,
          feeMinor: 0, // tariff engine will fill this later
        ));
      }
    }
    return transfers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transfers = _transfers;

    if (transfers.isEmpty) {
      return _Empty(
        isDark: isDark,
        message:
            'No transfers planned. Add accounts with different liquidity levels to see a payday checklist.',
      );
    }

    final totalFees =
        transfers.fold(0, (sum, t) => sum + t.feeMinor);

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      children: [
        // Summary
        Row(
          children: [
            Text(
              '${transfers.length} transfer${transfers.length == 1 ? '' : 's'} planned',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const Spacer(),
            if (totalFees > 0)
              Text(
                'Total fees: KES ${(totalFees / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        ...List.generate(transfers.length, (i) {
          final t = transfers[i];
          final isDone = _done.contains(i);
          return _TransferRow(
            transfer: t,
            isDone: isDone,
            isDark: isDark,
            onToggle: () => setState(
                () => isDone ? _done.remove(i) : _done.add(i)),
          );
        }),

        const SizedBox(height: 16),
        Text(
          'Fees are estimated. Confirm against your provider\'s current tariff before transferring.',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _Transfer {
  final Account from;
  final Account to;
  final int amountMinor;
  final int feeMinor;

  const _Transfer({
    required this.from,
    required this.to,
    required this.amountMinor,
    required this.feeMinor,
  });
}

class _TransferRow extends StatelessWidget {
  final _Transfer transfer;
  final bool isDone;
  final bool isDark;
  final VoidCallback onToggle;

  const _TransferRow({
    required this.transfer,
    required this.isDone,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isDone
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // From → To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(transfer.from.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDone
                                ? textSecondary
                                : textPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward,
                          size: 14, color: textSecondary),
                    ),
                    Text(transfer.to.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDone
                                ? textSecondary
                                : textPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null)),
                  ],
                ),
                if (transfer.feeMinor > 0)
                  Text(
                    'Fee: KES ${(transfer.feeMinor / 100).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          ),

          // Amount
          Text(
            'KES ${(transfer.amountMinor / 100).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDone ? textSecondary : AppColors.royalBlue,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;
  final String message;
  const _Empty({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swap_horiz_outlined,
              size: 32,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

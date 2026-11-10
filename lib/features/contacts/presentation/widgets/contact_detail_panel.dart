import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';

class ContactDetailPanel extends StatelessWidget {
  final Contact contact;
  final ContactSummary summary;
  final List<JournalEntry> entries;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onUntagEntry;

  const ContactDetailPanel({
    super.key,
    required this.contact,
    required this.summary,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
    required this.onUntagEntry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final net = summary.netMinor;
    final netColor =
        net > 0 ? AppColors.success : net < 0 ? AppColors.error : textTertiary;

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(contact.initials,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(contact.relationship.label,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalBlue)),
                      ),
                      if (contact.phone != null) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.phone_outlined,
                              size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(contact.phone!,
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary)),
                        ]),
                      ],
                      if (contact.email != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.email_outlined,
                              size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(contact.email!,
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary)),
                        ]),
                      ],
                      if (contact.notes != null) ...[
                        const SizedBox(height: 6),
                        Text(contact.notes!,
                            style: TextStyle(
                                fontSize: 12,
                                color: textTertiary,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 18, color: textSecondary),
                  color: surface,
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Net position cards ─────────────────────────────────────────
            Row(
              children: [
                _KpiCard(
                  label: 'PAID OUT',
                  value: _fmt(summary.totalPaidOutMinor),
                  sub: 'expenses on their behalf',
                  color: summary.totalPaidOutMinor > 0
                      ? AppColors.error
                      : textTertiary,
                  surface: surface,
                ),
                const SizedBox(width: 10),
                _KpiCard(
                  label: 'RECEIVED',
                  value: _fmt(summary.totalReceivedMinor),
                  sub: 'reimbursements & payments',
                  color: summary.totalReceivedMinor > 0
                      ? AppColors.success
                      : textTertiary,
                  surface: surface,
                ),
                const SizedBox(width: 10),
                _KpiCard(
                  label: net >= 0 ? 'NET RECEIVED' : 'NET OWED',
                  value: _fmt(net.abs()),
                  sub: net > 0
                      ? 'you are ahead'
                      : net < 0
                          ? 'you are owed this'
                          : 'all settled',
                  color: netColor,
                  surface: surface,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Transactions ───────────────────────────────────────────────
            Row(
              children: [
                Text('Transactions',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${entries.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlue)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'No transactions linked to ${contact.name} yet.\nTag entries from the Transactions screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ),
              )
            else
              ...entries.map((entry) {
                final debit = entry.lines
                    .where((l) => l.side == JournalSide.debit)
                    .fold(0, (s, l) => s + l.amountMinor);
                final credit = entry.lines
                    .where((l) => l.side == JournalSide.credit)
                    .fold(0, (s, l) => s + l.amountMinor);
                final isIncome = credit > debit;
                final amount = isIncome ? credit : debit;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isIncome
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.description,
                                style: TextStyle(
                                    fontSize: 13, color: textPrimary)),
                            Row(
                              children: [
                                Text(_fmtDate(entry.date),
                                    style: TextStyle(
                                        fontSize: 11, color: textTertiary)),
                                if (entry.tags.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  ...entry.tags.take(2).map((t) => Container(
                                        margin:
                                            const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.royalBlue
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(t,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.royalBlue)),
                                      )),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${_fmt(amount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isIncome
                              ? AppColors.success
                              : AppColors.error,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Remove from contact',
                        child: GestureDetector(
                          onTap: () => _confirmUntag(context, entry),
                          child: Icon(Icons.link_off,
                              size: 14, color: textTertiary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete contact?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '"${contact.name}" will be deleted. Their transactions will be unlinked but not deleted.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 14, color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onDelete();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmUntag(BuildContext context, JournalEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remove from contact?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '"${entry.description}" will be unlinked from ${contact.name}. The transaction is not deleted.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 14, color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onUntagEntry(entry.id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Remove',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final Color surface;

  const _KpiCard({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: textSecondary)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!,
                  style: TextStyle(fontSize: 10, color: textTertiary)),
            ],
          ],
        ),
      ),
    );
  }
}

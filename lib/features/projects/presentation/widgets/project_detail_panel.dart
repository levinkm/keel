import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/projects/domain/entities/project.dart';

class ProjectDetailPanel extends StatelessWidget {
  final Project project;
  final ProjectSummary summary;
  final List<JournalEntry> entries;
  final List<Account> accounts;
  final VoidCallback onEdit;
  final ValueChanged<ProjectStatus> onSetStatus;
  final ValueChanged<String> onUntagEntry; // journalEntryId

  const ProjectDetailPanel({
    super.key,
    required this.project,
    required this.summary,
    required this.entries,
    required this.accounts,
    required this.onEdit,
    required this.onSetStatus,
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
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final usedPct = summary.budgetUsedPct(project.budgetMinor);
    final isOver = summary.isOverBudget(project.budgetMinor);
    final remaining = project.budgetMinor - summary.totalSpentMinor;

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _typeColor(project.type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    project.isCapital
                        ? Icons.construction_outlined
                        : Icons.agriculture_outlined,
                    size: 20,
                    color: _typeColor(project.type),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(project.status),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _typeColor(project.type)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(project.type.label,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _typeColor(project.type))),
                          ),
                        ],
                      ),
                      if (project.description != null) ...[
                        const SizedBox(height: 6),
                        Text(project.description!,
                            style: TextStyle(
                                fontSize: 13, color: textSecondary)),
                      ],
                    ],
                  ),
                ),
                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 18, color: textSecondary),
                  color: surface,
                  onSelected: (v) => _handleMenu(context, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit project')),
                    if (project.status == ProjectStatus.planning)
                      const PopupMenuItem(value: 'activate', child: Text('Mark active')),
                    if (project.status == ProjectStatus.active)
                      const PopupMenuItem(value: 'hold', child: Text('Put on hold')),
                    if (project.status != ProjectStatus.completed &&
                        project.status != ProjectStatus.cancelled)
                      const PopupMenuItem(value: 'complete', child: Text('Mark completed')),
                    if (project.status != ProjectStatus.cancelled)
                      const PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel project',
                              style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── KPI cards ────────────────────────────────────────────────────
            Row(
              children: [
                _KpiCard(
                  label: 'BUDGET',
                  value: _fmt(project.budgetMinor),
                  sub: project.revenueTargetMinor != null
                      ? 'Target: ${_fmt(project.revenueTargetMinor!)}'
                      : null,
                  color: textPrimary,
                  surface: surface,
                ),
                const SizedBox(width: 10),
                _KpiCard(
                  label: 'SPENT',
                  value: _fmt(summary.totalSpentMinor),
                  sub: isOver ? 'Over budget!' : null,
                  color: isOver ? AppColors.error : textPrimary,
                  surface: surface,
                ),
                const SizedBox(width: 10),
                _KpiCard(
                  label: remaining >= 0 ? 'REMAINING' : 'OVERSPEND',
                  value: _fmt(remaining.abs()),
                  color: remaining >= 0 ? AppColors.success : AppColors.error,
                  surface: surface,
                ),
                if (project.isRevenue) ...[
                  const SizedBox(width: 10),
                  _KpiCard(
                    label: 'REVENUE',
                    value: _fmt(summary.totalIncomeMinor),
                    sub: summary.netMinor >= 0
                        ? 'Net: +${_fmt(summary.netMinor)}'
                        : 'Net: -${_fmt(summary.netMinor.abs())}',
                    color: summary.totalIncomeMinor > 0
                        ? AppColors.success
                        : textTertiary,
                    surface: surface,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Budget progress ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Budget utilisation',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary)),
                      const Spacer(),
                      Text(
                        '${(usedPct * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isOver ? AppColors.error : AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usedPct.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: divider,
                      valueColor: AlwaysStoppedAnimation(
                        isOver
                            ? AppColors.error
                            : usedPct > 0.85
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                  if (project.isRevenue &&
                      project.revenueTargetMinor != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Revenue progress',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary)),
                        const Spacer(),
                        Text(
                          '${((summary.totalIncomeMinor / project.revenueTargetMinor!) * 100).clamp(0, 999).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (summary.totalIncomeMinor /
                                project.revenueTargetMinor!)
                            .clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: divider,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.success),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Timeline ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _TimelineItem(
                    label: 'START',
                    value: _fmtDate(project.startDate),
                    color: AppColors.royalBlue,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (project.timeProgressPct != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: project.timeProgressPct!,
                              minHeight: 4,
                              backgroundColor: divider,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.royalBlue),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${project.daysElapsed}d elapsed'
                            '${project.daysRemaining != null ? ' · ${project.daysRemaining! > 0 ? '${project.daysRemaining}d left' : '${project.daysRemaining!.abs()}d overdue'}' : ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10, color: textTertiary),
                          ),
                        ] else
                          Text('Open-ended',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10, color: textTertiary)),
                      ],
                    ),
                  ),
                  _TimelineItem(
                    label: 'END',
                    value: project.endDate != null
                        ? _fmtDate(project.endDate!)
                        : '—',
                    color: project.daysRemaining != null &&
                            project.daysRemaining! < 0
                        ? AppColors.error
                        : textSecondary,
                    alignRight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Transactions ─────────────────────────────────────────────────
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
                    color: surface,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'No transactions tagged to this project yet.\nTag entries from the Transactions screen.',
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
                                        fontSize: 11,
                                        color: textTertiary)),
                                if (entry.tags.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  ...entry.tags.take(3).map((t) =>
                                      Container(
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
                      GestureDetector(
                        onTap: () => _confirmUntag(context, entry),
                        child: Tooltip(
                          message: 'Remove from project',
                          child: Icon(Icons.link_off,
                              size: 14, color: textTertiary),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            // Tags
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.royalBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.royalBlue,
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmUntag(BuildContext context, JournalEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: surface,
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
                Text('Remove from project?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '"${entry.description}" will be unlinked from this project. The transaction itself is not deleted.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 14, color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onUntagEntry(entry.id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Remove'),
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

  void _handleMenu(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        onEdit();
      case 'activate':
        onSetStatus(ProjectStatus.active);
      case 'hold':
        onSetStatus(ProjectStatus.onHold);
      case 'complete':
        onSetStatus(ProjectStatus.completed);
      case 'cancel':
        onSetStatus(ProjectStatus.cancelled);
    }
  }

  Color _typeColor(ProjectType t) =>
      t == ProjectType.capital ? AppColors.royalBlue : AppColors.success;

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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProjectStatus.planning => AppColors.info,
      ProjectStatus.active => AppColors.success,
      ProjectStatus.onHold => AppColors.warning,
      ProjectStatus.completed => AppColors.royalBlue,
      ProjectStatus.cancelled => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
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

class _TimelineItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  const _TimelineItem({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: textTertiary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

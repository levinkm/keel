import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/projects/domain/entities/project.dart';

class ProjectListTile extends StatelessWidget {
  final Project project;
  final ProjectSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const ProjectListTile({
    super.key,
    required this.project,
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final usedPct = summary.budgetUsedPct(project.budgetMinor);
    final isOver = summary.isOverBudget(project.budgetMinor);
    final progressColor = isOver
        ? AppColors.error
        : usedPct > 0.85
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _typeColor(project.type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    project.isCapital
                        ? Icons.construction_outlined
                        : Icons.agriculture_outlined,
                    size: 14,
                    color: _typeColor(project.type),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      Text(project.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(project.status))),
                    ],
                  ),
                ),
                Text(_fmt(summary.totalSpentMinor),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOver ? AppColors.error : textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
            const SizedBox(height: 8),
            // Budget progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: usedPct,
                minHeight: 3,
                backgroundColor:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${(usedPct * 100).toStringAsFixed(0)}% of ${_fmt(project.budgetMinor)}',
                  style: TextStyle(fontSize: 10, color: textTertiary),
                ),
                const Spacer(),
                if (project.endDate != null)
                  Text(
                    _daysLabel(),
                    style: TextStyle(
                        fontSize: 10,
                        color: _daysColor()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysLabel() {
    final remaining = project.daysRemaining;
    if (remaining == null) return '';
    if (remaining < 0) return '${remaining.abs()}d overdue';
    if (remaining == 0) return 'Due today';
    return '${remaining}d left';
  }

  Color _daysColor() {
    final remaining = project.daysRemaining;
    if (remaining == null) return AppColors.lightTextTertiary;
    if (remaining < 0) return AppColors.error;
    if (remaining <= 7) return AppColors.warning;
    return AppColors.lightTextTertiary;
  }

  Color _typeColor(ProjectType t) => t == ProjectType.capital
      ? AppColors.royalBlue
      : AppColors.success;

  Color _statusColor(ProjectStatus s) => switch (s) {
        ProjectStatus.planning => AppColors.info,
        ProjectStatus.active => AppColors.success,
        ProjectStatus.onHold => AppColors.warning,
        ProjectStatus.completed => AppColors.royalBlue,
        ProjectStatus.cancelled => AppColors.error,
      };

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';

class ContactListTile extends StatelessWidget {
  final Contact contact;
  final ContactSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const ContactListTile({
    super.key,
    required this.contact,
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
    final selectedBg =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    final net = summary.netMinor;
    final netColor = net > 0
        ? AppColors.success
        : net < 0
            ? AppColors.error
            : textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  Text(
                    '${contact.relationship.label} · ${summary.entryCount} transactions',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  net == 0
                      ? 'Settled'
                      : net > 0
                          ? '+${_fmt(net)}'
                          : '-${_fmt(net.abs())}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: netColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  net > 0
                      ? 'received'
                      : net < 0
                          ? 'paid out'
                          : '',
                  style: TextStyle(fontSize: 10, color: textTertiary),
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
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

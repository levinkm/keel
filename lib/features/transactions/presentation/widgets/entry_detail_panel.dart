import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/transactions/presentation/widgets/edit_entry_dialog.dart';

class EntryDetailPanel extends StatelessWidget {
  final JournalEntry entry;
  final List<Account> accounts;
  final List<Project> projects;
  final List<Contact> contacts;
  final String? currentProjectId;
  final bool isDark;
  final ValueChanged<String> onReverse;
  final ValueChanged<JournalEntry> onUpdateMeta;
  final void Function({
    required String feeAccountId,
    required String paidFromAccountId,
    required int amountMinor,
    required String memo,
  }) onAddCost;
  final ValueChanged<String?> onRetag;
  final ValueChanged<String?> onRetagContact;
  final void Function(String filePath, String fileName, String? mimeType)
      onAddAttachment;
  final ValueChanged<String> onRemoveAttachment;

  const EntryDetailPanel({
    super.key,
    required this.entry,
    required this.accounts,
    required this.projects,
    required this.contacts,
    required this.currentProjectId,
    required this.isDark,
    required this.onReverse,
    required this.onUpdateMeta,
    required this.onAddCost,
    required this.onRetag,
    required this.onRetagContact,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  String _accountName(String id) {
    final match = accounts.firstWhere((a) => a.id == id,
        orElse: () => Account(
              id: id,
              name: '',
              type: AccountType.equity,
              currency: 'KES',
              liquidity: Liquidity.instant,
              isActive: true,
              createdAt: DateTime.now(),
            ));
    if (match.name.isNotEmpty) return match.name;
    if (id == 'opening-equity') return 'Opening Equity';
    return 'Unknown account';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final totalDebits = entry.lines
        .where((l) => l.side == JournalSide.debit)
        .fold(0, (sum, l) => sum + l.amountMinor);
    final totalCredits = entry.lines
        .where((l) => l.side == JournalSide.credit)
        .fold(0, (sum, l) => sum + l.amountMinor);

    final linkedProject = currentProjectId == null
        ? null
        : projects.cast<Project?>().firstWhere(
            (p) => p?.id == currentProjectId,
            orElse: () => null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatDate(entry.date),
                        style: TextStyle(fontSize: 13, color: textSecondary)),
                    if (entry.payee != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(entry.payee!,
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ],
                    if (entry.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(entry.location!,
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ],
                    if (entry.reference != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.tag, size: 12, color: textTertiary),
                          const SizedBox(width: 4),
                          Text('Ref: ${entry.reference!}',
                              style: TextStyle(
                                  fontSize: 11, color: textTertiary)),
                        ],
                      ),
                    ],
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: entry.tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(tag,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.royalBlue,
                                          fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                      ),
                    ],
                    if (linkedProject != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              linkedProject.isCapital
                                  ? Icons.construction_outlined
                                  : Icons.agriculture_outlined,
                              size: 12,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(linkedProject.name,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(
                      label: entry.isLocked ? 'Locked' : 'Posted',
                      color: entry.isLocked
                          ? textTertiary
                          : AppColors.success),
                  const SizedBox(height: 8),
                  if (!entry.isLocked) ...[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => showEditEntryDialog(
                        context: context,
                        entry: entry,
                        accounts: accounts,
                        projects: projects,
                        contacts: contacts,
                        currentProjectId: currentProjectId,
                        currentContactId: entry.contactId,
                        onSave: onUpdateMeta,
                        onAddCost: onAddCost,
                        onRetag: onRetag,
                        onRetagContact: onRetagContact,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.royalBlue),
                          const SizedBox(width: 4),
                          const Text('Edit',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.royalBlue)),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showReverseDialog(context),
                      child: Row(
                        children: [
                          Icon(Icons.undo,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text('Reverse',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.warning)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Notes
          if (entry.notes != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: elevated, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textTertiary)),
                  const SizedBox(height: 6),
                  Text(entry.notes!,
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Journal lines table ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
                color: surfaceBg, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('Account',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textTertiary,
                                  letterSpacing: 0.3))),
                      Expanded(
                          flex: 2,
                          child: Text('Memo',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textTertiary,
                                  letterSpacing: 0.3))),
                      SizedBox(
                          width: 100,
                          child: Text('Debit',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textTertiary,
                                  letterSpacing: 0.3))),
                      SizedBox(
                          width: 100,
                          child: Text('Credit',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textTertiary,
                                  letterSpacing: 0.3))),
                    ],
                  ),
                ),
                Divider(height: 1, color: divider),
                ...entry.lines.map((line) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(_accountName(line.accountId),
                                style: TextStyle(
                                    fontSize: 13, color: textPrimary)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(line.memo ?? '',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: textTertiary,
                                    fontStyle: line.memo != null
                                        ? FontStyle.normal
                                        : FontStyle.italic)),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              line.side == JournalSide.debit
                                  ? _fmt(line.amountMinor)
                                  : '',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              line.side == JournalSide.credit
                                  ? _fmt(line.amountMinor)
                                  : '',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                Divider(height: 1, color: divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('Total',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary))),
                      const Expanded(flex: 2, child: SizedBox()),
                      SizedBox(
                        width: 100,
                        child: Text(_fmt(totalDebits),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: totalDebits == totalCredits
                                  ? AppColors.success
                                  : AppColors.error,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            )),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(_fmt(totalCredits),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: totalDebits == totalCredits
                                  ? AppColors.success
                                  : AppColors.error,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Balance check
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                entry.isBalanced
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 14,
                color: entry.isBalanced ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                entry.isBalanced
                    ? 'Entry is balanced'
                    : 'Entry is NOT balanced — debits ≠ credits',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      entry.isBalanced ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),

          // ── Attachments ──────────────────────────────────────────────────
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Receipts & attachments',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const Spacer(),
              if (!entry.isLocked)
                GestureDetector(
                  onTap: () => _pickAttachment(context),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          size: 14, color: AppColors.royalBlue),
                      const SizedBox(width: 4),
                      const Text('Attach',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.royalBlue,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (entry.attachments.isEmpty)
            Text('No attachments.',
                style: TextStyle(fontSize: 12, color: textTertiary))
          else
            ...entry.attachments.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(_mimeIcon(a.mimeType),
                          size: 16, color: AppColors.royalBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.fileName,
                                style: TextStyle(
                                    fontSize: 13, color: textPrimary)),
                            Text(_formatDate(a.createdAt),
                                style: TextStyle(
                                    fontSize: 10, color: textTertiary)),
                          ],
                        ),
                      ),
                      // Open file
                      GestureDetector(
                        onTap: () => _openFile(a.filePath),
                        child: Icon(Icons.open_in_new,
                            size: 14, color: textSecondary),
                      ),
                      const SizedBox(width: 12),
                      // Remove
                      if (!entry.isLocked)
                        GestureDetector(
                          onTap: () =>
                              _confirmRemoveAttachment(context, a),
                          child: Icon(Icons.delete_outline,
                              size: 14, color: AppColors.error),
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Future<void> _pickAttachment(BuildContext context) async {
    // Use macOS native file picker via osascript
    final result = await Process.run('osascript', [
      '-e',
      'POSIX path of (choose file with prompt "Select a receipt or attachment")'
    ]);
    if (result.exitCode != 0) return;
    final path = (result.stdout as String).trim();
    if (path.isEmpty) return;
    final name = path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : null;
    String? mime;
    if (ext != null) {
      mime = switch (ext) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'heic' => 'image/heic',
        _ => 'application/$ext',
      };
    }
    onAddAttachment(path, name, mime);
  }

  void _openFile(String path) {
    // On macOS open with default app
    Process.run('open', [path]);
  }

  void _confirmRemoveAttachment(
      BuildContext context, EntryAttachment attachment) {
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
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remove attachment?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '"${attachment.fileName}" will be removed from this entry. The file on disk is not deleted.',
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
                        onRemoveAttachment(attachment.id);
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

  void _showReverseDialog(BuildContext context) {
    final controller = TextEditingController();
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reverse entry',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'A reversing entry will be posted. The original entry is not deleted.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: controller,
                  placeholder: 'Reason for reversal',
                  autofocus: true,
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 14, color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onReverse(controller.text.trim().isEmpty
                            ? 'No reason given'
                            : controller.text.trim());
                      },
                      child: const Text('Reverse',
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
    );
  }

  IconData _mimeIcon(String? mime) {
    if (mime == null) return Icons.attach_file;
    if (mime.startsWith('image')) return Icons.image_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color));
}

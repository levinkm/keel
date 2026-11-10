import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:uuid/uuid.dart';

void showContactDialog({
  required BuildContext context,
  Contact? existing,
  required ValueChanged<Contact> onSave,
}) {
  showDialog(
    context: context,
    builder: (_) => _ContactDialog(existing: existing, onSave: onSave),
  );
}

class _ContactDialog extends StatefulWidget {
  final Contact? existing;
  final ValueChanged<Contact> onSave;
  const _ContactDialog({this.existing, required this.onSave});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  late ContactRelationship _relationship;

  bool get _isEdit => widget.existing != null;
  bool get _valid => _nameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _relationship = c?.relationship ?? ContactRelationship.family;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(Contact(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      relationship: _relationship,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    ));
    Navigator.of(context).pop();
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
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_isEdit ? 'Edit contact' : 'New contact',
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

              _Label('Name', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _nameCtrl,
                autofocus: true,
                placeholder: 'e.g. Jane Wanjiku',
                style: TextStyle(fontSize: 14, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 14, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Phone', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _phoneCtrl,
                          placeholder: '07XX XXX XXX',
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
                          decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Email', textSecondary),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _emailCtrl,
                          placeholder: 'jane@example.com',
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
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
              ),
              const SizedBox(height: 16),

              _Label('Relationship', textSecondary),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ContactRelationship.values.map((r) {
                  final isSelected = r == _relationship;
                  return GestureDetector(
                    onTap: () => setState(() => _relationship = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.royalBlue
                            : fieldBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _Label('Notes', textSecondary),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _notesCtrl,
                placeholder: 'Any notes about this contact…',
                maxLines: 2,
                style: TextStyle(fontSize: 13, color: textPrimary),
                placeholderStyle:
                    TextStyle(fontSize: 13, color: textTertiary),
                decoration: BoxDecoration(
                    color: fieldBg, borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 28),

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
                    color: _valid
                        ? AppColors.royalBlue
                        : AppColors.disabledSurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _valid ? _save : null,
                    child: Text(_isEdit ? 'Save changes' : 'Add contact',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _valid
                                ? Colors.white
                                : AppColors.disabledForeground)),
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

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color));
}

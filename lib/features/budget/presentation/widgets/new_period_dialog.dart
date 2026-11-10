import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';

class NewPeriodDialog extends StatefulWidget {
  final List<String> existingPeriods;
  final void Function(String period, bool copyPrevious) onCreate;

  const NewPeriodDialog({
    super.key,
    required this.existingPeriods,
    required this.onCreate,
  });

  @override
  State<NewPeriodDialog> createState() => _NewPeriodDialogState();
}

class _NewPeriodDialogState extends State<NewPeriodDialog> {
  late String _selectedPeriod;
  bool _copyPrevious = false;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = _nextPeriod();
  }

  String _nextPeriod() {
    if (widget.existingPeriods.isEmpty) return _todayPeriod();
    final latest = widget.existingPeriods.first; // sorted DESC
    final parts = latest.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + 1;
    if (month > 12) { month = 1; year++; }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  String _todayPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // Generate next 12 months as options
  List<String> get _options {
    final options = <String>[];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      var year = now.year;
      var month = now.month + i;
      if (month > 12) { month -= 12; year++; }
      final p = '$year-${month.toString().padLeft(2, '0')}';
      if (!widget.existingPeriods.contains(p)) options.add(p);
    }
    return options.isEmpty ? [_todayPeriod()] : options;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final options = _options;
    if (!options.contains(_selectedPeriod) && options.isNotEmpty) {
      _selectedPeriod = options.first;
    }

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New budget period',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 20),

              Text('Period', style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    dropdownColor: surface,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    items: options
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(_formatPeriod(p)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPeriod = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Copy options
              _OptionTile(
                label: 'Start blank',
                selected: !_copyPrevious,
                isDark: isDark,
                onTap: () => setState(() => _copyPrevious = false),
              ),
              const SizedBox(height: 8),
              _OptionTile(
                label: 'Copy from previous month',
                selected: _copyPrevious,
                isDark: isDark,
                onTap: () => setState(() => _copyPrevious = true),
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onCreate(_selectedPeriod, _copyPrevious);
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
    );
  }

  String _formatPeriod(String period) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final parts = period.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? elevated : surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.royalBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.royalBlue : AppColors.slateBlue,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.circle, size: 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 13, color: textPrimary)),
          ],
        ),
      ),
    );
  }
}

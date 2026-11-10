import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/presentation/widgets/asset_dialog.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/presentation/widgets/project_dialog.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class AssetDetailPanel extends StatefulWidget {
  final Asset asset;
  final List<Project> linkedProjects;
  final Map<String, ProjectSummary> linkedSummaries;
  final Map<String, List<JournalEntry>> linkedEntries;
  final List<AssetAttachment> attachments;
  final List<Account> accounts;
  final List<Asset> allAssets;
  final void Function(Asset) onEdit;
  final void Function(Asset) onStatusChange;
  final void Function(Project) onCreateProject;
  final void Function(Project) onEditProject;
  final VoidCallback onRefreshProjects;
  final void Function(String path, String name, String? mime) onAddAttachment;
  final ValueChanged<String> onRemoveAttachment;

  const AssetDetailPanel({
    super.key,
    required this.asset,
    required this.linkedProjects,
    required this.linkedSummaries,
    required this.linkedEntries,
    required this.attachments,
    required this.accounts,
    required this.allAssets,
    required this.onEdit,
    required this.onStatusChange,
    required this.onCreateProject,
    required this.onEditProject,
    required this.onRefreshProjects,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  @override
  State<AssetDetailPanel> createState() => _AssetDetailPanelState();
}

class _AssetDetailPanelState extends State<AssetDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_classIcon(widget.asset.assetClass), size: 20,
                      color: AppColors.royalBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(widget.asset.name,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                          ),
                          const SizedBox(width: 8),
                          _Tag(label: _classLabel(widget.asset.assetClass),
                              color: AppColors.royalBlue),
                          const SizedBox(width: 6),
                          _statusTag(widget.asset.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.asset.location != null
                            ? '${widget.asset.currency} · ${widget.asset.location}'
                            : widget.asset.currency,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  onPressed: () => showAssetDialog(
                      context: context, existing: widget.asset, onSave: widget.onEdit),
                  child: Text('Edit',
                      style: TextStyle(fontSize: 13, color: AppColors.royalBlue)),
                ),
                if (widget.asset.status == AssetStatus.inUse)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () => _confirmStatus(context, AssetStatus.sold, isDark),
                    child: Text('Mark Sold',
                        style: TextStyle(fontSize: 13, color: AppColors.warning)),
                  ),
                if (widget.asset.status == AssetStatus.inUse)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () => _confirmStatus(context, AssetStatus.writtenOff, isDark),
                    child: Text('Write Off',
                        style: TextStyle(fontSize: 13, color: AppColors.error)),
                  ),
                if (widget.asset.status != AssetStatus.inUse)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () => widget.onStatusChange(
                        widget.asset.copyWith(status: AssetStatus.inUse)),
                    child: Text('Reactivate',
                        style: TextStyle(fontSize: 13, color: AppColors.success)),
                  ),
              ],
            ),
          ),

          // ── Tab bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                _TabButton(label: 'Overview', index: 0, controller: _tab,
                    isDark: isDark),
                const SizedBox(width: 4),
                _TabButton(
                  label: 'Activity',
                  index: 1,
                  controller: _tab,
                  isDark: isDark,
                  badge: widget.linkedProjects.isNotEmpty
                      ? '${widget.linkedProjects.length}'
                      : null,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: divider),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(
                  asset: widget.asset,
                  attachments: widget.attachments,
                  isDark: isDark,
                  onAddAttachment: widget.onAddAttachment,
                  onRemoveAttachment: widget.onRemoveAttachment,
                ),
                _ActivityTab(
                  asset: widget.asset,
                  projects: widget.linkedProjects,
                  summaries: widget.linkedSummaries,
                  entries: widget.linkedEntries,
                  accounts: widget.accounts,
                  allAssets: widget.allAssets,
                  isDark: isDark,
                  onCreateProject: widget.onCreateProject,
                  onEditProject: widget.onEditProject,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStatus(BuildContext context, AssetStatus newStatus, bool isDark) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final label = newStatus == AssetStatus.sold ? 'Mark as Sold' : 'Write Off';
    final color = newStatus == AssetStatus.sold ? AppColors.warning : AppColors.error;
    final desc = newStatus == AssetStatus.sold
        ? 'This will mark the asset as sold. You can reactivate it later.'
        : 'This will write off the asset. You can reactivate it later.';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const SizedBox(height: 8),
              Text(desc,
                  style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancel', style: TextStyle(color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      widget.onStatusChange(widget.asset.copyWith(status: newStatus));
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: color, foregroundColor: Colors.white),
                    child: Text(label),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTag(AssetStatus status) {
    final (label, color) = switch (status) {
      AssetStatus.inUse => ('In Use', AppColors.success),
      AssetStatus.sold => ('Sold', AppColors.warning),
      AssetStatus.writtenOff => ('Written Off', AppColors.error),
    };
    return _Tag(label: label, color: color);
  }

  IconData _classIcon(AssetClass c) => switch (c) {
        AssetClass.cashAndBank => Icons.account_balance_outlined,
        AssetClass.investments => Icons.show_chart_outlined,
        AssetClass.vehicle => Icons.directions_car_outlined,
        AssetClass.machinery => Icons.precision_manufacturing_outlined,
        AssetClass.land => Icons.landscape_outlined,
        AssetClass.building => Icons.home_outlined,
        AssetClass.receivable => Icons.receipt_long_outlined,
        AssetClass.other => Icons.category_outlined,
      };

  String _classLabel(AssetClass c) => switch (c) {
        AssetClass.cashAndBank => 'Cash & Bank',
        AssetClass.investments => 'Investments',
        AssetClass.vehicle => 'Vehicle',
        AssetClass.machinery => 'Machinery',
        AssetClass.land => 'Land',
        AssetClass.building => 'Building',
        AssetClass.receivable => 'Receivable',
        AssetClass.other => 'Other',
      };
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Asset asset;
  final List<AssetAttachment> attachments;
  final bool isDark;
  final void Function(String path, String name, String? mime) onAddAttachment;
  final ValueChanged<String> onRemoveAttachment;

  const _OverviewTab({
    required this.asset,
    required this.attachments,
    required this.isDark,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final gainLoss = asset.bookValue - asset.costMinor;
    final gainPct = asset.costMinor > 0 ? (gainLoss / asset.costMinor * 100) : 0.0;
    final isGain = gainLoss >= 0;
    final gainColor = isGain ? AppColors.success : AppColors.error;

    final now = DateTime.now();
    final isInsured = asset.insuranceExpiry != null && asset.insuranceExpiry!.isAfter(now);
    final expiringSoon = isInsured &&
        asset.insuranceExpiry!.isBefore(now.add(const Duration(days: 30)));

    final depreciableBase = asset.costMinor - asset.salvageMinor;
    final accumulated = asset.costMinor - asset.bookValue;
    final depPct = depreciableBase > 0
        ? (accumulated / depreciableBase).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book value card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book value', style: TextStyle(fontSize: 11, color: textTertiary)),
                const SizedBox(height: 6),
                Text(_fmtFull(asset.bookValue),
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: textPrimary, letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cost', style: TextStyle(fontSize: 11, color: textTertiary)),
                              Text(_fmtShort(asset.costMinor),
                                  style: TextStyle(fontSize: 11, color: textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: asset.costMinor > 0
                                  ? (asset.bookValue / asset.costMinor).clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation(
                                  isGain ? AppColors.success : AppColors.royalBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${isGain ? '+' : ''}${gainPct.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: gainColor)),
                        Text('${isGain ? '+' : ''}${_fmtShort(gainLoss)}',
                            style: TextStyle(fontSize: 12, color: gainColor)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // KPI row
          Row(children: [
            _kpi('ACQUISITION COST', _fmtShort(asset.costMinor), textPrimary, textSecondary, surface),
            const SizedBox(width: 10),
            _kpi('SALVAGE VALUE', _fmtShort(asset.salvageMinor), textSecondary, textSecondary, surface),
            const SizedBox(width: 10),
            _kpi(isGain ? 'UNREALISED GAIN' : 'UNREALISED LOSS',
                '${isGain ? '+' : ''}${_fmtShort(gainLoss)}', gainColor, textSecondary, surface),
          ]),
          const SizedBox(height: 20),

          // Details
          _sectionLabel('Details', textTertiary),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _row('Acquisition Date', _fmtDate(asset.acquisitionDate), textPrimary, textSecondary),
              _div(isDark),
              _row('Ownership', '${(asset.ownershipShareBp / 100).toStringAsFixed(0)}%',
                  textPrimary, textSecondary),
              if (asset.location != null) ...[
                _div(isDark),
                _row('Location', asset.location!, textPrimary, textSecondary),
              ],
              if (asset.valuationDate != null) ...[
                _div(isDark),
                _row('Last Valued', _fmtDate(asset.valuationDate!), textPrimary, textSecondary),
              ],
              if (asset.valuationSource != null) ...[
                _div(isDark),
                _row('Valuation Source', asset.valuationSource!, textPrimary, textSecondary),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // Depreciation
          if (asset.depreciationMethod != null) ...[
            _sectionLabel('Depreciation', textTertiary),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('Method', _depLabel(asset.depreciationMethod!), textPrimary, textSecondary),
                if (asset.annualRateBp != null) ...[
                  _div(isDark),
                  _row('Annual Rate', '${(asset.annualRateBp! / 100).toStringAsFixed(1)}%',
                      textPrimary, textSecondary),
                ],
                _div(isDark),
                _row('Salvage Value', _fmtFull(asset.salvageMinor), textPrimary, textSecondary),
                _div(isDark),
                _row('Accumulated Dep.', _fmtFull(accumulated), AppColors.warning, textSecondary),
                if (asset.annualRateBp != null && asset.annualRateBp! > 0) ...[
                  _div(isDark),
                  _row('Annual Charge', _fmtFull(_annualCharge(asset)), textPrimary, textSecondary),
                ],
                if (depreciableBase > 0) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Depreciation consumed',
                          style: TextStyle(fontSize: 11, color: textTertiary)),
                      Text('${(depPct * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: depPct,
                      minHeight: 6,
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      valueColor: AlwaysStoppedAnimation(
                          depPct > 0.8 ? AppColors.error : AppColors.warning),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Insurance
          if (asset.insuranceExpiry != null) ...[
            _sectionLabel('Insurance', textTertiary),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: (expiringSoon ? AppColors.warning
                            : isInsured ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shield_outlined, size: 18,
                      color: expiringSoon ? AppColors.warning
                          : isInsured ? AppColors.success : AppColors.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isInsured ? 'Active coverage' : 'Coverage expired',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isInsured ? AppColors.success : AppColors.error)),
                    Text(
                      isInsured
                          ? 'Valid until ${_fmtDate(asset.insuranceExpiry!)}'
                          : 'Expired ${_fmtDate(asset.insuranceExpiry!)}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ]),
                ),
                if (expiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Expiring soon',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.warning)),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (asset.notes != null) ...[
            _sectionLabel('Notes', textTertiary),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Text(asset.notes!,
                  style: TextStyle(fontSize: 13, color: textSecondary, height: 1.6)),
            ),
          ],

          // Attachments
          const SizedBox(height: 16),
          Row(
            children: [
              _sectionLabel('Documents', textTertiary),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickAttachment(context),
                child: Row(children: [
                  const Icon(Icons.attach_file, size: 14, color: AppColors.royalBlue),
                  const SizedBox(width: 4),
                  const Text('Attach',
                      style: TextStyle(fontSize: 12, color: AppColors.royalBlue,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (attachments.isEmpty)
            Text('No documents attached.',
                style: TextStyle(fontSize: 12, color: textTertiary))
          else
            ...attachments.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(_mimeIcon(a.mimeType), size: 16, color: AppColors.royalBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.fileName,
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_fmtDate(a.createdAt),
                          style: TextStyle(fontSize: 10, color: textTertiary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _openFile(a.filePath),
                  child: Icon(Icons.open_in_new, size: 14, color: textSecondary),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _confirmRemove(context, a),
                  child: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                ),
              ]),
            )),
        ],
      ),
    );
  }

  Future<void> _pickAttachment(BuildContext context) async {
    final result = await Process.run('osascript', [
      '-e',
      'POSIX path of (choose file with prompt "Select a document or receipt")'
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

  void _openFile(String path) => Process.run('open', [path]);

  void _confirmRemove(BuildContext context, AssetAttachment a) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remove document?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Text('"${a.fileName}" will be removed. The file on disk is not deleted.',
                    style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('Cancel', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        onRemoveAttachment(a.id);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white),
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

  IconData _mimeIcon(String? mime) {
    if (mime == null) return Icons.insert_drive_file_outlined;
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _kpi(String label, String value, Color valueColor, Color labelColor, Color surface) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: labelColor, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      );

  Widget _row(String label, String value, Color textPrimary, Color textSecondary) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: textSecondary))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );

  Widget _div(bool isDark) => Divider(
      height: 1,
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5));

  Widget _sectionLabel(String label, Color color) => Text(label.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.8));

  int _annualCharge(Asset a) {
    if (a.depreciationMethod == DepreciationMethod.straightLine && a.annualRateBp != null) {
      return ((a.costMinor - a.salvageMinor) * a.annualRateBp! / 10000).round();
    }
    if (a.depreciationMethod == DepreciationMethod.reducingBalance && a.annualRateBp != null) {
      return (a.bookValue * a.annualRateBp! / 10000).round();
    }
    return 0;
  }

  String _depLabel(DepreciationMethod m) => switch (m) {
        DepreciationMethod.straightLine => 'Straight Line',
        DepreciationMethod.reducingBalance => 'Reducing Balance',
      };

  String _fmtFull(int minor) {
    final v = minor / 100;
    final abs = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${v < 0 ? '−' : ''}KES $abs';
  }

  String _fmtShort(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

// ── Activity Tab ──────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final Asset asset;
  final List<Project> projects;
  final Map<String, ProjectSummary> summaries;
  final Map<String, List<JournalEntry>> entries;
  final List<Account> accounts;
  final List<Asset> allAssets;
  final bool isDark;
  final void Function(Project) onCreateProject;
  final void Function(Project) onEditProject;

  const _ActivityTab({
    required this.asset,
    required this.projects,
    required this.summaries,
    required this.entries,
    required this.accounts,
    required this.allAssets,
    required this.isDark,
    required this.onCreateProject,
    required this.onEditProject,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    // Aggregate across all linked projects
    int totalSpent = 0;
    int totalIncome = 0;
    for (final s in summaries.values) {
      totalSpent += s.totalSpentMinor;
      totalIncome += s.totalIncomeMinor;
    }
    final net = totalIncome - totalSpent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary KPIs
          if (projects.isNotEmpty) ...[
            Row(children: [
              _akpi('TOTAL SPENT', _fmtShort(totalSpent), AppColors.error, textSecondary, surface),
              const SizedBox(width: 10),
              _akpi('TOTAL INCOME', _fmtShort(totalIncome), AppColors.success, textSecondary, surface),
              const SizedBox(width: 10),
              _akpi('NET', '${net >= 0 ? '+' : ''}${_fmtShort(net)}',
                  net >= 0 ? AppColors.success : AppColors.error, textSecondary, surface),
            ]),
            const SizedBox(height: 20),
          ],

          // Header row
          Row(
            children: [
              Text('Projects', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: textPrimary)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => showProjectDialog(
                  context: context,
                  accounts: accounts,
                  assets: allAssets,
                  preselectedAssetId: asset.id,
                  onSave: onCreateProject,
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New project'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (projects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Icon(Icons.folder_open_outlined, size: 32,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                const SizedBox(height: 10),
                Text('No projects linked to this asset.',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 4),
                Text('Create a project to track spending and income.',
                    style: TextStyle(fontSize: 12, color: textTertiary)),
              ]),
            )
          else
            ...projects.map((project) {
              final summary = summaries[project.id];
              final projectEntries = entries[project.id] ?? [];
              final isExpanded = true; // always show entries inline

              final spent = summary?.totalSpentMinor ?? 0;
              final income = summary?.totalIncomeMinor ?? 0;
              final usedPct = project.budgetMinor > 0
                  ? (spent / project.budgetMinor).clamp(0.0, 1.0)
                  : 0.0;
              final isOver = spent > project.budgetMinor && project.budgetMinor > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (project.isCapital
                                      ? AppColors.royalBlue
                                      : AppColors.success)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              project.isCapital
                                  ? Icons.construction_outlined
                                  : Icons.agriculture_outlined,
                              size: 18,
                              color: project.isCapital
                                  ? AppColors.royalBlue
                                  : AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.name,
                                    style: TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w600, color: textPrimary)),
                                Row(children: [
                                  _statusChip(project.status),
                                  const SizedBox(width: 6),
                                  Text(project.type.label,
                                      style: TextStyle(fontSize: 11, color: textSecondary)),
                                ]),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                            tooltip: 'Edit project',
                            onPressed: () => showProjectDialog(
                              context: context,
                              accounts: accounts,
                              assets: allAssets,
                              existing: project,
                              onSave: onEditProject,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // KPI row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(children: [
                        _inlineKpi('BUDGET', _fmtShort(project.budgetMinor),
                            textPrimary, textSecondary),
                        _inlineKpi('SPENT', _fmtShort(spent),
                            isOver ? AppColors.error : textPrimary, textSecondary),
                        _inlineKpi('INCOME', _fmtShort(income),
                            income > 0 ? AppColors.success : textSecondary, textSecondary),
                        _inlineKpi('NET',
                            '${(income - spent) >= 0 ? '+' : ''}${_fmtShort(income - spent)}',
                            (income - spent) >= 0 ? AppColors.success : AppColors.error,
                            textSecondary),
                      ]),
                    ),

                    // Budget bar
                    if (project.budgetMinor > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Budget utilisation',
                                    style: TextStyle(fontSize: 11, color: textSecondary)),
                                Text('${(usedPct * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isOver ? AppColors.error : AppColors.success)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: usedPct,
                                minHeight: 5,
                                backgroundColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                valueColor: AlwaysStoppedAnimation(isOver
                                    ? AppColors.error
                                    : usedPct > 0.85
                                        ? AppColors.warning
                                        : AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Entries
                    if (isExpanded && projectEntries.isNotEmpty) ...[
                      Divider(height: 1,
                          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                              .withValues(alpha: 0.5)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Text('Transactions',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: textSecondary)),
                      ),
                      ...projectEntries.take(5).map((entry) {
                        final debit = entry.lines
                            .where((l) => l.side == JournalSide.debit)
                            .fold(0, (s, l) => s + l.amountMinor);
                        final credit = entry.lines
                            .where((l) => l.side == JournalSide.credit)
                            .fold(0, (s, l) => s + l.amountMinor);
                        final isIncome = credit > debit;
                        final amount = isIncome ? credit : debit;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                                color: elevated,
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: isIncome ? AppColors.success : AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.description,
                                        style: TextStyle(fontSize: 13, color: textPrimary),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(_fmtDate(entry.date),
                                        style: TextStyle(fontSize: 11, color: textTertiary)),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'}${_fmtShort(amount ~/ 2)}',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isIncome ? AppColors.success : AppColors.error,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ]),
                          ),
                        );
                      }),
                      if (projectEntries.length > 5)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text('+${projectEntries.length - 5} more — view in Projects',
                              style: TextStyle(fontSize: 11, color: textTertiary)),
                        )
                      else
                        const SizedBox(height: 10),
                    ] else if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text('No transactions tagged yet.',
                            style: TextStyle(fontSize: 12, color: textTertiary)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _akpi(String label, String value, Color valueColor, Color labelColor, Color surface) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: labelColor, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      );

  Widget _inlineKpi(String label, String value, Color valueColor, Color labelColor) =>
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: labelColor, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );

  Widget _statusChip(ProjectStatus status) {
    final color = switch (status) {
      ProjectStatus.planning => AppColors.info,
      ProjectStatus.active => AppColors.success,
      ProjectStatus.onHold => AppColors.warning,
      ProjectStatus.completed => AppColors.royalBlue,
      ProjectStatus.cancelled => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _fmtShort(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final int index;
  final TabController controller;
  final bool isDark;
  final String? badge;

  const _TabButton({
    required this.label,
    required this.index,
    required this.controller,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context2, unused) {
        final isActive = controller.index == index;
        final textSecondary =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        return GestureDetector(
          onTap: () => controller.animateTo(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.royalBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.royalBlue : textSecondary,
                  )),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700, color: AppColors.royalBlue)),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

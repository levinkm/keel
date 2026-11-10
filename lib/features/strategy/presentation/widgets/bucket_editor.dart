import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:uuid/uuid.dart';

class BucketEditor extends StatefulWidget {
  final List<StrategyBucket> buckets;
  final String strategyId;
  final List<Account> expenseAccounts;
  final List<Account> assetAccounts;
  final int monthlyIncomeMinor;
  final ValueChanged<List<StrategyBucket>> onSave;
  final ValueChanged<List<StrategyBucket>>? onPreview;

  const BucketEditor({
    super.key,
    required this.buckets,
    required this.strategyId,
    required this.expenseAccounts,
    required this.assetAccounts,
    required this.monthlyIncomeMinor,
    required this.onSave,
    this.onPreview,
  });

  @override
  State<BucketEditor> createState() => _BucketEditorState();
}

class _BucketEditorState extends State<BucketEditor> {
  late List<_BucketDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = widget.buckets
        .map((b) => _BucketDraft(
              id: b.id,
              nameCtrl: TextEditingController(text: b.name),
              pctCtrl: TextEditingController(text: '${b.targetPct}'),
              accountIds: List.of(b.accountIds),
              weightCtrls: {
                for (final id in b.accountIds)
                  id: TextEditingController(
                      text: '${b.accountWeights[id] ?? 0}')
              },
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.nameCtrl.dispose();
      d.pctCtrl.dispose();
      for (final c in d.weightCtrls.values) c.dispose();
    }
    super.dispose();
  }

  int get _totalPct =>
      _drafts.fold(0, (s, d) => s + (int.tryParse(d.pctCtrl.text) ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final total = _totalPct;
    final totalColor = total == 100
        ? AppColors.success
        : total > 100
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Buckets',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary)),
              const Spacer(),
              Text(
                '$total% allocated',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: totalColor),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addBucket,
                child: Icon(Icons.add_circle_outline,
                    size: 18, color: AppColors.royalBlue),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ..._drafts.asMap().entries.map((e) {
            final i = e.key;
            final draft = e.value;
            final pct = int.tryParse(draft.pctCtrl.text) ?? 0;
            final allocatedMinor =
                (widget.monthlyIncomeMinor * pct / 100).round();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Name
                      Expanded(
                        flex: 3,
                        child: CupertinoTextField(
                          controller: draft.nameCtrl,
                          placeholder: 'Bucket name',
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage
                      SizedBox(
                        width: 70,
                        child: CupertinoTextField(
                          controller: draft.pctCtrl,
                          keyboardType: TextInputType.number,
                          placeholder: '0',
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          placeholderStyle:
                              TextStyle(fontSize: 13, color: textTertiary),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('%',
                                style: TextStyle(
                                    fontSize: 13, color: textTertiary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Allocated amount preview
                      if (widget.monthlyIncomeMinor > 0)
                        Text(
                          _fmt(allocatedMinor),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Delete
                      GestureDetector(
                        onTap: _drafts.length > 1
                            ? () => setState(() => _drafts.removeAt(i))
                            : null,
                        child: Icon(Icons.remove_circle_outline,
                            size: 16,
                            color: _drafts.length > 1
                                ? AppColors.error
                                : textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Account linking
                  Text('Link accounts',
                      style: TextStyle(fontSize: 11, color: textTertiary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...[...widget.expenseAccounts, ...widget.assetAccounts]
                          .map((a) {
                        final linked = draft.accountIds.contains(a.id);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (linked) {
                              draft.accountIds.remove(a.id);
                              draft.weightCtrls.remove(a.id)?.dispose();
                            } else {
                              draft.accountIds.add(a.id);
                              // Default: equal split
                              final equalPct = 100 ~/ (draft.accountIds.length);
                              draft.weightCtrls[a.id] =
                                  TextEditingController(text: '$equalPct');
                              // Rebalance existing weights to equal
                              for (final id in draft.accountIds) {
                                draft.weightCtrls[id]?.text = '$equalPct';
                              }
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: linked ? AppColors.royalBlue : surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: linked
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: linked ? Colors.white : textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  // Weight inputs for linked accounts
                  if (draft.accountIds.length > 1) ...[
                    const SizedBox(height: 10),
                    Builder(builder: (_) {
                      final weightTotal = draft.accountIds.fold(
                          0,
                          (s, id) =>
                              s + (int.tryParse(draft.weightCtrls[id]?.text ?? '0') ?? 0));
                      final weightColor = weightTotal == 100
                          ? AppColors.success
                          : AppColors.warning;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Split within bucket',
                                  style: TextStyle(
                                      fontSize: 11, color: textTertiary)),
                              const Spacer(),
                              Text('$weightTotal%',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: weightColor)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...draft.accountIds.map((id) {
                            final acct = [...widget.expenseAccounts, ...widget.assetAccounts]
                                .cast<Account?>().firstWhere(
                                    (a) => a?.id == id, orElse: () => null);
                            if (acct == null) return const SizedBox.shrink();
                            final pct = int.tryParse(draft.pctCtrl.text) ?? 0;
                            final w = int.tryParse(
                                    draft.weightCtrls[id]?.text ?? '0') ??
                                0;
                            final accountAmount =
                                (widget.monthlyIncomeMinor * pct / 100 * w / 100)
                                    .round();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(acct.name,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary)),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: CupertinoTextField(
                                      controller: draft.weightCtrls[id],
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      style: TextStyle(
                                          fontSize: 12, color: textPrimary),
                                      decoration: BoxDecoration(
                                        color: surface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      suffix: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: Text('%',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: textTertiary)),
                                      ),
                                    ),
                                  ),
                                  if (widget.monthlyIncomeMinor > 0) ...[
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 72,
                                      child: Text(
                                        _fmt(accountAmount),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: total == 100
                  ? (widget.onPreview != null ? _preview : _save)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    total == 100 ? AppColors.royalBlue : AppColors.disabledSurface,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: Text(total == 100
                  ? (widget.onPreview != null ? 'Preview allocation →' : 'Save buckets')
                  : 'Total must be 100% (currently $total%)'),
            ),
          ),
        ],
      ),
    );
  }

  void _addBucket() {
    setState(() {
      _drafts.add(_BucketDraft(
        id: const Uuid().v4(),
        nameCtrl: TextEditingController(),
        pctCtrl: TextEditingController(text: '0'),
        accountIds: [],
        weightCtrls: {},
      ));
    });
  }

  List<StrategyBucket> _buildBuckets() {
    return _drafts.map((d) {
      final weights = <String, int>{
        for (final id in d.accountIds)
          id: int.tryParse(d.weightCtrls[id]?.text ?? '0') ?? 0,
      };
      return StrategyBucket(
        id: d.id,
        strategyId: widget.strategyId,
        name: d.nameCtrl.text.trim().isEmpty ? 'Bucket' : d.nameCtrl.text.trim(),
        targetPct: int.tryParse(d.pctCtrl.text) ?? 0,
        accountIds: d.accountIds,
        accountWeights: weights,
      );
    }).toList();
  }

  void _preview() => widget.onPreview!(_buildBuckets());

  void _save() => widget.onSave(_buildBuckets());

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

class _BucketDraft {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController pctCtrl;
  final List<String> accountIds;
  final Map<String, TextEditingController> weightCtrls; // accountId -> weight ctrl

  _BucketDraft({
    required this.id,
    required this.nameCtrl,
    required this.pctCtrl,
    required this.accountIds,
    required this.weightCtrls,
  });
}

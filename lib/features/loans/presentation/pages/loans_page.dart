import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/presentation/bloc/loans_cubit.dart';
import 'package:keel/features/loans/presentation/widgets/loan_detail_panel.dart';
import 'package:keel/features/loans/presentation/widgets/loan_dialog.dart';
import 'package:keel/features/loans/presentation/widgets/loan_list_tile.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoansCubit>()..load(),
      child: const _LoansView(),
    );
  }
}

class _LoansView extends StatelessWidget {
  const _LoansView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoansCubit, LoansState>(
      listenWhen: (_, current) =>
          current.maybeMap(loaded: (s) => s.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error = state.maybeMap(
            loaded: (s) => s.validationError, orElse: () => null);
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
        context.read<LoansCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 4),
          error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (loans, summaries, filter, selectedLoanId, selectedEvents,
              totalBorrowed, totalLent, monthlyBurden, nextDueDate, validationError) {
            final cubit = context.read<LoansCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
            final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            final filtered = loans.where((l) => switch (filter) {
                  LoanFilter.borrowed => l.direction == LoanDirection.borrowed,
                  LoanFilter.lent => l.direction == LoanDirection.lent,
                  LoanFilter.all => true,
                }).toList();

            final selectedLoan = selectedLoanId == null
                ? null
                : loans.cast<Loan?>().firstWhere(
                    (l) => l?.id == selectedLoanId,
                    orElse: () => null);

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Column(
                children: [
                  // ── Top bar ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Loans',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => showLoanDialog(
                                context: context,
                                existing: null,
                                onSave: cubit.createLoan,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add loan'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.royalBlue,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stat cards
                        Row(
                          children: [
                            _StatCard(
                              label: 'TOTAL OWED',
                              value: _fmt(totalBorrowed),
                              color: totalBorrowed > 0
                                  ? AppColors.error
                                  : textTertiary,
                              surface: surface,
                              icon: Icons.arrow_downward,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL LENT',
                              value: _fmt(totalLent),
                              color: totalLent > 0
                                  ? AppColors.success
                                  : textTertiary,
                              surface: surface,
                              icon: Icons.arrow_upward,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'MONTHLY BURDEN',
                              value: _fmt(monthlyBurden),
                              color: AppColors.royalBlue,
                              surface: surface,
                              icon: Icons.calendar_month_outlined,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'NEXT DUE',
                              value: nextDueDate != null
                                  ? _fmtDate(nextDueDate)
                                  : '—',
                              color: nextDueDate != null &&
                                      nextDueDate.isBefore(DateTime.now())
                                  ? AppColors.error
                                  : textPrimary,
                              surface: surface,
                              icon: Icons.event_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Split panel ────────────────────────────────────────────
                  Expanded(
                    child: Row(
                      children: [
                        // Left: loan list
                        SizedBox(
                          width: listPanelWidth(context),
                          child: Container(
                            color: bg,
                            child: Column(
                              children: [
                                // Filter tabs
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                  child: Row(
                                    children: LoanFilter.values.map((f) {
                                      final isActive = f == filter;
                                      return GestureDetector(
                                        onTap: () => cubit.setFilter(f),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppColors.royalBlue
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _filterLabel(f),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isActive
                                                  ? Colors.white
                                                  : textSecondary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No ${_filterLabel(filter).toLowerCase()} loans.',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: textTertiary),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, i) {
                                            final loan = filtered[i];
                                            final summary = summaries[loan.id]!;
                                            return LoanListTile(
                                              loan: loan,
                                              summary: summary,
                                              isSelected:
                                                  loan.id == selectedLoanId,
                                              onTap: () => cubit.selectLoan(
                                                  loan.id == selectedLoanId
                                                      ? null
                                                      : loan.id),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VerticalDivider(width: 1, color: divider),

                        // Right: detail panel
                        Expanded(
                          child: selectedLoan == null
                              ? Center(
                                  child: Text(
                                    loans.isEmpty
                                        ? 'Add a loan to get started.'
                                        : 'Select a loan to view details.',
                                    style: TextStyle(
                                        fontSize: 13, color: textTertiary),
                                  ),
                                )
                              : LoanDetailPanel(
                                  loan: selectedLoan,
                                  summary: summaries[selectedLoan.id]!,
                                  events: selectedEvents,
                                  onEdit: () => showLoanDialog(
                                    context: context,
                                    existing: selectedLoan,
                                    onSave: cubit.updateLoan,
                                  ),
                                  onRecordEvent: (type, amount, note) =>
                                      cubit.recordPayment(
                                        loan: selectedLoan,
                                        type: type,
                                        amountMinor: amount,
                                        note: note,
                                      ),
                                  onSettle: () => cubit.settleLoan(selectedLoan),
                                  onWriteOff: () =>
                                      cubit.writeOffLoan(selectedLoan),
                                  onReactivate: () =>
                                      cubit.reactivateLoan(selectedLoan),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _filterLabel(LoanFilter f) => switch (f) {
        LoanFilter.all => 'All',
        LoanFilter.borrowed => 'Borrowed',
        LoanFilter.lent => 'Lent',
      };

  static String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month]}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: textSecondary)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

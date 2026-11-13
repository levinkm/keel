import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/income/presentation/bloc/income_cubit.dart';
import 'package:keel/features/income/presentation/widgets/income_detail_panel.dart';
import 'package:keel/features/income/presentation/widgets/income_stream_dialog.dart';
import 'package:keel/features/income/presentation/widgets/income_stream_tile.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
import 'package:keel/core/widgets/shimmer.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<IncomeCubit>()..load(),
      child: const _IncomeView(),
    );
  }
}

class _IncomeView extends StatelessWidget {
  const _IncomeView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncomeCubit, IncomeState>(
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
        context.read<IncomeCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 4),
          error: (msg) =>
              Center(child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (streams, period, stats, receivedByStream, incomeAccounts,
              selectedStreamId, sparkline, paymentHistory, validationError) {
            final cubit = context.read<IncomeCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
            final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            final selectedStream = selectedStreamId == null
                ? null
                : streams.cast().firstWhere(
                    (s) => s.id == selectedStreamId,
                    orElse: () => null);

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Column(
                children: [
                  // Top bar: stat cards + period switcher
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        // Period switcher
                        Row(
                          children: [
                            Text('Income',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                            const Spacer(),
                            IconButton(
                              onPressed: cubit.previousPeriod,
                              icon: Icon(Icons.chevron_left,
                                  color: textSecondary, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            Text(_periodLabel(period),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary)),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: cubit.nextPeriod,
                              icon: Icon(Icons.chevron_right,
                                  color: textSecondary, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: () => showIncomeStreamDialog(
                                context: context,
                                accounts: incomeAccounts,
                                existing: null,
                                onSave: cubit.createStream,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add stream'),
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
                                label: 'EXPECTED',
                                value: _fmt(stats.expectedMinor),
                                color: textPrimary,
                                surface: surface),
                            const SizedBox(width: 10),
                            _StatCard(
                                label: 'RECEIVED',
                                value: _fmt(stats.receivedMinor),
                                color: AppColors.success,
                                surface: surface),
                            const SizedBox(width: 10),
                            _StatCard(
                                label: 'PENDING',
                                value: _fmt(stats.pendingMinor),
                                color: stats.pendingMinor > 0
                                    ? AppColors.warning
                                    : textTertiary,
                                surface: surface),
                            const SizedBox(width: 10),
                            _StatCard(
                                label: 'YTD TOTAL',
                                value: _fmt(stats.ytdMinor),
                                color: AppColors.royalBlue,
                                surface: surface),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Split panel
                  Expanded(
                    child: Row(
                      children: [
                        // Left: stream list
                        SizedBox(
                          width: listPanelWidth(context),
                          child: Container(
                            color: bg,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Row(
                                    children: [
                                      Text('Streams',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textSecondary)),
                                      const Spacer(),
                                      Text('${streams.length} total',
                                          style: TextStyle(
                                              fontSize: 11, color: textTertiary)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: streams.isEmpty
                                      ? Center(
                                          child: Text('No income streams yet.',
                                              style: TextStyle(
                                                  fontSize: 13, color: textTertiary)))
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          itemCount: streams.length,
                                          itemBuilder: (context, i) {
                                            final stream = streams[i];
                                            return IncomeStreamTile(
                                              stream: stream,
                                              receivedMinor: receivedByStream[stream.id] ?? 0,
                                              isSelected: stream.id == selectedStreamId,
                                              onTap: () => cubit.selectStream(
                                                  stream.id == selectedStreamId
                                                      ? null
                                                      : stream.id),
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
                          child: selectedStream == null
                              ? Center(
                                  child: Text(
                                    streams.isEmpty
                                        ? 'Add an income stream to get started.'
                                        : 'Select a stream to view details.',
                                    style: TextStyle(
                                        fontSize: 13, color: textTertiary),
                                  ),
                                )
                              : IncomeDetailPanel(
                                  stream: selectedStream,
                                  receivedMinor: receivedByStream[selectedStream.id] ?? 0,
                                  sparkline: sparkline,
                                  paymentHistory: paymentHistory,
                                  incomeAccounts: incomeAccounts,
                                  period: period,
                                  onEdit: () => showIncomeStreamDialog(
                                    context: context,
                                    accounts: incomeAccounts,
                                    existing: selectedStream,
                                    onSave: cubit.updateStream,
                                  ),
                                  onMarkReceived: (amount, note) =>
                                      cubit.markReceived(
                                        stream: selectedStream,
                                        amountMinor: amount,
                                        note: note,
                                      ),
                                  onToggleActive: () => cubit.updateStream(
                                    IncomeStreamExt(selectedStream)
                                        .withActive(!selectedStream.isActive),
                                  ),
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

  String _periodLabel(String period) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final parts = period.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

extension IncomeStreamExt on IncomeStream {
  IncomeStream withActive(bool active) => IncomeStream(
        id: id,
        name: name,
        type: type,
        accountId: accountId,
        frequency: frequency,
        paymentMode: paymentMode,
        amountMinor: amountMinor,
        reliableAmountMinor: reliableAmountMinor,
        currency: currency,
        isActive: active,
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
        ),
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
            BlurredAmount(
                text: value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ],
        ),
      ),
    );
  }
}

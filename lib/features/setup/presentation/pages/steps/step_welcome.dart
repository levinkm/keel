import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/sync/sync_service.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class StepWelcome extends StatefulWidget {
  const StepWelcome({super.key});

  @override
  State<StepWelcome> createState() => _StepWelcomeState();
}

class _StepWelcomeState extends State<StepWelcome> {
  bool _checkingCloud = true;
  bool _hasCloudData = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _checkCloud();
  }

  Future<void> _checkCloud() async {
    final has = await SyncService.instance.hasRemoteData();
    if (mounted) setState(() { _checkingCloud = false; _hasCloudData = has; });
  }

  Future<void> _restore(BuildContext context) async {
    setState(() => _restoring = true);
    try {
      await SyncService.instance.restore();
      if (context.mounted) context.read<SetupCubit>().skipToStep(SetupStep.done);
    } catch (e) {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SetupStepShell(
      title: 'Welcome to Keel',
      subtitle: 'Your personal ledger — every shilling tracked, every plan grounded in real numbers.',
      onNext: () => context.read<SetupCubit>().nextStep(),
      nextLabel: 'Get started',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cloud restore banner — shown only when remote data exists
          if (!_checkingCloud && _hasCloudData) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.infoSurfaceDark : AppColors.infoSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined,
                      size: 20, color: AppColors.royalBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cloud backup found',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Restore your previous data instead of starting fresh.',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _restoring ? null : () => _restore(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: _restoring
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Restore'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 8),
          ..._features(isDark).map((f) => _FeatureTile(
                icon: f.$1,
                title: f.$2,
                description: f.$3,
                isDark: isDark,
              )),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.slateBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Everything stays on your device. No account required. Sync is optional and added later.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<(IconData, String, String)> _features(bool isDark) => [
        (Icons.menu_book_outlined, 'Double-entry ledger', 'Every transaction balances. Net worth, loan balances and cash flow fall out of the data automatically.'),
        (Icons.pie_chart_outline, 'Strategy engine', 'Choose 50/30/20, Commitments first, Kakeibo or build your own. Strategies are data, not code.'),
        (Icons.trending_up_outlined, 'Projections', 'See where you will stand in 1, 5 or 10 years — with scenarios, stress tests and assumptions shown clearly.'),
        (Icons.credit_card_outlined, 'Loan tracking', 'Real amortization schedules, prepayment what-ifs and a settlement quote on demand.'),
      ];
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.royalBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

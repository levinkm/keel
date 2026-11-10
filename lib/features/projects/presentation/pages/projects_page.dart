import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/presentation/bloc/projects_cubit.dart';
import 'package:keel/features/projects/presentation/widgets/project_detail_panel.dart';
import 'package:keel/features/projects/presentation/widgets/project_dialog.dart';
import 'package:keel/features/projects/presentation/widgets/project_list_tile.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProjectsCubit>()..load(),
      child: const _ProjectsView(),
    );
  }
}

class _ProjectsView extends StatefulWidget {
  const _ProjectsView();

  @override
  State<_ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<_ProjectsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ProjectsCubit>().load();
    }
  }
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectsCubit, ProjectsState>(
      listenWhen: (_, current) => current.maybeMap(
          loaded: (s) => s.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error =
            state.maybeMap(loaded: (s) => s.validationError, orElse: () => null);
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
        context.read<ProjectsCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 4),
          error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (projects, summaries, filter, selectedProjectId,
              selectedEntries, accounts, totalBudgeted, totalSpent,
              totalRevenue, activeCount, _) {
            final cubit = context.read<ProjectsCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg =
                isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface =
                isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary =
                isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;
            final textTertiary = isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary;
            final divider =
                isDark ? AppColors.darkBorder : AppColors.lightBorder;

            final filtered = projects.where((p) => switch (filter) {
                  ProjectFilter.active => p.status == ProjectStatus.active ||
                      p.status == ProjectStatus.planning,
                  ProjectFilter.capital => p.type == ProjectType.capital,
                  ProjectFilter.revenue => p.type == ProjectType.revenue,
                  ProjectFilter.completed =>
                    p.status == ProjectStatus.completed ||
                        p.status == ProjectStatus.cancelled,
                  ProjectFilter.all => true,
                }).toList();

            final selectedProject = selectedProjectId == null
                ? null
                : projects.cast<Project?>().firstWhere(
                    (p) => p?.id == selectedProjectId,
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
                            Text('Projects',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.refresh, size: 18, color: textSecondary),
                              onPressed: cubit.load,
                              tooltip: 'Refresh',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => showProjectDialog(
                                context: context,
                                accounts: accounts,
                                onSave: cubit.createProject,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('New project'),
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
                              label: 'ACTIVE',
                              value: '$activeCount',
                              color: activeCount > 0
                                  ? AppColors.royalBlue
                                  : textTertiary,
                              surface: surface,
                              icon: Icons.rocket_launch_outlined,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL BUDGETED',
                              value: _fmt(totalBudgeted),
                              color: textPrimary,
                              surface: surface,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL SPENT',
                              value: _fmt(totalSpent),
                              color: totalSpent > totalBudgeted
                                  ? AppColors.error
                                  : textPrimary,
                              surface: surface,
                              icon: Icons.payments_outlined,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL REVENUE',
                              value: _fmt(totalRevenue),
                              color: totalRevenue > 0
                                  ? AppColors.success
                                  : textTertiary,
                              surface: surface,
                              icon: Icons.trending_up_outlined,
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
                        // Left: project list
                        SizedBox(
                          width: listPanelWidth(context),
                          child: Container(
                            color: bg,
                            child: Column(
                              children: [
                                // Filter tabs
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children:
                                          ProjectFilter.values.map((f) {
                                        final isActive = f == filter;
                                        return GestureDetector(
                                          onTap: () => cubit.setFilter(f),
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                right: 6),
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
                                ),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No ${_filterLabel(filter).toLowerCase()} projects.',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: textTertiary),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: filtered.length,
                                          itemBuilder: (_, i) {
                                            final p = filtered[i];
                                            return ProjectListTile(
                                              project: p,
                                              summary: summaries[p.id]!,
                                              isSelected:
                                                  p.id == selectedProjectId,
                                              onTap: () =>
                                                  cubit.selectProject(
                                                      p.id == selectedProjectId
                                                          ? null
                                                          : p.id),
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
                          child: selectedProject == null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.folder_open_outlined,
                                          size: 40, color: textTertiary),
                                      const SizedBox(height: 12),
                                      Text(
                                        projects.isEmpty
                                            ? 'Create your first project to get started.'
                                            : 'Select a project to view details.',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary),
                                      ),
                                    ],
                                  ),
                                )
                              : ProjectDetailPanel(
                                  project: selectedProject,
                                  summary: summaries[selectedProject.id]!,
                                  entries: selectedEntries,
                                  accounts: accounts,
                                  onEdit: () => showProjectDialog(
                                    context: context,
                                    accounts: accounts,
                                    existing: selectedProject,
                                    onSave: cubit.updateProject,
                                  ),
                                  onSetStatus: (status) =>
                                      cubit.setStatus(selectedProject, status),
                                  onUntagEntry: (entryId) => cubit.untagEntry(
                                      selectedProject.id, entryId),
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

  String _filterLabel(ProjectFilter f) => switch (f) {
        ProjectFilter.all => 'All',
        ProjectFilter.active => 'Active',
        ProjectFilter.capital => 'Capital',
        ProjectFilter.revenue => 'Revenue',
        ProjectFilter.completed => 'Completed',
      };

  static String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
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

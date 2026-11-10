import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/responsive.dart';

// ── Animated shimmer base ─────────────────────────────────────────────────────

class _ShimmerBase extends StatefulWidget {
  final Widget child;
  const _ShimmerBase({required this.child});

  @override
  State<_ShimmerBase> createState() => _ShimmerBaseState();
}

class _ShimmerBaseState extends State<_ShimmerBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => _ShimmerScope(progress: _anim.value, child: child!),
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final double progress;
  const _ShimmerScope({required this.progress, required super.child});

  static _ShimmerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.progress != progress;
}

// ── Single shimmer box ────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final highlight = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final scope = _ShimmerScope.of(context);
    final progress = scope?.progress ?? 0.5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [base, highlight, base],
          transform: _SlideTransform(progress),
        ),
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  final double progress;
  const _SlideTransform(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * progress, 0, 0);
  }
}

// ── Page-level shimmer skeletons ──────────────────────────────────────────────

/// Master/detail layout: title bar + N stat cards + list panel + detail panel.
class MasterDetailShimmer extends StatelessWidget {
  final int statCardCount;
  final int listItemCount;

  const MasterDetailShimmer({
    super.key,
    this.statCardCount = 4,
    this.listItemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return _ShimmerBase(
      child: Container(
        color: bg,
        padding: const EdgeInsets.only(top: kTitleBarHeight),
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 140, height: 22, radius: 6),
                      const Spacer(),
                      ShimmerBox(width: 110, height: 34, radius: 8),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stat cards
                  Row(
                    children: [
                      for (int i = 0; i < statCardCount; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 68,
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                ShimmerBox(width: 80, height: 10, radius: 4),
                                SizedBox(height: 8),
                                ShimmerBox(width: 100, height: 16, radius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                  // Left list
                  SizedBox(
                    width: listPanelWidth(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          for (int i = 0; i < listItemCount; i++) ...[
                            if (i > 0) const SizedBox(height: 6),
                            Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  ShimmerBox(
                                      width: 36, height: 36, radius: 8),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        ShimmerBox(
                                            width: 120, height: 12, radius: 4),
                                        SizedBox(height: 6),
                                        ShimmerBox(
                                            width: 80, height: 10, radius: 4),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      ShimmerBox(
                                          width: 70, height: 12, radius: 4),
                                      SizedBox(height: 6),
                                      ShimmerBox(
                                          width: 50, height: 10, radius: 4),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: divider),
                  // Right detail placeholder
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerBox(width: 200, height: 22, radius: 6),
                          const SizedBox(height: 12),
                          const ShimmerBox(height: 120, radius: 10),
                          const SizedBox(height: 12),
                          const ShimmerBox(height: 80, radius: 10),
                          const SizedBox(height: 12),
                          const ShimmerBox(height: 80, radius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard shimmer: hero card + metric cards row + two bottom cards.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return _ShimmerBase(
      child: Container(
        color: bg,
        padding: const EdgeInsets.only(top: kTitleBarHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 160, height: 22, radius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 100, height: 13, radius: 4),
                    ],
                  ),
                  const Spacer(),
                  const ShimmerBox(width: 70, height: 14, radius: 4),
                ],
              ),
              const SizedBox(height: 20),
              // Hero card
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 80, height: 11, radius: 4),
                          SizedBox(height: 10),
                          ShimmerBox(width: 200, height: 32, radius: 6),
                          SizedBox(height: 10),
                          ShimmerBox(width: 160, height: 12, radius: 4),
                          SizedBox(height: 16),
                          ShimmerBox(height: 24, radius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 100, height: 10, radius: 4),
                          SizedBox(height: 8),
                          Expanded(child: ShimmerBox(radius: 6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Metric cards
              Row(
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 80, height: 10, radius: 4),
                            SizedBox(height: 10),
                            ShimmerBox(width: 90, height: 17, radius: 4),
                            SizedBox(height: 6),
                            ShimmerBox(width: 60, height: 10, radius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Bottom row
              Row(
                children: [
                  Expanded(
                    child: ShimmerBox(height: 200, radius: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShimmerBox(height: 200, radius: 12),
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

/// Net worth shimmer: headline card + allocation bar + 3-column section cards.
class NetWorthShimmer extends StatelessWidget {
  const NetWorthShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return _ShimmerBase(
      child: Container(
        color: bg,
        padding: const EdgeInsets.only(top: kTitleBarHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 120, height: 22, radius: 6),
              const SizedBox(height: 20),
              Container(
                height: 160,
                decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 100, height: 12, radius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 240, height: 36, radius: 6),
                    SizedBox(height: 16),
                    ShimmerBox(height: 8, radius: 4),
                    SizedBox(height: 16),
                    ShimmerBox(height: 14, radius: 4),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ShimmerBox(height: 70, radius: 12),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 220, radius: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Budget shimmer: period list + detail panel.
class BudgetShimmer extends StatelessWidget {
  /// Set [padTitleBar] to false when already inside a PageShell.
  final bool padTitleBar;
  const BudgetShimmer({super.key, this.padTitleBar = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return _ShimmerBase(
      child: Container(
        color: bg,
        padding: EdgeInsets.only(top: padTitleBar ? kTitleBarHeight : 0),
        child: Row(
          children: [
            // Period list
            SizedBox(
              width: listPanelWidth(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  children: [
                    for (int i = 0; i < 8; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: const ShimmerBox(width: 100, height: 14, radius: 4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            VerticalDivider(width: 1, color: divider),
            // Detail
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 180, height: 22, radius: 6),
                    const SizedBox(height: 16),
                    for (int i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      ShimmerBox(height: 52, radius: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight shimmer for use inside an already-laid-out panel
/// (e.g. settings detail pane, reports content area).
class PanelShimmer extends StatelessWidget {
  final int rowCount;
  const PanelShimmer({super.key, this.rowCount = 6});

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 180, height: 20, radius: 6),
            const SizedBox(height: 20),
            for (int i = 0; i < rowCount; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              ShimmerBox(height: 48, radius: 8),
            ],
          ],
        ),
      ),
    );
  }
}

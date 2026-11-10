import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keel/core/shortcuts/shortcut_service.dart';
import 'package:keel/core/theme/app_colors.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}

const _navItems = [
  _NavItem('Dashboard', Iconsax.element_4, '/dashboard'),
  _NavItem('Net Worth', Iconsax.chart_square, '/net-worth'),
  _NavItem('Budget', Iconsax.chart_2, '/budget'),
  _NavItem('Transactions', Iconsax.receipt_text, '/transactions'),
  _NavItem('Accounts', Iconsax.wallet, '/accounts'),
  _NavItem('Income', Iconsax.money_recive, '/income'),
  _NavItem('Loans', Iconsax.money_send, '/loans'),
  _NavItem('Projects', Iconsax.folder_open, '/projects'),
  _NavItem('Assets', Iconsax.home_2, '/assets'),
  _NavItem('Investments', Iconsax.chart_1, '/investments'),
  _NavItem('Projections', Iconsax.trend_up, '/projections'),
  _NavItem('Reports', Iconsax.presention_chart, '/reports'),
  _NavItem('Settings', Iconsax.setting_2, '/settings'),
];

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final active = _navItems.indexWhere((i) => location.startsWith(i.path));

    void goTo(String path) => context.go(path);
    void goIndex(int i) => goTo(_navItems[i].path);
    void goPrev() => goIndex((active - 1).clamp(0, _navItems.length - 2));
    void goNext() => goIndex((active + 1).clamp(0, _navItems.length - 2));

    // Map shortcut id → action
    final actions = <String, VoidCallback>{
      'nav_dashboard':    () => goIndex(0),
      'nav_networth':     () => goIndex(1),
      'nav_budget':       () => goIndex(2),
      'nav_transactions': () => goIndex(3),
      'nav_accounts':     () => goIndex(4),
      'nav_income':       () => goIndex(5),
      'nav_loans':        () => goIndex(6),
      'nav_projects':     () => goIndex(7),
      'nav_assets':       () => goIndex(8),
      'nav_prev':         goPrev,
      'nav_next':         goNext,
      'go_transactions':  () => goTo('/transactions'),
      'go_budget':        () => goTo('/budget'),
      'go_loans':         () => goTo('/loans'),
      'go_reports':       () => goTo('/reports'),
      'go_projections':   () => goTo('/projections'),
      'go_settings':      () => goTo('/settings'),
    };

    return Scaffold(
      body: ValueListenableBuilder<List<ShortcutDef>>(
        valueListenable: ShortcutService.instance.shortcuts,
        builder: (context, defs, _) {
          final bindings = <ShortcutActivator, VoidCallback>{};
          for (final def in defs) {
            final action = actions[def.id];
            if (action != null) bindings[def.activator] = action;
          }
          return CallbackShortcuts(
            bindings: bindings,
            child: Focus(
              autofocus: true,
              child: Builder(
                builder: (context) {
                  final topInset = MediaQuery.of(context).padding.top;
                  return Stack(
                    children: [
                      Positioned.fill(left: 68, top: topInset, child: child),
                      Positioned(
                        left: 12, top: topInset, bottom: 0,
                        child: Center(
                          child: _FloatingDock(
                            items: _navItems,
                            activeIndex: active < 0 ? 0 : active,
                            onTap: (i) => context.go(_navItems[i].path),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingDock extends StatelessWidget {
  final List<_NavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _FloatingDock({
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewportHeight = MediaQuery.sizeOf(context).height;

    final bgColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.96)
        : AppColors.lightSurface.withValues(alpha: 0.96);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      constraints: BoxConstraints(maxHeight: viewportHeight - 48),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Image.asset(
                'assets/png/logos/keel_icon_1024.png',
                width: 28,
                height: 28,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 4),
            ...List.generate(items.length, (i) {
              final isSeparatorBefore = i == items.length - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSeparatorBefore) const SizedBox(height: 8),
                  _DockItem(
                    item: items[i],
                    isActive: i == activeIndex,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _DockItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive
        ? AppColors.royalBlue
        : _hovered
            ? (widget.isDark ? AppColors.darkText : AppColors.lightText)
            : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Tooltip(
      message: widget.item.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      textStyle: TextStyle(
        fontSize: 12,
        color: widget.isDark ? AppColors.darkText : AppColors.lightTextInverse,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: _hovered && !widget.isActive
                  ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Icon(widget.item.icon, size: 22, color: iconColor),
                ),
                if (widget.isActive)
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.royalBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

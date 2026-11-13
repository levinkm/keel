import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:keel/core/auth/auth_service.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/shortcuts/shortcut_service.dart';
import 'package:keel/core/sync/sync_service.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';
import 'package:keel/features/tariffs/domain/entities/tariff.dart';
import 'package:keel/features/tariffs/domain/repositories/tariff_repository.dart';
import 'package:keel/features/tariffs/domain/tariff_csv_importer.dart';
import 'package:keel/features/tariffs/presentation/tariff_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Section { profile, appearance, security, data, shortcuts, tariffs, about }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _Section _active = _Section.profile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>()..load(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground;
          final surface = isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface;
          final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
          final textSecondary = isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary;
          final textTertiary = isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary;
          final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

          final settings = state.maybeMap(
            loaded: (s) => s.settings,
            orElse: () => <String, String>{},
          );
          final stats = state.maybeMap(
            loaded: (s) => s.stats,
            orElse: () => null,
          );
          final cubit = state.maybeMap(
            loaded: (_) => context.read<SettingsCubit>(),
            orElse: () => null,
          );

          return Container(
            color: bg,
            padding: const EdgeInsets.only(top: kTitleBarHeight),
            child: Row(
              children: [
                // ── Left nav ─────────────────────────────────────────────────
                SizedBox(
                  width: 220,
                  child: Container(
                    color: bg,
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._Section.values.map(
                          (s) => _NavItem(
                            label: _label(s),
                            icon: _icon(s),
                            isActive: s == _active,
                            isDark: isDark,
                            onTap: () => setState(() => _active = s),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                VerticalDivider(width: 1, color: divider),

                // ── Right content ─────────────────────────────────────────────
                Expanded(
                  child: state.when(
                    initial: () => const SizedBox.shrink(),
                    loading: () => const PanelShimmer(),
                    error: (msg) => Center(
                      child: Text(
                        msg,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    loaded: (s, dbStats) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                      child: _buildSection(
                        context,
                        _active,
                        settings,
                        stats,
                        cubit!,
                        isDark,
                        surface,
                        textPrimary,
                        textSecondary,
                        textTertiary,
                        divider,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext ctx,
    _Section section,
    Map<String, String> settings,
    DbStats? stats,
    SettingsCubit cubit,
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
    Color divider,
  ) {
    return switch (section) {
      _Section.profile => _ProfileSection(
        settings: settings,
        cubit: cubit,
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
      _Section.appearance => _AppearanceSection(
        settings: settings,
        cubit: cubit,
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
      _Section.security => _SecuritySection(
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
      _Section.data => _DataSection(
        stats: stats,
        cubit: cubit,
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
      _Section.shortcuts => _ShortcutsSection(
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
      _Section.tariffs => _TariffsSection(
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
      _Section.about => _AboutSection(
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        divider: divider,
      ),
    };
  }

  String _label(_Section s) => switch (s) {
    _Section.profile => 'Profile',
    _Section.appearance => 'Appearance',
    _Section.security => 'Security & Privacy',
    _Section.data => 'Data & Storage',
    _Section.shortcuts => 'Keyboard Shortcuts',
    _Section.tariffs => 'Transaction Fees',
    _Section.about => 'About',
  };

  IconData _icon(_Section s) => switch (s) {
    _Section.profile => Icons.person_outline,
    _Section.appearance => Icons.palette_outlined,
    _Section.security => Icons.shield_outlined,
    _Section.data => Icons.storage_outlined,
    _Section.shortcuts => Icons.keyboard_outlined,
    _Section.tariffs => Icons.receipt_long_outlined,
    _Section.about => Icons.info_outline,
  };
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive, isDark;
  final VoidCallback onTap;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.royalBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.royalBlue : inactive,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.royalBlue : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile section ───────────────────────────────────────────────────────────

class _ProfileSection extends StatefulWidget {
  final Map<String, String> settings;
  final SettingsCubit cubit;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _ProfileSection({
    required this.settings,
    required this.cubit,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });
  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.settings['displayName'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fieldBg = widget.isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final currency = widget.settings['currency'] ?? 'KES';
    final fiscalStart = widget.settings['fiscalYearStart'] ?? '1';
    final dateFormat = widget.settings['dateFormat'] ?? 'dd MMM yyyy';
    final avatarUrl = SyncService.instance.googleAvatarUrl;
    final googleName = SyncService.instance.googleDisplayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Profile', widget.textPrimary),
        const SizedBox(height: 20),
        // Google account card — shown when signed in
        if (SyncService.instance.isSignedIn) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar
                ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _InitialsAvatar(name: googleName ?? 'U'),
                        )
                      : _InitialsAvatar(name: googleName ?? 'U'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        googleName ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.textPrimary,
                        ),
                      ),
                      Text(
                        SyncService.instance.currentUser.value?.email ?? '',
                        style: TextStyle(
                            fontSize: 12, color: widget.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Google',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.royalBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _card(widget.surface, [
          _row(
            label: 'Display name',
            sub: 'Shown in dashboard greetings',
            trailing: SizedBox(
              width: 200,
              child: CupertinoTextField(
                controller: _nameCtrl,
                placeholder: 'Your name',
                onSubmitted: (v) => widget.cubit.set('displayName', v.trim()),
                style: TextStyle(fontSize: 13, color: widget.textPrimary),
                placeholderStyle: TextStyle(
                  fontSize: 13,
                  color: widget.textTertiary,
                ),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
              ),
            ),
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            divider: widget.divider,
            isLast: false,
          ),
          _row(
            label: 'Default currency',
            sub: 'Used across all monetary values',
            trailing: _Dropdown<String>(
              value: currency,
              items: const [
                'KES',
                'USD',
                'EUR',
                'GBP',
                'UGX',
                'TZS',
                'ETB',
                'ZAR',
                'NGN',
                'GHS',
              ],
              isDark: widget.isDark,
              onChanged: (v) => widget.cubit.set('currency', v),
            ),
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            divider: widget.divider,
            isLast: false,
          ),
          _row(
            label: 'Fiscal year start',
            sub: 'Month your financial year begins',
            trailing: _Dropdown<String>(
              value: fiscalStart,
              items: const [
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '10',
                '11',
                '12',
              ],
              labels: const [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December',
              ],
              isDark: widget.isDark,
              onChanged: (v) => widget.cubit.set('fiscalYearStart', v),
            ),
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            divider: widget.divider,
            isLast: false,
          ),
          _row(
            label: 'Date format',
            sub: 'How dates are displayed throughout the app',
            trailing: _Dropdown<String>(
              value: dateFormat,
              items: const [
                'dd MMM yyyy',
                'MM/dd/yyyy',
                'dd/MM/yyyy',
                'yyyy-MM-dd',
              ],
              isDark: widget.isDark,
              onChanged: (v) => widget.cubit.set('dateFormat', v),
            ),
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            divider: widget.divider,
            isLast: true,
          ),
        ]),
      ],
    );
  }
}

// ── Appearance section ────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final Map<String, String> settings;
  final SettingsCubit cubit;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _AppearanceSection({
    required this.settings,
    required this.cubit,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final themeValue = settings['themeMode'] ?? 'system';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appearance', textPrimary),
        const SizedBox(height: 20),

        // Theme
        _card(surface, [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Controls the colour scheme of the entire app',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ThemeCard(
                      label: 'Light',
                      icon: Icons.light_mode_outlined,
                      isSelected: themeValue == 'light',
                      isDark: isDark,
                      onTap: () => cubit.setTheme(ThemeMode.light),
                    ),
                    const SizedBox(width: 10),
                    _ThemeCard(
                      label: 'Dark',
                      icon: Icons.dark_mode_outlined,
                      isSelected: themeValue == 'dark',
                      isDark: isDark,
                      onTap: () => cubit.setTheme(ThemeMode.dark),
                    ),
                    const SizedBox(width: 10),
                    _ThemeCard(
                      label: 'System',
                      icon: Icons.brightness_auto_outlined,
                      isSelected: themeValue == 'system',
                      isDark: isDark,
                      onTap: () => cubit.setTheme(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Number format
        _card(surface, [
          _row(
            label: 'Number format',
            sub: 'How large numbers are displayed',
            trailing: _Dropdown<String>(
              value: settings['numberFormat'] ?? 'compact',
              items: const ['compact', 'full'],
              labels: const ['Compact (1.2M)', 'Full (1,200,000)'],
              isDark: isDark,
              onChanged: (v) => cubit.set('numberFormat', v),
            ),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            divider: divider,
            isLast: true,
          ),
        ]),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected, isDark;
  final VoidCallback onTap;
  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fieldBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final inactive = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalBlue.withValues(alpha: 0.1)
              : fieldBg,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.royalBlue.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.royalBlue : inactive,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.royalBlue : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Security & Privacy section ───────────────────────────────────────────────

class _SecuritySection extends StatefulWidget {
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _SecuritySection({
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });
  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    AuthService.instance.isBiometricAvailable().then(
      (v) => setState(() => _biometricAvailable = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Security & Privacy', widget.textPrimary),
        const SizedBox(height: 20),

        _sectionLabel('AUTHENTICATION', widget.textTertiary),
        const SizedBox(height: 10),
        _card(widget.surface, [
          _row(
            label: 'Require Touch ID on launch',
            sub: _biometricAvailable
                ? 'Lock Keel when the app is hidden or the window loses focus'
                : 'Touch ID is not available on this device',
            trailing: ValueListenableBuilder<bool>(
              valueListenable: AuthService.instance.biometricEnabled,
              builder: (_, enabled, _) => CupertinoSwitch(
                value: enabled,
                activeTrackColor: AppColors.royalBlue,
                onChanged: _biometricAvailable
                    ? (v) async {
                        if (v) {
                          // Verify once before enabling
                          final ok = await AuthService.instance.authenticate(
                            reason:
                                'Confirm your identity to enable Touch ID lock',
                          );
                          if (ok) {
                            await AuthService.instance.setBiometricEnabled(
                              true,
                            );
                          }
                        } else {
                          await AuthService.instance.setBiometricEnabled(false);
                        }
                      }
                    : null,
              ),
            ),
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            divider: widget.divider,
            isLast: true,
          ),
        ]),
        const SizedBox(height: 20),

        _sectionLabel('PRIVACY', widget.textTertiary),
        const SizedBox(height: 10),
        _card(widget.surface, [
          _row(
            label: 'Privacy mode',
            sub:
                'Blur all monetary values. Hover over any amount to reveal it.',
            trailing: ValueListenableBuilder<bool>(
              valueListenable: AuthService.instance.privacyMode,
              builder: (_, enabled, _) => CupertinoSwitch(
                value: enabled,
                activeTrackColor: AppColors.royalBlue,
                onChanged: (v) => AuthService.instance.setPrivacyMode(v),
              ),
            ),
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            divider: widget.divider,
            isLast: true,
          ),
        ]),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.infoSurfaceDark
                : AppColors.infoSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.royalBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Privacy mode blurs amounts across all pages. '
                  'Hover over any value to temporarily reveal it. '
                  'Touch ID lock re-engages automatically when Keel is hidden.',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Data & Storage section ────────────────────────────────────────────────────

class _DataSection extends StatelessWidget {
  final DbStats? stats;
  final SettingsCubit cubit;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _DataSection({
    required this.stats,
    required this.cubit,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Data & Storage', textPrimary),
        const SizedBox(height: 20),

        // Database statistics
        if (stats != null) ...[
          _sectionLabel('DATABASE STATISTICS', textTertiary),
          const SizedBox(height: 10),
          _card(surface, [
            _statRow(
              'Accounts',
              '${stats!.accounts}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Transactions',
              '${stats!.transactions}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Income streams',
              '${stats!.incomeStreams}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Loans',
              '${stats!.loans}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Assets',
              '${stats!.assets}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Investments',
              '${stats!.holdings}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Contacts',
              '${stats!.contacts}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Projects',
              '${stats!.projects}',
              textPrimary,
              textSecondary,
              divider,
              false,
            ),
            _statRow(
              'Database size',
              _fmtBytes(stats!.dbSizeBytes),
              AppColors.royalBlue,
              textSecondary,
              divider,
              true,
            ),
          ]),
          const SizedBox(height: 20),
        ],

        // Backup & Export
        _sectionLabel('BACKUP & EXPORT', textTertiary),
        const SizedBox(height: 10),
        _card(surface, [
          _actionRow(
            icon: Icons.save_outlined,
            label: 'Backup database',
            sub: 'Save a copy of the SQLite database file to your Mac',
            color: AppColors.royalBlue,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () async {
              final path = await cubit.exportDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      path != null
                          ? 'Backup saved to $path'
                          : 'Backup cancelled',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: path != null
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
          ),
        ]),
        const SizedBox(height: 20),

        // Cloud Backup
        _sectionLabel('CLOUD BACKUP', textTertiary),
        const SizedBox(height: 10),
        _CloudBackupCard(
          isDark: isDark,
          surface: surface,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textTertiary: textTertiary,
          divider: divider,
        ),
        const SizedBox(height: 20),

        // Privacy notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.infoSurfaceDark : AppColors.infoSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.royalBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your data stays on your device',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All financial data is stored locally in a SQLite database on this Mac. '
                      'Nothing is sent to any server. Backups are your responsibility.',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Danger zone
        _sectionLabel('DANGER ZONE', AppColors.error),
        const SizedBox(height: 10),
        _card(surface, [
          _actionRow(
            icon: Icons.restart_alt_outlined,
            label: 'Reset settings',
            sub: 'Restore display name, currency, theme and date format to defaults. Financial data is not affected.',
            color: AppColors.error,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _confirmReset(context),
          ),
        ]),
      ],
    );
  }

  void _confirmReset(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset settings?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This resets display name, currency, theme, fiscal year start, '
                  'and date format. Your financial data is not affected.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        cubit.resetSettings();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reset'),
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

  Widget _statRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
    Color divider,
    bool isLast,
  ) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
      if (!isLast)
        Divider(
          height: 1,
          color: divider.withValues(alpha: 0.5),
          indent: 16,
          endIndent: 16,
        ),
    ],
  );

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

// ── Cloud Backup card ────────────────────────────────────────────────────────

class _CloudBackupCard extends StatefulWidget {
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _CloudBackupCard({
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });
  @override
  State<_CloudBackupCard> createState() => _CloudBackupCardState();
}

class _CloudBackupCardState extends State<_CloudBackupCard> {
  String? _message;
  bool _isError = false;
  int _intervalMinutes = SyncService.defaultIntervalMinutes;

  @override
  void initState() {
    super.initState();
    SyncService.instance.getSyncIntervalMinutes()
        .then((v) => setState(() => _intervalMinutes = v));
  }
  Future<void> _backup() async {
    setState(() {
      _message = null;
      _isError = false;
    });
    try {
      final result = await SyncService.instance.sync();
      if (result.hasError) {
        setState(() { _message = result.error; _isError = true; });
      } else {
        final conflicts = result.conflicts > 0
            ? ' (${result.conflicts} conflict${result.conflicts == 1 ? '' : 's'} resolved)'
            : '';
        setState(() => _message =
            'Sync complete. ${result.pushed} pushed, ${result.pulled} pulled$conflicts.');
      }
    } catch (e) {
      setState(() {
        _message = 'Sync failed: $e';
        _isError = true;
      });
    }
  }

  Future<void> _restore(BuildContext context) async {
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restore from cloud?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will replace all local data with your cloud backup. '
                  'This cannot be undone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Restore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() {
      _message = null;
      _isError = false;
    });
    try {
      final result = await SyncService.instance.restore();
      if (result.hasError) {
        setState(() { _message = result.error; _isError = true; });
      } else {
        setState(
          () => _message = 'Restore complete. Restart the app to see your data.',
        );
      }
    } catch (e) {
      setState(() {
        _message = 'Restore failed: $e';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: SyncService.instance.currentUser,
      builder: (_, user, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: SyncService.instance.isEnabled,
          builder: (_, enabled, _) {
            return ValueListenableBuilder<SyncStatus>(
              valueListenable: SyncService.instance.syncStatus,
              builder: (_, status, _) {
                final isSyncing = status == SyncStatus.syncing;
                return ValueListenableBuilder<DateTime?>(
                  valueListenable: SyncService.instance.lastSyncAt,
                  builder: (_, lastSync, _) {
                    return _card(widget.surface, [
                      // Google sign-in / signed-in state
                      if (user == null)
                        _GoogleSignInRow(
                          isDark: widget.isDark,
                          surface: widget.surface,
                          textPrimary: widget.textPrimary,
                          textSecondary: widget.textSecondary,
                          divider: widget.divider,
                          isLast: !enabled,
                        )
                      else
                        _row(
                          label: 'Signed in as',
                          sub: SyncService.instance.googleDisplayName ??
                              user.email ??
                              'Google account',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (SyncService.instance.googleAvatarUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipOval(
                                    child: Image.network(
                                      SyncService.instance.googleAvatarUrl!,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              TextButton(
                                onPressed: () =>
                                    SyncService.instance.signOut(),
                                child: const Text('Sign out',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error)),
                              ),
                            ],
                          ),
                          textPrimary: widget.textPrimary,
                          textSecondary: widget.textSecondary,
                          divider: widget.divider,
                          isLast: !enabled,
                        ),
                      // Enable toggle — only shown when signed in
                      if (user != null)
                        _row(
                          label: 'Enable cloud sync',
                          sub: 'Automatically sync data across your devices.',
                          trailing: CupertinoSwitch(
                            value: enabled,
                            activeTrackColor: AppColors.royalBlue,
                            onChanged: (v) =>
                                SyncService.instance.setEnabled(v),
                          ),
                          textPrimary: widget.textPrimary,
                          textSecondary: widget.textSecondary,
                          divider: widget.divider,
                          isLast: !enabled,
                        ),
                      if (enabled) ...[
                    // Last synced
                    _row(
                      label: 'Last sync',
                      sub: lastSync != null
                          ? _fmtDateTime(lastSync)
                          : 'Never synced',
                      trailing: isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.royalBlue,
                              ),
                            )
                          : const SizedBox.shrink(),
                      textPrimary: widget.textPrimary,
                      textSecondary: widget.textSecondary,
                      divider: widget.divider,
                      isLast: false,
                    ),
                    // Auto-sync interval
                    _row(
                      label: 'Auto-sync every',
                      sub: 'How often Keel syncs in the background',
                      trailing: _Dropdown<int>(
                        value: _intervalMinutes,
                        items: const [5, 15, 30, 60],
                        labels: const ['5 minutes', '15 minutes', '30 minutes', '1 hour'],
                        isDark: widget.isDark,
                        onChanged: (v) {
                          setState(() => _intervalMinutes = v);
                          SyncService.instance.setSyncIntervalMinutes(v);
                        },
                      ),
                      textPrimary: widget.textPrimary,
                      textSecondary: widget.textSecondary,
                      divider: widget.divider,
                      isLast: false,
                    ),
                    // Sync now
                    _actionRow(
                      icon: Icons.sync_outlined,
                      label: 'Sync now',
                      sub: 'Push local changes and pull remote changes',
                      color: AppColors.royalBlue,
                      textPrimary: widget.textPrimary,
                      textSecondary: widget.textSecondary,
                      onTap: isSyncing ? () {} : _backup,
                    ),
                    // Restore
                    _actionRow(
                      icon: Icons.cloud_download_outlined,
                      label: 'Restore from cloud',
                      sub: 'Replace local data with your cloud backup',
                      color: AppColors.warning,
                      textPrimary: widget.textPrimary,
                      textSecondary: widget.textSecondary,
                      onTap: isSyncing ? () {} : () => _restore(context),
                    ),
                    // Status message
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isError
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ]);
              },
            );
          },
        );
      },
    );
  },
);
  }

  String _fmtDateTime(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Initials avatar fallback ────────────────────────────────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.royalBlue,
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Google sign-in row ────────────────────────────────────────────────────────────────────────────────────

class _GoogleSignInRow extends StatefulWidget {
  final bool isDark;
  final Color surface, textPrimary, textSecondary, divider;
  final bool isLast;
  const _GoogleSignInRow({
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.isLast,
  });
  @override
  State<_GoogleSignInRow> createState() => _GoogleSignInRowState();
}

class _GoogleSignInRowState extends State<_GoogleSignInRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in to enable sync',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your data is linked to your Google account '
                  'and accessible on all your devices.',
                  style: TextStyle(fontSize: 11, color: widget.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    await SyncService.instance.signInWithGoogle();
                    if (mounted) setState(() => _loading = false);
                  },
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.login, size: 16),
            label: Text(_loading ? 'Opening browser…' : 'Sign in with Google'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Keyboard shortcuts section ────────────────────────────────────────────────────────────────────────────────────

class _ShortcutsSection extends StatefulWidget {
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _ShortcutsSection({
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });
  @override
  State<_ShortcutsSection> createState() => _ShortcutsSectionState();
}

class _ShortcutsSectionState extends State<_ShortcutsSection> {
  String? _recording; // id of shortcut being recorded

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ShortcutDef>>(
      valueListenable: ShortcutService.instance.shortcuts,
      builder: (context, defs, _) {
        final groups = <String, List<ShortcutDef>>{};
        for (final d in defs) {
          groups.putIfAbsent(d.group, () => []).add(d);
        }
        final anyModified = defs.any((d) => d.isModified);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _header('Keyboard Shortcuts', widget.textPrimary),
                ),
                if (anyModified)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        await ShortcutService.instance.resetAll();
                        setState(() => _recording = null);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Reset all to defaults',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.royalBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Click a shortcut to record a new key combination.',
              style: TextStyle(fontSize: 12, color: widget.textTertiary),
            ),
            const SizedBox(height: 20),
            ...groups.entries.map(
              (entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(entry.key.toUpperCase(), widget.textTertiary),
                  const SizedBox(height: 10),
                  _card(
                    widget.surface,
                    entry.value.asMap().entries.map((e) {
                      final def = e.value;
                      final isLast = e.key == entry.value.length - 1;
                      final isRecording = _recording == def.id;
                      return Column(
                        children: [
                          _ShortcutRow(
                            def: def,
                            isRecording: isRecording,
                            isDark: widget.isDark,
                            textPrimary: widget.textPrimary,
                            textSecondary: widget.textSecondary,
                            textTertiary: widget.textTertiary,
                            onTap: () => setState(
                              () => _recording = isRecording ? null : def.id,
                            ),
                            onRecorded: (activator) async {
                              await ShortcutService.instance.update(
                                def.id,
                                activator,
                              );
                              setState(() => _recording = null);
                            },
                            onReset: () async {
                              await ShortcutService.instance.reset(def.id);
                              setState(() => _recording = null);
                            },
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: widget.divider.withValues(alpha: 0.5),
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShortcutRow extends StatefulWidget {
  final ShortcutDef def;
  final bool isRecording;
  final bool isDark;
  final Color textPrimary, textSecondary, textTertiary;
  final VoidCallback onTap;
  final ValueChanged<SingleActivator> onRecorded;
  final VoidCallback onReset;

  const _ShortcutRow({
    required this.def,
    required this.isRecording,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onTap,
    required this.onRecorded,
    required this.onReset,
  });

  @override
  State<_ShortcutRow> createState() => _ShortcutRowState();
}

class _ShortcutRowState extends State<_ShortcutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isRecording
        ? AppColors.royalBlue.withValues(alpha: 0.08)
        : _hovered
        ? (widget.isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02))
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: widget.isRecording
              ? _RecordingCapture(
                  onRecorded: widget.onRecorded,
                  onCancel: widget.onTap,
                  isDark: widget.isDark,
                  textPrimary: widget.textPrimary,
                  textTertiary: widget.textTertiary,
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.def.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.textPrimary,
                        ),
                      ),
                    ),
                    _KeyBadge(
                      label: widget.def.displayKey,
                      isDark: widget.isDark,
                      textPrimary: widget.textPrimary,
                      isModified: widget.def.isModified,
                    ),
                    if (widget.def.isModified) ...[
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onReset,
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            'reset',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.textTertiary,
                              decoration: TextDecoration.underline,
                              decorationColor: widget.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _RecordingCapture extends StatefulWidget {
  final ValueChanged<SingleActivator> onRecorded;
  final VoidCallback onCancel;
  final bool isDark;
  final Color textPrimary, textTertiary;
  const _RecordingCapture({
    required this.onRecorded,
    required this.onCancel,
    required this.isDark,
    required this.textPrimary,
    required this.textTertiary,
  });
  @override
  State<_RecordingCapture> createState() => _RecordingCaptureState();
}

class _RecordingCaptureState extends State<_RecordingCapture> {
  String _preview = 'Press a key combination…';

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return;
        }
        final modifiers = HardwareKeyboard.instance.logicalKeysPressed;
        final hasMeta =
            modifiers.contains(LogicalKeyboardKey.metaLeft) ||
            modifiers.contains(LogicalKeyboardKey.metaRight);
        final hasShift =
            modifiers.contains(LogicalKeyboardKey.shiftLeft) ||
            modifiers.contains(LogicalKeyboardKey.shiftRight);
        final hasAlt =
            modifiers.contains(LogicalKeyboardKey.altLeft) ||
            modifiers.contains(LogicalKeyboardKey.altRight);
        final hasCtrl =
            modifiers.contains(LogicalKeyboardKey.controlLeft) ||
            modifiers.contains(LogicalKeyboardKey.controlRight);

        final isModifierOnly = {
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.metaRight,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.shiftRight,
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.altRight,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlRight,
        }.contains(event.logicalKey);
        if (isModifierOnly) return;

        if (!hasMeta && !hasCtrl) {
          setState(() => _preview = 'Use ⌘ or ⌃ as a modifier');
          return;
        }

        final activator = SingleActivator(
          event.logicalKey,
          meta: hasMeta,
          shift: hasShift,
          alt: hasAlt,
          control: hasCtrl,
        );
        widget.onRecorded(activator);
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              _preview,
              style: TextStyle(
                fontSize: 13,
                color: _preview.startsWith('Use')
                    ? AppColors.error
                    : AppColors.royalBlue,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Text(
            'Esc to cancel',
            style: TextStyle(fontSize: 11, color: widget.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String label;
  final bool isDark, isModified;
  final Color textPrimary;
  const _KeyBadge({
    required this.label,
    required this.isDark,
    required this.textPrimary,
    required this.isModified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isModified
            ? AppColors.royalBlue.withValues(alpha: 0.1)
            : (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceSecondary),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isModified ? AppColors.royalBlue : textPrimary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
// ── About section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _AboutSection({
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('About', textPrimary),
        const SizedBox(height: 20),

        // Identity card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/png/logos/keel_icon_1024.png',
                    width: 64,
                    height: 64,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Image.asset(
                'assets/png/logos/keel_wordmark_1024.png',
                width: 80,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 4),
              Text(
                'Personal finance, clearly.',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Version 1.0.0 · DB v13',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.royalBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tech stack
        _sectionLabel('BUILT WITH', textTertiary),
        const SizedBox(height: 10),
        _card(surface, [
          _infoRow(
            'Framework',
            'Flutter 3.x + Dart',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'State management',
            'flutter_bloc + freezed',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Database',
            'SQLite via sqflite',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Navigation',
            'go_router',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Architecture',
            'Clean Architecture (domain/data/presentation)',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Storage',
            'Local only — no cloud, no telemetry',
            textPrimary,
            textSecondary,
            divider,
            true,
          ),
        ]),
        const SizedBox(height: 12),

        // Features summary
        _sectionLabel('FEATURES', textTertiary),
        const SizedBox(height: 10),
        _card(surface, [
          _infoRow(
            'Accounting',
            'Double-entry journal ledger',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Budgeting',
            'Strategy-based envelope budgeting',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Loans',
            'Full amortisation engine (3 methods)',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Investments',
            'FIFO gain/loss, lot tracking, income',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Assets',
            'Depreciation, insurance, documents',
            textPrimary,
            textSecondary,
            divider,
            false,
          ),
          _infoRow(
            'Projections',
            'Forward net worth modelling',
            textPrimary,
            textSecondary,
            divider,
            true,
          ),
        ]),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
    Color divider,
    bool isLast,
  ) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      if (!isLast)
        Divider(
          height: 1,
          color: divider.withValues(alpha: 0.5),
          indent: 16,
          endIndent: 16,
        ),
    ],
  );
}

// ── Tariffs section ──────────────────────────────────────────────────────────

class _TariffsSection extends StatefulWidget {
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _TariffsSection({
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });
  @override
  State<_TariffsSection> createState() => _TariffsSectionState();
}

class _TariffsSectionState extends State<_TariffsSection> {
  List<Tariff> _tariffs = [];
  List<Account> _accounts = [];
  bool _loading = true;

  TariffRepository get _repo => getIt<TariffRepository>();
  AccountsRepository get _accountsRepo => getIt<AccountsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tariffs = await _repo.getTariffs();
    final accounts = await _accountsRepo.getAccounts();
    setState(() {
      _tariffs = tariffs.fold((_) => [], (t) => t);
      _accounts = accounts.fold((_) => [], (a) => a);
      _loading = false;
    });
  }

  Future<void> _downloadTemplate() async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose folder with prompt "Save template to")'
      ]);
      if (result.exitCode != 0) return;
      final folder = (result.stdout as String).trim();
      if (folder.isEmpty) return;
      final path = '$folder/keel_tariff_template.csv';
      await File(path).writeAsString(TariffCsvImporter.templateExample);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Template saved to $path'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  Future<void> _importCsv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return;

    final String content;
    if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      final bytes = await file.readAsBytes();
      content = String.fromCharCodes(bytes);
    }

    final parsed = TariffCsvImporter.parse(content, _accounts);
    if (!mounted) return;
    _showImportResult(parsed);
  }

  void _showImportResult(TariffCsvImportResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 480,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Import preview',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '${result.tariffs.length} tariff rule${result.tariffs.length == 1 ? '' : 's'} parsed from ${result.rowsRead} rows.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                if (result.hasErrors) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: result.errors.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_outlined, size: 13, color: AppColors.error),
                            const SizedBox(width: 6),
                            Expanded(child: Text(e, style: const TextStyle(fontSize: 12, color: AppColors.error))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
                if (result.tariffs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...result.tariffs.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${t.provider} — ${t.operation.name} — ${t.tiers.length} tier${t.tiers.length == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 13, color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel', style: TextStyle(fontSize: 14, color: textSecondary)),
                    ),
                    if (result.tariffs.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        color: AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          for (final t in result.tariffs) {
                            await _repo.createTariff(t);
                          }
                          await _load();
                        },
                        child: Text(
                          'Import ${result.tariffs.length} rule${result.tariffs.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _accountName(String id) =>
      _accounts.cast<Account?>().firstWhere((a) => a?.id == id, orElse: () => null)?.name ?? id;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _header('Transaction Fees', widget.textPrimary)),
            OutlinedButton.icon(
              onPressed: _importCsv,
              icon: const Icon(Icons.upload_file_outlined, size: 15),
              label: const Text('Import CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.royalBlue,
                side: const BorderSide(color: AppColors.royalBlue),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => showTariffDialog(
                context: context,
                accounts: _accounts,
                existing: null,
                onSave: (t) async {
                  await _repo.createTariff(t);
                  await _load();
                },
              ),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Add rule'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Define fee schedules for each account. Fees are automatically computed and shown when recording transactions.',
          style: TextStyle(fontSize: 12, color: widget.textSecondary),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _downloadTemplate,
          child: Text(
            'Download CSV template',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.royalBlue,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.royalBlue,
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: CupertinoActivityIndicator())
        else if (_tariffs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 32, color: widget.textTertiary),
                const SizedBox(height: 10),
                Text('No tariff rules configured.',
                    style: TextStyle(fontSize: 13, color: widget.textSecondary)),
                const SizedBox(height: 4),
                Text('Add a rule to automatically compute fees when recording transactions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: widget.textTertiary)),
              ],
            ),
          )
        else
          _card(widget.surface, [
            ..._tariffs.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final isLast = i == _tariffs.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              size: 16, color: AppColors.royalBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(t.provider,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: widget.textPrimary)),
                                  const SizedBox(width: 8),
                                  _OperationBadge(t.operation),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_accountName(t.accountId)}  •  ${t.tiers.length} tier${t.tiers.length == 1 ? '' : 's'}'
                                '${t.taxRateBp > 0 ? '  •  ${(t.taxRateBp / 100).toStringAsFixed(1)}% excise' : ''}',
                                style: TextStyle(fontSize: 11, color: widget.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          onPressed: () => showTariffDialog(
                            context: context,
                            accounts: _accounts,
                            existing: t,
                            onSave: (updated) async {
                              await _repo.updateTariff(updated);
                              await _load();
                            },
                          ),
                          child: Text('Edit',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.royalBlue)),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          onPressed: () async {
                            await _repo.deleteTariff(t.id);
                            await _load();
                          },
                          child: const Text('Delete',
                              style: TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: widget.divider.withValues(alpha: 0.5),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ]),
      ],
    );
  }
}

class _OperationBadge extends StatelessWidget {
  final TariffOperation op;
  const _OperationBadge(this.op);

  @override
  Widget build(BuildContext context) {
    final label = switch (op) {
      TariffOperation.withdrawal => 'Withdraw',
      TariffOperation.transfer => 'Transfer',
      TariffOperation.deposit => 'Deposit',
    };
    final color = switch (op) {
      TariffOperation.withdrawal => AppColors.warning,
      TariffOperation.transfer => AppColors.royalBlue,
      TariffOperation.deposit => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _header(String title, Color color) => Text(
  title,
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.3,
  ),
);

Widget _sectionLabel(String text, Color color) => Text(
  text,
  style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.8,
  ),
);

Widget _card(Color surface, List<Widget> children) => Container(
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(children: children),
);

Widget _row({
  required String label,
  required String sub,
  required Widget trailing,
  required Color textPrimary,
  required Color textSecondary,
  required Color divider,
  required bool isLast,
}) => Column(
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    ),
    if (!isLast)
      Divider(
        height: 1,
        color: divider.withValues(alpha: 0.5),
        indent: 16,
        endIndent: 16,
      ),
  ],
);

Widget _actionRow({
  required IconData icon,
  required String label,
  required String sub,
  required Color color,
  required Color textPrimary,
  required Color textSecondary,
  required VoidCallback onTap,
}) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(12),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, size: 16, color: textSecondary),
      ],
    ),
  ),
);

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final List<String>? labels;
  final bool isDark;
  final ValueChanged<T> onChanged;
  const _Dropdown({
    required this.value,
    required this.items,
    this.labels,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fieldBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: surface,
          style: TextStyle(fontSize: 13, color: textPrimary),
          items: items
              .asMap()
              .entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(
                    labels != null ? labels![e.key] : e.value.toString(),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

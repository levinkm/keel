import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/auth/auth_service.dart';
import 'package:keel/core/auth/lock_screen.dart';
import 'package:keel/core/di/injector.dart';

import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'core/shortcuts/shortcut_service.dart';
import 'core/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await ShortcutService.instance.init(getIt<SettingsRepository>());
  await AuthService.instance.init();
  runApp(const KeelApp());
}

class KeelApp extends StatefulWidget {
  const KeelApp({super.key});

  @override
  State<KeelApp> createState() => _KeelAppState();
}

class _KeelAppState extends State<KeelApp> with WidgetsBindingObserver {
  bool _showSplash = true;

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
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      AuthService.instance.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, child) => MaterialApp(
        title: 'Keel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: _showSplash
            ? SplashScreen(
                onComplete: () {
                  setState(() => _showSplash = false);
                  // Trigger auth immediately after splash if locked
                  if (AuthService.instance.isLocked.value) {
                    AuthService.instance.authenticate(
                      reason: 'Unlock Keel to access your financial data',
                    );
                  }
                },
              )
            : ValueListenableBuilder<bool>(
                valueListenable: AuthService.instance.isLocked,
                builder: (_, locked, _) =>
                    locked ? const LockScreen() : _RouterApp(mode: mode),
              ),
      ),
    );
  }
}

class _RouterApp extends StatelessWidget {
  final ThemeMode mode;
  const _RouterApp({required this.mode});

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'keel',
          menus: [
            PlatformMenuItem(
              label: 'About Keel',
              onSelected: () => appRouter.go('/settings'),
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Preferences...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => appRouter.go('/settings'),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Quit Keel',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyQ,
                    meta: true,
                  ),
                  onSelected: () => ServicesBinding.instance.exitApplication(
                    ui.AppExitType.cancelable,
                  ),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Go',
          menus: [
            PlatformMenuItem(
              label: 'Dashboard',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit1,
                meta: true,
              ),
              onSelected: () => appRouter.go('/dashboard'),
            ),
            PlatformMenuItem(
              label: 'Net Worth',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit2,
                meta: true,
              ),
              onSelected: () => appRouter.go('/net-worth'),
            ),
            PlatformMenuItem(
              label: 'Budget',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit3,
                meta: true,
              ),
              onSelected: () => appRouter.go('/budget'),
            ),
            PlatformMenuItem(
              label: 'Transactions',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit4,
                meta: true,
              ),
              onSelected: () => appRouter.go('/transactions'),
            ),
            PlatformMenuItem(
              label: 'Accounts',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit5,
                meta: true,
              ),
              onSelected: () => appRouter.go('/accounts'),
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Income',
                  onSelected: () => appRouter.go('/income'),
                ),
                PlatformMenuItem(
                  label: 'Loans',
                  onSelected: () => appRouter.go('/loans'),
                ),
                PlatformMenuItem(
                  label: 'Investments',
                  onSelected: () => appRouter.go('/investments'),
                ),
                PlatformMenuItem(
                  label: 'Assets',
                  onSelected: () => appRouter.go('/assets'),
                ),
                PlatformMenuItem(
                  label: 'Projects',
                  onSelected: () => appRouter.go('/projects'),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Projections',
                  onSelected: () => appRouter.go('/projections'),
                ),
                PlatformMenuItem(
                  label: 'Reports',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyR,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: () => appRouter.go('/reports'),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Window',
          menus: [
            PlatformMenuItem(
              label: 'Minimize',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyM,
                meta: true,
              ),
              onSelected: () {},
            ),
          ],
        ),
        PlatformMenu(
          label: 'Help',
          menus: [PlatformMenuItem(label: 'Keel Help', onSelected: () {})],
        ),
      ],
      child: MaterialApp.router(
        title: 'Keel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: appRouter,
      ),
    );
  }
}

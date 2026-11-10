import 'package:go_router/go_router.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/features/accounts/presentation/pages/accounts_page.dart';
import 'package:keel/features/assets/presentation/pages/assets_page.dart';
import 'package:keel/features/budget/presentation/pages/budget_page.dart';
import 'package:keel/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:keel/features/income/presentation/pages/income_page.dart';
import 'package:keel/features/investments/presentation/pages/investments_page.dart';
import 'package:keel/features/loans/presentation/pages/loans_page.dart';
import 'package:keel/features/net_worth/presentation/pages/net_worth_page.dart';
import 'package:keel/features/projections/presentation/pages/projections_page.dart';
import 'package:keel/features/projects/presentation/pages/projects_page.dart';
import 'package:keel/features/reports/presentation/pages/reports_page.dart';
import 'package:keel/features/settings/domain/repositories/settings_repository.dart';
import 'package:keel/features/settings/presentation/pages/settings_page.dart';
import 'package:keel/features/setup/presentation/pages/setup_page.dart';
import 'package:keel/features/strategy/presentation/pages/strategy_page.dart';
import 'package:keel/features/transactions/presentation/pages/transactions_page.dart';
import 'package:keel/core/router/shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) async {
    if (state.uri.path.startsWith('/setup')) return null;
    final settings = getIt<SettingsRepository>();
    final result = await settings.getAll();
    final completed = result.fold((_) => false, (s) => s['hasCompletedSetup'] == 'true');
    if (!completed) return '/setup';
    return null;
  },
  routes: [
    GoRoute(path: '/setup', builder: (c, s) => const SetupPage()),
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (c, s) => const DashboardPage()),
        GoRoute(path: '/net-worth', builder: (c, s) => const NetWorthPage()),
        GoRoute(path: '/budget', builder: (c, s) => const BudgetPage()),
        GoRoute(path: '/transactions', builder: (c, s) => const TransactionsPage()),
        GoRoute(path: '/accounts', builder: (c, s) => const AccountsPage()),
        GoRoute(path: '/income', builder: (c, s) => const IncomePage()),
        GoRoute(path: '/strategy', builder: (c, s) => const StrategyPage()),
        GoRoute(path: '/loans', builder: (c, s) => const LoansPage()),
        GoRoute(path: '/projects', builder: (c, s) => const ProjectsPage()),
        GoRoute(path: '/assets', builder: (c, s) => const AssetsPage()),
        GoRoute(path: '/investments', builder: (c, s) => const InvestmentsPage()),
        GoRoute(path: '/projections', builder: (c, s) => const ProjectionsPage()),
        GoRoute(path: '/reports', builder: (c, s) => const ReportsPage()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsPage()),
      ],
    ),
  ],
);

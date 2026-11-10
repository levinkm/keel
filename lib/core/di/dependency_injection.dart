import 'package:keel/core/database/app_database.dart';
import 'package:keel/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:keel/features/accounts/data/repositories/accounts_repository_impl.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/accounts/domain/usecases/get_accounts_usecase.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:keel/features/ledger/data/datasources/ledger_local_datasource.dart';
import 'package:keel/features/ledger/data/repositories/ledger_repository_impl.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/ledger/domain/usecases/get_journal_entries_usecase.dart';
import 'package:keel/features/ledger/domain/usecases/post_journal_entry_usecase.dart';
import 'package:keel/features/ledger/presentation/bloc/ledger_cubit.dart';
import 'package:keel/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:keel/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:keel/features/budget/domain/usecases/get_budget_plan_usecase.dart';
import 'package:keel/features/budget/presentation/bloc/budget_cubit.dart';
import 'package:keel/features/loans/data/datasources/loans_local_datasource.dart';
import 'package:keel/features/loans/data/repositories/loans_repository_impl.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:keel/features/loans/domain/usecases/get_loans_usecase.dart';
import 'package:keel/features/loans/presentation/bloc/loans_cubit.dart';
import 'package:keel/features/income/data/datasources/income_local_datasource.dart';
import 'package:keel/features/income/data/repositories/income_repository_impl.dart';
import 'package:keel/features/income/domain/repositories/income_repository.dart';
import 'package:keel/features/income/domain/usecases/get_income_streams_usecase.dart';
import 'package:keel/features/income/presentation/bloc/income_cubit.dart';
import 'package:keel/features/assets/data/datasources/assets_local_datasource.dart';
import 'package:keel/features/assets/data/repositories/assets_repository_impl.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/assets/domain/usecases/get_assets_usecase.dart';
import 'package:keel/features/assets/presentation/bloc/assets_cubit.dart';
import 'package:keel/features/investments/data/datasources/investments_local_datasource.dart';
import 'package:keel/features/investments/data/repositories/investments_repository_impl.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:keel/features/investments/domain/usecases/get_holdings_usecase.dart';
import 'package:keel/features/investments/presentation/bloc/investments_cubit.dart';
import 'package:keel/features/net_worth/data/datasources/net_worth_local_datasource.dart';
import 'package:keel/features/net_worth/data/repositories/net_worth_repository_impl.dart';
import 'package:keel/features/net_worth/domain/repositories/net_worth_repository.dart';
import 'package:keel/features/net_worth/domain/usecases/get_net_worth_usecase.dart';
import 'package:keel/features/net_worth/presentation/bloc/net_worth_cubit.dart';
import 'package:keel/features/projections/presentation/bloc/projections_cubit.dart';
import 'package:keel/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:keel/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:keel/features/settings/domain/repositories/settings_repository.dart';
import 'package:keel/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:keel/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:keel/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:keel/features/strategy/data/datasources/strategy_local_datasource.dart';
import 'package:keel/features/strategy/data/repositories/strategy_repository_impl.dart';
import 'package:keel/features/strategy/domain/repositories/strategy_repository.dart';
import 'package:keel/features/strategy/presentation/bloc/strategy_cubit.dart';
import 'package:keel/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:keel/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:keel/features/contacts/domain/repositories/contact_repository.dart';
import 'package:keel/features/contacts/presentation/bloc/contacts_cubit.dart';
import 'package:keel/features/projects/data/datasources/project_local_datasource.dart';
import 'package:keel/features/projects/data/repositories/project_repository_impl.dart';
import 'package:keel/features/projects/domain/repositories/project_repository.dart';
import 'package:keel/features/projects/presentation/bloc/projects_cubit.dart';
import 'package:keel/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'injector.dart';

Future<void> initDependencies() async {
  // Core
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

  // Accounts
  getIt.registerLazySingleton<AccountsLocalDatasource>(
    () => AccountsLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetAccountsUsecase(getIt()));
  getIt.registerFactory(() => AccountsCubit(getIt(), getIt(), getIt()));

  // Ledger
  getIt.registerLazySingleton<LedgerLocalDatasource>(
    () => LedgerLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<LedgerRepository>(
    () => LedgerRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetJournalEntriesUsecase(getIt()));
  getIt.registerLazySingleton(() => PostJournalEntryUsecase(getIt()));
  getIt.registerFactory(() => LedgerCubit(getIt(), getIt(), getIt()));

  // Budget
  getIt.registerLazySingleton<BudgetLocalDatasource>(
    () => BudgetLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetBudgetPlanUsecase(getIt()));
  getIt.registerFactory(() => BudgetCubit(getIt(), getIt(), getIt(), getIt()));

  // Loans
  getIt.registerLazySingleton<LoansLocalDatasource>(
    () => LoansLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<LoansRepository>(
    () => LoansRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetLoansUsecase(getIt()));
  getIt.registerFactory(() => LoansCubit(getIt(), getIt(), getIt()));

  // Income
  getIt.registerLazySingleton<IncomeLocalDatasource>(
    () => IncomeLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<IncomeRepository>(
    () => IncomeRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetIncomeStreamsUsecase(getIt()));
  getIt.registerFactory(() => IncomeCubit(getIt(), getIt(), getIt()));

  // Assets
  getIt.registerLazySingleton<AssetsLocalDatasource>(
    () => AssetsLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<AssetsRepository>(
    () => AssetsRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetAssetsUsecase(getIt()));
  getIt.registerFactory(() => AssetsCubit(getIt<AssetsRepository>(), getIt<ProjectRepository>(), getIt<LedgerRepository>()));

  // Investments
  getIt.registerLazySingleton<InvestmentsLocalDatasource>(
    () => InvestmentsLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<InvestmentsRepository>(
    () => InvestmentsRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetHoldingsUsecase(getIt()));
  getIt.registerFactory(() => InvestmentsCubit(getIt<InvestmentsRepository>(), getIt<AssetsRepository>(), getIt<LedgerRepository>()));

  // Net Worth
  getIt.registerLazySingleton<NetWorthLocalDatasource>(
    () => NetWorthLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<NetWorthRepository>(
    () => NetWorthRepositoryImpl(getIt(), getIt<AssetsRepository>(), getIt<InvestmentsRepository>()),
  );
  getIt.registerLazySingleton(() => GetNetWorthUsecase(getIt()));
  getIt.registerFactory(() => NetWorthCubit(
    getIt<AccountsRepository>(),
    getIt<LedgerRepository>(),
    getIt<AssetsRepository>(),
    getIt<InvestmentsRepository>(),
    getIt<LoansRepository>(),
  ));

  // Settings
  getIt.registerLazySingleton<SettingsLocalDatasource>(
    () => SettingsLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetSettingsUsecase(getIt()));
  getIt.registerFactory(() => SettingsCubit(getIt<SettingsRepository>(), getIt<AppDatabase>()));

  // Strategy
  getIt.registerLazySingleton<StrategyLocalDatasource>(
    () => StrategyLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<StrategyRepository>(
    () => StrategyRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => StrategyCubit(getIt(), getIt(), getIt(), getIt(), getIt()));

  // Contacts
  getIt.registerLazySingleton<ContactLocalDatasource>(
    () => ContactLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(getIt()),
  );
  getIt.registerFactory(
      () => ContactsCubit(getIt(), getIt(), getIt()));

  // Projects
  getIt.registerLazySingleton<ProjectLocalDatasource>(
    () => ProjectLocalDatasource(getIt()),
  );
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(getIt()),
  );
  getIt.registerFactory(
      () => ProjectsCubit(getIt(), getIt(), getIt()));

  // Dashboard
  getIt.registerFactory(() => DashboardCubit(getIt(), getIt(), getIt(), getIt(), getIt<AssetsRepository>(), getIt<InvestmentsRepository>(), getIt<LoansRepository>()));

  // Projections
  getIt.registerFactory(() => ProjectionsCubit(
    getIt<NetWorthRepository>(),
    getIt<IncomeRepository>(),
    getIt<BudgetRepository>(),
    getIt<LoansRepository>(),
  ));

  // Reports
  getIt.registerFactory(() => ReportsCubit(
    getIt<LedgerRepository>(),
    getIt<AccountsRepository>(),
    getIt<BudgetRepository>(),
    getIt<LoansRepository>(),
    getIt<InvestmentsRepository>(),
    getIt<AssetsRepository>(),
  ));

  // Setup
  getIt.registerFactory(() => SetupCubit(
    accounts: getIt(),
    income: getIt(),
    loans: getIt(),
    ledger: getIt(),
    settings: getIt(),
  ));
}

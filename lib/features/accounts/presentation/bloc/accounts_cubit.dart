import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/core/usecases/usecase.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/accounts/domain/usecases/get_accounts_usecase.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:uuid/uuid.dart';

part 'accounts_state.dart';
part 'accounts_cubit.freezed.dart';

class AccountsCubit extends Cubit<AccountsState> {
  final GetAccountsUsecase _getAccounts;
  final AccountsRepository _accountsRepo;
  final LedgerRepository _ledgerRepo;

  AccountsCubit(this._getAccounts, this._accountsRepo, this._ledgerRepo)
      : super(const AccountsState.initial());

  static String _todayPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _offsetPeriod(String period, int offset) {
    final parts = period.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + offset;
    while (month < 1) { month += 12; year--; }
    while (month > 12) { month -= 12; year++; }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Future<void> loadAccounts() async {
    emit(const AccountsState.loading());
    await _reload();
  }

  Future<void> setFilter(AccountFilter filter) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(filter: filter));
  }

  Future<void> selectAccount(String? accountId) async {
    final current = state;
    if (current is! _Loaded) return;
    if (accountId == null) {
      emit(current.copyWith(
          selectedAccountId: null,
          selectedHistory: [],
          selectedSparkline: []));
      return;
    }
    final history = await _loadHistory(accountId);
    final sparkline = await _loadSparkline(accountId);
    emit(current.copyWith(
      selectedAccountId: accountId,
      selectedHistory: history,
      selectedSparkline: sparkline,
    ));
  }

  Future<void> createAccount(Account account) async {
    final result = await _accountsRepo.createAccount(account);
    result.fold(
      (f) => emit(AccountsState.error(f.message)),
      (_) async {
        await _reload(selectedAccountId: account.id);
      },
    );
  }

  Future<void> updateAccount(Account account) async {
    final result = await _accountsRepo.updateAccount(account);
    result.fold(
      (f) => emit(AccountsState.error(f.message)),
      (_) async => await _reload(selectedAccountId: account.id),
    );
  }

  Future<void> toggleActive(Account account) async {
    await updateAccount(Account(
      id: account.id,
      name: account.name,
      type: account.type,
      currency: account.currency,
      liquidity: account.liquidity,
      isActive: !account.isActive,
      createdAt: account.createdAt,
    ));
  }

  Future<void> transfer({
    required Account from,
    required Account to,
    required int amountMinor,
    required String description,
  }) async {
    final now = DateTime.now();
    final period = _todayPeriod();
    final entry = JournalEntry(
      id: const Uuid().v4(),
      date: now,
      description: description.isEmpty
          ? 'Transfer: ${from.name} → ${to.name}'
          : description,
      period: period,
      isLocked: false,
      createdAt: now,
      lines: [
        JournalLine(
          id: const Uuid().v4(),
          entryId: '',
          accountId: to.id,
          amountMinor: amountMinor,
          currency: from.currency,
          side: JournalSide.debit,
        ),
        JournalLine(
          id: const Uuid().v4(),
          entryId: '',
          accountId: from.id,
          amountMinor: amountMinor,
          currency: from.currency,
          side: JournalSide.credit,
        ),
      ],
    );
    await _ledgerRepo.postEntry(entry);
    final current = state;
    final selectedId = current is _Loaded ? current.selectedAccountId : null;
    await _reload(selectedAccountId: selectedId);
  }

  Future<void> _reload({String? selectedAccountId}) async {
    final accountsResult = await _getAccounts(const NoParams());
    final balancesResult = await _ledgerRepo.getAccountBalances();

    final accounts = accountsResult.fold((_) => <Account>[], (a) => a);
    final balances = balancesResult.fold((_) => <String, int>{}, (b) => b);

    final current = state;
    final filter = current is _Loaded ? current.filter : AccountFilter.all;
    final resolvedId = selectedAccountId ??
        (current is _Loaded ? current.selectedAccountId : null) ??
        (accounts.isNotEmpty ? accounts.first.id : null);

    List<JournalEntry> history = [];
    List<MonthlyBalance> sparkline = [];
    if (resolvedId != null) {
      history = await _loadHistory(resolvedId);
      sparkline = await _loadSparkline(resolvedId);
    }

    emit(AccountsState.loaded(
      accounts: accounts,
      balances: balances,
      filter: filter,
      selectedAccountId: resolvedId,
      selectedHistory: history,
      selectedSparkline: sparkline,
    ));
  }

  Future<List<JournalEntry>> _loadHistory(String accountId) async {
    final result = await _ledgerRepo.getEntriesByAccount(accountId);
    return result.fold((_) => [], (e) => e.take(30).toList());
  }

  Future<List<MonthlyBalance>> _loadSparkline(String accountId) async {
    final result = <MonthlyBalance>[];
    final today = _todayPeriod();
    // Build running balance month by month for last 6 months
    for (int i = -5; i <= 0; i++) {
      final p = _offsetPeriod(today, i);
      final r = await _ledgerRepo.getEntriesByPeriod(p);
      int net = 0;
      r.fold((_) => null, (entries) {
        for (final entry in entries) {
          for (final line in entry.lines) {
            if (line.accountId == accountId) {
              net += line.side == JournalSide.debit
                  ? line.amountMinor
                  : -line.amountMinor;
            }
          }
        }
      });
      result.add(MonthlyBalance(period: p, balanceMinor: net));
    }
    return result;
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';

part 'net_worth_state.dart';
part 'net_worth_cubit.freezed.dart';

class NetWorthCubit extends Cubit<NetWorthState> {
  final AccountsRepository _accountsRepo;
  final LedgerRepository _ledgerRepo;
  final AssetsRepository _assetsRepo;
  final InvestmentsRepository _investmentsRepo;
  final LoansRepository _loansRepo;

  NetWorthCubit(this._accountsRepo, this._ledgerRepo, this._assetsRepo,
      this._investmentsRepo, this._loansRepo)
      : super(const NetWorthState.initial());

  Future<void> load() async {
    emit(const NetWorthState.loading());
    try {
      final accountsResult = await _accountsRepo.getAccounts();
      final balancesResult = await _ledgerRepo.getAccountBalances();
      final assetsResult = await _assetsRepo.getAssets();
      final holdingsResult = await _investmentsRepo.getHoldings();
      final loansResult = await _loansRepo.getLoans();

      final accounts = accountsResult.fold((_) => <Account>[], (a) => a);
      final balances = balancesResult.fold((_) => <String, int>{}, (b) => b);
      final assets = assetsResult.fold((_) => <Asset>[], (a) => a);
      final holdings = holdingsResult.fold((_) => <Holding>[], (h) => h);
      final loans = loansResult.fold((_) => <Loan>[], (l) => l);

      // ── Cash & Bank accounts ──────────────────────────────────────────────
      final cashAccounts = accounts
          .where((a) => a.type == AccountType.asset && a.isActive)
          .map((a) => AccountBalance(
                account: a,
                balanceMinor: balances[a.id] ?? 0,
              ))
          .toList()
        ..sort((a, b) => b.balanceMinor.compareTo(a.balanceMinor));

      final totalCashMinor =
          cashAccounts.fold(0, (s, a) => s + a.balanceMinor);

      // ── Physical assets ───────────────────────────────────────────────────
      final physicalAssets = assets
          .where((a) => a.holdingId == null && a.status == AssetStatus.inUse)
          .toList()
        ..sort((a, b) => b.bookValue.compareTo(a.bookValue));

      final totalPhysicalMinor =
          physicalAssets.fold(0, (s, a) => s + a.bookValue);

      // ── Investments ───────────────────────────────────────────────────────
      final activeHoldings = holdings.where((h) => h.isActive).toList()
        ..sort((a, b) => b.marketValueMinor.compareTo(a.marketValueMinor));

      final totalInvestmentsMinor =
          activeHoldings.fold(0, (s, h) => s + h.marketValueMinor);

      // ── Liabilities ───────────────────────────────────────────────────────
      final loanBalances = <LoanBalance>[];
      for (final loan in loans.where((l) =>
          l.status == LoanStatus.active &&
          l.direction == LoanDirection.borrowed)) {
        final eventsResult = await _loansRepo.getEventsForLoan(loan.id);
        final events = eventsResult.fold((_) => <LoanEvent>[], (e) => e);
        final summary = LoanEngine.compute(loan, events);
        loanBalances.add(LoanBalance(
            loan: loan, outstandingMinor: summary.outstandingMinor));
      }
      final totalLoansMinor =
          loanBalances.fold(0, (s, l) => s + l.outstandingMinor);
      final totalLiabilitiesMinor = totalLoansMinor;

      // ── Net worth ─────────────────────────────────────────────────────────
      final totalAssetsMinor =
          totalCashMinor + totalPhysicalMinor + totalInvestmentsMinor;
      final netWorthMinor = totalAssetsMinor - totalLiabilitiesMinor;

      // Liquid = instant + days accounts
      final liquidMinor = cashAccounts
          .where((a) =>
              a.account.liquidity == Liquidity.instant ||
              a.account.liquidity == Liquidity.days)
          .fold(0, (s, a) => s + a.balanceMinor);

      emit(NetWorthState.loaded(
        netWorthMinor: netWorthMinor,
        totalAssetsMinor: totalAssetsMinor,
        totalLiabilitiesMinor: totalLiabilitiesMinor,
        liquidMinor: liquidMinor,
        totalCashMinor: totalCashMinor,
        totalPhysicalMinor: totalPhysicalMinor,
        totalInvestmentsMinor: totalInvestmentsMinor,
        cashAccounts: cashAccounts,
        physicalAssets: physicalAssets,
        activeHoldings: activeHoldings,
        loanBalances: loanBalances,
      ));
    } catch (e) {
      emit(NetWorthState.error(e.toString()));
    }
  }
}

class AccountBalance {
  final Account account;
  final int balanceMinor;
  const AccountBalance({required this.account, required this.balanceMinor});
}

class LoanBalance {
  final Loan loan;
  final int outstandingMinor;
  const LoanBalance({required this.loan, required this.outstandingMinor});
}

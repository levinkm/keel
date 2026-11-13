import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:uuid/uuid.dart';

part 'loans_state.dart';
part 'loans_cubit.freezed.dart';

class LoansCubit extends Cubit<LoansState> {
  final LoansRepository _repo;
  final LedgerRepository _ledgerRepo;
  final AccountsRepository _accountsRepo;

  LoansCubit(this._repo, this._ledgerRepo, this._accountsRepo)
      : super(const LoansState.initial());

  Future<void> load() async {
    emit(const LoansState.loading());
    await _reload();
  }

  Future<void> setFilter(LoanFilter filter) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(filter: filter, selectedLoanId: null, selectedEvents: []));
  }

  Future<void> selectLoan(String? loanId) async {
    final current = state;
    if (current is! _Loaded) return;
    if (loanId == null) {
      emit(current.copyWith(selectedLoanId: null, selectedEvents: []));
      return;
    }
    final eventsResult = await _repo.getEventsForLoan(loanId);
    final events = eventsResult.fold((_) => <LoanEvent>[], (e) => e);
    emit(current.copyWith(selectedLoanId: loanId, selectedEvents: events));
  }

  Future<void> createLoan(Loan loan) async {
    await _repo.createLoan(loan);
    await _reload();
  }

  Future<void> updateLoan(Loan loan) async {
    await _repo.updateLoan(loan);
    await _reload(selectedLoanId: loan.id);
  }

  Future<void> recordPayment({
    required Loan loan,
    required LoanEventType type,
    required int amountMinor,
    required String note,
  }) async {
    final current = state;
    if (current is! _Loaded) return;

    // ── Balance validation (only for payments out, not fees on lent loans) ──
    if (loan.direction == LoanDirection.borrowed &&
        (type == LoanEventType.instalment || type == LoanEventType.prepayment)) {
      final balancesResult = await _ledgerRepo.getAccountBalances();
      final balances = balancesResult.fold((_) => <String, int>{}, (b) => b);
      final allAccounts = (await _accountsRepo.getAccounts())
          .fold((_) => <Account>[], (a) => a);
      final totalAssets = allAccounts
          .where((a) => a.type == AccountType.asset && a.isActive)
          .fold(0, (s, a) => s + (balances[a.id] ?? 0));
      if (totalAssets < amountMinor) {
        final available = (totalAssets / 100).toStringAsFixed(0)
            .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
        final needed = (amountMinor / 100).toStringAsFixed(0)
            .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
        emit(current.copyWith(
          validationError:
              'Insufficient funds. Available: KES $available, needed: KES $needed.',
        ));
        return;
      }
    }

    final event = LoanEvent(
      id: const Uuid().v4(),
      loanId: loan.id,
      type: type,
      date: DateTime.now(),
      amountMinor: amountMinor,
      currency: loan.currency,
      note: note.isEmpty ? null : note,
    );
    await _repo.addEvent(event);

    // Post journal entry so it appears in Transactions and affects balances
    final now = DateTime.now();
    final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Pick the asset account to credit (cash going out)
    final allAccounts = (await _accountsRepo.getAccounts())
        .fold((_) => [], (a) => a);
    final assetAccounts = allAccounts
        .where((a) => a.type == AccountType.asset && a.isActive)
        .toList();
    final cashAccount = assetAccounts.isNotEmpty ? assetAccounts.first : null;

    if (cashAccount != null) {
      // For a borrowed loan payment:
      //   Debit  loan-liability (reduces what we owe)  — use opening-equity as proxy
      //   Credit asset account (cash goes out)
      // For a lent loan repayment received:
      //   Debit  asset account (cash comes in)
      //   Credit opening-equity (reduces receivable)
      final isBorrowed = loan.direction == LoanDirection.borrowed;
      final debitId = isBorrowed ? 'opening-equity' : cashAccount.id;
      final creditId = isBorrowed ? cashAccount.id : 'opening-equity';

      final description = note.isEmpty
          ? '${isBorrowed ? 'Loan payment' : 'Loan repayment received'}: ${loan.counterparty}'
          : note;

      final entry = JournalEntry(
        id: const Uuid().v4(),
        date: now,
        description: description,
        reference: loan.id,
        period: period,
        isLocked: false,
        createdAt: now,
        lines: [
          JournalLine(
            id: const Uuid().v4(),
            entryId: '',
            accountId: debitId,
            amountMinor: amountMinor,
            currency: loan.currency,
            side: JournalSide.debit,
          ),
          JournalLine(
            id: const Uuid().v4(),
            entryId: '',
            accountId: creditId,
            amountMinor: amountMinor,
            currency: loan.currency,
            side: JournalSide.credit,
          ),
        ],
      );
      await _ledgerRepo.postEntry(entry);
    }

    // Auto-settle if outstanding reaches zero
    final summary = current.summaries[loan.id];
    if (summary != null) {
      final newOutstanding = summary.outstandingMinor - amountMinor;
      if (newOutstanding <= 0 && loan.status == LoanStatus.active) {
        await _repo.updateLoan(_withStatus(loan, LoanStatus.settled));
      }
    }
    await _reload(selectedLoanId: loan.id);
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  Future<void> settleLoan(Loan loan) async {
    await _repo.updateLoan(_withStatus(loan, LoanStatus.settled));
    await _reload(selectedLoanId: loan.id);
  }

  Future<void> writeOffLoan(Loan loan) async {
    await _repo.updateLoan(_withStatus(loan, LoanStatus.writtenOff));
    await _reload(selectedLoanId: loan.id);
  }

  Future<void> reactivateLoan(Loan loan) async {
    await _repo.updateLoan(_withStatus(loan, LoanStatus.active));
    await _reload(selectedLoanId: loan.id);
  }

  Loan _withStatus(Loan loan, LoanStatus status) => Loan(
        id: loan.id,
        direction: loan.direction,
        counterparty: loan.counterparty,
        principalMinor: loan.principalMinor,
        currency: loan.currency,
        interestMethod: loan.interestMethod,
        annualRateBp: loan.annualRateBp,
        ratePeriod: loan.ratePeriod,
        termMonths: loan.termMonths,
        disbursementDate: loan.disbursementDate,
        firstDueDate: loan.firstDueDate,
        instalmentMinor: loan.instalmentMinor,
        isSalaryDeducted: loan.isSalaryDeducted,
        status: status,
        accountId: loan.accountId,
        createdAt: loan.createdAt,
      );

  Future<void> _reload({String? selectedLoanId}) async {
    final loansResult = await _repo.getLoans();
    final loans = loansResult.fold((_) => <Loan>[], (l) => l);

    // Build summaries for all loans
    final summaries = <String, LoanSummary>{};
    final allEvents = <String, List<LoanEvent>>{};
    for (final loan in loans) {
      final eventsResult = await _repo.getEventsForLoan(loan.id);
      final events = eventsResult.fold((_) => <LoanEvent>[], (e) => e);
      allEvents[loan.id] = events;
      summaries[loan.id] = LoanEngine.compute(loan, events);
    }

    // Aggregate stats
    int totalBorrowed = 0;
    int totalLent = 0;
    int monthlyBurden = 0;
    DateTime? nextDue;

    for (final loan in loans.where((l) => l.status == LoanStatus.active)) {
      final summary = summaries[loan.id]!;
      if (loan.direction == LoanDirection.borrowed) {
        totalBorrowed += summary.outstandingMinor;
        monthlyBurden += loan.instalmentMinor;
      } else {
        totalLent += summary.outstandingMinor;
      }
      if (summary.nextDueDate != null) {
        if (nextDue == null || summary.nextDueDate!.isBefore(nextDue)) {
          nextDue = summary.nextDueDate;
        }
      }
    }

    final selectedEvents = selectedLoanId != null
        ? (allEvents[selectedLoanId] ?? <LoanEvent>[])
        : <LoanEvent>[];

    final current = state;
    final filter = current is _Loaded ? current.filter : LoanFilter.all;
    final resolvedId = selectedLoanId ?? (loans.isNotEmpty ? loans.first.id : null);
    final resolvedEvents = resolvedId != null
        ? (allEvents[resolvedId] ?? <LoanEvent>[])
        : selectedEvents;

    emit(LoansState.loaded(
      loans: loans,
      summaries: summaries,
      filter: filter,
      selectedLoanId: resolvedId,
      selectedEvents: resolvedEvents,
      totalBorrowedOutstandingMinor: totalBorrowed,
      totalLentOutstandingMinor: totalLent,
      monthlyBurdenMinor: monthlyBurden,
      nextDueDate: nextDue,
    ));
  }
}

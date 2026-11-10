import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/income/domain/repositories/income_repository.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/settings/domain/repositories/settings_repository.dart';
import 'package:uuid/uuid.dart';

part 'setup_state.dart';
part 'setup_cubit.freezed.dart';

class SetupCubit extends Cubit<SetupState> {
  final AccountsRepository _accounts;
  final IncomeRepository _income;
  final LoansRepository _loans;
  final LedgerRepository _ledger;
  final SettingsRepository _settings;

  SetupCubit({
    required this._accounts,
    required this._income,
    required this._loans,
    required this._ledger,
    required this._settings,
  }) : super(const SetupState());

  void nextStep() {
    final next = SetupStep.values[state.step.index + 1];
    emit(state.copyWith(step: next, error: null));
  }

  void previousStep() {
    if (state.step.index == 0) return;
    final prev = SetupStep.values[state.step.index - 1];
    emit(state.copyWith(step: prev, error: null));
  }

  void skipToStep(SetupStep step) => emit(state.copyWith(step: step, error: null));

  void setAccounts(List<AccountDraft> accounts) =>
      emit(state.copyWith(accounts: accounts));

  void setIncomeStreams(List<IncomeStreamDraft> streams) =>
      emit(state.copyWith(incomeStreams: streams));

  void setLoans(List<LoanDraft> loans) =>
      emit(state.copyWith(loans: loans));

  void setStrategy(String strategyId) =>
      emit(state.copyWith(strategyId: strategyId));

  Future<void> finish() async {
    emit(state.copyWith(isSubmitting: true, error: null));

    try {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final idMap = <String, String>{}; // accountName → id

      // 1. Create accounts + opening balance journal entries
      for (final draft in state.accounts) {
        final id = const Uuid().v4();
        idMap[draft.name] = id;

        final account = Account(
          id: id,
          name: draft.name,
          type: draft.type,
          currency: draft.currency,
          liquidity: draft.liquidity,
          isActive: true,
          createdAt: now,
        );
        await _accounts.createAccount(account);

        // Post opening balance entry if non-zero
        if (draft.openingBalanceMinor != 0) {
          // Equity account for opening balances
          const equityId = 'opening-equity';
          final isDebitNormal = draft.type == AccountType.asset || draft.type == AccountType.expense;
          final entry = JournalEntry(
            id: const Uuid().v4(),
            date: now,
            description: 'Opening balance — ${draft.name}',
            period: period,
            isLocked: false,
            createdAt: now,
            lines: [
              JournalLine(
                id: const Uuid().v4(),
                entryId: '',
                accountId: id,
                amountMinor: draft.openingBalanceMinor,
                currency: draft.currency,
                side: isDebitNormal ? JournalSide.debit : JournalSide.credit,
              ),
              JournalLine(
                id: const Uuid().v4(),
                entryId: '',
                accountId: equityId,
                amountMinor: draft.openingBalanceMinor,
                currency: draft.currency,
                side: isDebitNormal ? JournalSide.credit : JournalSide.debit,
              ),
            ],
          );
          await _ledger.postEntry(entry);
        }
      }

      // 2. Create income streams
      for (final draft in state.incomeStreams) {
        final accountId = idMap[draft.depositAccountName] ?? '';
        await _income.createStream(IncomeStream(
          id: const Uuid().v4(),
          name: draft.name,
          type: draft.type,
          accountId: accountId,
          frequency: draft.frequency,
          amountMinor: draft.amountMinor,
          currency: draft.currency,
          isActive: true,
          createdAt: now,
        ));
      }

      // 3. Create loans
      for (final draft in state.loans) {
        final instalment = _computeInstalment(
          draft.principalMinor,
          draft.annualRateBp,
          draft.termMonths,
          draft.interestMethod,
        );
        await _loans.createLoan(Loan(
          id: const Uuid().v4(),
          direction: draft.direction,
          counterparty: draft.counterparty,
          principalMinor: draft.principalMinor,
          currency: 'KES',
          interestMethod: draft.interestMethod,
          annualRateBp: draft.annualRateBp,
          termMonths: draft.termMonths,
          disbursementDate: draft.disbursementDate,
          firstDueDate: draft.disbursementDate.copyWith(month: draft.disbursementDate.month + 1),
          instalmentMinor: instalment,
          isSalaryDeducted: draft.isSalaryDeducted,
          status: LoanStatus.active,
          createdAt: now,
        ));
      }

      // 4. Mark setup complete
      await _settings.set('hasCompletedSetup', 'true');
      await _settings.set('activeStrategyId', state.strategyId);

      emit(state.copyWith(step: SetupStep.done, isSubmitting: false));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  /// Reducing balance instalment in minor units. Falls back to P÷n if rate is 0.
  int _computeInstalment(int principalMinor, int annualRateBp, int termMonths, InterestMethod method) {
    if (method == InterestMethod.fixedFee) return principalMinor ~/ termMonths;
    final monthlyRate = annualRateBp / 10000 / 12;
    if (monthlyRate == 0) return principalMinor ~/ termMonths;
    if (method == InterestMethod.flatRate) {
      final totalInterest = principalMinor * (annualRateBp / 10000) * (termMonths / 12);
      return ((principalMinor + totalInterest) / termMonths).round();
    }
    // Reducing balance
    final a = principalMinor * monthlyRate / (1 - _pow(1 + monthlyRate, -termMonths));
    return a.round();
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp.abs(); i++) {
      result *= base;
    }
    return exp < 0 ? 1 / result : result;
  }
}

extension on DateTime {
  DateTime copyWith({int? month}) => DateTime(year, month ?? this.month, day);
}

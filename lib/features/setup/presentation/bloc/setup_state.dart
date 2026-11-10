part of 'setup_cubit.dart';

enum SetupStep { welcome, accounts, income, assetsLoans, strategy, preview, done }

@freezed
abstract class SetupState with _$SetupState {
  const factory SetupState({
    @Default(SetupStep.welcome) SetupStep step,
    @Default([]) List<AccountDraft> accounts,
    @Default([]) List<IncomeStreamDraft> incomeStreams,
    @Default([]) List<LoanDraft> loans,
    @Default('commitments_first') String strategyId,
    @Default(false) bool isSubmitting,
    String? error,
  }) = _SetupState;
}

class AccountDraft {
  final String name;
  final AccountType type;
  final int openingBalanceMinor;
  final String currency;
  final Liquidity liquidity;

  const AccountDraft({
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.currency,
    required this.liquidity,
  });
}

class IncomeStreamDraft {
  final String name;
  final IncomeType type;
  final int amountMinor;
  final String currency;
  final IncomeFrequency frequency;
  final String depositAccountName;

  const IncomeStreamDraft({
    required this.name,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.frequency,
    required this.depositAccountName,
  });
}

class LoanDraft {
  final String counterparty;
  final LoanDirection direction;
  final int principalMinor;
  final int annualRateBp;
  final int termMonths;
  final InterestMethod interestMethod;
  final DateTime disbursementDate;
  final bool isSalaryDeducted;

  const LoanDraft({
    required this.counterparty,
    required this.direction,
    required this.principalMinor,
    required this.annualRateBp,
    required this.termMonths,
    required this.interestMethod,
    required this.disbursementDate,
    required this.isSalaryDeducted,
  });
}

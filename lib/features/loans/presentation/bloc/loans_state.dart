part of 'loans_cubit.dart';

enum LoanFilter { all, borrowed, lent }

@freezed
abstract class LoansState with _$LoansState {
  const factory LoansState.initial() = _Initial;
  const factory LoansState.loading() = _Loading;
  const factory LoansState.loaded({
    required List<Loan> loans,
    required Map<String, LoanSummary> summaries,
    required LoanFilter filter,
    String? selectedLoanId,
    required List<LoanEvent> selectedEvents,
    required int totalBorrowedOutstandingMinor,
    required int totalLentOutstandingMinor,
    required int monthlyBurdenMinor,
    required DateTime? nextDueDate,
    String? validationError,
  }) = _Loaded;
  const factory LoansState.error(String message) = _Error;
}

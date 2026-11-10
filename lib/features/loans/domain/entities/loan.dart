enum LoanDirection { borrowed, lent }
enum InterestMethod { reducingBalance, flatRate, fixedFee }
enum LoanStatus { active, settled, writtenOff }
enum LoanEventType { disbursement, instalment, prepayment, rateChange, fee, penalty, topUp }

class LoanEvent {
  final String id;
  final String loanId;
  final LoanEventType type;
  final DateTime date;
  final int amountMinor;
  final String currency;
  final String? note;

  const LoanEvent({
    required this.id,
    required this.loanId,
    required this.type,
    required this.date,
    required this.amountMinor,
    required this.currency,
    this.note,
  });
}

class Loan {
  final String id;
  final LoanDirection direction;
  final String counterparty;
  final int principalMinor;
  final String currency;
  final InterestMethod interestMethod;
  final int annualRateBp; // basis points, e.g. 1400 = 14%
  final int termMonths;
  final DateTime disbursementDate;
  final DateTime firstDueDate;
  final int instalmentMinor;
  final bool isSalaryDeducted;
  final LoanStatus status;
  final String? accountId;
  final DateTime createdAt;

  const Loan({
    required this.id,
    required this.direction,
    required this.counterparty,
    required this.principalMinor,
    required this.currency,
    required this.interestMethod,
    required this.annualRateBp,
    required this.termMonths,
    required this.disbursementDate,
    required this.firstDueDate,
    required this.instalmentMinor,
    required this.isSalaryDeducted,
    required this.status,
    this.accountId,
    required this.createdAt,
  });

  double get monthlyRate => annualRateBp / 10000 / 12;
}

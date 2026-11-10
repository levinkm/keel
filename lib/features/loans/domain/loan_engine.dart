import 'package:keel/features/loans/domain/entities/loan.dart';

class AmortizationRow {
  final int month;
  final DateTime dueDate;
  final int openingBalanceMinor;
  final int principalMinor;
  final int interestMinor;
  final int instalmentMinor;
  final int closingBalanceMinor;
  final bool isPaid;
  final bool isOverdue;

  const AmortizationRow({
    required this.month,
    required this.dueDate,
    required this.openingBalanceMinor,
    required this.principalMinor,
    required this.interestMinor,
    required this.instalmentMinor,
    required this.closingBalanceMinor,
    required this.isPaid,
    required this.isOverdue,
  });
}

class LoanSummary {
  final int outstandingMinor;
  final int totalPaidMinor;
  final int principalPaidMinor;
  final int interestPaidMinor;
  final int totalInterestMinor;
  final int remainingMonths;
  final int missedPayments;
  final DateTime? nextDueDate;
  final bool isOverdue;
  final int daysOverdue;
  final List<AmortizationRow> schedule;

  const LoanSummary({
    required this.outstandingMinor,
    required this.totalPaidMinor,
    required this.principalPaidMinor,
    required this.interestPaidMinor,
    required this.totalInterestMinor,
    required this.remainingMonths,
    required this.missedPayments,
    required this.nextDueDate,
    required this.isOverdue,
    required this.daysOverdue,
    required this.schedule,
  });
}

class LoanEngine {
  static LoanSummary compute(Loan loan, List<LoanEvent> events) {
    final schedule = _buildSchedule(loan);
    final now = DateTime.now();

    // Total principal payments from events
    int principalPaid = 0;
    int interestPaid = 0;
    for (final e in events) {
      if (e.type == LoanEventType.instalment ||
          e.type == LoanEventType.prepayment) {
        // Split payment into principal + interest based on schedule
        final month = _monthIndex(loan.firstDueDate, e.date);
        if (month >= 0 && month < schedule.length) {
          interestPaid += schedule[month].interestMinor;
          principalPaid +=
              e.amountMinor - schedule[month].interestMinor.clamp(0, e.amountMinor);
        } else {
          principalPaid += e.amountMinor;
        }
      }
    }

    final totalPaid = principalPaid + interestPaid;
    final outstanding = (loan.principalMinor - principalPaid).clamp(0, loan.principalMinor);
    final totalInterest = schedule.fold(0, (s, r) => s + r.interestMinor);

    // Mark rows paid/overdue
    final paidCount = events
        .where((e) =>
            e.type == LoanEventType.instalment ||
            e.type == LoanEventType.prepayment)
        .length;

    final markedSchedule = schedule.asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value;
      final isPaid = i < paidCount;
      final isOverdue = !isPaid && row.dueDate.isBefore(now);
      return AmortizationRow(
        month: row.month,
        dueDate: row.dueDate,
        openingBalanceMinor: row.openingBalanceMinor,
        principalMinor: row.principalMinor,
        interestMinor: row.interestMinor,
        instalmentMinor: row.instalmentMinor,
        closingBalanceMinor: row.closingBalanceMinor,
        isPaid: isPaid,
        isOverdue: isOverdue,
      );
    }).toList();

    final missed = markedSchedule.where((r) => r.isOverdue).length;
    final nextDue = markedSchedule
        .cast<AmortizationRow?>()
        .firstWhere((r) => r != null && !r.isPaid, orElse: () => null)
        ?.dueDate;

    final daysOverdue = nextDue != null && nextDue.isBefore(now)
        ? now.difference(nextDue).inDays
        : 0;

    return LoanSummary(
      outstandingMinor: outstanding,
      totalPaidMinor: totalPaid,
      principalPaidMinor: principalPaid,
      interestPaidMinor: interestPaid,
      totalInterestMinor: totalInterest,
      remainingMonths: (schedule.length - paidCount).clamp(0, schedule.length),
      missedPayments: missed,
      nextDueDate: nextDue,
      isOverdue: daysOverdue > 0,
      daysOverdue: daysOverdue,
      schedule: markedSchedule,
    );
  }

  static List<AmortizationRow> _buildSchedule(Loan loan) {
    final rows = <AmortizationRow>[];
    final p = loan.principalMinor;
    final n = loan.termMonths;
    final r = loan.monthlyRate;

    switch (loan.interestMethod) {
      case InterestMethod.reducingBalance:
        int balance = p;
        for (int i = 0; i < n; i++) {
          final interest = (balance * r).round();
          final instalment = loan.instalmentMinor;
          final principal = (instalment - interest).clamp(0, balance);
          final closing = balance - principal;
          rows.add(AmortizationRow(
            month: i + 1,
            dueDate: _addMonths(loan.firstDueDate, i),
            openingBalanceMinor: balance,
            principalMinor: principal,
            interestMinor: interest,
            instalmentMinor: instalment,
            closingBalanceMinor: closing,
            isPaid: false,
            isOverdue: false,
          ));
          balance = closing;
          if (balance <= 0) break;
        }

      case InterestMethod.flatRate:
        final totalInterest = (p * (loan.annualRateBp / 10000) *
                (n / 12))
            .round();
        final interestPerMonth = (totalInterest / n).round();
        final principalPerMonth = (p / n).round();
        final instalment = principalPerMonth + interestPerMonth;
        int balance = p;
        for (int i = 0; i < n; i++) {
          final closing = (balance - principalPerMonth).clamp(0, balance);
          rows.add(AmortizationRow(
            month: i + 1,
            dueDate: _addMonths(loan.firstDueDate, i),
            openingBalanceMinor: balance,
            principalMinor: principalPerMonth,
            interestMinor: interestPerMonth,
            instalmentMinor: instalment,
            closingBalanceMinor: closing,
            isPaid: false,
            isOverdue: false,
          ));
          balance = closing;
        }

      case InterestMethod.fixedFee:
        final principalPerMonth = (p / n).round();
        int balance = p;
        for (int i = 0; i < n; i++) {
          final closing = (balance - principalPerMonth).clamp(0, balance);
          rows.add(AmortizationRow(
            month: i + 1,
            dueDate: _addMonths(loan.firstDueDate, i),
            openingBalanceMinor: balance,
            principalMinor: principalPerMonth,
            interestMinor: 0,
            instalmentMinor: loan.instalmentMinor,
            closingBalanceMinor: closing,
            isPaid: false,
            isOverdue: false,
          ));
          balance = closing;
        }
    }
    return rows;
  }

  static DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    while (month > 12) { month -= 12; year++; }
    final day = date.day.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int _monthIndex(DateTime firstDue, DateTime paymentDate) {
    final months = (paymentDate.year - firstDue.year) * 12 +
        (paymentDate.month - firstDue.month);
    return months.clamp(0, 999);
  }
}

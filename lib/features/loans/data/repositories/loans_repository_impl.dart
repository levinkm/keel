import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/loans/data/datasources/loans_local_datasource.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:uuid/uuid.dart';

class LoansRepositoryImpl implements LoansRepository {
  final LoansLocalDatasource _datasource;
  LoansRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Loan>>> getLoans() async {
    try {
      final rows = await _datasource.getLoans();
      return Right(rows.map(_rowToLoan).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Loan>> createLoan(Loan loan) async {
    try {
      await _datasource.insertLoan(_loanToRow(loan));
      return Right(loan);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Loan>> updateLoan(Loan loan) async {
    try {
      await _datasource.updateLoan(_loanToRow(loan));
      return Right(loan);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addEvent(LoanEvent event) async {
    try {
      await _datasource.insertEvent({
        'id': event.id.isEmpty ? const Uuid().v4() : event.id,
        'loan_id': event.loanId,
        'type': event.type.name,
        'date': event.date.toIso8601String(),
        'amount_minor': event.amountMinor,
        'currency': event.currency,
        'note': event.note,
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoanEvent>>> getEventsForLoan(String loanId) async {
    try {
      final rows = await _datasource.getEventsForLoan(loanId);
      return Right(rows.map(_rowToEvent).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Map<String, dynamic> _loanToRow(Loan loan) => {
        'id': loan.id,
        'direction': loan.direction.name,
        'counterparty': loan.counterparty,
        'principal_minor': loan.principalMinor,
        'currency': loan.currency,
        'interest_method': loan.interestMethod.name,
        'annual_rate_bp': loan.annualRateBp,
        'rate_period': loan.ratePeriod.name,
        'term_months': loan.termMonths,
        'disbursement_date': loan.disbursementDate.toIso8601String(),
        'first_due_date': loan.firstDueDate.toIso8601String(),
        'instalment_minor': loan.instalmentMinor,
        'is_salary_deducted': loan.isSalaryDeducted ? 1 : 0,
        'status': loan.status.name,
        'account_id': loan.accountId,
        'created_at': loan.createdAt.toIso8601String(),
      };

  Loan _rowToLoan(Map<String, dynamic> r) => Loan(
        id: r['id'] as String,
        direction: LoanDirection.values.byName(r['direction'] as String),
        counterparty: r['counterparty'] as String,
        principalMinor: r['principal_minor'] as int,
        currency: r['currency'] as String,
        interestMethod: InterestMethod.values.byName(r['interest_method'] as String),
        annualRateBp: r['annual_rate_bp'] as int,
        ratePeriod: r['rate_period'] != null
            ? RatePeriod.values.byName(r['rate_period'] as String)
            : RatePeriod.annual,
        termMonths: r['term_months'] as int,
        disbursementDate: DateTime.parse(r['disbursement_date'] as String),
        firstDueDate: DateTime.parse(r['first_due_date'] as String),
        instalmentMinor: r['instalment_minor'] as int,
        isSalaryDeducted: (r['is_salary_deducted'] as int) == 1,
        status: LoanStatus.values.byName(r['status'] as String),
        accountId: r['account_id'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
      );

  LoanEvent _rowToEvent(Map<String, dynamic> r) => LoanEvent(
        id: r['id'] as String,
        loanId: r['loan_id'] as String,
        type: LoanEventType.values.byName(r['type'] as String),
        date: DateTime.parse(r['date'] as String),
        amountMinor: r['amount_minor'] as int,
        currency: r['currency'] as String,
        note: r['note'] as String?,
      );
}

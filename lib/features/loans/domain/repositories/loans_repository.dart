import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/loan.dart';

abstract class LoansRepository {
  Future<Either<Failure, List<Loan>>> getLoans();
  Future<Either<Failure, Loan>> createLoan(Loan loan);
  Future<Either<Failure, Loan>> updateLoan(Loan loan);
  Future<Either<Failure, void>> addEvent(LoanEvent event);
  Future<Either<Failure, List<LoanEvent>>> getEventsForLoan(String loanId);
}

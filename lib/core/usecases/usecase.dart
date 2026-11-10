import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class Usecase<T, Params> {
  Future<Either<Failure, T>> call([Params params]);

  static void assertParamsRequired(dynamic p) {
    if (p == null) throw Exception('Missing required params for Usecase');
  }
}

class NoParams {
  const NoParams();
}

class VoidType {
  const VoidType();
}

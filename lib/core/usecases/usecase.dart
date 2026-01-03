import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
// Parameters
class UserIdParams {
  final String userId;
  UserIdParams({required this.userId});
}



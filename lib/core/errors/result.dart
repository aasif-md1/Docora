import 'package:dartz/dartz.dart';
import 'package:docora/core/errors/app_exception.dart';

/// Alias for the Either type used throughout the domain and data layers.
/// [L] is always [AppException] (failure).
/// [R] is the success value type.
typedef Result<R> = Either<AppException, R>;

/// Alias for async Results
typedef AsyncResult<R> = Future<Either<AppException, R>>;

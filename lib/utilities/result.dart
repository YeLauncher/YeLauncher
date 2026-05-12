sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Exception error) = Failure<T>;
}

final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Result<$T>.success($value)';
}

final class Failure<T> extends Result<T> {
  final Exception error;

  const Failure(this.error);

  @override
  String toString() => 'Result<$T>.failure($error)';
}

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;

  const factory Result.failure(Exception error) = Failure<T>;

  /// Transforms the value of a [Success] using the given [transform] function.
  /// If the result is a [Failure], the error is passed through.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Result.success(transform(value)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Chains operations that also return a [Result].
  /// If the current result is a [Failure], the error is passed through immediately.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success(:final value) => transform(value),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Chains a `Future<Result>` with another `Future<Result>`.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    return switch (this) {
      Success(:final value) => await transform(value),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Evaluates both cases and returns a single unified value.
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Exception error) onFailure,
  ) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }

  /// Awaits the Result and evaluates both cases asynchronously.
  Future<R> foldAsync<R>(
    Future<R> Function(T value) onSuccess,
    Future<R> Function(Exception error) onFailure,
  ) async {
    return switch (this) {
      Success(:final value) => await onSuccess(value),
      Failure(:final error) => await onFailure(error),
    };
  }
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

extension ResultFutureExtension<T> on Future<Result<T>> {
  /// Chains a `Future<Result>` with another `Future<Result>`.
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => await transform(value),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Transforms the inner value of a `Future<Success>`.
  Future<Result<R>> map<R>(R Function(T value) transform) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => Result.success(transform(value)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Awaits the Result and evaluates both cases synchronously.
  Future<R> fold<R>(
    R Function(T value) onSuccess,
    R Function(Exception error) onFailure,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }

  /// Awaits the Result and evaluates both cases asynchronously.
  Future<R> foldAsync<R>(
    Future<R> Function(T value) onSuccess,
    Future<R> Function(Exception error) onFailure,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => await onSuccess(value),
      Failure(:final error) => await onFailure(error),
    };
  }
}

class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class CancelledException implements Exception {
  final String message;
  CancelledException([this.message = 'The operation was cancelled']);

  @override
  String toString() => 'CancelledException: $message';
}

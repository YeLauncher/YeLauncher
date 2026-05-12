import 'package:flutter/foundation.dart';
import 'package:yelauncher/utilities/result.dart';

typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, P1> = Future<Result<T>> Function(P1);

abstract class Command<T> extends ChangeNotifier {
  bool _running = false;

  Command();

  bool get running => _running;

  Result<T>? _result;

  bool get failure => _result is Failure;

  bool get complete => _result is Success;

  Result? get result => _result;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

class Command0<T> extends Command<T> {

  final CommandAction0<T> _action;

  Command0(this._action);

  Future<void> execute() async => await _execute(_action);
}

class Command1<T, P1> extends Command<T> {

  final CommandAction1<T, P1> _action;

  Command1(this._action);

  Future<void> execute(P1 param) async => await _execute(() => _action(param));
}

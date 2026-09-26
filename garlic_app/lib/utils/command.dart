import 'package:flutter/foundation.dart';

import 'result.dart';

/// Acción asíncrona de un ViewModel con estado observable (en curso, error, completada).
///
/// Basado en el patrón `Command` de la arquitectura recomendada de Flutter: la vista escucha
/// el comando para mostrar un spinner o un error sin que el ViewModel maneje banderas sueltas.
class Command<T> extends ChangeNotifier {
  Command(this._action);

  final Future<Result<T>> Function() _action;

  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  Result<T>? get result => _result;
  bool get completed => _result is Ok<T>;
  AppFailure? get failure => switch (_result) {
    Error<T>(:final failure) => failure,
    _ => null,
  };

  Future<Result<T>?> execute() async {
    if (_running) return null;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action();
      return _result;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}

/// Variante con un argumento.
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  Result<T>? get result => _result;
  AppFailure? get failure => switch (_result) {
    Error<T>(:final failure) => failure,
    _ => null,
  };

  Future<Result<T>?> execute(A arg) async {
    if (_running) return null;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action(arg);
      return _result;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}

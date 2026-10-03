import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Informa si el dispositivo tiene alguna red. No garantiza que el servidor responda:
/// el motor de sincronización confirma el acceso real al enviar.
class ConectividadService {
  ConectividadService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get cambios => _connectivity.onConnectivityChanged.map(_hayRed).distinct();

  Future<bool> hayRed() async => _hayRed(await _connectivity.checkConnectivity());

  static bool _hayRed(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);
}

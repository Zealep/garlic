import 'package:flutter/foundation.dart';

import '../../../../data/repositories/sesion_repository.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Cambio de la propia contraseña. Es obligatorio cuando la clave es temporal (alta o restablecida por el
/// administrador); en ese caso no se puede salir de la pantalla salvo cerrando sesión.
class CambiarClaveViewModel extends ChangeNotifier {
  CambiarClaveViewModel({required SesionRepository sesion}) : _sesion = sesion {
    guardar = Command(_guardar);
  }

  static const minimo = 8;

  final SesionRepository _sesion;
  late final Command<void> guardar;

  String actual = '';
  String nueva = '';

  bool get obligatorio => _sesion.debeCambiarClave;
  String get nombre => _sesion.usuario?.primerNombre ?? '';

  /// Reglas locales (el servidor valida lo mismo).
  static String? validarNueva(String? v, {String? actual}) {
    final s = v ?? '';
    if (s.length < minimo) return 'Mínimo $minimo caracteres';
    if (actual != null && s == actual) return 'Debe ser distinta de la actual';
    return null;
  }

  Future<Result<void>> _guardar() => _sesion.cambiarClave(actual: actual, nueva: nueva);

  Future<void> cerrarSesion() => _sesion.cerrar();
}

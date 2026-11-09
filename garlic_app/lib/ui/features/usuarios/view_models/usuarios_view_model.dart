import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/sesion_repository.dart';
import '../../../../data/repositories/usuarios_repository.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Usuarios de la empresa (solo administrador). Cada uno entra con su DNI y una contraseña temporal
/// que cambia en su primer ingreso.
class UsuariosViewModel extends ChangeNotifier {
  UsuariosViewModel({required UsuariosRepository usuarios, required SesionRepository sesion})
    : _usuarios = usuarios,
      _sesion = sesion {
    cargar = Command(_cargar)..execute();
  }

  final UsuariosRepository _usuarios;
  final SesionRepository _sesion;

  late final Command<void> cargar;
  List<UsuarioItem> lista = const [];

  String? get miId => _sesion.usuario?.id;

  /// Contraseña temporal legible (sin 0/O ni 1/l para dictarla sin errores).
  static String claveTemporal([Random? azar]) {
    const letras = 'abcdefghjkmnpqrstuvwxyz';
    const digitos = '23456789';
    final r = azar ?? Random.secure();
    final l = List.generate(4, (_) => letras[r.nextInt(letras.length)]).join();
    final d = List.generate(4, (_) => digitos[r.nextInt(digitos.length)]).join();
    return '$l$d';
  }

  Future<Result<void>> _cargar() async {
    final r = await _usuarios.listar();
    switch (r) {
      case Ok(:final value):
        lista = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final failure):
        return Result.error(failure);
    }
  }

  Future<Result<UsuarioItem>> crear({
    required String nombres,
    required String dni,
    String? email,
    required bool admin,
    required String claveTemporal,
  }) => _y(_usuarios.crear(nombres: nombres, dni: dni, email: email, admin: admin, claveTemporal: claveTemporal));

  Future<Result<UsuarioItem>> actualizar(UsuarioItem u, {required String nombres, String? email, required bool admin}) =>
      _y(_usuarios.actualizar(u, nombres: nombres, email: email, admin: admin));

  Future<Result<UsuarioItem>> asignarClave(UsuarioItem u, String clave) => _y(_usuarios.asignarClave(u.id, clave));

  Future<Result<void>> cambiarActivo(UsuarioItem u) async {
    final r = u.activo ? await _usuarios.desactivar(u.id) : await _usuarios.activar(u.id);
    if (r is Ok) await cargar.execute();
    return switch (r) {
      Error(:final failure) => Result.error(failure),
      _ => const Result.ok(null),
    };
  }

  /// Ejecuta la acción y, si salió bien, recarga la lista.
  Future<Result<T>> _y<T>(Future<Result<T>> accion) async {
    final r = await accion;
    if (r is Ok<T>) await cargar.execute();
    return r;
  }
}

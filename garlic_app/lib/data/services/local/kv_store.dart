import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Almacén clave-valor (JSON) sobre la base local, para configuración y catálogos en caché.
class KvStore {
  KvStore(this._db);

  final AppDatabase _db;

  Future<Object?> leer(String clave) async {
    final fila = await (_db.select(_db.kvEntries)..where((t) => t.clave.equals(clave))).getSingleOrNull();
    return fila == null ? null : jsonDecode(fila.valor);
  }

  Future<DateTime?> actualizado(String clave) async {
    final fila = await (_db.select(_db.kvEntries)..where((t) => t.clave.equals(clave))).getSingleOrNull();
    return fila?.actualizado;
  }

  Future<void> escribir(String clave, Object? valor) => _db
      .into(_db.kvEntries)
      .insertOnConflictUpdate(
        KvEntriesCompanion.insert(clave: clave, valor: jsonEncode(valor), actualizado: DateTime.now()),
      );

  Future<void> borrar(String clave) => (_db.delete(_db.kvEntries)..where((t) => t.clave.equals(clave))).go();

  /// Tipos de valor que guarda la app (evita warnings de raw types al leer).
  static Map<String, Object?>? mapa(Object? v) => v is Map ? v.cast<String, Object?>() : null;

  static List<Map<String, Object?>> lista(Object? v) =>
      v is List ? v.whereType<Map<Object?, Object?>>().map((e) => e.cast<String, Object?>()).toList() : const [];
}

/// Para escribir companions con valores opcionales sin repetir `Value(...)`.
Value<T> valor<T>(T v) => Value(v);

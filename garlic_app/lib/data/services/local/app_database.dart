import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Configuración y datos de referencia en caché (catálogos, formulario), como JSON.
class KvEntries extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();
  DateTimeColumn get actualizado => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {clave};
}

/// Lotes conocidos por el teléfono (descargados o creados sin conexión), con forma de respuesta del API.
class LotesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  TextColumn get codigo => text()();
  TextColumn get zona => text()();
  TextColumn get agricultor => text()();
  TextColumn get estado => text()();
  TextColumn get syncState => text()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get actualizado => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Evaluaciones: resumen para listados + borrador editable (formato request) si se editó en el teléfono.
class EvaluacionesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get loteId => text()();
  TextColumn get resumenJson => text()();
  TextColumn get borradorJson => text().nullable()();
  TextColumn get estado => text()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get syncState => text()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get actualizado => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Fotos tomadas en campo (se guardan en el teléfono hasta subirse).
class EvidenciasLocal extends Table {
  TextColumn get id => text()();
  TextColumn get evaluacionId => text()();
  IntColumn get muestraNumero => integer().nullable()();
  TextColumn get factor => text().nullable()();
  BlobColumn get bytes => blob()();
  TextColumn get mime => text()();
  TextColumn get syncState => text()();
  DateTimeColumn get creado => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Punto 3 (compra del lote): fijación de precio, cargas, gastos y pagos, uno por fila (JSON del request).
/// La fijación usa el id `fijacion:<loteId>`.
class MovimientosCompraLocal extends Table {
  TextColumn get id => text()();
  TextColumn get loteId => text()();
  TextColumn get tipo => text()();
  TextColumn get json => text()();
  TextColumn get syncState => text()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get actualizado => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Fotos de respaldo de la compra (ticket de balanza, voucher, recibo) tomadas en el equipo.
class ComprobantesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get loteId => text()();
  TextColumn get entidad => text()();
  TextColumn get entidadId => text()();
  BlobColumn get bytes => blob()();
  TextColumn get mime => text()();
  TextColumn get syncState => text()();
  DateTimeColumn get creado => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cola de operaciones a enviar al servidor, en orden (patrón outbox).
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get tipo => text()();
  TextColumn get entidadId => text()();
  TextColumn get descripcion => text()();
  TextColumn get payload => text()();
  IntColumn get intentos => integer().withDefault(const Constant(0))();
  TextColumn get ultimoError => text().nullable()();
  BoolColumn get bloqueada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get creado => dateTime()();
}

@DriftDatabase(
  tables: [KvEntries, LotesLocal, EvaluacionesLocal, EvidenciasLocal, MovimientosCompraLocal, ComprobantesLocal, Outbox],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrir());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: compra del lote (punto 3)
        await m.createTable(movimientosCompraLocal);
        await m.createTable(comprobantesLocal);
      }
    },
  );

  static QueryExecutor _abrir() => driftDatabase(
    name: 'garlic',
    web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
  );
}

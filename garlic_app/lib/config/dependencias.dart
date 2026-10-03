import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/catalogos_repository.dart';
import '../data/repositories/compra_repository.dart';
import '../data/repositories/config_repository.dart';
import '../data/repositories/evaluaciones_repository.dart';
import '../data/repositories/lotes_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/services/api/api_client.dart';
import '../data/services/conectividad_service.dart';
import '../data/services/local/app_database.dart';
import '../data/services/local/kv_store.dart';

/// Contenedor de dependencias (servicios → repositorios). Los ViewModels se crean por pantalla
/// en el router leyendo estos repositorios (guía de arquitectura de Flutter con `provider`).
class Dependencias {
  Dependencias._({
    required this.db,
    required this.config,
    required this.catalogos,
    required this.sync,
    required this.lotes,
    required this.evaluaciones,
    required this.compra,
  });

  final AppDatabase db;
  final ConfigRepository config;
  final CatalogosRepository catalogos;
  final SyncRepository sync;
  final LotesRepository lotes;
  final EvaluacionesRepository evaluaciones;
  final CompraRepository compra;

  static Future<Dependencias> iniciar({AppDatabase? db, ApiClient? api, ConectividadService? conectividad}) async {
    final base = db ?? AppDatabase();
    final cliente = api ?? ApiClient();
    final kv = KvStore(base);
    final config = ConfigRepository(kv: kv, api: cliente);
    final catalogos = CatalogosRepository(kv: kv, api: cliente);
    final sync = SyncRepository(db: base, api: cliente, conectividad: conectividad ?? ConectividadService(), kv: kv);
    final deps = Dependencias._(
      db: base,
      config: config,
      catalogos: catalogos,
      sync: sync,
      lotes: LotesRepository(db: base, api: cliente, sync: sync, catalogos: catalogos),
      evaluaciones: EvaluacionesRepository(db: base, api: cliente, sync: sync),
      compra: CompraRepository(db: base, api: cliente, sync: sync, kv: kv),
    );
    await config.cargar();
    await catalogos.cargar();
    await sync.iniciar();
    return deps;
  }

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider.value(value: config),
    ChangeNotifierProvider.value(value: catalogos),
    ChangeNotifierProvider.value(value: sync),
    Provider.value(value: lotes),
    Provider.value(value: evaluaciones),
    Provider.value(value: compra),
  ];
}

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/catalogo.dart';
import '../../../../domain/models/lote.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Formulario de identificación del lote (punto 1). Guarda en el teléfono y encola.
class LoteFormViewModel extends ChangeNotifier {
  LoteFormViewModel({required CatalogosRepository catalogos, required LotesRepository lotes})
    : _catalogos = catalogos,
      _lotes = lotes {
    guardar = Command(_guardar);
    ubicar = Command(_ubicar);
    registrarAgricultor = Command1(_registrarAgricultor);
    campaniaId = catalogos.campanias.lastOrNull?.id;
    localidadId = catalogos.localidades.length == 1 ? catalogos.localidades.first.id : null;
    catalogos.addListener(notifyListeners);
  }

  final CatalogosRepository _catalogos;
  final LotesRepository _lotes;

  late final Command<Lote> guardar;
  late final Command<void> ubicar;
  late final Command1<PersonaItem, ({String dni, String nombres})> registrarAgricultor;

  String? campaniaId;
  String codigo = '';
  String zona = '';
  String? variedadId;
  String? tipoCompraId;
  String? localidadId;
  String? agricultorId;
  String? proveedorId;
  bool titularDistinto = false;
  String titularDni = '';
  String titularNombres = '';
  double? latitud;
  double? longitud;
  DateTime? fechaArrancado;
  DateTime? fechaCorte;
  DateTime? fechaCarga;

  List<CatalogoItem> get campanias => _catalogos.campanias;
  List<CatalogoItem> get variedades => _catalogos.variedades;
  List<CatalogoItem> get tiposCompra => _catalogos.tiposCompra;
  List<CatalogoItem> get localidades => _catalogos.localidades;
  List<PersonaItem> get agricultores => _catalogos.agricultores;
  List<PersonaItem> get proveedores => _catalogos.proveedores;

  /// Error por campo devuelto por el guardado (p. ej. zona repetida).
  String? errorCampo(String campo) => guardar.failure?.fieldErrors[campo];

  void cambiar(VoidCallback f) {
    f();
    notifyListeners();
  }

  Future<Result<Lote>> _guardar() => _lotes.crear(
    NuevoLote(
      id: const Uuid().v4(),
      campaniaId: campaniaId!,
      codigo: codigo.trim(),
      variedadId: variedadId!,
      agricultorId: agricultorId!,
      proveedorId: proveedorId,
      titular:
          titularDistinto
              ? TitularLiquidacion(numeroDocumento: titularDni.trim(), nombres: titularNombres.trim())
              : null,
      localidadId: localidadId!,
      zona: zona.trim(),
      latitud: latitud,
      longitud: longitud,
      tipoCompraId: tipoCompraId!,
      fechaArrancado: fechaArrancado,
      fechaCorte: fechaCorte,
      fechaCarga: fechaCarga,
    ),
  );

  Future<Result<void>> _ubicar() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        return const Result.error(AppFailure(FailureKind.validacion, 'Permiso de ubicación denegado'));
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      latitud = pos.latitude;
      longitud = pos.longitude;
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(AppFailure(FailureKind.desconocido, 'No se pudo obtener la ubicación ($e)'));
    }
  }

  Future<Result<PersonaItem>> _registrarAgricultor(({String dni, String nombres}) datos) async {
    final r = await _catalogos.registrarPersona(rol: 'agricultor', dni: datos.dni, nombres: datos.nombres);
    if (r case Ok(:final value)) {
      agricultorId = value.id;
      notifyListeners();
    }
    return r;
  }

  @override
  void dispose() {
    _catalogos.removeListener(notifyListeners);
    guardar.dispose();
    ubicar.dispose();
    registrarAgricultor.dispose();
    super.dispose();
  }
}

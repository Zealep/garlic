import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/compra_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/catalogo.dart';
import '../../../../domain/models/compra.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/lote.dart';
import '../../../../domain/use_cases/calculo_compra.dart';
import '../../../../domain/use_cases/reglas_compra.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

enum PestanaCompra {
  precio('Precio'),
  cargas('Cargas'),
  gastos('Gastos'),
  pagos('Pagos'),
  resumen('Resumen');

  const PestanaCompra(this.titulo);

  final String titulo;
}

/// Persona que puede recibir un pago (agricultor, proveedor o titular de la liquidación del lote).
typedef Beneficiario = ({String personaId, String nombre, String rol});

/// Punto 3: fijación de precio, cargas, gastos vinculados, pagos y balance del lote.
/// Todo se guarda primero en el equipo y se sincroniza solo.
class CompraViewModel extends ChangeNotifier {
  CompraViewModel({
    required this.loteId,
    required LotesRepository lotes,
    required EvaluacionesRepository evaluaciones,
    required CompraRepository compra,
    required CatalogosRepository catalogos,
  }) : _evaluaciones = evaluaciones,
       _compra = compra,
       _catalogos = catalogos {
    _subs = [
      lotes.observarUno(loteId).listen((l) {
        lote = l;
        notifyListeners();
      }),
      compra.observar(loteId).listen(_alCambiarCompra),
      compra.observarComprobantes(loteId).listen((f) {
        comprobantes = f;
        notifyListeners();
      }),
      evaluaciones.observar(loteId: loteId).listen((e) {
        evaluacionesCerradas = e.where((x) => x.estado == EstadoEvaluacion.cerrada).toList();
        unawaited(_asegurarEvaluacion());
        notifyListeners();
      }),
    ];
    refrescar = Command(_refrescar);
    guardarFijacion = Command(_guardarFijacion);
    unawaited(refrescar.execute());
  }

  final String loteId;
  final EvaluacionesRepository _evaluaciones;
  final CompraRepository _compra;
  final CatalogosRepository _catalogos;
  late final List<StreamSubscription<Object?>> _subs;

  late final Command<void> refrescar;
  late final Command<void> guardarFijacion;

  Lote? lote;
  CompraLote? compra;
  List<ComprobanteLocal> comprobantes = const [];
  List<EvaluacionResumen> evaluacionesCerradas = const [];
  PestanaCompra pestana = PestanaCompra.precio;

  /// Fijación en edición (se guarda con "Guardar precio").
  FijacionPrecio? fijacion;
  bool fijacionModificada = false;

  /// % de calidad de cada muestra de la evaluación elegida para el precio.
  List<Map<String, double>> calidadMuestras = const [];
  List<int> numerosMuestra = const [];
  String? errorEvaluacion;

  bool get editable => lote?.activo ?? false;
  List<CatalogoItem> get clasesCalidad => _catalogos.formulario?.clasesCalidad ?? const [];
  List<CatalogoItem> get tiposEmpaque => _catalogos.tiposEmpaque;
  List<CatalogoItem> get tiposGasto => _catalogos.tiposGasto;
  List<CatalogoItem> get condicionesPago => _catalogos.condicionesPago;
  bool get catalogosCompra => tiposGasto.isNotEmpty && condicionesPago.isNotEmpty;

  BalanceCompra get balance => (compra ?? CompraLote(loteId: loteId)).balance;

  ResultadoFijacion? get calculoFijacion => fijacion?.calcular(calidadMuestras);

  /// Precio pactado guardado (sugerido en cada carga nueva).
  double? get precioPactado => compra?.fijacion?.precioPactado;

  String? get problemaFijacion =>
      fijacion == null ? null : ReglasCompra.fijacion(fijacion!, calidadMuestras, clasesCalidad);

  List<Beneficiario> get beneficiarios {
    final l = lote;
    if (l == null) return const [];
    String? personaDeRol(List<PersonaItem> lista, String rolId) =>
        lista.where((p) => p.id == rolId).firstOrNull?.personaId;
    final lista = <Beneficiario>[];
    final agricultor = personaDeRol(_catalogos.agricultores, l.agricultor.id);
    if (agricultor != null) lista.add((personaId: agricultor, nombre: l.agricultor.nombres, rol: 'Agricultor'));
    if (l.proveedor != null) {
      final proveedor = personaDeRol(_catalogos.proveedores, l.proveedor!.id);
      if (proveedor != null) lista.add((personaId: proveedor, nombre: l.proveedor!.nombres, rol: 'Proveedor'));
    }
    final titular = l.titularLiquidacion;
    if (titular != null && lista.every((b) => b.personaId != titular.id)) {
      lista.add((personaId: titular.id, nombre: titular.nombres, rol: 'DNI liquidación'));
    }
    return lista;
  }

  CatalogoItem? buscar(List<CatalogoItem> lista, String? id) => _catalogos.buscar(lista, id);

  List<ComprobanteLocal> fotosDe(String entidadId) => comprobantes.where((f) => f.entidadId == entidadId).toList();

  void irA(PestanaCompra p) {
    pestana = p;
    notifyListeners();
  }

  // ------------------------------------------------------------------ carga de datos

  Future<Result<void>> _refrescar() async {
    final r = await _compra.refrescar(loteId);
    await _evaluaciones.refrescar();
    return r;
  }

  void _alCambiarCompra(CompraLote c) {
    compra = c;
    if (!fijacionModificada) {
      fijacion = c.fijacion == null ? null : FijacionPrecio.fromJson(c.fijacion!.toRequestJson());
    }
    unawaited(_asegurarEvaluacion());
    notifyListeners();
  }

  /// Si no hay fijación todavía, la prepara con la evaluación cerrada más reciente y los últimos precios usados.
  Future<void> _asegurarEvaluacion() async {
    if (fijacion == null && evaluacionesCerradas.isNotEmpty && compra != null && compra!.fijacion == null) {
      fijacion = FijacionPrecio(evaluacionId: evaluacionesCerradas.first.id, preciosBase: await _preciosIniciales());
    }
    final id = fijacion?.evaluacionId;
    if (id != null && id != _evaluacionCargada) await _cargarCalidad(id);
  }

  String? _evaluacionCargada;

  Future<Map<String, double>> _preciosIniciales() async {
    final ultimos = await _compra.ultimosPreciosBase();
    final ids = clasesCalidad.map((c) => c.id).toSet();
    return {
      for (final e in ultimos.entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
  }

  Future<void> _cargarCalidad(String evaluacionId) async {
    _evaluacionCargada = evaluacionId;
    final r = await _evaluaciones.cargar(evaluacionId);
    switch (r) {
      case Ok(value: final ev):
        final muestras = [...ev.muestras]..sort((a, b) => a.numero.compareTo(b.numero));
        calidadMuestras = muestras.map((m) => Map<String, double>.of(m.calidad)).toList();
        numerosMuestra = muestras.map((m) => m.numero).toList();
        errorEvaluacion = null;
      case Error(:final failure):
        _evaluacionCargada = null;
        calidadMuestras = const [];
        numerosMuestra = const [];
        errorEvaluacion = 'No se pudo leer la evaluación (${failure.message}). Conéctate para descargarla.';
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------ fijación de precio

  void elegirEvaluacion(String id) {
    fijacion?.evaluacionId = id;
    _modificar();
    unawaited(_cargarCalidad(id));
  }

  void setPrecioBase(String claseId, double? valor) {
    if (valor == null) {
      fijacion!.preciosBase.remove(claseId);
    } else {
      fijacion!.preciosBase[claseId] = valor;
    }
    _modificar();
  }

  void setGastoLlenado(double? v) {
    fijacion!.gastoLlenado = v ?? 0;
    _modificar();
  }

  void setPrecioPactado(double? v) {
    fijacion!.precioPactado = v;
    fijacion!.fechaPacto = v == null ? null : (fijacion!.fechaPacto ?? DateTime.now());
    _modificar();
  }

  void usarPrecioTecnico() {
    final tecnico = calculoFijacion?.precioTecnico;
    if (tecnico != null && tecnico > 0) setPrecioPactado(CalculoCompra.redondear(tecnico, 2));
  }

  void setObservacionPrecio(String v) {
    fijacion!.observacion = v;
    _modificar();
  }

  void descartarCambiosPrecio() {
    fijacionModificada = false;
    fijacion = compra?.fijacion == null ? null : FijacionPrecio.fromJson(compra!.fijacion!.toRequestJson());
    unawaited(_asegurarEvaluacion());
    notifyListeners();
  }

  void _modificar() {
    fijacionModificada = true;
    notifyListeners();
  }

  Future<Result<void>> _guardarFijacion() async {
    final f = fijacion;
    final l = lote;
    if (f == null || l == null) return const Result.error(AppFailure(FailureKind.validacion, 'Sin datos para guardar'));
    final problema = problemaFijacion;
    if (problema != null) return Result.error(AppFailure(FailureKind.validacion, problema));
    await _compra.guardarFijacion(loteId, l.codigo, f);
    fijacionModificada = false;
    notifyListeners();
    return const Result.ok(null);
  }

  // ------------------------------------------------------------------ cargas, gastos y pagos

  Carga nuevaCarga() => Carga(
    id: _compra.nuevoId(),
    fecha: DateTime.now(),
    kg: 0,
    precioKg: precioPactado ?? 0,
    tipoEmpaqueId: tiposEmpaque.firstOrNull?.id,
    placa: compra?.cargas.lastOrNull?.placa,
  );

  GastoVinculado nuevoGasto({String? cargaId}) => GastoVinculado(
    id: _compra.nuevoId(),
    tipoGastoId: tiposGasto.firstOrNull?.id ?? '',
    fecha: DateTime.now(),
    monto: 0,
    cargaId: cargaId ?? compra?.cargas.lastOrNull?.id,
  );

  Pago nuevoPago() => Pago(
    id: _compra.nuevoId(),
    fecha: DateTime.now(),
    condicionPagoId: condicionesPago.firstOrNull?.id ?? '',
    monto: 0,
    beneficiarioId: beneficiarios.firstOrNull?.personaId,
  );

  /// Devuelve el problema a mostrar o null si se guardó.
  Future<String?> guardarCarga(Carga c) async {
    final problema = ReglasCompra.carga(c);
    if (problema != null) return problema;
    await _compra.guardarCarga(loteId, lote?.codigo ?? '', c);
    return null;
  }

  Future<String?> guardarGasto(GastoVinculado g) async {
    final problema = ReglasCompra.gasto(g, buscar(tiposGasto, g.tipoGastoId));
    if (problema != null) return problema;
    await _compra.guardarGasto(loteId, lote?.codigo ?? '', g);
    return null;
  }

  Future<String?> guardarPago(Pago p) async {
    final problema = ReglasCompra.pago(p);
    if (problema != null) return problema;
    await _compra.guardarPago(loteId, lote?.codigo ?? '', p);
    return null;
  }

  /// Una carga con gastos asociados no se elimina (igual que en el servidor).
  Future<String?> eliminarCarga(Carga c) async {
    if (compra?.gastos.any((g) => g.cargaId == c.id) ?? false) {
      return 'La carga tiene gastos vinculados; quítelos o páselos a generales primero';
    }
    await _compra.eliminar(loteId: loteId, id: c.id, tipo: 'carga', descripcion: 'Eliminar carga');
    return null;
  }

  Future<void> eliminarGasto(GastoVinculado g) =>
      _compra.eliminar(loteId: loteId, id: g.id, tipo: 'gasto', descripcion: 'Eliminar gasto');

  Future<void> eliminarPago(Pago p) =>
      _compra.eliminar(loteId: loteId, id: p.id, tipo: 'pago', descripcion: 'Eliminar pago');

  Future<void> agregarFoto(EntidadComprobante entidad, String entidadId, Uint8List bytes, String mime) =>
      _compra.agregarComprobante(loteId: loteId, entidad: entidad, entidadId: entidadId, bytes: bytes, mime: mime);

  Future<void> eliminarFoto(String id) => _compra.eliminarComprobante(id);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    refrescar.dispose();
    guardarFijacion.dispose();
    super.dispose();
  }
}

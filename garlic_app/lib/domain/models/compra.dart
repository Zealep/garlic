import '../../utils/formato.dart';
import '../use_cases/calculo_compra.dart';
import 'sync.dart';

double? _num(Object? v) => (v as num?)?.toDouble();

String? _texto(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

/// Módulo de fijación de precio del lote (punto 3). Precios en S/ por kg.
///
/// precio técnico = promedio de los precios por muestra − gasto de llenado;
/// precio de una muestra = Σ precio base de la clase × % de la clase en la muestra.
class FijacionPrecio {
  FijacionPrecio({
    required this.evaluacionId,
    Map<String, double>? preciosBase,
    this.gastoLlenado = 0,
    this.precioPactado,
    this.fechaPacto,
    this.observacion,
    this.syncState = SyncState.sincronizado,
    this.syncError,
  }) : preciosBase = preciosBase ?? {};

  /// Acepta el request guardado en el equipo o la respuesta del servidor (`precios: [{claseCalidadId, precioBase}]`).
  factory FijacionPrecio.fromJson(Map<String, Object?> json, {SyncState syncState = SyncState.sincronizado, String? syncError}) =>
      FijacionPrecio(
        evaluacionId: json['evaluacionId']! as String,
        preciosBase: {
          for (final p in (json['precios'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
            p['claseCalidadId']! as String: _num(p['precioBase']) ?? 0,
        },
        gastoLlenado: _num(json['gastoLlenado']) ?? 0,
        precioPactado: _num(json['precioPactado']),
        fechaPacto: Formato.parseFecha(json['fechaPacto']),
        observacion: json['observacion'] as String?,
        syncState: syncState,
        syncError: syncError,
      );

  String evaluacionId;
  final Map<String, double> preciosBase;
  double gastoLlenado;
  double? precioPactado;
  DateTime? fechaPacto;
  String? observacion;
  final SyncState syncState;
  final String? syncError;

  bool get pactado => precioPactado != null;

  Map<String, Object?> toRequestJson() => {
    'evaluacionId': evaluacionId,
    'precios': [
      for (final e in preciosBase.entries) {'claseCalidadId': e.key, 'precioBase': e.value},
    ],
    'gastoLlenado': gastoLlenado,
    'precioPactado': precioPactado,
    'fechaPacto': precioPactado == null || fechaPacto == null ? null : Formato.fechaIso(fechaPacto!),
    'observacion': _texto(observacion),
  };

  /// Cálculo con los % de calidad de cada muestra de la evaluación.
  ResultadoFijacion calcular(List<Map<String, double>> calidadMuestras) =>
      CalculoCompra.fijacion(preciosBase, calidadMuestras, gastoLlenado);
}

/// 3.2 Compra de materia prima: un camión (carga).
class Carga {
  Carga({
    required this.id,
    required this.fecha,
    required this.kg,
    required this.precioKg,
    this.destarePct = 1,
    this.cantidadEmpaques = 0,
    this.tipoEmpaqueId,
    this.placa,
    this.observacion,
    this.syncState = SyncState.sincronizado,
    this.syncError,
  });

  factory Carga.fromJson(Map<String, Object?> json, {SyncState syncState = SyncState.sincronizado, String? syncError}) =>
      Carga(
        id: json['id']! as String,
        fecha: Formato.parseFecha(json['fecha']) ?? DateTime.now(),
        kg: _num(json['kg']) ?? 0,
        precioKg: _num(json['precioKg']) ?? 0,
        destarePct: _num(json['destarePct']) ?? 1,
        cantidadEmpaques: (json['cantidadEmpaques'] as num?)?.toInt() ?? 0,
        tipoEmpaqueId: json['tipoEmpaqueId'] as String?,
        placa: json['placa'] as String?,
        observacion: json['observacion'] as String?,
        syncState: syncState,
        syncError: syncError,
      );

  final String id;
  DateTime fecha;
  double kg;
  double precioKg;
  double destarePct;
  int cantidadEmpaques;
  String? tipoEmpaqueId;
  String? placa;
  String? observacion;
  final SyncState syncState;
  final String? syncError;

  LineaCarga get calculo => CalculoCompra.carga(kg, precioKg, destarePct);

  Map<String, Object?> toJson() => {'id': id, ...toRequestJson()};

  Map<String, Object?> toRequestJson() => {
    'fecha': Formato.fechaIso(fecha),
    'placa': _texto(placa)?.toUpperCase(),
    'kg': kg,
    'cantidadEmpaques': cantidadEmpaques,
    'tipoEmpaqueId': tipoEmpaqueId,
    'precioKg': precioKg,
    'destarePct': destarePct,
    'observacion': _texto(observacion),
  };
}

/// Gasto vinculado a la materia prima (llevar el producto al packing). Sin carga = gasto general.
class GastoVinculado {
  GastoVinculado({
    required this.id,
    required this.tipoGastoId,
    required this.fecha,
    required this.monto,
    this.cargaId,
    this.descripcion,
    this.syncState = SyncState.sincronizado,
    this.syncError,
  });

  factory GastoVinculado.fromJson(
    Map<String, Object?> json, {
    SyncState syncState = SyncState.sincronizado,
    String? syncError,
  }) => GastoVinculado(
    id: json['id']! as String,
    tipoGastoId: json['tipoGastoId']! as String,
    fecha: Formato.parseFecha(json['fecha']) ?? DateTime.now(),
    monto: _num(json['monto']) ?? 0,
    cargaId: json['cargaId'] as String?,
    descripcion: json['descripcion'] as String?,
    syncState: syncState,
    syncError: syncError,
  );

  final String id;
  String tipoGastoId;
  DateTime fecha;
  double monto;
  String? cargaId;
  String? descripcion;
  final SyncState syncState;
  final String? syncError;

  Map<String, Object?> toJson() => {'id': id, ...toRequestJson()};

  Map<String, Object?> toRequestJson() => {
    'cargaId': cargaId,
    'tipoGastoId': tipoGastoId,
    'fecha': Formato.fechaIso(fecha),
    'monto': monto,
    'descripcion': _texto(descripcion),
  };
}

/// 3.1 Abono / adelanto al agricultor o proveedor, solo por la materia prima.
class Pago {
  Pago({
    required this.id,
    required this.fecha,
    required this.condicionPagoId,
    required this.monto,
    this.beneficiarioId,
    this.referencia,
    this.observacion,
    this.syncState = SyncState.sincronizado,
    this.syncError,
  });

  factory Pago.fromJson(Map<String, Object?> json, {SyncState syncState = SyncState.sincronizado, String? syncError}) =>
      Pago(
        id: json['id']! as String,
        fecha: Formato.parseFecha(json['fecha']) ?? DateTime.now(),
        condicionPagoId: json['condicionPagoId']! as String,
        monto: _num(json['monto']) ?? 0,
        beneficiarioId: json['beneficiarioId'] as String?,
        referencia: json['referencia'] as String?,
        observacion: json['observacion'] as String?,
        syncState: syncState,
        syncError: syncError,
      );

  final String id;
  DateTime fecha;
  String condicionPagoId;
  double monto;

  /// Persona que recibe el pago (agricultor, proveedor o titular de la liquidación).
  String? beneficiarioId;
  String? referencia;
  String? observacion;
  final SyncState syncState;
  final String? syncError;

  Map<String, Object?> toJson() => {'id': id, ...toRequestJson()};

  Map<String, Object?> toRequestJson() => {
    'fecha': Formato.fechaIso(fecha),
    'condicionPagoId': condicionPagoId,
    'monto': monto,
    'beneficiarioId': beneficiarioId,
    'referencia': _texto(referencia),
    'observacion': _texto(observacion),
  };
}

/// Registro de la compra al que pertenece un comprobante (foto).
enum EntidadComprobante {
  carga('CARGA', 'Ticket de balanza'),
  gasto('GASTO', 'Recibo'),
  pago('PAGO', 'Voucher');

  const EntidadComprobante(this.api, this.etiqueta);

  final String api;
  final String etiqueta;
}

/// Todo el punto 3 de un lote, tal como está en el equipo.
class CompraLote {
  const CompraLote({
    required this.loteId,
    this.fijacion,
    this.cargas = const [],
    this.gastos = const [],
    this.pagos = const [],
  });

  final String loteId;
  final FijacionPrecio? fijacion;
  final List<Carga> cargas;
  final List<GastoVinculado> gastos;
  final List<Pago> pagos;

  bool get vacia => fijacion == null && cargas.isEmpty && gastos.isEmpty && pagos.isEmpty;

  BalanceCompra get balance => CalculoCompra.balance(
    cargas.map((c) => c.calculo).toList(),
    gastos.map((g) => g.monto).toList(),
    pagos.map((p) => p.monto).toList(),
  );

  int get cantidadEmpaques => cargas.fold(0, (a, c) => a + c.cantidadEmpaques);

  int get pendientes =>
      [
        fijacion?.syncState,
        ...cargas.map((c) => c.syncState),
        ...gastos.map((g) => g.syncState),
        ...pagos.map((p) => p.syncState),
      ].where((s) => s != null && s != SyncState.sincronizado).length;

  /// Número visible de la carga ("Carga 2"), según el orden por fecha.
  int numeroCarga(String cargaId) => cargas.indexWhere((c) => c.id == cargaId) + 1;
}

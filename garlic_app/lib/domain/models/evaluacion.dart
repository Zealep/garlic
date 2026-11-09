import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../utils/formato.dart';
import 'foto.dart';
import 'sync.dart';

enum EstadoEvaluacion {
  borrador('BORRADOR'),
  cerrada('CERRADA');

  const EstadoEvaluacion(this.api);

  final String api;

  static EstadoEvaluacion parse(String? v) => v == 'CERRADA' ? cerrada : borrador;
}

/// Dictamen de una evaluación cerrada (null = pendiente). No bloquea la compra: un lote rechazado
/// puede comprarse igual por necesidad de producto.
enum ResultadoEvaluacion {
  aceptada('ACEPTADA', 'Aceptada'),
  rechazada('RECHAZADA', 'Rechazada'),
  sinAcuerdo('SIN_ACUERDO', 'Sin acuerdo de precio');

  const ResultadoEvaluacion(this.api, this.etiqueta);

  final String api;
  final String etiqueta;

  static ResultadoEvaluacion? parse(Object? v) => values.where((r) => r.api == v).firstOrNull;
}

/// Fila de listados de evaluaciones (bandeja, historial del lote).
class EvaluacionResumen {
  const EvaluacionResumen({
    required this.id,
    required this.loteId,
    required this.loteCodigo,
    required this.fecha,
    required this.estado,
    required this.nroMuestras,
    this.zona,
    this.evaluador,
    this.promedioPrimera,
    this.resultado,
    this.syncState = SyncState.sincronizado,
    this.syncError,
  });

  factory EvaluacionResumen.fromJson(
    Map<String, Object?> json, {
    SyncState syncState = SyncState.sincronizado,
    String? syncError,
  }) => EvaluacionResumen(
    id: json['id']! as String,
    loteId: json['loteId']! as String,
    loteCodigo: (json['loteCodigo'] ?? '') as String,
    zona: json['zona'] as String?,
    fecha: Formato.parseFecha(json['fechaEvaluacion']) ?? DateTime.now(),
    estado: EstadoEvaluacion.parse(json['estado'] as String?),
    evaluador: json['evaluador'] as String?,
    nroMuestras: (json['nroMuestras'] as num?)?.toInt() ?? 0,
    promedioPrimera: (json['promedioPrimera'] as num?)?.toDouble(),
    resultado: ResultadoEvaluacion.parse(json['resultado']),
    syncState: syncState,
    syncError: syncError,
  );

  final String id;
  final String loteId;
  final String loteCodigo;
  final String? zona;
  final DateTime fecha;
  final EstadoEvaluacion estado;
  final String? evaluador;
  final int nroMuestras;

  /// Promedio de la primera clase de calidad (PRIMERA), si se conoce localmente.
  final double? promedioPrimera;

  /// Dictamen tras cerrar (null = pendiente o borrador).
  final ResultadoEvaluacion? resultado;
  final SyncState syncState;
  final String? syncError;

  Map<String, Object?> toJson() => {
    'id': id,
    'loteId': loteId,
    'loteCodigo': loteCodigo,
    'zona': zona,
    'fechaEvaluacion': Formato.fechaIso(fecha),
    'estado': estado.api,
    'evaluador': evaluador,
    'nroMuestras': nroMuestras,
    'promedioPrimera': promedioPrimera,
    'resultado': resultado?.api,
  };
}

/// Daño no visible marcado en una muestra. Si el tipo pide cantidades (parálisis) se cuentan los frutos
/// y se calcula el % de daño.
class DanoBorrador {
  DanoBorrador({this.total, this.afectados});

  int? total;
  int? afectados;

  /// Frutos con problema / total × 100 (2 decimales); null sin cantidades.
  double? get porcentaje =>
      (total == null || afectados == null || total == 0)
          ? null
          : double.parse((afectados! * 100 / total!).toStringAsFixed(2));

  DanoBorrador copia() => DanoBorrador(total: total, afectados: afectados);
}

class SanidadBorrador {
  SanidadBorrador({required this.presente, this.porcentaje});

  bool presente;
  double? porcentaje;

  SanidadBorrador copia() => SanidadBorrador(presente: presente, porcentaje: porcentaje);
}

/// Muestra representativa: % por clase de calidad (2.1) y por calibre (2.2), sensoriales (humedad SI/NO,
/// empaste y daños) y sanidad. El [id] lo genera la app y no cambia al renumerar: identifica sus fotos.
class MuestraBorrador {
  MuestraBorrador({
    String? id,
    required this.numero,
    this.observacion,
    Map<String, double>? calidad,
    Map<String, double>? calibres,
    Map<String, bool>? humedad,
    Set<String>? empastes,
    Map<String, DanoBorrador>? danos,
    Map<String, SanidadBorrador>? sanidad,
  }) : id = id ?? const Uuid().v4(),
       calidad = calidad ?? {},
       calibres = calibres ?? {},
       humedad = humedad ?? {},
       empastes = empastes ?? {},
       danos = danos ?? {},
       sanidad = sanidad ?? {};

  final String id;
  int numero;
  String? observacion;
  final Map<String, double> calidad;
  final Map<String, double> calibres;

  /// 2.2.1 Humedad: SI (true) / NO (false) por indicador.
  final Map<String, bool> humedad;
  final Set<String> empastes;
  final Map<String, DanoBorrador> danos;
  final Map<String, SanidadBorrador> sanidad;

  double get totalCalidad => calidad.values.fold(0, (a, b) => a + b);
  double get totalCalibres => calibres.values.fold(0, (a, b) => a + b);

  /// Lo que falta para que los calibres sumen 100% (negativo si se pasan).
  double get faltaCalibres => double.parse((100 - totalCalibres).toStringAsFixed(2));

  /// Pone lo que falta para llegar a 100% en el primer calibre sin valor o, si todos tienen, en el último.
  /// No hace nada si ya suman 100% o se pasan.
  void completarCalibres() {
    if (calibres.isEmpty || faltaCalibres <= 0) return;
    final destino = calibres.keys.firstWhere((id) => calibres[id] == 0, orElse: () => calibres.keys.last);
    calibres[destino] = double.parse((calibres[destino]! + faltaCalibres).toStringAsFixed(2));
  }

  /// Copia los sensoriales y la sanidad de otra muestra (suelen repetirse entre muestras del lote).
  /// Las cantidades de frutos no se copian: se cuentan en cada muestra.
  void copiarSensorialesYSanidad(MuestraBorrador otra) {
    humedad
      ..clear()
      ..addAll(otra.humedad);
    empastes
      ..clear()
      ..addAll(otra.empastes);
    danos
      ..clear()
      ..addAll({for (final id in otra.danos.keys) id: DanoBorrador()});
    sanidad
      ..clear()
      ..addAll({for (final e in otra.sanidad.entries) e.key: e.value.copia()});
  }

  bool get sinSensorialesNiSanidad => humedad.isEmpty && empastes.isEmpty && danos.isEmpty && sanidad.isEmpty;

  MuestraBorrador copia() => MuestraBorrador(
    id: id,
    numero: numero,
    observacion: observacion,
    calidad: {...calidad},
    calibres: {...calibres},
    humedad: {...humedad},
    empastes: {...empastes},
    danos: {for (final e in danos.entries) e.key: e.value.copia()},
    sanidad: {for (final e in sanidad.entries) e.key: e.value.copia()},
  );

  Map<String, Object?> toRequestJson() => {
    'id': id,
    'numero': numero,
    'observacion': observacion,
    'calidad': [
      for (final e in calidad.entries) {'claseCalidadId': e.key, 'porcentaje': _redondeo(e.value)},
    ],
    'calibres': [
      for (final e in calibres.entries) {'calibreId': e.key, 'porcentaje': _redondeo(e.value)},
    ],
    'humedad': [
      for (final e in humedad.entries) {'tipoHumedadId': e.key, 'presente': e.value},
    ],
    'empastes': empastes.toList(),
    'danos': [
      for (final e in danos.entries)
        {'tipoDanoId': e.key, 'frutosTotal': e.value.total, 'frutosAfectados': e.value.afectados},
    ],
    'sanidad': [
      for (final e in sanidad.entries)
        {
          'enfermedadId': e.key,
          'presente': e.value.presente,
          'porcentaje': e.value.presente ? e.value.porcentaje : null,
        },
    ],
  };

  /// Acepta el formato del request (guardado en el teléfono) y el de la respuesta del API
  /// (`id` de la opción en lugar de `claseCalidadId`, `calibreId`, ...).
  factory MuestraBorrador.fromJson(Map<String, Object?> m) {
    List<Map<String, Object?>> lista(Object? v) => ((v as List<Object?>?) ?? const []).cast<Map<String, Object?>>();
    String clave(Map<String, Object?> f, String campo) => (f[campo] ?? f['id'])! as String;
    double? numero(Object? v) => (v as num?)?.toDouble();
    return MuestraBorrador(
      id: m['id'] as String?,
      numero: (m['numero']! as num).toInt(),
      observacion: m['observacion'] as String?,
      calidad: {for (final c in lista(m['calidad'])) clave(c, 'claseCalidadId'): numero(c['porcentaje'])!},
      calibres: {for (final c in lista(m['calibres'])) clave(c, 'calibreId'): numero(c['porcentaje'])!},
      humedad: {for (final h in lista(m['humedad'])) clave(h, 'tipoHumedadId'): h['presente']! as bool},
      empastes: {
        for (final e in (m['empastes'] as List<Object?>?) ?? const []) e is Map ? e['id']! as String : e! as String,
      },
      danos: {
        for (final d in lista(m['danos']))
          clave(d, 'tipoDanoId'): DanoBorrador(
            total: (d['frutosTotal'] as num?)?.toInt(),
            afectados: (d['frutosAfectados'] as num?)?.toInt(),
          ),
      },
      sanidad: {
        for (final x in lista(m['sanidad']))
          clave(x, 'enfermedadId'): SanidadBorrador(
            presente: x['presente']! as bool,
            porcentaje: numero(x['porcentaje']),
          ),
      },
    );
  }

  static double _redondeo(double v) => double.parse(v.toStringAsFixed(2));
}

/// Evaluación en edición (punto 2 del protocolo). Es un borrador mutable que pertenece al
/// ViewModel del wizard; se serializa en el formato del request del API para guardarse
/// localmente y encolarse para sincronizar. Todo lo observado está en sus muestras.
class EvaluacionBorrador {
  EvaluacionBorrador({
    required this.id,
    required this.loteId,
    required this.fecha,
    this.evaluadorId,
    this.observacion,
    this.estado = EstadoEvaluacion.borrador,
    this.resultado,
    this.motivoResultado,
    List<MuestraBorrador>? muestras,
  }) : muestras = muestras ?? [];

  /// Formato del request (lo que se guarda localmente y se envía).
  factory EvaluacionBorrador.fromRequestJson(
    Map<String, Object?> json, {
    required String loteId,
    EstadoEvaluacion? estado,
  }) => EvaluacionBorrador(
    id: json['id']! as String,
    loteId: loteId,
    evaluadorId: json['evaluadorId'] as String?,
    fecha: Formato.parseFecha(json['fechaEvaluacion']) ?? DateTime.now(),
    observacion: json['observacion'] as String?,
    estado: estado ?? EstadoEvaluacion.parse(json['estado'] as String?),
    resultado: ResultadoEvaluacion.parse(json['resultado']),
    motivoResultado: json['motivoResultado'] as String?,
    muestras: _muestras(json['muestras']),
  );

  /// Formato de la respuesta de detalle del API (evaluación descargada del servidor).
  factory EvaluacionBorrador.fromResponseJson(Map<String, Object?> json) => EvaluacionBorrador(
    id: json['id']! as String,
    loteId: json['loteId']! as String,
    evaluadorId: (json['evaluador'] as Map<String, Object?>?)?['id'] as String?,
    fecha: Formato.parseFecha(json['fechaEvaluacion']) ?? DateTime.now(),
    observacion: json['observacion'] as String?,
    estado: EstadoEvaluacion.parse(json['estado'] as String?),
    resultado: ResultadoEvaluacion.parse(json['resultado']),
    motivoResultado: json['motivoResultado'] as String?,
    muestras: _muestras(json['muestras']),
  );

  static List<MuestraBorrador> _muestras(Object? v) =>
      ((v as List<Object?>?) ?? const []).cast<Map<String, Object?>>().map(MuestraBorrador.fromJson).toList()
        ..sort((a, b) => a.numero.compareTo(b.numero));

  final String id;
  final String loteId;
  String? evaluadorId;
  DateTime fecha;
  String? observacion;
  EstadoEvaluacion estado;

  /// Dictamen (solo cerradas): aceptada, rechazada o sin acuerdo de precio. Null = pendiente.
  ResultadoEvaluacion? resultado;
  String? motivoResultado;
  final List<MuestraBorrador> muestras;

  bool get editable => estado == EstadoEvaluacion.borrador;

  Map<String, Object?> toRequestJson() => {
    'id': id,
    'evaluadorId': evaluadorId,
    'fechaEvaluacion': Formato.fechaIso(fecha),
    'observacion': (observacion?.trim().isEmpty ?? true) ? null : observacion!.trim(),
    'muestras': [for (final m in muestras) m.toRequestJson()],
  };

  /// Promedio por opción sobre las muestras que la registran (columna PROM del protocolo).
  Map<String, double> promediosCalidad() => _promedios((m) => m.calidad);

  Map<String, double> promediosCalibres() => _promedios((m) => m.calibres);

  /// % de daño promedio por tipo (parálisis) sobre las muestras que lo cuentan.
  Map<String, double> promediosDanos() => _promedios(
    (m) => {
      for (final e in m.danos.entries)
        if (e.value.porcentaje != null) e.key: e.value.porcentaje!,
    },
  );

  /// Incidencia promedio por enfermedad sobre las muestras que la respondieron (NO cuenta como 0%).
  Map<String, double> promediosSanidad() =>
      _promedios((m) => {for (final e in m.sanidad.entries) e.key: e.value.presente ? (e.value.porcentaje ?? 0) : 0});

  /// Cuántas muestras marcan SI en cada indicador de humedad.
  Map<String, int> muestrasConHumedad() {
    final n = <String, int>{};
    for (final m in muestras) {
      for (final e in m.humedad.entries) {
        n[e.key] = (n[e.key] ?? 0) + (e.value ? 1 : 0);
      }
    }
    return n;
  }

  Map<String, double> _promedios(Map<String, double> Function(MuestraBorrador) valores) {
    final suma = <String, double>{};
    final n = <String, int>{};
    for (final m in muestras) {
      for (final e in valores(m).entries) {
        suma[e.key] = (suma[e.key] ?? 0) + e.value;
        n[e.key] = (n[e.key] ?? 0) + 1;
      }
    }
    return {for (final k in suma.keys) k: double.parse((suma[k]! / n[k]!).toStringAsFixed(2))};
  }

  /// Nueva muestra que reutiliza los calibres elegidos en la última (con 0%, pendientes de llenar).
  MuestraBorrador nuevaMuestra() => MuestraBorrador(
    numero: muestras.length + 1,
    calibres: muestras.isEmpty ? {} : {for (final id in muestras.last.calibres.keys) id: 0},
  );

  /// Quita la muestra y renumera las demás 1..n en el orden en que se ven (de izquierda a derecha).
  void quitarMuestra(String muestraId) {
    muestras.removeWhere((m) => m.id == muestraId);
    for (final (i, m) in muestras.indexed) {
      m.numero = i + 1;
    }
  }
}

/// Sección del wizard a la que pertenece una foto.
enum SeccionFoto {
  /// Evidencia general del lote (paso Datos): sin muestra.
  general,

  /// Foto de una muestra (calidad, calibre, sensoriales o sanidad).
  muestra;

  static SeccionFoto de(EvidenciaLocal foto) =>
      foto.muestraId != null || foto.muestraNumero != null ? muestra : general;
}

/// Foto tomada en campo, guardada en el teléfono hasta subirse.
class EvidenciaLocal implements FotoLocal {
  const EvidenciaLocal({
    required this.id,
    required this.evaluacionId,
    required this.bytes,
    required this.mime,
    required this.creado,
    this.muestraId,
    this.muestraNumero,
    this.factor,
    this.syncState = SyncState.pendiente,
  });

  @override
  final String id;
  final String evaluacionId;

  /// Muestra a la que pertenece (no cambia al renumerar); null = evidencia general.
  final String? muestraId;
  final int? muestraNumero;
  final String? factor;
  @override
  final Uint8List bytes;
  final String mime;
  final DateTime creado;
  @override
  final SyncState syncState;
}

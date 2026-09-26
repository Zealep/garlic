import 'dart:typed_data';

import '../../utils/formato.dart';
import 'sync.dart';

enum NivelHumedad {
  baja('BAJA'),
  media('MEDIA'),
  alta('ALTA');

  const NivelHumedad(this.api);

  final String api;

  String get etiqueta => api[0] + api.substring(1).toLowerCase();

  static NivelHumedad parse(String v) => NivelHumedad.values.firstWhere((e) => e.api == v);
}

enum EstadoEvaluacion {
  borrador('BORRADOR'),
  cerrada('CERRADA');

  const EstadoEvaluacion(this.api);

  final String api;

  static EstadoEvaluacion parse(String? v) => v == 'CERRADA' ? cerrada : borrador;
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
  };
}

/// Muestra representativa: % por clase de calidad (2.1) y por calibre (2.2).
class MuestraBorrador {
  MuestraBorrador({required this.numero, this.observacion, Map<String, double>? calidad, Map<String, double>? calibres})
    : calidad = calidad ?? {},
      calibres = calibres ?? {};

  int numero;
  String? observacion;
  final Map<String, double> calidad;
  final Map<String, double> calibres;

  double get totalCalidad => calidad.values.fold(0, (a, b) => a + b);
  double get totalCalibres => calibres.values.fold(0, (a, b) => a + b);

  MuestraBorrador copia() =>
      MuestraBorrador(numero: numero, observacion: observacion, calidad: {...calidad}, calibres: {...calibres});
}

class SanidadBorrador {
  SanidadBorrador({required this.presente, this.porcentaje});

  bool presente;
  double? porcentaje;
}

/// Evaluación en edición (punto 2 del protocolo). Es un borrador mutable que pertenece al
/// ViewModel del wizard; se serializa en el formato del request del API para guardarse
/// localmente y encolarse para sincronizar.
class EvaluacionBorrador {
  EvaluacionBorrador({
    required this.id,
    required this.loteId,
    required this.fecha,
    this.evaluadorId,
    this.observacion,
    this.estado = EstadoEvaluacion.borrador,
    List<MuestraBorrador>? muestras,
    Map<String, NivelHumedad>? humedad,
    Set<String>? empastes,
    Set<String>? danos,
    Map<String, SanidadBorrador>? sanidad,
  }) : muestras = muestras ?? [],
       humedad = humedad ?? {},
       empastes = empastes ?? {},
       danos = danos ?? {},
       sanidad = sanidad ?? {};

  /// Formato del request (lo que se guarda localmente y se envía).
  factory EvaluacionBorrador.fromRequestJson(
    Map<String, Object?> json, {
    required String loteId,
    EstadoEvaluacion? estado,
  }) {
    List<Map<String, Object?>> lista(Object? v) => ((v as List<Object?>?) ?? const []).cast<Map<String, Object?>>();
    return EvaluacionBorrador(
      id: json['id']! as String,
      loteId: loteId,
      evaluadorId: json['evaluadorId'] as String?,
      fecha: Formato.parseFecha(json['fechaEvaluacion']) ?? DateTime.now(),
      observacion: json['observacion'] as String?,
      estado: estado ?? EstadoEvaluacion.parse(json['estado'] as String?),
      muestras:
          lista(json['muestras'])
              .map(
                (m) => MuestraBorrador(
                  numero: (m['numero']! as num).toInt(),
                  observacion: m['observacion'] as String?,
                  calidad: {
                    for (final c in lista(m['calidad']))
                      c['claseCalidadId']! as String: (c['porcentaje']! as num).toDouble(),
                  },
                  calibres: {
                    for (final c in lista(m['calibres']))
                      c['calibreId']! as String: (c['porcentaje']! as num).toDouble(),
                  },
                ),
              )
              .toList(),
      humedad: {
        for (final h in lista(json['humedad']))
          h['tipoHumedadId']! as String: NivelHumedad.parse(h['nivel']! as String),
      },
      empastes: {...((json['empastes'] as List<Object?>?) ?? const []).cast<String>()},
      danos: {...((json['danos'] as List<Object?>?) ?? const []).cast<String>()},
      sanidad: {
        for (final s in lista(json['sanidad']))
          s['enfermedadId']! as String: SanidadBorrador(
            presente: s['presente']! as bool,
            porcentaje: (s['porcentaje'] as num?)?.toDouble(),
          ),
      },
    );
  }

  /// Formato de la respuesta de detalle del API (evaluación descargada del servidor).
  factory EvaluacionBorrador.fromResponseJson(Map<String, Object?> json) {
    List<Map<String, Object?>> lista(Object? v) => ((v as List<Object?>?) ?? const []).cast<Map<String, Object?>>();
    return EvaluacionBorrador(
      id: json['id']! as String,
      loteId: json['loteId']! as String,
      evaluadorId: (json['evaluador'] as Map<String, Object?>?)?['id'] as String?,
      fecha: Formato.parseFecha(json['fechaEvaluacion']) ?? DateTime.now(),
      observacion: json['observacion'] as String?,
      estado: EstadoEvaluacion.parse(json['estado'] as String?),
      muestras:
          lista(json['muestras'])
              .map(
                (m) => MuestraBorrador(
                  numero: (m['numero']! as num).toInt(),
                  observacion: m['observacion'] as String?,
                  calidad: {
                    for (final c in lista(m['calidad'])) c['id']! as String: (c['porcentaje']! as num).toDouble(),
                  },
                  calibres: {
                    for (final c in lista(m['calibres'])) c['id']! as String: (c['porcentaje']! as num).toDouble(),
                  },
                ),
              )
              .toList(),
      humedad: {for (final h in lista(json['humedad'])) h['id']! as String: NivelHumedad.parse(h['nivel']! as String)},
      empastes: {for (final e in lista(json['empastes'])) e['id']! as String},
      danos: {for (final d in lista(json['danos'])) d['id']! as String},
      sanidad: {
        for (final s in lista(json['sanidad']))
          s['id']! as String: SanidadBorrador(
            presente: s['presente']! as bool,
            porcentaje: (s['porcentaje'] as num?)?.toDouble(),
          ),
      },
    );
  }

  final String id;
  final String loteId;
  String? evaluadorId;
  DateTime fecha;
  String? observacion;
  EstadoEvaluacion estado;
  final List<MuestraBorrador> muestras;
  final Map<String, NivelHumedad> humedad;
  final Set<String> empastes;
  final Set<String> danos;
  final Map<String, SanidadBorrador> sanidad;

  bool get editable => estado == EstadoEvaluacion.borrador;

  Map<String, Object?> toRequestJson() => {
    'id': id,
    'evaluadorId': evaluadorId,
    'fechaEvaluacion': Formato.fechaIso(fecha),
    'observacion': (observacion?.trim().isEmpty ?? true) ? null : observacion!.trim(),
    'muestras': [
      for (final m in muestras)
        {
          'numero': m.numero,
          'observacion': m.observacion,
          'calidad': [
            for (final e in m.calidad.entries) {'claseCalidadId': e.key, 'porcentaje': _redondeo(e.value)},
          ],
          'calibres': [
            for (final e in m.calibres.entries) {'calibreId': e.key, 'porcentaje': _redondeo(e.value)},
          ],
        },
    ],
    'humedad': [
      for (final e in humedad.entries) {'tipoHumedadId': e.key, 'nivel': e.value.api},
    ],
    'empastes': empastes.toList(),
    'danos': danos.toList(),
    'sanidad': [
      for (final e in sanidad.entries)
        {
          'enfermedadId': e.key,
          'presente': e.value.presente,
          'porcentaje': e.value.presente ? e.value.porcentaje : null,
        },
    ],
  };

  /// Promedio por opción sobre las muestras que la registran (columna PROM del protocolo).
  Map<String, double> promediosCalidad() => _promedios((m) => m.calidad);

  Map<String, double> promediosCalibres() => _promedios((m) => m.calibres);

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

  int siguienteNumeroMuestra() =>
      muestras.isEmpty ? 1 : muestras.map((m) => m.numero).reduce((a, b) => a > b ? a : b) + 1;

  static double _redondeo(double v) => double.parse(v.toStringAsFixed(2));
}

/// Foto tomada en campo, guardada en el teléfono hasta subirse.
class EvidenciaLocal {
  const EvidenciaLocal({
    required this.id,
    required this.evaluacionId,
    required this.bytes,
    required this.mime,
    required this.creado,
    this.muestraNumero,
    this.factor,
    this.syncState = SyncState.pendiente,
  });

  final String id;
  final String evaluacionId;
  final int? muestraNumero;
  final String? factor;
  final Uint8List bytes;
  final String mime;
  final DateTime creado;
  final SyncState syncState;
}

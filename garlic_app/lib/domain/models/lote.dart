import '../../utils/formato.dart';
import 'sync.dart';

/// Referencia resumida a un catálogo (variedad, campaña, localidad, tipo de compra).
class Ref {
  const Ref({required this.id, this.codigo, this.nombre});

  factory Ref.fromJson(Map<String, Object?> json) =>
      Ref(id: json['id']! as String, codigo: json['codigo'] as String?, nombre: json['nombre'] as String?);

  final String id;
  final String? codigo;
  final String? nombre;

  String get texto => nombre ?? codigo ?? '';

  Map<String, Object?> toJson() => {'id': id, 'codigo': codigo, 'nombre': nombre};
}

/// Referencia resumida a una persona o rol.
class PersonaRef {
  const PersonaRef({required this.id, required this.nombres, this.tipoDocumento, this.numeroDocumento});

  factory PersonaRef.fromJson(Map<String, Object?> json) => PersonaRef(
    id: json['id']! as String,
    nombres: json['nombres']! as String,
    tipoDocumento: json['tipoDocumento'] as String?,
    numeroDocumento: json['numeroDocumento'] as String?,
  );

  final String id;
  final String nombres;
  final String? tipoDocumento;
  final String? numeroDocumento;

  Map<String, Object?> toJson() => {
    'id': id,
    'nombres': nombres,
    'tipoDocumento': tipoDocumento,
    'numeroDocumento': numeroDocumento,
  };
}

enum EstadoLote { activo, anulado }

/// Punto 1 del protocolo: identificación del lote (forma de la respuesta del API).
class Lote {
  const Lote({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.campania,
    required this.cultivoId,
    required this.variedad,
    required this.agricultor,
    required this.localidad,
    required this.zona,
    required this.tipoCompra,
    this.proveedor,
    this.titularLiquidacion,
    this.latitud,
    this.longitud,
    this.mapsUrl,
    this.fechaArrancado,
    this.fechaCorte,
    this.fechaCarga,
    this.creado,
    this.syncState = SyncState.sincronizado,
    this.syncError,
  });

  factory Lote.fromJson(Map<String, Object?> json, {SyncState syncState = SyncState.sincronizado, String? syncError}) {
    Map<String, Object?>? m(String k) => json[k] as Map<String, Object?>?;
    return Lote(
      id: json['id']! as String,
      codigo: json['codigo']! as String,
      estado: json['estado'] == 'ANULADO' ? EstadoLote.anulado : EstadoLote.activo,
      campania: Ref.fromJson(m('campania')!),
      cultivoId: json['cultivoId']! as String,
      variedad: Ref.fromJson(m('variedad')!),
      agricultor: PersonaRef.fromJson(m('agricultor')!),
      proveedor: m('proveedor') == null ? null : PersonaRef.fromJson(m('proveedor')!),
      titularLiquidacion: m('titularLiquidacion') == null ? null : PersonaRef.fromJson(m('titularLiquidacion')!),
      localidad: Ref.fromJson(m('localidad')!),
      zona: json['zona']! as String,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      mapsUrl: json['mapsUrl'] as String?,
      tipoCompra: Ref.fromJson(m('tipoCompra')!),
      fechaArrancado: Formato.parseFecha(json['fechaArrancado']),
      fechaCorte: Formato.parseFecha(json['fechaCorte']),
      fechaCarga: Formato.parseFecha(json['fechaCarga']),
      creado: Formato.parseFecha(json['createdAt']),
      syncState: syncState,
      syncError: syncError,
    );
  }

  final String id;
  final String codigo;
  final EstadoLote estado;
  final Ref campania;
  final String cultivoId;
  final Ref variedad;
  final PersonaRef agricultor;
  final PersonaRef? proveedor;
  final PersonaRef? titularLiquidacion;
  final Ref localidad;
  final String zona;
  final double? latitud;
  final double? longitud;
  final String? mapsUrl;
  final Ref tipoCompra;
  final DateTime? fechaArrancado;
  final DateTime? fechaCorte;
  final DateTime? fechaCarga;
  final DateTime? creado;
  final SyncState syncState;
  final String? syncError;

  bool get activo => estado == EstadoLote.activo;
  bool get tieneUbicacion => latitud != null && longitud != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'codigo': codigo,
    'estado': estado == EstadoLote.anulado ? 'ANULADO' : 'ACTIVO',
    'campania': campania.toJson(),
    'cultivoId': cultivoId,
    'variedad': variedad.toJson(),
    'agricultor': agricultor.toJson(),
    'proveedor': proveedor?.toJson(),
    'titularLiquidacion': titularLiquidacion?.toJson(),
    'localidad': localidad.toJson(),
    'zona': zona,
    'latitud': latitud,
    'longitud': longitud,
    'mapsUrl': mapsUrl,
    'tipoCompra': tipoCompra.toJson(),
    'fechaArrancado': fechaArrancado == null ? null : Formato.fechaIso(fechaArrancado!),
    'fechaCorte': fechaCorte == null ? null : Formato.fechaIso(fechaCorte!),
    'fechaCarga': fechaCarga == null ? null : Formato.fechaIso(fechaCarga!),
    'createdAt': creado?.toIso8601String(),
  };
}

/// Datos de identidad del titular de la liquidación de compra (DNI LC).
class TitularLiquidacion {
  const TitularLiquidacion({required this.numeroDocumento, required this.nombres, this.tipoDocumento = 'DNI'});

  final String tipoDocumento;
  final String numeroDocumento;
  final String nombres;

  Map<String, Object?> toJson() => {
    'tipoDocumento': tipoDocumento,
    'numeroDocumento': numeroDocumento,
    'nombres': nombres,
  };
}

/// Datos que envía el formulario de lote (forma del request del API).
class NuevoLote {
  const NuevoLote({
    required this.id,
    required this.campaniaId,
    required this.codigo,
    required this.variedadId,
    required this.agricultorId,
    required this.localidadId,
    required this.zona,
    required this.tipoCompraId,
    this.proveedorId,
    this.titular,
    this.latitud,
    this.longitud,
    this.fechaArrancado,
    this.fechaCorte,
    this.fechaCarga,
  });

  final String id;
  final String campaniaId;
  final String codigo;
  final String variedadId;
  final String agricultorId;
  final String? proveedorId;
  final TitularLiquidacion? titular;
  final String localidadId;
  final String zona;
  final double? latitud;
  final double? longitud;
  final String tipoCompraId;
  final DateTime? fechaArrancado;
  final DateTime? fechaCorte;
  final DateTime? fechaCarga;

  Map<String, Object?> toRequestJson() => {
    'id': id,
    'campaniaId': campaniaId,
    'codigo': codigo,
    'variedadId': variedadId,
    'agricultorId': agricultorId,
    'proveedorId': proveedorId,
    'titularLiquidacion': titular?.toJson(),
    'localidadId': localidadId,
    'zona': zona,
    'latitud': latitud == null ? null : double.parse(latitud!.toStringAsFixed(6)),
    'longitud': longitud == null ? null : double.parse(longitud!.toStringAsFixed(6)),
    'mapsUrl': latitud == null ? null : 'https://maps.google.com/?q=$latitud,$longitud',
    'tipoCompraId': tipoCompraId,
    'fechaArrancado': fechaArrancado == null ? null : Formato.fechaIso(fechaArrancado!),
    'fechaCorte': fechaCorte == null ? null : Formato.fechaIso(fechaCorte!),
    'fechaCarga': fechaCarga == null ? null : Formato.fechaIso(fechaCarga!),
  };
}

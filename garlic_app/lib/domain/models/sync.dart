/// Estado de sincronización de un registro local respecto al servidor.
enum SyncState {
  /// Igual que en el servidor.
  sincronizado,

  /// Guardado en el teléfono, esperando enviarse.
  pendiente,

  /// El servidor lo rechazó (p. ej. zona duplicada); requiere corrección.
  error;

  static SyncState parse(String? v) => SyncState.values.firstWhere((e) => e.name == v, orElse: () => sincronizado);
}

/// Resumen global que muestran el chip de sincronización y el centro de sincronización.
class SyncResumen {
  const SyncResumen({
    this.pendientes = 0,
    this.errores = 0,
    this.online = true,
    this.sincronizando = false,
    this.ultimaSincronizacion,
    this.ultimoError,
  });

  final int pendientes;
  final int errores;
  final bool online;
  final bool sincronizando;
  final DateTime? ultimaSincronizacion;
  final String? ultimoError;

  SyncResumen copyWith({
    int? pendientes,
    int? errores,
    bool? online,
    bool? sincronizando,
    DateTime? ultimaSincronizacion,
    String? ultimoError,
    bool limpiarError = false,
  }) => SyncResumen(
    pendientes: pendientes ?? this.pendientes,
    errores: errores ?? this.errores,
    online: online ?? this.online,
    sincronizando: sincronizando ?? this.sincronizando,
    ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
    ultimoError: limpiarError ? null : (ultimoError ?? this.ultimoError),
  );
}

/// Operación en cola para enviar al servidor.
class OperacionPendiente {
  const OperacionPendiente({
    required this.seq,
    required this.tipo,
    required this.entidadId,
    required this.descripcion,
    required this.intentos,
    required this.creado,
    this.ultimoError,
  });

  final int seq;
  final TipoOperacion tipo;
  final String entidadId;
  final String descripcion;
  final int intentos;
  final DateTime creado;
  final String? ultimoError;
}

enum TipoOperacion {
  loteUpsert('Lote'),
  evaluacionUpsert('Evaluación'),
  evaluacionCerrar('Cierre de evaluación'),
  evidenciaSubir('Foto');

  const TipoOperacion(this.etiqueta);

  final String etiqueta;

  static TipoOperacion parse(String v) => TipoOperacion.values.byName(v);
}

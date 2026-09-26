/// Opción de un catálogo configurable por empresa (variedad, calibre, tipo de humedad, ...).
///
/// Los campos específicos de algunos catálogos (rango de calibre, "excluyente", "evaluar en campo")
/// son opcionales para usar un solo modelo en toda la app.
class CatalogoItem {
  const CatalogoItem({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.orden = 0,
    this.activo = true,
    this.diametroMinMm,
    this.diametroMaxMm,
    this.esExcluyente = false,
    this.evaluarEnCampo = false,
    this.nombreCientifico,
  });

  factory CatalogoItem.fromJson(Map<String, Object?> json) => CatalogoItem(
    id: json['id']! as String,
    codigo: (json['codigo'] ?? json['nombre'] ?? '') as String,
    nombre: (json['nombre'] ?? json['codigo'] ?? '') as String,
    orden: (json['orden'] as num?)?.toInt() ?? 0,
    activo: json['activo'] as bool? ?? true,
    diametroMinMm: (json['diametroMinMm'] as num?)?.toDouble(),
    diametroMaxMm: (json['diametroMaxMm'] as num?)?.toDouble(),
    esExcluyente: json['esExcluyente'] as bool? ?? false,
    evaluarEnCampo: json['evaluarEnCampo'] as bool? ?? false,
    nombreCientifico: json['nombreCientifico'] as String?,
  );

  final String id;
  final String codigo;
  final String nombre;
  final int orden;
  final bool activo;
  final double? diametroMinMm;
  final double? diametroMaxMm;
  final bool esExcluyente;
  final bool evaluarEnCampo;
  final String? nombreCientifico;

  Map<String, Object?> toJson() => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre,
    'orden': orden,
    'activo': activo,
    'diametroMinMm': diametroMinMm,
    'diametroMaxMm': diametroMaxMm,
    'esExcluyente': esExcluyente,
    'evaluarEnCampo': evaluarEnCampo,
    'nombreCientifico': nombreCientifico,
  };

  /// Nombre con primera letra en mayúscula para mostrar ("GOTAS DENTRO" -> "Gotas dentro").
  String get etiqueta {
    if (nombre.isEmpty) return codigo;
    final bajo = nombre.toLowerCase();
    return bajo[0].toUpperCase() + bajo.substring(1);
  }

  @override
  bool operator ==(Object other) => other is CatalogoItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Persona con un rol (agricultor, proveedor) o usuario evaluador, para selectores.
class PersonaItem {
  const PersonaItem({required this.id, required this.nombres, this.documento, this.personaId});

  /// Rol de agricultor/proveedor: `{id, persona: {...}}`.
  factory PersonaItem.fromRolJson(Map<String, Object?> json) {
    final persona = json['persona']! as Map<String, Object?>;
    return PersonaItem(
      id: json['id']! as String,
      personaId: persona['id'] as String?,
      nombres: persona['nombres']! as String,
      documento: persona['numeroDocumento'] as String?,
    );
  }

  /// Usuario: `{id, nombres, dni}`.
  factory PersonaItem.fromUsuarioJson(Map<String, Object?> json) =>
      PersonaItem(id: json['id']! as String, nombres: json['nombres']! as String, documento: json['dni'] as String?);

  factory PersonaItem.fromJson(Map<String, Object?> json) => PersonaItem(
    id: json['id']! as String,
    nombres: json['nombres']! as String,
    documento: json['documento'] as String?,
    personaId: json['personaId'] as String?,
  );

  final String id;
  final String nombres;
  final String? documento;
  final String? personaId;

  Map<String, Object?> toJson() => {'id': id, 'nombres': nombres, 'documento': documento, 'personaId': personaId};

  String get nombreVisible => _titulo(nombres);

  @override
  bool operator ==(Object other) => other is PersonaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

String _titulo(String s) =>
    s.toLowerCase().split(' ').where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase() + p.substring(1)).join(' ');

/// Tipo de dato de un campo de catálogo (define el control del formulario).
enum TipoCampo { texto, entero, decimal, booleano, fecha, opcion }

/// Campo editable de un catálogo. [clave] es el nombre en el JSON del API.
class CampoCatalogo {
  const CampoCatalogo(
    this.clave,
    this.etiqueta,
    this.tipo, {
    this.requerido = false,
    this.max,
    this.ayuda,
    this.opciones = const {},
    this.mayusculas = false,
  });

  final String clave;
  final String etiqueta;
  final TipoCampo tipo;
  final bool requerido;

  /// Largo máximo (texto).
  final int? max;
  final String? ayuda;

  /// Valor del API → texto visible (tipo opción).
  final Map<String, String> opciones;
  final bool mayusculas;
}

enum GrupoCatalogo {
  lote('Identificación del lote'),
  calidad('Calidad (evaluación)'),
  compra('Compra y pagos');

  const GrupoCatalogo(this.titulo);

  final String titulo;
}

/// Catálogo configurable por empresa: recurso del API, campos y dónde se usa.
/// Una sola pantalla genérica administra todos a partir de estas definiciones.
class DefinicionCatalogo {
  const DefinicionCatalogo({
    required this.recurso,
    required this.titulo,
    required this.descripcion,
    required this.grupo,
    required this.campos,
    this.porCultivo = true,
    this.ordenable = true,
  });

  /// Ruta bajo `/api/v1/catalogos/` (ej. `clases-calidad`).
  final String recurso;
  final String titulo;
  final String descripcion;
  final GrupoCatalogo grupo;
  final List<CampoCatalogo> campos;

  /// Se envía `cultivoId` y se filtra por el cultivo de la app.
  final bool porCultivo;

  /// Tiene campo `orden` (define el orden en formularios).
  final bool ordenable;

  String get ruta => '/api/v1/catalogos/$recurso';

  /// Texto principal de un registro.
  String etiquetaDe(Map<String, Object?> item) => '${item['nombre'] ?? item['codigo'] ?? ''}';

  /// Cuerpo del request a partir de los valores del formulario.
  Map<String, Object?> request(Map<String, Object?> valores, String cultivoId) => {
    if (porCultivo) 'cultivoId': cultivoId,
    for (final c in campos) c.clave: valores[c.clave],
  };

  static const _codigo = CampoCatalogo(
    'codigo',
    'Código',
    TipoCampo.texto,
    requerido: true,
    max: 30,
    mayusculas: true,
    ayuda: 'Identificador corto y único (ej. POROTO)',
  );
  static const _nombre = CampoCatalogo('nombre', 'Nombre', TipoCampo.texto, requerido: true, max: 120);
  static const _orden = CampoCatalogo('orden', 'Orden', TipoCampo.entero, ayuda: 'Posición en los formularios');

  static DefinicionCatalogo _simple(
    String recurso,
    String titulo,
    String descripcion,
    GrupoCatalogo grupo, [
    List<CampoCatalogo> extra = const [],
  ]) => DefinicionCatalogo(
    recurso: recurso,
    titulo: titulo,
    descripcion: descripcion,
    grupo: grupo,
    campos: [_codigo, _nombre, _orden, ...extra],
  );

  static final todas = <DefinicionCatalogo>[
    // ---- lote
    const DefinicionCatalogo(
      recurso: 'campanias',
      titulo: 'Campañas',
      descripcion: 'Temporadas de compra; no se repite la zona de un lote activo en la misma campaña.',
      grupo: GrupoCatalogo.lote,
      ordenable: false,
      campos: [
        CampoCatalogo('codigo', 'Código', TipoCampo.texto, requerido: true, max: 20, ayuda: 'Ej. 2026'),
        CampoCatalogo('fechaInicio', 'Inicio', TipoCampo.fecha),
        CampoCatalogo('fechaFin', 'Fin', TipoCampo.fecha),
      ],
    ),
    _simple('variedades', 'Variedades', 'Napuri, Chino blanco, Barranquino…', GrupoCatalogo.lote),
    _simple(
      'tipos-compra',
      'Tipos de compra',
      'Lo elige el evaluador para el lote (Primera 5 arriba, Segunda…).',
      GrupoCatalogo.lote,
    ),
    const DefinicionCatalogo(
      recurso: 'localidades',
      titulo: 'Localidades',
      descripcion: 'Ciudad o centro poblado del lote.',
      grupo: GrupoCatalogo.lote,
      porCultivo: false,
      ordenable: false,
      campos: [
        CampoCatalogo('nombre', 'Nombre', TipoCampo.texto, requerido: true, max: 120, mayusculas: true),
        CampoCatalogo(
          'tipo',
          'Tipo',
          TipoCampo.opcion,
          requerido: true,
          opciones: {'CCPP': 'Centro poblado', 'CIUDAD': 'Ciudad'},
        ),
        CampoCatalogo('ubigeo', 'Ubigeo (opcional)', TipoCampo.texto, max: 6, ayuda: '6 dígitos'),
      ],
    ),
    // ---- calidad
    _simple(
      'clases-calidad',
      'Clases de calidad',
      '2.1 Factor calidad global (Primera, Abiertos, Poroto…). Cada clase tiene precio base en la fijación de precio.',
      GrupoCatalogo.calidad,
    ),
    _simple(
      'calibres',
      'Calibres',
      '2.2 Factor tamaño; el evaluador elige los de cada muestra (deben sumar 100%).',
      GrupoCatalogo.calidad,
      const [
        CampoCatalogo('diametroMinMm', 'Diámetro mínimo (mm)', TipoCampo.decimal),
        CampoCatalogo('diametroMaxMm', 'Diámetro máximo (mm)', TipoCampo.decimal, ayuda: 'Vacío = sin tope (>70)'),
      ],
    ),
    _simple(
      'tipos-humedad',
      'Indicadores de humedad',
      '2.2.1 Se califican como baja, media o alta.',
      GrupoCatalogo.calidad,
    ),
    _simple('tipos-empaste', 'Tipos de empaste', '2.2.2 Selección múltiple.', GrupoCatalogo.calidad),
    _simple(
      'tipos-dano',
      'Daños no visibles',
      'Selección múltiple; "excluyente" no se combina con otros (No contiene).',
      GrupoCatalogo.calidad,
      const [CampoCatalogo('esExcluyente', 'Excluyente', TipoCampo.booleano)],
    ),
    _simple(
      'enfermedades',
      'Enfermedades',
      'Las marcadas "evaluar en campo" aparecen en Sanidad (SÍ/NO + %).',
      GrupoCatalogo.calidad,
      const [
        CampoCatalogo('nombreCientifico', 'Nombre científico', TipoCampo.texto, max: 150),
        CampoCatalogo('evaluarEnCampo', 'Evaluar en campo', TipoCampo.booleano),
        CampoCatalogo('seTransmitePorSemilla', 'Se transmite por semilla', TipoCampo.booleano),
      ],
    ),
    // ---- compra
    _simple(
      'tipos-empaque',
      'Tipos de empaque',
      'Mallas, javas, sacos… El peso sugiere la cantidad por camión.',
      GrupoCatalogo.compra,
      const [
        CampoCatalogo('pesoReferencialKg', 'Peso referencial (kg)', TipoCampo.decimal, ayuda: 'Ej. malla de 40 kg'),
      ],
    ),
    _simple(
      'tipos-gasto',
      'Tipos de gasto vinculado',
      'Gastos para llevar la materia prima al packing.',
      GrupoCatalogo.compra,
      const [
        CampoCatalogo('porCarga', 'Se registra por camión', TipoCampo.booleano),
        CampoCatalogo('requiereDescripcion', 'Exige descripción', TipoCampo.booleano),
      ],
    ),
    _simple('condiciones-pago', 'Condiciones de pago', 'Cta. banco, efectivo, crédito…', GrupoCatalogo.compra),
  ];
}

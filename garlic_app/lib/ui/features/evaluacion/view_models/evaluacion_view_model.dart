import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/catalogo.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/formulario.dart';
import '../../../../domain/models/lote.dart';
import '../../../../domain/use_cases/reglas_evaluacion.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Wizard de evaluación de calidad (punto 2). Mantiene el borrador en memoria, lo autoguarda
/// en el teléfono (y lo encola) con cada cambio, y aplica las reglas antes de cerrar.
class EvaluacionViewModel extends ChangeNotifier {
  EvaluacionViewModel({
    required this.loteId,
    this.evaluacionId,
    required LotesRepository lotes,
    required EvaluacionesRepository evaluaciones,
    required CatalogosRepository catalogos,
    required ConfigRepository config,
  }) : _lotes = lotes,
       _evaluaciones = evaluaciones,
       _catalogos = catalogos,
       _config = config {
    cargar = Command(_cargar);
    cerrar = Command(_cerrar);
    unawaited(cargar.execute());
  }

  final String loteId;
  final String? evaluacionId;
  final LotesRepository _lotes;
  final EvaluacionesRepository _evaluaciones;
  final CatalogosRepository _catalogos;
  final ConfigRepository _config;

  late final Command<void> cargar;
  late final Command<void> cerrar;

  Lote? lote;
  FormularioEvaluacion? formulario;
  EvaluacionBorrador? borrador;
  PasoEvaluacion paso = PasoEvaluacion.general;
  int muestraIndice = 0;
  DateTime? ultimoGuardado;
  bool guardando = false;
  StreamSubscription<List<EvidenciaLocal>>? _fotosSub;
  List<EvidenciaLocal> fotos = const [];
  Timer? _autoguardado;
  bool _sucio = false;

  bool get listo => lote != null && formulario != null && borrador != null;
  bool get editable => borrador?.editable ?? false;
  List<PersonaItem> get evaluadores => _catalogos.evaluadores;
  MuestraBorrador? get muestraActual =>
      borrador == null || borrador!.muestras.isEmpty
          ? null
          : borrador!.muestras[muestraIndice.clamp(0, borrador!.muestras.length - 1)];

  List<ProblemaEvaluacion> get problemas =>
      listo ? ReglasEvaluacion.validarContenido(borrador!, formulario!) : const [];

  List<ProblemaEvaluacion> get problemasCierre =>
      listo ? ReglasEvaluacion.validarCierre(borrador!, formulario!) : const [];

  /// Problemas para cerrar de una muestra (para marcar su chip y su sección).
  List<ProblemaEvaluacion> problemasDeMuestra(MuestraBorrador m) =>
      problemasCierre.where((x) => x.muestra == m.numero).toList();

  bool pasoCompleto(PasoEvaluacion p) {
    if (!listo) return false;
    final b = borrador!;
    return switch (p) {
      PasoEvaluacion.general => b.evaluadorId != null,
      PasoEvaluacion.muestras => b.muestras.isNotEmpty && problemasCierre.where((x) => x.paso == p).isEmpty,
      PasoEvaluacion.resumen => b.estado == EstadoEvaluacion.cerrada,
    };
  }

  Future<Result<void>> _cargar() async {
    lote = await _lotes.obtener(loteId);
    formulario = _catalogos.formulario;
    if (lote == null || formulario == null) {
      return const Result.error(
        AppFailure(FailureKind.noEncontrado, 'Faltan datos del lote o catálogos. Sincroniza primero.'),
      );
    }
    if (evaluacionId == null) {
      borrador = _evaluaciones.nuevo(loteId: loteId, evaluadorId: _config.config?.evaluadorId);
    } else {
      final r = await _evaluaciones.cargar(evaluacionId!);
      switch (r) {
        case Ok(:final value):
          borrador = value;
        case Error(:final failure):
          return Result.error(failure);
      }
      if (!borrador!.editable) paso = PasoEvaluacion.resumen;
    }
    _fotosSub = _evaluaciones.observarEvidencias(borrador!.id).listen((f) {
      fotos = f;
      notifyListeners();
    });
    notifyListeners();
    return const Result.ok(null);
  }

  // ------------------------------------------------------------------ navegación

  void irA(PasoEvaluacion p) {
    paso = p;
    unawaited(guardarAhora());
    notifyListeners();
  }

  /// Lleva al paso del problema y, si es de una muestra, la selecciona.
  void irAProblema(ProblemaEvaluacion p) {
    final i = p.muestra == null ? -1 : borrador!.muestras.indexWhere((m) => m.numero == p.muestra);
    if (i >= 0) muestraIndice = i;
    irA(p.paso);
  }

  void siguiente() {
    if (paso.index < PasoEvaluacion.values.length - 1) irA(PasoEvaluacion.values[paso.index + 1]);
  }

  void anterior() {
    if (paso.index > 0) irA(PasoEvaluacion.values[paso.index - 1]);
  }

  // ------------------------------------------------------------------ datos generales

  void setEvaluador(String? id) => _editar(() => borrador!.evaluadorId = id);

  void setFecha(DateTime? d) => _editar(() => borrador!.fecha = d ?? DateTime.now());

  void setObservacion(String v) => _editar(() => borrador!.observacion = v);

  // ------------------------------------------------------------------ muestras

  void seleccionarMuestra(int i) {
    muestraIndice = i;
    notifyListeners();
  }

  /// La muestra nueva trae los calibres elegidos en la anterior (sin valores): suele evaluarse igual.
  void agregarMuestra() => _editar(() {
    borrador!.muestras.add(borrador!.nuevaMuestra());
    muestraIndice = borrador!.muestras.length - 1;
  });

  /// Quita la muestra y sus fotos del equipo (en el servidor se eliminan al sincronizar la evaluación) y
  /// renumera las demás 1..n de izquierda a derecha. Las fotos van por id de muestra: no cambian de muestra.
  Future<void> quitarMuestra(MuestraBorrador muestra) async {
    final fotosMuestra = fotosDeMuestra(muestra);
    _editar(() {
      borrador!.quitarMuestra(muestra.id);
      muestraIndice = 0;
    });
    for (final f in fotosMuestra) {
      await _evaluaciones.eliminarEvidencia(f.id);
    }
  }

  /// Muestra anterior a la actual (para copiar sus sensoriales y sanidad).
  MuestraBorrador? get muestraAnterior {
    final i = borrador?.muestras.indexOf(muestraActual!) ?? -1;
    return i > 0 ? borrador!.muestras[i - 1] : null;
  }

  void copiarDeAnterior() => _editar(() => muestraActual!.copiarSensorialesYSanidad(muestraAnterior!));

  /// Calidad: con exactamente dos clases (PRIMERA / ABIERTOS) la otra se completa sola al 100%,
  /// igual que la fórmula ABIERTOS = 1 - PRIMERA del protocolo.
  void setCalidad(String claseId, double? valor) => _editar(() {
    final m = muestraActual!;
    final clases = formulario!.clasesCalidad;
    if (valor == null) {
      m.calidad.remove(claseId);
      return;
    }
    final v = valor.clamp(0, 100).toDouble();
    m.calidad[claseId] = v;
    if (clases.length == 2) {
      final otra = clases.firstWhere((c) => c.id != claseId);
      m.calidad[otra.id] = double.parse((100 - v).toStringAsFixed(2));
    }
  });

  /// % de un calibre elegido. Vaciar el campo no lo quita: queda pendiente (0) hasta ingresar el valor.
  void setCalibre(String calibreId, double? valor) => _editar(() {
    muestraActual!.calibres[calibreId] = (valor ?? 0).clamp(0, 100).toDouble();
  });

  /// Agrega o quita un calibre del catálogo en la muestra actual.
  void alternarCalibre(String calibreId) => _editar(() {
    final m = muestraActual!;
    if (m.calibres.remove(calibreId) == null) m.calibres[calibreId] = 0;
  });

  /// Asigna lo que falta para llegar a 100% al calibre pendiente (o al último elegido).
  void completarCalibres() => _editar(() => muestraActual!.completarCalibres());

  void setObservacionMuestra(String v) => _editar(() => muestraActual!.observacion = v);

  // ------------------------------------------------------------------ sensoriales (de la muestra actual)

  /// Humedad SI/NO por indicador; null la deja sin responder.
  void setHumedad(String tipoId, bool? presente) => _editar(() {
    final humedad = muestraActual!.humedad;
    if (presente == null) {
      humedad.remove(tipoId);
    } else {
      humedad[tipoId] = presente;
    }
  });

  void alternarEmpaste(String id) => _editar(() {
    final empastes = muestraActual!.empastes;
    if (!empastes.remove(id)) empastes.add(id);
  });

  /// "No contiene" (excluyente) desmarca los demás daños y viceversa.
  void alternarDano(CatalogoItem dano) => _editar(() {
    final danos = muestraActual!.danos;
    if (danos.remove(dano.id) != null) return;
    final excluyentes = formulario!.tiposDano.where((d) => d.esExcluyente).map((d) => d.id).toSet();
    if (dano.esExcluyente) {
      danos.clear();
    } else {
      danos.removeWhere((id, _) => excluyentes.contains(id));
    }
    danos[dano.id] = DanoBorrador();
  });

  /// Frutos contados de un daño que pide cantidades (parálisis): el % se calcula solo.
  void setFrutosDano(
    String danoId, {
    int? total,
    int? afectados,
    bool limpiarTotal = false,
    bool limpiarAfectados = false,
  }) => _editar(() {
    final d = muestraActual!.danos[danoId];
    if (d == null) return;
    if (total != null || limpiarTotal) d.total = total;
    if (afectados != null || limpiarAfectados) d.afectados = afectados;
  });

  // ------------------------------------------------------------------ sanidad (de la muestra actual)

  void setPresente(String enfermedadId, bool presente) => _editar(() {
    final sanidad = muestraActual!.sanidad;
    final actual = sanidad[enfermedadId];
    sanidad[enfermedadId] = SanidadBorrador(presente: presente, porcentaje: presente ? actual?.porcentaje : null);
  });

  void setPorcentajeEnfermedad(String enfermedadId, double? v) => _editar(() {
    final s = muestraActual!.sanidad[enfermedadId];
    if (s != null && s.presente) s.porcentaje = v?.clamp(0, 100).toDouble();
  });

  // ------------------------------------------------------------------ fotos

  /// Fotos generales del lote (paso Datos).
  List<EvidenciaLocal> get fotosGenerales => fotos.where((f) => SeccionFoto.de(f) == SeccionFoto.general).toList();

  /// Fotos de una muestra: por su id (las anteriores al cambio, por número).
  List<EvidenciaLocal> fotosDeMuestra(MuestraBorrador m) =>
      fotos.where((f) => f.muestraId != null ? f.muestraId == m.id : f.muestraNumero == m.numero).toList();

  /// Guarda la evaluación antes de encolar la foto: la muestra debe llegar al servidor antes que su foto.
  Future<void> agregarFoto(Uint8List bytes, String mime, {MuestraBorrador? muestra}) async {
    _sucio = _sucio || muestra != null;
    await guardarAhora();
    await _evaluaciones.agregarEvidencia(
      evaluacionId: borrador!.id,
      bytes: bytes,
      mime: mime,
      muestraId: muestra?.id,
      muestraNumero: muestra?.numero,
    );
  }

  Future<void> eliminarFoto(String id) => _evaluaciones.eliminarEvidencia(id);

  // ------------------------------------------------------------------ guardado y cierre

  void _editar(VoidCallback cambio) {
    if (!editable) return;
    cambio();
    _sucio = true;
    notifyListeners();
    _autoguardado?.cancel();
    _autoguardado = Timer(const Duration(milliseconds: 900), () => unawaited(guardarAhora()));
  }

  Future<void> guardarAhora() async {
    _autoguardado?.cancel();
    if (!_sucio || !listo || !editable) return;
    _sucio = false;
    guardando = true;
    notifyListeners();
    await _evaluaciones.guardar(borrador!, lote!, evaluadorNombre: _nombreEvaluador());
    guardando = false;
    ultimoGuardado = DateTime.now();
    notifyListeners();
  }

  Future<Result<void>> _cerrar() async {
    final pendientes = problemasCierre;
    if (pendientes.isNotEmpty) {
      paso = pendientes.first.paso;
      final n = pendientes.first.muestra;
      final i = n == null ? -1 : borrador!.muestras.indexWhere((m) => m.numero == n);
      if (i >= 0) muestraIndice = i;
      notifyListeners();
      return Result.error(AppFailure(FailureKind.validacion, pendientes.first.toString()));
    }
    _autoguardado?.cancel();
    await _evaluaciones.cerrar(borrador!, lote!, evaluadorNombre: _nombreEvaluador());
    _sucio = false;
    ultimoGuardado = DateTime.now();
    notifyListeners();
    return const Result.ok(null);
  }

  /// Dictamen tras cerrar: aceptada, rechazada o sin acuerdo de precio (null = pendiente). Se puede corregir.
  Future<void> definirResultado(ResultadoEvaluacion? resultado, {String? motivo}) async {
    if (borrador == null || lote == null || editable) return;
    await _evaluaciones.definirResultado(
      borrador!,
      lote!,
      resultado: resultado,
      motivo: motivo,
      evaluadorNombre: _nombreEvaluador(),
    );
    notifyListeners();
  }

  String? _nombreEvaluador() =>
      _catalogos.evaluadores.where((e) => e.id == borrador!.evaluadorId).firstOrNull?.nombreVisible ??
      _config.config?.evaluadorNombre;

  @override
  void dispose() {
    unawaited(guardarAhora());
    _fotosSub?.cancel();
    cargar.dispose();
    cerrar.dispose();
    super.dispose();
  }
}

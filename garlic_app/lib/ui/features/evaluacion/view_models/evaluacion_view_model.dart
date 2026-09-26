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

  bool pasoCompleto(PasoEvaluacion p) {
    if (!listo) return false;
    final b = borrador!;
    return switch (p) {
      PasoEvaluacion.general => b.evaluadorId != null,
      PasoEvaluacion.muestras => b.muestras.isNotEmpty && problemasCierre.where((x) => x.paso == p).isEmpty,
      PasoEvaluacion.sensoriales => b.humedad.isNotEmpty || b.empastes.isNotEmpty || b.danos.isNotEmpty,
      PasoEvaluacion.sanidad => problemasCierre.where((x) => x.paso == p).isEmpty,
      PasoEvaluacion.evidencias => fotos.isNotEmpty,
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

  void agregarMuestra() => _editar(() {
    borrador!.muestras.add(MuestraBorrador(numero: borrador!.siguienteNumeroMuestra()));
    muestraIndice = borrador!.muestras.length - 1;
  });

  void quitarMuestra(int numero) => _editar(() {
    borrador!.muestras.removeWhere((m) => m.numero == numero);
    muestraIndice = 0;
  });

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

  void setCalibre(String calibreId, double? valor) => _editar(() {
    final m = muestraActual!;
    if (valor == null) {
      m.calibres.remove(calibreId);
    } else {
      m.calibres[calibreId] = valor.clamp(0, 100).toDouble();
    }
  });

  void setObservacionMuestra(String v) => _editar(() => muestraActual!.observacion = v);

  // ------------------------------------------------------------------ sensoriales

  void setHumedad(String tipoId, NivelHumedad? nivel) => _editar(() {
    if (nivel == null) {
      borrador!.humedad.remove(tipoId);
    } else {
      borrador!.humedad[tipoId] = nivel;
    }
  });

  void alternarEmpaste(String id) => _editar(() {
    if (!borrador!.empastes.remove(id)) borrador!.empastes.add(id);
  });

  /// "No contiene" (excluyente) desmarca los demás daños y viceversa.
  void alternarDano(CatalogoItem dano) => _editar(() {
    final danos = borrador!.danos;
    if (danos.remove(dano.id)) return;
    final excluyentes = formulario!.tiposDano.where((d) => d.esExcluyente).map((d) => d.id).toSet();
    if (dano.esExcluyente) {
      danos.clear();
    } else {
      danos.removeAll(excluyentes);
    }
    danos.add(dano.id);
  });

  // ------------------------------------------------------------------ sanidad

  void setPresente(String enfermedadId, bool presente) => _editar(() {
    final actual = borrador!.sanidad[enfermedadId];
    borrador!.sanidad[enfermedadId] = SanidadBorrador(
      presente: presente,
      porcentaje: presente ? actual?.porcentaje : null,
    );
  });

  void setPorcentajeEnfermedad(String enfermedadId, double? v) => _editar(() {
    final s = borrador!.sanidad[enfermedadId];
    if (s != null && s.presente) s.porcentaje = v?.clamp(0, 100).toDouble();
  });

  // ------------------------------------------------------------------ fotos

  Future<void> agregarFoto(Uint8List bytes, String mime, {int? muestraNumero}) async {
    await guardarAhora(); // la muestra debe existir antes de subir su foto
    await _evaluaciones.agregarEvidencia(
      evaluacionId: borrador!.id,
      bytes: bytes,
      mime: mime,
      muestraNumero: muestraNumero,
      factor: muestraNumero == null ? null : 'CALIDAD',
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

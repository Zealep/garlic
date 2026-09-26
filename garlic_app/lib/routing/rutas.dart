/// Rutas de la app (go_router).
abstract final class Rutas {
  static const setup = '/configurar';
  static const inicio = '/inicio';
  static const lotes = '/lotes';
  static const loteNuevo = '/lotes/nuevo';
  static const evaluaciones = '/evaluaciones';
  static const sync = '/sincronizar';

  static String lote(String id) => '/lotes/$id';

  /// Nueva evaluación de un lote.
  static String evaluar(String loteId) => '/lotes/$loteId/evaluar';

  /// Abrir una evaluación existente (editar borrador o ver cerrada).
  static String evaluacion(String loteId, String id) => '/lotes/$loteId/evaluaciones/$id';
}

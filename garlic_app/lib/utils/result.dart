/// Resultado de una operación que puede fallar, sin lanzar excepciones hacia la UI.
///
/// Patrón recomendado por la guía de arquitectura de Flutter: los servicios y repositorios
/// devuelven `Result`, y los ViewModels deciden cómo mostrar el error.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;

  const factory Result.error(AppFailure failure) = Error<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);

  final AppFailure failure;
}

/// Tipos de falla que la UI sabe presentar.
enum FailureKind {
  /// Sin conexión o servidor inalcanzable: se puede reintentar más tarde.
  sinConexion,

  /// Datos inválidos (400) o regla de negocio (422).
  validacion,

  /// Conflicto con el estado actual (409), p. ej. zona ya registrada.
  conflicto,

  /// Recurso inexistente (404).
  noEncontrado,

  /// Cualquier otro error inesperado.
  desconocido,
}

class AppFailure {
  const AppFailure(this.kind, this.message, {this.fieldErrors = const {}, this.statusCode});

  final FailureKind kind;
  final String message;

  /// Errores por campo devueltos por el backend (ProblemDetail.errors).
  final Map<String, String> fieldErrors;
  final int? statusCode;

  /// Los errores de red se reintentan; los de negocio necesitan corrección del usuario.
  bool get esReintentable => kind == FailureKind.sinConexion;

  @override
  String toString() => 'AppFailure($kind, $message)';
}

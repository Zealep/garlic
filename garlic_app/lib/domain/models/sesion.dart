/// Usuario que inició sesión (DNI + contraseña). Sin roles de negocio: [admin] solo gestiona usuarios.
class UsuarioSesion {
  const UsuarioSesion({
    required this.id,
    required this.nombres,
    required this.dni,
    this.email,
    this.admin = false,
    this.debeCambiarClave = false,
  });

  factory UsuarioSesion.fromJson(Map<String, Object?> j) => UsuarioSesion(
    id: j['id']! as String,
    nombres: j['nombres']! as String,
    dni: (j['dni'] as String?) ?? '',
    email: j['email'] as String?,
    admin: (j['admin'] as bool?) ?? false,
    debeCambiarClave: (j['debeCambiarClave'] as bool?) ?? false,
  );

  final String id;
  final String nombres;
  final String dni;
  final String? email;
  final bool admin;

  /// La clave es temporal (alta o restablecida por el administrador): se pide cambiarla al entrar.
  final bool debeCambiarClave;

  String get primerNombre => nombres.split(' ').first;

  String get iniciales {
    final partes = nombres.split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return (partes.first[0] + (partes.length > 1 ? partes[1][0] : '')).toUpperCase();
  }

  UsuarioSesion copyWith({bool? debeCambiarClave}) => UsuarioSesion(
    id: id,
    nombres: nombres,
    dni: dni,
    email: email,
    admin: admin,
    debeCambiarClave: debeCambiarClave ?? this.debeCambiarClave,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'nombres': nombres,
    'dni': dni,
    'email': email,
    'admin': admin,
    'debeCambiarClave': debeCambiarClave,
  };
}

class EmpresaSesion {
  const EmpresaSesion({required this.id, required this.ruc, required this.razonSocial});

  factory EmpresaSesion.fromJson(Map<String, Object?> j) =>
      EmpresaSesion(id: j['id']! as String, ruc: j['ruc']! as String, razonSocial: j['razonSocial']! as String);

  final String id;
  final String ruc;
  final String razonSocial;

  Map<String, Object?> toJson() => {'id': id, 'ruc': ruc, 'razonSocial': razonSocial};
}

/// Tokens + quién entró. El access token dura horas; el refresh token mantiene la sesión 30 días
/// (se renueva con cada uso), así el evaluador trabaja sin señal en campo.
class Sesion {
  const Sesion({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
    required this.empresa,
  });

  factory Sesion.fromJson(Map<String, Object?> j) => Sesion(
    accessToken: j['accessToken']! as String,
    refreshToken: j['refreshToken']! as String,
    usuario: UsuarioSesion.fromJson((j['usuario']! as Map).cast<String, Object?>()),
    empresa: EmpresaSesion.fromJson((j['empresa']! as Map).cast<String, Object?>()),
  );

  final String accessToken;
  final String refreshToken;
  final UsuarioSesion usuario;
  final EmpresaSesion empresa;

  Sesion copyWith({UsuarioSesion? usuario}) => Sesion(
    accessToken: accessToken,
    refreshToken: refreshToken,
    usuario: usuario ?? this.usuario,
    empresa: empresa,
  );

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'usuario': usuario.toJson(),
    'empresa': empresa.toJson(),
  };
}

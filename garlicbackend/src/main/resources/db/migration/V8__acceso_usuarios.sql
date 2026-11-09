-- =====================================================================
-- V8 (2026-11-06): login propio por usuario (DNI + contrasena), sin roles de negocio.
--   * El usuario entra con su DNI (unico); el email pasa a ser opcional.
--   * La clave se guarda como hash BCrypt; la clave inicial (o restablecida) es temporal.
--   * sesion_usuario guarda el refresh token rotativo (solo su hash SHA-256): permite
--     trabajar sin senal hasta 30 dias y cerrar sesion / revocar desde el servidor.
-- =====================================================================

ALTER TABLE usuario ALTER COLUMN email DROP NOT NULL;
ALTER TABLE usuario ADD COLUMN clave_hash         varchar(100);
ALTER TABLE usuario ADD COLUMN debe_cambiar_clave boolean NOT NULL DEFAULT true;
ALTER TABLE usuario ADD COLUMN ultimo_acceso      timestamptz;

CREATE UNIQUE INDEX uq_usuario_dni ON usuario (dni) WHERE dni IS NOT NULL;

COMMENT ON COLUMN usuario.dni IS 'DNI: con el entra al sistema (unico).';
COMMENT ON COLUMN usuario.clave_hash IS 'Hash BCrypt de la contrasena (null = aun no puede entrar).';
COMMENT ON COLUMN usuario.debe_cambiar_clave IS 'La clave es temporal: se pide cambiarla al entrar.';

CREATE TABLE sesion_usuario (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  uuid         NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    token_hash  varchar(64)  NOT NULL UNIQUE,
    creada      timestamptz  NOT NULL DEFAULT now(),
    expira_en   timestamptz  NOT NULL,
    ultimo_uso  timestamptz,
    revocada    boolean      NOT NULL DEFAULT false,
    dispositivo varchar(200)
);
CREATE INDEX ix_sesion_usuario_usuario ON sesion_usuario (usuario_id);
COMMENT ON TABLE sesion_usuario IS 'Sesiones (refresh token rotativo, 30 dias deslizantes) de cada usuario.';

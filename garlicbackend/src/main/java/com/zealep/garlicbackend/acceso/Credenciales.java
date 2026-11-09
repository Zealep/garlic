package com.zealep.garlicbackend.acceso;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Claves y sesiones de los usuarios (SQL directo: son datos de acceso, no del catalogo de usuarios).
 */
@Repository
public class Credenciales {

    private final JdbcClient jdbc;

    public Credenciales(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public record Usuario(
            UUID id, UUID empresaId, String nombres, String dni, String email, String rol, boolean activo,
            String claveHash, boolean debeCambiarClave) {

        public boolean admin() {
            return "ADMIN".equals(rol);
        }
    }

    public record Sesion(UUID id, UUID usuarioId, Instant expiraEn, boolean revocada) {
    }

    private static final String COLUMNAS =
            "id, empresa_id, nombres, dni, email, rol, activo, clave_hash, debe_cambiar_clave FROM usuario";

    public Optional<Usuario> porDni(String dni) {
        return jdbc.sql("SELECT " + COLUMNAS + " WHERE dni = :dni").param("dni", dni).query(Usuario.class).optional();
    }

    public Optional<Usuario> porId(UUID id) {
        return jdbc.sql("SELECT " + COLUMNAS + " WHERE id = :id").param("id", id).query(Usuario.class).optional();
    }

    public void guardarClave(UUID usuarioId, String hash, boolean temporal) {
        jdbc.sql("UPDATE usuario SET clave_hash = :hash, debe_cambiar_clave = :temporal, updated_at = now() WHERE id = :id")
                .param("hash", hash)
                .param("temporal", temporal)
                .param("id", usuarioId)
                .update();
    }

    public void hacerAdmin(UUID usuarioId) {
        jdbc.sql("UPDATE usuario SET rol = 'ADMIN' WHERE id = :id AND rol <> 'ADMIN'").param("id", usuarioId).update();
    }

    public void registrarAcceso(UUID usuarioId) {
        jdbc.sql("UPDATE usuario SET ultimo_acceso = now() WHERE id = :id").param("id", usuarioId).update();
    }

    public UUID crearSesion(UUID usuarioId, String tokenHash, Instant expiraEn, String dispositivo) {
        return jdbc.sql("""
                        INSERT INTO sesion_usuario (usuario_id, token_hash, expira_en, ultimo_uso, dispositivo)
                        VALUES (:usuario, :hash, :expira, now(), :dispositivo) RETURNING id""")
                .param("usuario", usuarioId)
                .param("hash", tokenHash)
                .param("expira", java.sql.Timestamp.from(expiraEn))
                .param("dispositivo", dispositivo)
                .query(UUID.class)
                .single();
    }

    public Optional<Sesion> sesionPorToken(String tokenHash) {
        return jdbc.sql("SELECT id, usuario_id, expira_en, revocada FROM sesion_usuario WHERE token_hash = :hash")
                .param("hash", tokenHash)
                .query(Sesion.class)
                .optional();
    }

    /** Rota el refresh token y extiende la sesion (30 dias deslizantes). */
    public void rotar(UUID sesionId, String nuevoHash, Instant expiraEn) {
        jdbc.sql("UPDATE sesion_usuario SET token_hash = :hash, expira_en = :expira, ultimo_uso = now() WHERE id = :id")
                .param("hash", nuevoHash)
                .param("expira", java.sql.Timestamp.from(expiraEn))
                .param("id", sesionId)
                .update();
    }

    public void revocar(UUID sesionId) {
        jdbc.sql("UPDATE sesion_usuario SET revocada = true WHERE id = :id").param("id", sesionId).update();
    }

    /** Cierra todas las sesiones del usuario salvo {@code excepto} (puede ser null). */
    public void revocarTodas(UUID usuarioId, UUID excepto) {
        jdbc.sql("UPDATE sesion_usuario SET revocada = true WHERE usuario_id = :usuario AND NOT revocada"
                        + (excepto == null ? "" : " AND id <> :excepto"))
                .param("usuario", usuarioId)
                .params(excepto == null ? java.util.Map.of() : java.util.Map.of("excepto", excepto))
                .update();
    }

    public Optional<EmpresaSesion> empresa(UUID empresaId) {
        return jdbc.sql("SELECT id, ruc, razon_social FROM empresa WHERE id = :id")
                .param("id", empresaId)
                .query(EmpresaSesion.class)
                .optional();
    }
}

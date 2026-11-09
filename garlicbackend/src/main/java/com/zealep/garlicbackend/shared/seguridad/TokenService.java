package com.zealep.garlicbackend.shared.seguridad;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

/** Emite access tokens (JWT) y refresh tokens (opacos; en la base solo su hash). */
@Service
public class TokenService {

    private static final String EMISOR = "garlic";
    private final SecureRandom azar = new SecureRandom();
    private final JwtEncoder encoder;
    private final AccesoProperties props;

    public TokenService(JwtEncoder encoder, AccesoProperties props) {
        this.encoder = encoder;
        this.props = props;
    }

    public record Acceso(String token, Instant expiraEn) {
    }

    public Acceso acceso(UUID usuarioId, UUID empresaId, UUID sesionId, String nombres, boolean admin) {
        Instant ahora = Instant.now();
        Instant expira = ahora.plus(props.duracionAcceso());
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(EMISOR)
                .subject(usuarioId.toString())
                .issuedAt(ahora)
                .expiresAt(expira)
                .claim(UsuarioActual.CLAIM_EMPRESA, empresaId.toString())
                .claim(UsuarioActual.CLAIM_SESION, sesionId.toString())
                .claim(UsuarioActual.CLAIM_NOMBRES, nombres)
                .claim(UsuarioActual.CLAIM_ADMIN, admin)
                .build();
        String token = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
        return new Acceso(token, expira);
    }

    /** Refresh token nuevo: 32 bytes al azar (base64 url). */
    public String nuevoRefresh() {
        byte[] bytes = new byte[32];
        azar.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public static String hash(String refresh) {
        return HexFormat.of().formatHex(SecurityConfig.sha256(refresh.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
    }

    public Instant vencimientoSesion() {
        return Instant.now().plus(props.duracionSesion());
    }
}

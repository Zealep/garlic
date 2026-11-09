package com.zealep.garlicbackend.shared.seguridad;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.List;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;

/**
 * Login propio: la app envia DNI + clave a {@code /api/v1/auth/login} y recibe un access token (JWT HS256
 * firmado por este servidor) y un refresh token. Todo {@code /api/**} exige el access token, salvo el login.
 * <p>
 * Sin roles de negocio: cualquier usuario autenticado puede trabajar. La unica restriccion es que solo un
 * administrador ({@code rol = ADMIN}) gestiona usuarios.
 */
@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(AccesoProperties.class)
public class SecurityConfig {

    private static final Logger logger = LoggerFactory.getLogger(SecurityConfig.class);
    static final String ROL_ADMIN = "ADMIN";

    @Bean
    SecurityFilterChain seguridad(HttpSecurity http) throws Exception {
        http.csrf(c -> c.disable())
                .cors(Customizer.withDefaults())
                .httpBasic(b -> b.disable())
                .formLogin(f -> f.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(a -> a
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers("/api/v1/auth/login", "/api/v1/auth/refresh", "/api/v1/auth/logout").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/usuarios/**").authenticated()
                        .requestMatchers("/api/v1/usuarios/**").hasRole(ROL_ADMIN)
                        .requestMatchers("/api/**").authenticated()
                        // /instalacion/empresa, /actuator/health, swagger (solo dev) y /error
                        .anyRequest().permitAll())
                .oauth2ResourceServer(o -> o
                        .jwt(j -> j.jwtAuthenticationConverter(convertidor()))
                        .authenticationEntryPoint(noAutenticado())
                        .accessDeniedHandler(sinPermiso()))
                .exceptionHandling(e -> e.authenticationEntryPoint(noAutenticado()).accessDeniedHandler(sinPermiso()));
        return http.build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    SecretKey claveJwt(AccesoProperties props) {
        String secreto = props.jwtSecret();
        if (secreto == null || secreto.isBlank()) {
            logger.warn("garlic.acceso.jwt-secret vacio: se usa una clave al azar (las sesiones no sobreviven un reinicio)");
            byte[] azar = new byte[32];
            new SecureRandom().nextBytes(azar);
            return new SecretKeySpec(azar, "HmacSHA256");
        }
        if (secreto.length() < 32) {
            throw new IllegalStateException("garlic.acceso.jwt-secret debe tener al menos 32 caracteres");
        }
        // SHA-256 del secreto: siempre 256 bits, cualquiera sea su largo
        return new SecretKeySpec(sha256(secreto.getBytes(StandardCharsets.UTF_8)), "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey claveJwt) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(claveJwt));
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey claveJwt) {
        return NimbusJwtDecoder.withSecretKey(claveJwt).macAlgorithm(MacAlgorithm.HS256).build();
    }

    /** {@code admin: true} en el token da el rol ADMIN (gestion de usuarios). */
    private static JwtAuthenticationConverter convertidor() {
        JwtAuthenticationConverter c = new JwtAuthenticationConverter();
        c.setJwtGrantedAuthoritiesConverter(jwt -> {
            List<GrantedAuthority> permisos = Boolean.TRUE.equals(jwt.getClaimAsBoolean(UsuarioActual.CLAIM_ADMIN))
                    ? List.of(new SimpleGrantedAuthority("ROLE_" + ROL_ADMIN))
                    : List.of();
            return permisos;
        });
        return c;
    }

    private static AuthenticationEntryPoint noAutenticado() {
        return (request, response, ex) -> problema(response, HttpStatus.UNAUTHORIZED, "No autenticado",
                "Inicie sesion para continuar");
    }

    private static AccessDeniedHandler sinPermiso() {
        return (request, response, ex) -> problema(response, HttpStatus.FORBIDDEN, "Sin permiso",
                "Solo un administrador puede hacer esta accion");
    }

    /** ProblemDetail (RFC 9457) escrito a mano: estos errores ocurren antes de llegar a los controladores. */
    private static void problema(HttpServletResponse response, HttpStatus status, String titulo, String detalle)
            throws IOException {
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write("""
                {"type":"about:blank","title":"%s","status":%d,"detail":"%s"}""".formatted(titulo, status.value(), detalle));
    }

    static byte[] sha256(byte[] datos) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(datos);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}

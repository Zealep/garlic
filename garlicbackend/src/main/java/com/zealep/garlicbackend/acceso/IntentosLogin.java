package com.zealep.garlicbackend.acceso;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Frena la adivinanza de claves: tras {@value #MAXIMO} intentos fallidos seguidos de un DNI, ese DNI queda
 * bloqueado {@link #BLOQUEO}. En memoria (una sola instancia del backend).
 */
@Component
public class IntentosLogin {

    static final int MAXIMO = 5;
    static final Duration BLOQUEO = Duration.ofMinutes(15);

    private final Map<String, Estado> porDni = new ConcurrentHashMap<>();
    private final Clock reloj;

    public IntentosLogin() {
        this(Clock.systemUTC());
    }

    IntentosLogin(Clock reloj) {
        this.reloj = reloj;
    }

    private record Estado(int fallos, Instant bloqueadoHasta) {
    }

    public boolean bloqueado(String dni) {
        Estado e = porDni.get(dni);
        return e != null && e.bloqueadoHasta() != null && reloj.instant().isBefore(e.bloqueadoHasta());
    }

    public void fallo(String dni) {
        porDni.compute(dni, (k, e) -> {
            int fallos = (e == null || e.bloqueadoHasta() != null ? 0 : e.fallos()) + 1;
            return fallos >= MAXIMO ? new Estado(0, reloj.instant().plus(BLOQUEO)) : new Estado(fallos, null);
        });
    }

    public void exito(String dni) {
        porDni.remove(dni);
    }
}

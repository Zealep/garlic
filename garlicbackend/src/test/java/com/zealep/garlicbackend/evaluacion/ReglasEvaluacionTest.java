package com.zealep.garlicbackend.evaluacion;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.zealep.garlicbackend.catalogo.tipodano.TipoDano;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest.Calidad;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest.Muestra;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest.Sanidad;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ReglasEvaluacionTest {

    private static final UUID PRIMERA = UUID.randomUUID();
    private static final UUID ABIERTOS = UUID.randomUUID();
    private static final UUID NO_CONTIENE = UUID.randomUUID();
    private static final UUID CEROSA = UUID.randomUUID();
    private static final Map<UUID, TipoDano> DANOS = Map.of(
            NO_CONTIENE, dano("NO CONTIENE", true),
            CEROSA, dano("PARALISIS CEROSA", false));

    @Test
    void calidadQueSuma100_esValida_inclusoConDecimales() {
        EvaluacionRequest req = request(List.of(muestra(1, "33.33", "66.67")), List.of(), List.of());

        assertThatCode(() -> ReglasEvaluacion.validarContenido(req, DANOS)).doesNotThrowAnyException();
    }

    @Test
    void calidadQueNoSuma100_esRechazada() {
        EvaluacionRequest req = request(List.of(muestra(2, "80", "10")), List.of(), List.of());

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Muestra 2: la calidad debe sumar 100% (suma 90%)");
    }

    @Test
    void numeroDeMuestraRepetido_esRechazado() {
        EvaluacionRequest req = request(List.of(muestra(1, "80", "20"), muestra(1, "70", "30")), List.of(), List.of());

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("numero de muestra repetido");
    }

    @Test
    void danoExcluyente_juntoAOtro_esRechazado() {
        EvaluacionRequest req = request(List.of(), List.of(NO_CONTIENE, CEROSA), List.of());

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("'NO CONTIENE' no puede marcarse junto a otros danos");
    }

    @Test
    void danoExcluyente_solo_esValido() {
        EvaluacionRequest req = request(List.of(), List.of(NO_CONTIENE), List.of());

        assertThatCode(() -> ReglasEvaluacion.validarContenido(req, DANOS)).doesNotThrowAnyException();
    }

    @Test
    void porcentajeDeEnfermedadNoPresente_esRechazado() {
        EvaluacionRequest req = request(List.of(), List.of(),
                List.of(new Sanidad(UUID.randomUUID(), false, new BigDecimal("5"))));

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("solo se registra si esta presente");
    }

    @Test
    void cierre_sinMuestras_esRechazado() {
        EvaluacionLote ev = new EvaluacionLote(UUID.randomUUID(), null);

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("al menos una muestra");
    }

    @Test
    void cierre_sinResponderEnfermedadObligatoria_esRechazado() {
        EvaluacionLote ev = new EvaluacionLote(UUID.randomUUID(), null);
        ev.muestraONueva((short) 1).reemplazarCalidad(List.of(new PorcentajeCalidad(PRIMERA, BigDecimal.valueOf(100))));

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(UUID.randomUUID())))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("responda SI/NO");
    }

    private static EvaluacionRequest request(List<Muestra> muestras, List<UUID> danos, List<Sanidad> sanidad) {
        return new EvaluacionRequest(null, UUID.randomUUID(), LocalDate.now(), null, muestras, null, null, danos, sanidad);
    }

    private static Muestra muestra(int numero, String primera, String abiertos) {
        return new Muestra((short) numero, null, List.of(
                new Calidad(PRIMERA, new BigDecimal(primera)),
                new Calidad(ABIERTOS, new BigDecimal(abiertos))), null);
    }

    private static TipoDano dano(String nombre, boolean excluyente) {
        TipoDano d = new TipoDano();
        d.setNombre(nombre);
        d.setEsExcluyente(excluyente);
        return d;
    }
}

package com.zealep.garlicbackend.evaluacion;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.zealep.garlicbackend.catalogo.tipodano.TipoDano;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest.Calidad;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest.Dano;
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
    private static final UUID CAL_50_60 = UUID.randomUUID();
    private static final UUID CAL_60_70 = UUID.randomUUID();
    private static final Map<UUID, TipoDano> DANOS = Map.of(
            NO_CONTIENE, dano("NO CONTIENE", true, false),
            CEROSA, dano("PARALISIS CEROSA", false, true));

    @Test
    void calidadQueSuma100_esValida_inclusoConDecimales() {
        EvaluacionRequest req = request(muestra(1, "33.33", "66.67"));

        assertThatCode(() -> ReglasEvaluacion.validarContenido(req, DANOS)).doesNotThrowAnyException();
    }

    @Test
    void calidadQueNoSuma100_esRechazada() {
        EvaluacionRequest req = request(muestra(2, "80", "10"));

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Muestra 2: la calidad debe sumar 100% (suma 90%)");
    }

    @Test
    void numeroDeMuestraRepetido_esRechazado() {
        EvaluacionRequest req = request(muestra(1, "80", "20"), muestra(1, "70", "30"));

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("numero de muestra repetido");
    }

    @Test
    void danoExcluyente_juntoAOtro_esRechazado() {
        EvaluacionRequest req = request(conDanos(new Dano(NO_CONTIENE, null, null), new Dano(CEROSA, 20, 5)));

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Muestra 1: 'NO CONTIENE' no puede marcarse junto a otros danos");
    }

    @Test
    void danoExcluyente_solo_esValido() {
        EvaluacionRequest req = request(conDanos(new Dano(NO_CONTIENE, null, null)));

        assertThatCode(() -> ReglasEvaluacion.validarContenido(req, DANOS)).doesNotThrowAnyException();
    }

    @Test
    void porcentajeDeEnfermedadNoPresente_esRechazado() {
        EvaluacionRequest req = request(new Muestra(null, (short) 1, null, null, null, null, null, null,
                List.of(new Sanidad(UUID.randomUUID(), false, new BigDecimal("5")))));

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("solo se registra si esta presente");
    }

    @Test
    void frutosConProblemaMayoresAlTotal_sonRechazados() {
        EvaluacionRequest req = request(conDanos(new Dano(CEROSA, 10, 12)));

        assertThatThrownBy(() -> ReglasEvaluacion.validarContenido(req, DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Muestra 1: PARALISIS CEROSA: los frutos con problema no pueden ser mas que el total");
    }

    @Test
    void danoPorcentaje_seCalculaConLasCantidades() {
        assertThat(new DanoObservado(CEROSA, 20, 10).porcentaje()).isEqualByComparingTo("50");
        assertThat(new DanoObservado(CEROSA, 3, 1).porcentaje()).isEqualByComparingTo("33.33");
        assertThat(new DanoObservado(NO_CONTIENE, null, null).porcentaje()).isNull();
    }

    @Test
    void cierre_paralisisSinCantidades_esRechazado() {
        EvaluacionLote ev = muestraCompleta(new BigDecimal("100"));
        ev.muestra((short) 1).orElseThrow().reemplazarDanos(List.of(new DanoObservado(CEROSA, null, null)));

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("frutos total y con problema de PARALISIS CEROSA");
    }

    @Test
    void cierre_cadaMuestraDebeResponderLaSanidad() {
        UUID fusarium = UUID.randomUUID();
        EvaluacionLote ev = muestraCompleta(new BigDecimal("100"));
        ev.muestra((short) 1).orElseThrow().reemplazarSanidad(List.of(new SanidadObservada(fusarium, false, null)));
        var m2 = ev.agregarMuestra(null, (short) 2);
        m2.reemplazarCalidad(List.of(new PorcentajeCalidad(PRIMERA, BigDecimal.valueOf(100))));
        m2.reemplazarCalibres(List.of(new PorcentajeCalibre(CAL_50_60, BigDecimal.valueOf(100))));

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(fusarium), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Para cerrar, la muestra 2 debe responder SI/NO en todas las enfermedades a evaluar en campo");
    }

    @Test
    void cierre_sinMuestras_esRechazado() {
        EvaluacionLote ev = new EvaluacionLote(UUID.randomUUID(), null);

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("al menos una muestra");
    }

    @Test
    void cierre_sinResponderEnfermedadObligatoria_esRechazado() {
        EvaluacionLote ev = muestraCompleta(new BigDecimal("100"));

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(UUID.randomUUID()), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("responder SI/NO");
    }

    @Test
    void cierre_sinCalibres_esRechazado() {
        EvaluacionLote ev = new EvaluacionLote(UUID.randomUUID(), null);
        ev.agregarMuestra(null, (short) 1).reemplazarCalidad(List.of(new PorcentajeCalidad(PRIMERA, BigDecimal.valueOf(100))));

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("al menos un calibre");
    }

    @Test
    void cierre_calibresQueNoSuman100_esRechazado() {
        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(muestraCompleta(new BigDecimal("79.3")), List.of(), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("sumen 100% (suma 79.3%)");
    }

    @Test
    void cierre_calibreSinPorcentaje_esRechazado() {
        EvaluacionLote ev = muestraCompleta(new BigDecimal("100"));
        ev.muestra((short) 1).orElseThrow().reemplazarCalibres(List.of(
                new PorcentajeCalibre(CAL_50_60, new BigDecimal("100")),
                new PorcentajeCalibre(CAL_60_70, BigDecimal.ZERO)));

        assertThatThrownBy(() -> ReglasEvaluacion.validarCierre(ev, List.of(), DANOS))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("calibre sin porcentaje");
    }

    @Test
    void cierre_calibresSuperpuestosQueSuman100_esValido() {
        EvaluacionLote ev = muestraCompleta(new BigDecimal("100"));
        ev.muestra((short) 1).orElseThrow().reemplazarCalibres(List.of(
                new PorcentajeCalibre(CAL_50_60, new BigDecimal("60")),
                new PorcentajeCalibre(CAL_60_70, new BigDecimal("40"))));

        assertThatCode(() -> ReglasEvaluacion.validarCierre(ev, List.of(), DANOS)).doesNotThrowAnyException();
    }

    /** Muestra 1 con calidad 100% y un calibre con el porcentaje indicado. */
    private static EvaluacionLote muestraCompleta(BigDecimal pctCalibre) {
        EvaluacionLote ev = new EvaluacionLote(UUID.randomUUID(), null);
        var m = ev.agregarMuestra(null, (short) 1);
        m.reemplazarCalidad(List.of(new PorcentajeCalidad(PRIMERA, BigDecimal.valueOf(100))));
        m.reemplazarCalibres(List.of(new PorcentajeCalibre(CAL_50_60, pctCalibre)));
        return ev;
    }

    private static EvaluacionRequest request(Muestra... muestras) {
        return new EvaluacionRequest(null, UUID.randomUUID(), LocalDate.now(), null, List.of(muestras));
    }

    private static Muestra muestra(int numero, String primera, String abiertos) {
        return new Muestra(null, (short) numero, null, List.of(
                new Calidad(PRIMERA, new BigDecimal(primera)),
                new Calidad(ABIERTOS, new BigDecimal(abiertos))), null, null, null, null, null);
    }

    private static Muestra conDanos(Dano... danos) {
        return new Muestra(null, (short) 1, null, null, null, null, null, List.of(danos), null);
    }

    private static TipoDano dano(String nombre, boolean excluyente, boolean pideCantidades) {
        TipoDano d = new TipoDano();
        d.setNombre(nombre);
        d.setEsExcluyente(excluyente);
        d.setPideCantidades(pideCantidades);
        return d;
    }
}

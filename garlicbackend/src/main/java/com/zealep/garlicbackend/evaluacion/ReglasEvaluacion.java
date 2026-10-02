package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.catalogo.tipodano.TipoDano;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import java.math.BigDecimal;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;

/**
 * Reglas de negocio de la evaluacion (sin dependencias de Spring, faciles de probar).
 */
final class ReglasEvaluacion {

    private static final BigDecimal CIEN = BigDecimal.valueOf(100);

    private ReglasEvaluacion() {
    }

    /** Reglas que se validan en cada guardado (incluido el borrador). */
    static void validarContenido(EvaluacionRequest request, Map<UUID, TipoDano> tiposDano) {
        sinRepetidos(request.muestrasOVacio(), EvaluacionRequest.Muestra::numero, "numero de muestra");

        for (EvaluacionRequest.Muestra m : request.muestrasOVacio()) {
            String muestra = "Muestra " + m.numero() + ": ";
            sinRepetidos(m.calidadOVacio(), EvaluacionRequest.Calidad::claseCalidadId, muestra + "clase de calidad");
            sinRepetidos(m.calibresOVacio(), EvaluacionRequest.Calibre::calibreId, muestra + "calibre");
            if (!m.calidadOVacio().isEmpty()) {
                BigDecimal suma = m.calidadOVacio().stream()
                        .map(EvaluacionRequest.Calidad::porcentaje)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                if (suma.compareTo(CIEN) != 0) {
                    throw new BusinessException(muestra + "la calidad debe sumar 100% (suma " + suma.stripTrailingZeros().toPlainString() + "%)");
                }
            }
            // calibres: la suma de 100% se exige al cerrar (el borrador se guarda mientras se escribe)
        }

        sinRepetidos(request.humedadOVacio(), EvaluacionRequest.Humedad::tipoHumedadId, "tipo de humedad");
        sinRepetidos(request.sanidadOVacio(), EvaluacionRequest.Sanidad::enfermedadId, "enfermedad");

        for (EvaluacionRequest.Sanidad s : request.sanidadOVacio()) {
            if (!s.presente() && s.porcentaje() != null) {
                throw new BusinessException("El porcentaje de una enfermedad solo se registra si esta presente");
            }
        }

        Set<UUID> danos = new HashSet<>(request.danosOVacio());
        boolean excluyenteMarcado = danos.stream().map(tiposDano::get).anyMatch(TipoDano::isEsExcluyente);
        if (excluyenteMarcado && danos.size() > 1) {
            String excluyente = danos.stream().map(tiposDano::get).filter(TipoDano::isEsExcluyente)
                    .map(TipoDano::getNombre).findFirst().orElse("");
            throw new BusinessException("'" + excluyente + "' no puede marcarse junto a otros danos");
        }
    }

    /** Reglas adicionales para cerrar la evaluacion (debe estar completa). */
    static void validarCierre(EvaluacionLote ev, Collection<UUID> enfermedadesObligatorias) {
        List<Muestra> muestras = ev.getMuestras();
        if (muestras.isEmpty()) {
            throw new BusinessException("Para cerrar la evaluacion registre al menos una muestra");
        }
        for (Muestra m : muestras) {
            String muestra = "Para cerrar, la muestra " + m.getNumero() + " ";
            if (m.getCalidad().isEmpty()) {
                throw new BusinessException(muestra + "debe tener el factor de calidad");
            }
            if (m.getCalibres().isEmpty()) {
                throw new BusinessException(muestra + "debe tener al menos un calibre");
            }
            if (m.getCalibres().stream().anyMatch(c -> c.porcentaje().signum() == 0)) {
                throw new BusinessException(muestra + "tiene un calibre sin porcentaje");
            }
            BigDecimal sumaCalibres = m.getCalibres().stream()
                    .map(PorcentajeCalibre::porcentaje)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            if (sumaCalibres.compareTo(CIEN) != 0) {
                throw new BusinessException(muestra + "debe tener calibres que sumen 100% (suma "
                        + sumaCalibres.stripTrailingZeros().toPlainString() + "%)");
            }
        }
        Set<UUID> respondidas = new HashSet<>();
        ev.getSanidad().forEach(s -> respondidas.add(s.enfermedadId()));
        if (!respondidas.containsAll(enfermedadesObligatorias)) {
            throw new BusinessException("Para cerrar, responda SI/NO en todas las enfermedades a evaluar en campo");
        }
    }

    private static <T, K> void sinRepetidos(List<T> items, Function<T, K> clave, String que) {
        Set<K> vistos = new HashSet<>();
        for (T item : items) {
            if (!vistos.add(clave.apply(item))) {
                throw new BusinessException("Hay un " + que + " repetido: " + clave.apply(item));
            }
        }
    }
}

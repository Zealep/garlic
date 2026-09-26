package com.zealep.garlicbackend.evaluacion.dto;

import com.zealep.garlicbackend.catalogo.calibre.CalibreResponse;
import com.zealep.garlicbackend.catalogo.clasecalidad.ClaseCalidadResponse;
import com.zealep.garlicbackend.catalogo.enfermedad.EnfermedadResponse;
import com.zealep.garlicbackend.catalogo.tipodano.TipoDanoResponse;
import com.zealep.garlicbackend.catalogo.tipoempaste.TipoEmpasteResponse;
import com.zealep.garlicbackend.catalogo.tipohumedad.TipoHumedadResponse;
import com.zealep.garlicbackend.evaluacion.NivelHumedad;
import java.util.List;
import java.util.UUID;

/**
 * Todo lo que el front necesita para dibujar el formulario de evaluacion de un cultivo:
 * las opciones activas de cada factor (configurables por empresa).
 *
 * @param enfermedades solo las marcadas "evaluar en campo" (SI/NO + %)
 */
public record FormularioEvaluacion(
        UUID cultivoId,
        List<ClaseCalidadResponse> clasesCalidad,
        List<CalibreResponse> calibres,
        List<TipoHumedadResponse> tiposHumedad,
        List<NivelHumedad> nivelesHumedad,
        List<TipoEmpasteResponse> tiposEmpaste,
        List<TipoDanoResponse> tiposDano,
        List<EnfermedadResponse> enfermedades) {
}

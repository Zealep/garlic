package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import com.zealep.garlicbackend.catalogo.calibre.Calibre;
import com.zealep.garlicbackend.catalogo.calibre.CalibreService;
import com.zealep.garlicbackend.catalogo.clasecalidad.ClaseCalidad;
import com.zealep.garlicbackend.catalogo.clasecalidad.ClaseCalidadService;
import com.zealep.garlicbackend.catalogo.enfermedad.Enfermedad;
import com.zealep.garlicbackend.catalogo.enfermedad.EnfermedadService;
import com.zealep.garlicbackend.catalogo.tipodano.TipoDano;
import com.zealep.garlicbackend.catalogo.tipodano.TipoDanoService;
import com.zealep.garlicbackend.catalogo.tipoempaste.TipoEmpaste;
import com.zealep.garlicbackend.catalogo.tipoempaste.TipoEmpasteService;
import com.zealep.garlicbackend.catalogo.tipohumedad.TipoHumedad;
import com.zealep.garlicbackend.catalogo.tipohumedad.TipoHumedadService;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest;
import com.zealep.garlicbackend.evaluacion.dto.FormularioEvaluacion;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Stream;
import org.springframework.stereotype.Component;

/**
 * Acceso a los catalogos que usa la evaluacion (calidad, calibre, humedad, empaste, danos, enfermedades).
 */
@Component
public class CatalogosEvaluacion {

    private final ClaseCalidadService claseCalidadService;
    private final CalibreService calibreService;
    private final TipoHumedadService tipoHumedadService;
    private final TipoEmpasteService tipoEmpasteService;
    private final TipoDanoService tipoDanoService;
    private final EnfermedadService enfermedadService;

    public CatalogosEvaluacion(ClaseCalidadService claseCalidadService, CalibreService calibreService,
            TipoHumedadService tipoHumedadService, TipoEmpasteService tipoEmpasteService,
            TipoDanoService tipoDanoService, EnfermedadService enfermedadService) {
        this.claseCalidadService = claseCalidadService;
        this.calibreService = calibreService;
        this.tipoHumedadService = tipoHumedadService;
        this.tipoEmpasteService = tipoEmpasteService;
        this.tipoDanoService = tipoDanoService;
        this.enfermedadService = enfermedadService;
    }

    /** Catalogos referenciados por el request: deben existir, estar activos y ser del cultivo del lote. */
    public Resueltos validar(EvaluacionRequest request, UUID cultivoId) {
        Resueltos r = new Resueltos(
                claseCalidadService.referenciasActivas(request.muestrasOVacio().stream()
                        .flatMap(m -> m.calidadOVacio().stream()).map(EvaluacionRequest.Calidad::claseCalidadId).toList()),
                calibreService.referenciasActivas(request.muestrasOVacio().stream()
                        .flatMap(m -> m.calibresOVacio().stream()).map(EvaluacionRequest.Calibre::calibreId).toList()),
                tipoHumedadService.referenciasActivas(request.humedadOVacio().stream()
                        .map(EvaluacionRequest.Humedad::tipoHumedadId).toList()),
                tipoEmpasteService.referenciasActivas(request.empastesOVacio()),
                tipoDanoService.referenciasActivas(request.danosOVacio()),
                enfermedadService.referenciasActivas(request.sanidadOVacio().stream()
                        .map(EvaluacionRequest.Sanidad::enfermedadId).toList()));
        r.todos()
                .filter(c -> !c.getCultivoId().equals(cultivoId))
                .findFirst()
                .ifPresent(c -> {
                    throw new BusinessException("La opcion " + c.getCodigo() + " no corresponde al cultivo del lote");
                });
        return r;
    }

    /** Catalogos que aparecen en una evaluacion guardada (activos o no), para armar la respuesta. */
    public Resueltos deEvaluacion(EvaluacionLote ev) {
        List<Muestra> muestras = ev.getMuestras();
        return new Resueltos(
                claseCalidadService.porIds(muestras.stream().flatMap(m -> m.getCalidad().stream())
                        .map(PorcentajeCalidad::claseCalidadId).toList()),
                calibreService.porIds(muestras.stream().flatMap(m -> m.getCalibres().stream())
                        .map(PorcentajeCalibre::calibreId).toList()),
                tipoHumedadService.porIds(ev.getHumedad().stream().map(HumedadObservada::tipoHumedadId).toList()),
                tipoEmpasteService.porIds(ev.getEmpastes()),
                tipoDanoService.porIds(ev.getDanos()),
                enfermedadService.porIds(ev.getSanidad().stream().map(SanidadObservada::enfermedadId).toList()));
    }

    /** Enfermedades que deben responderse SI/NO en toda evaluacion del cultivo. */
    public List<UUID> enfermedadesObligatorias(UUID cultivoId) {
        return enfermedadService.listarActivos(cultivoId).stream()
                .filter(e -> Boolean.TRUE.equals(e.evaluarEnCampo()))
                .map(e -> e.id())
                .toList();
    }

    public FormularioEvaluacion formulario(UUID cultivoId) {
        return new FormularioEvaluacion(
                cultivoId,
                claseCalidadService.listarActivos(cultivoId),
                calibreService.listarActivos(cultivoId),
                tipoHumedadService.listarActivos(cultivoId),
                Arrays.asList(NivelHumedad.values()),
                tipoEmpasteService.listarActivos(cultivoId),
                tipoDanoService.listarActivos(cultivoId),
                enfermedadService.listarActivos(cultivoId).stream()
                        .filter(e -> Boolean.TRUE.equals(e.evaluarEnCampo()))
                        .toList());
    }

    /** Catalogos resueltos por id. */
    public record Resueltos(
            Map<UUID, ClaseCalidad> clasesCalidad,
            Map<UUID, Calibre> calibres,
            Map<UUID, TipoHumedad> tiposHumedad,
            Map<UUID, TipoEmpaste> tiposEmpaste,
            Map<UUID, TipoDano> tiposDano,
            Map<UUID, Enfermedad> enfermedades) {

        Stream<CatalogoCultivoEntity> todos() {
            return Stream.<Collection<? extends CatalogoCultivoEntity>>of(
                            clasesCalidad.values(), calibres.values(), tiposHumedad.values(),
                            tiposEmpaste.values(), tiposDano.values(), enfermedades.values())
                    .flatMap(Collection::stream);
        }
    }
}

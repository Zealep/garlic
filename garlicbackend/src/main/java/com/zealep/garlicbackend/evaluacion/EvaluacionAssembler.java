package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import com.zealep.garlicbackend.evaluacion.CatalogosEvaluacion.Resueltos;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResponse;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResponse.Item;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResponse.ValorPorcentaje;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResumen;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import org.springframework.stereotype.Component;

/**
 * Arma las respuestas de evaluacion: agrega codigo/nombre de cada opcion, ordena segun el catalogo
 * y calcula los promedios por clase de calidad y calibre (columna PROM del protocolo).
 */
@Component
public class EvaluacionAssembler {

    public EvaluacionResponse toResponse(EvaluacionLote ev, Resueltos cat) {
        List<Muestra> muestras = ev.getMuestras();
        List<EvaluacionResponse.Muestra> muestrasRes = muestras.stream()
                .map(m -> new EvaluacionResponse.Muestra(m.getId(), m.getNumero(), m.getObservacion(),
                        valores(m.getCalidad(), PorcentajeCalidad::claseCalidadId, PorcentajeCalidad::porcentaje, cat.clasesCalidad()),
                        valores(m.getCalibres(), PorcentajeCalibre::calibreId, PorcentajeCalibre::porcentaje, cat.calibres())))
                .toList();

        EvaluacionResponse.Promedios promedios = new EvaluacionResponse.Promedios(
                promedios(muestras.stream().flatMap(m -> m.getCalidad().stream()).toList(),
                        PorcentajeCalidad::claseCalidadId, PorcentajeCalidad::porcentaje, cat.clasesCalidad()),
                promedios(muestras.stream().flatMap(m -> m.getCalibres().stream()).toList(),
                        PorcentajeCalibre::calibreId, PorcentajeCalibre::porcentaje, cat.calibres()));

        return new EvaluacionResponse(
                ev.getId(),
                ev.getLote().getId(),
                ev.getLote().getCodigo(),
                new EvaluacionResponse.Evaluador(ev.getEvaluador().getId(), ev.getEvaluador().getNombres()),
                ev.getFechaEvaluacion(),
                ev.getObservacion(),
                ev.getEstado(),
                muestrasRes,
                promedios,
                ordenados(ev.getHumedad(), HumedadObservada::tipoHumedadId, cat.tiposHumedad()).stream()
                        .map(h -> {
                            CatalogoCultivoEntity c = cat.tiposHumedad().get(h.tipoHumedadId());
                            return new EvaluacionResponse.Humedad(h.tipoHumedadId(), codigo(c), nombre(c), h.nivel());
                        }).toList(),
                items(ev.getEmpastes(), cat.tiposEmpaste()),
                items(ev.getDanos(), cat.tiposDano()),
                ordenados(ev.getSanidad(), SanidadObservada::enfermedadId, cat.enfermedades()).stream()
                        .map(s -> {
                            CatalogoCultivoEntity c = cat.enfermedades().get(s.enfermedadId());
                            return new EvaluacionResponse.Sanidad(s.enfermedadId(), codigo(c), nombre(c), s.presente(), s.porcentaje());
                        }).toList(),
                ev.getCreatedAt(),
                ev.getUpdatedAt());
    }

    public EvaluacionResumen toResumen(EvaluacionLote ev) {
        return new EvaluacionResumen(ev.getId(), ev.getLote().getId(), ev.getLote().getCodigo(), ev.getLote().getZona(),
                ev.getFechaEvaluacion(), ev.getEstado(),
                ev.getEvaluador().getNombres(), ev.getMuestras().size(), ev.getCreatedAt());
    }

    private static <T> List<ValorPorcentaje> valores(Collection<T> filas, Function<T, UUID> id,
            Function<T, BigDecimal> pct, Map<UUID, ? extends CatalogoCultivoEntity> cat) {
        return ordenados(filas, id, cat).stream()
                .map(f -> {
                    CatalogoCultivoEntity c = cat.get(id.apply(f));
                    return new ValorPorcentaje(id.apply(f), codigo(c), nombre(c), pct.apply(f));
                })
                .toList();
    }

    /** Promedio de cada opcion sobre las muestras que la registran (igual que AVERAGE del Excel y las vistas v_*_prom). */
    private static <T> List<ValorPorcentaje> promedios(List<T> filas, Function<T, UUID> id,
            Function<T, BigDecimal> pct, Map<UUID, ? extends CatalogoCultivoEntity> cat) {
        Map<UUID, BigDecimal[]> acumulado = new LinkedHashMap<>();
        for (T f : filas) {
            BigDecimal[] a = acumulado.computeIfAbsent(id.apply(f), k -> new BigDecimal[] {BigDecimal.ZERO, BigDecimal.ZERO});
            a[0] = a[0].add(pct.apply(f));
            a[1] = a[1].add(BigDecimal.ONE);
        }
        return acumulado.entrySet().stream()
                .sorted(Comparator.comparingInt(e -> orden(cat.get(e.getKey()))))
                .map(e -> {
                    CatalogoCultivoEntity c = cat.get(e.getKey());
                    BigDecimal promedio = e.getValue()[0].divide(e.getValue()[1], 2, RoundingMode.HALF_UP);
                    return new ValorPorcentaje(e.getKey(), codigo(c), nombre(c), promedio);
                })
                .toList();
    }

    private static List<Item> items(Collection<UUID> ids, Map<UUID, ? extends CatalogoCultivoEntity> cat) {
        return ordenados(ids, Function.identity(), cat).stream()
                .map(id -> new Item(id, codigo(cat.get(id)), nombre(cat.get(id))))
                .toList();
    }

    private static <T> List<T> ordenados(Collection<T> filas, Function<T, UUID> id,
            Map<UUID, ? extends CatalogoCultivoEntity> cat) {
        return filas.stream().sorted(Comparator.comparingInt(f -> orden(cat.get(id.apply(f))))).toList();
    }

    private static int orden(CatalogoCultivoEntity c) {
        return c == null || c.getOrden() == null ? Integer.MAX_VALUE : c.getOrden();
    }

    private static String codigo(CatalogoCultivoEntity c) {
        return c == null ? null : c.getCodigo();
    }

    private static String nombre(CatalogoCultivoEntity c) {
        return c == null ? null : c.getNombre();
    }
}

package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.catalogo.clasecalidad.ClaseCalidad;
import com.zealep.garlicbackend.catalogo.clasecalidad.ClaseCalidadService;
import com.zealep.garlicbackend.catalogo.condicionpago.CondicionPago;
import com.zealep.garlicbackend.catalogo.condicionpago.CondicionPagoService;
import com.zealep.garlicbackend.catalogo.tipoempaque.TipoEmpaque;
import com.zealep.garlicbackend.catalogo.tipoempaque.TipoEmpaqueService;
import com.zealep.garlicbackend.catalogo.tipogasto.TipoGasto;
import com.zealep.garlicbackend.catalogo.tipogasto.TipoGastoService;
import com.zealep.garlicbackend.compra.dto.CargaRequest;
import com.zealep.garlicbackend.compra.dto.CargaResponse;
import com.zealep.garlicbackend.compra.dto.CompraLoteResponse;
import com.zealep.garlicbackend.compra.dto.FijacionRequest;
import com.zealep.garlicbackend.compra.dto.FijacionResponse;
import com.zealep.garlicbackend.compra.dto.GastoRequest;
import com.zealep.garlicbackend.compra.dto.GastoResponse;
import com.zealep.garlicbackend.compra.dto.PagoRequest;
import com.zealep.garlicbackend.compra.dto.PagoResponse;
import com.zealep.garlicbackend.compra.dto.ResumenCompra;
import com.zealep.garlicbackend.evaluacion.EvaluacionService;
import com.zealep.garlicbackend.evaluacion.dto.CalidadPorMuestra;
import com.zealep.garlicbackend.lote.Lote;
import com.zealep.garlicbackend.lote.LoteService;
import com.zealep.garlicbackend.shared.domain.TenantEntity;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.Creacion;
import com.zealep.garlicbackend.tercero.persona.PersonaService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * Punto 3 del protocolo: fijacion de precio, cargas, gastos vinculados, pagos y balance del lote.
 * Cargas, gastos y pagos se guardan con PUT idempotente usando el UUID del cliente (app offline):
 * 201 si se crea, 200 si se actualiza.
 */
@Service
@Transactional(readOnly = true)
public class CompraService {

    private static final Logger logger = LoggerFactory.getLogger(CompraService.class);
    private static final BigDecimal DESTARE_POR_DEFECTO = BigDecimal.ONE;

    private final FijacionPrecioRepository fijacionRepository;
    private final CargaRepository cargaRepository;
    private final GastoVinculadoRepository gastoRepository;
    private final PagoRepository pagoRepository;
    private final ComprobanteService comprobanteService;
    private final LoteService loteService;
    private final EvaluacionService evaluacionService;
    private final ClaseCalidadService claseCalidadService;
    private final TipoEmpaqueService tipoEmpaqueService;
    private final TipoGastoService tipoGastoService;
    private final CondicionPagoService condicionPagoService;
    private final PersonaService personaService;
    private final TenantProvider tenantProvider;

    public CompraService(FijacionPrecioRepository fijacionRepository, CargaRepository cargaRepository,
            GastoVinculadoRepository gastoRepository, PagoRepository pagoRepository,
            ComprobanteService comprobanteService, LoteService loteService, EvaluacionService evaluacionService,
            ClaseCalidadService claseCalidadService, TipoEmpaqueService tipoEmpaqueService,
            TipoGastoService tipoGastoService, CondicionPagoService condicionPagoService,
            PersonaService personaService, TenantProvider tenantProvider) {
        this.fijacionRepository = fijacionRepository;
        this.cargaRepository = cargaRepository;
        this.gastoRepository = gastoRepository;
        this.pagoRepository = pagoRepository;
        this.comprobanteService = comprobanteService;
        this.loteService = loteService;
        this.evaluacionService = evaluacionService;
        this.claseCalidadService = claseCalidadService;
        this.tipoEmpaqueService = tipoEmpaqueService;
        this.tipoGastoService = tipoGastoService;
        this.condicionPagoService = condicionPagoService;
        this.personaService = personaService;
        this.tenantProvider = tenantProvider;
    }

    // ================================================================ consulta

    /** Todo el punto 3 del lote con su balance. */
    public CompraLoteResponse obtener(UUID loteId) {
        Lote lote = loteService.referencia(loteId);
        UUID empresaId = tenantProvider.currentEmpresaId();
        List<Carga> cargas = cargaRepository.findByLoteIdAndEmpresaIdOrderByCreatedAt(lote.getId(), empresaId).stream()
                .sorted(Comparator.comparing(Carga::getFecha).thenComparing(Carga::getCreatedAt))
                .toList();
        List<GastoVinculado> gastos = gastoRepository.findByLoteIdAndEmpresaIdOrderByCreatedAt(lote.getId(), empresaId);
        List<Pago> pagos = pagoRepository.findByLoteIdAndEmpresaIdOrderByCreatedAt(lote.getId(), empresaId).stream()
                .sorted(Comparator.comparing(Pago::getFecha).thenComparing(Pago::getCreatedAt))
                .toList();

        Map<UUID, TipoEmpaque> empaques = tipoEmpaqueService.porIds(ids(cargas, Carga::getTipoEmpaqueId));
        Map<UUID, TipoGasto> tiposGasto = tipoGastoService.porIds(ids(gastos, GastoVinculado::getTipoGastoId));
        Map<UUID, CondicionPago> condiciones = condicionPagoService.porIds(ids(pagos, Pago::getCondicionPagoId));
        Map<UUID, String> beneficiarios = personaService.nombresPorId(ids(pagos, Pago::getBeneficiarioId));

        FijacionResponse fijacion = fijacionRepository.findByLoteIdAndEmpresaId(lote.getId(), empresaId)
                .map(this::toResponse).orElse(null);
        return new CompraLoteResponse(
                lote.getId(),
                fijacion,
                cargas.stream().map(c -> toResponse(c, empaques)).toList(),
                gastos.stream().map(g -> toResponse(g, tiposGasto)).toList(),
                pagos.stream().map(p -> toResponse(p, condiciones, beneficiarios)).toList(),
                comprobanteService.listar(lote.getId()),
                resumen(cargas, gastos, pagos));
    }

    static ResumenCompra resumen(List<Carga> cargas, List<GastoVinculado> gastos, List<Pago> pagos) {
        CalculoCompra.Balance balance = CalculoCompra.balance(
                cargas.stream().map(Carga::calcular).toList(),
                gastos.stream().map(GastoVinculado::getMonto).toList(),
                pagos.stream().map(Pago::getMonto).toList());
        int empaques = cargas.stream().mapToInt(Carga::getCantidadEmpaques).sum();
        return ResumenCompra.of(cargas.size(), empaques, balance);
    }

    // ================================================================ fijacion de precio

    /** Crea o reemplaza la fijacion de precio del lote; el servidor recalcula promedio y precio tecnico. */
    @Transactional
    public Creacion<FijacionResponse> guardarFijacion(UUID loteId, FijacionRequest request) {
        Lote lote = loteEditable(loteId);
        CalidadPorMuestra calidad = evaluacionService.calidadPorMuestra(request.evaluacionId(), lote.getId());
        if (!calidad.cerrada()) {
            throw new BusinessException("El precio se fija con una evaluacion cerrada; cierre la evaluacion primero");
        }

        Map<UUID, BigDecimal> precios = new LinkedHashMap<>();
        for (FijacionRequest.PrecioClase p : request.preciosOVacio()) {
            if (precios.put(p.claseCalidadId(), p.precioBase()) != null) {
                throw new BusinessException("La clase de calidad " + p.claseCalidadId() + " tiene dos precios");
            }
        }
        Map<UUID, ClaseCalidad> clases = claseCalidadService.referenciasActivas(precios.keySet());

        if (request.precioPactado() != null) {
            List<UUID> sinPrecio = calidad.muestras().stream()
                    .flatMap(m -> m.calidad().entrySet().stream())
                    .filter(e -> e.getValue().signum() > 0 && !precios.containsKey(e.getKey()))
                    .map(Map.Entry::getKey).distinct().toList();
            if (!sinPrecio.isEmpty()) {
                String nombres = claseCalidadService.porIds(sinPrecio).values().stream()
                        .map(ClaseCalidad::getNombre).sorted().collect(Collectors.joining(", "));
                throw new BusinessException("Para pactar el precio falta el precio base de: " + nombres);
            }
        }

        UUID empresaId = tenantProvider.currentEmpresaId();
        var existente = fijacionRepository.findByLoteIdAndEmpresaId(lote.getId(), empresaId);
        FijacionPrecio fijacion = existente.orElseGet(() -> new FijacionPrecio(empresaId, lote.getId()));
        BigDecimal llenado = request.gastoLlenado() == null ? BigDecimal.ZERO : request.gastoLlenado();
        CalculoCompra.Fijacion calculo = CalculoCompra.fijacion(precios, calidadMuestras(calidad), llenado);

        fijacion.setEvaluacionId(calidad.evaluacionId());
        fijacion.reemplazarPrecios(clases.keySet().stream()
                .map(id -> new FijacionPrecio.PrecioClase(id, precio(precios.get(id))))
                .toList());
        fijacion.setGastoLlenado(precio(llenado));
        fijacion.setPreciosCalculados(calculo.precioPromedio(), calculo.precioTecnico());
        fijacion.setPrecioPactado(request.precioPactado() == null ? null : precio(request.precioPactado()));
        fijacion.setFechaPacto(request.precioPactado() == null ? null : request.fechaPacto());
        fijacion.setObservacion(request.observacion());
        FijacionPrecio guardada = fijacionRepository.saveAndFlush(fijacion);
        logger.info("Fijacion de precio del lote {}: tecnico {} pactado {}", lote.getCodigo(),
                guardada.getPrecioTecnico(), guardada.getPrecioPactado());
        return new Creacion<>(toResponse(guardada), existente.isEmpty());
    }

    private FijacionResponse toResponse(FijacionPrecio f) {
        CalidadPorMuestra calidad = evaluacionService.calidadPorMuestra(f.getEvaluacionId(), f.getLoteId());
        Map<UUID, BigDecimal> precios = f.getPrecios().stream()
                .collect(Collectors.toMap(FijacionPrecio.PrecioClase::claseCalidadId, FijacionPrecio.PrecioClase::precioBase));
        Map<UUID, ClaseCalidad> clases = claseCalidadService.porIds(precios.keySet());
        List<FijacionResponse.PrecioClase> preciosClase = f.getPrecios().stream()
                .map(p -> {
                    ClaseCalidad c = clases.get(p.claseCalidadId());
                    return new FijacionResponse.PrecioClase(p.claseCalidadId(), c == null ? null : c.getCodigo(),
                            c == null ? null : c.getNombre(), p.precioBase());
                })
                .sorted(Comparator.comparing((FijacionResponse.PrecioClase p) -> orden(clases.get(p.claseCalidadId())))
                        .thenComparing(p -> Objects.toString(p.nombre(), "")))
                .toList();
        List<FijacionResponse.PrecioMuestra> porMuestra = calidad.muestras().stream()
                .map(m -> new FijacionResponse.PrecioMuestra(m.numero(), CalculoCompra.precioMuestra(precios, m.calidad())))
                .toList();
        BigDecimal ajuste = f.getPrecioPactado() == null ? null : f.getPrecioPactado().subtract(f.getPrecioTecnico());
        return new FijacionResponse(f.getId(), f.getLoteId(), f.getEvaluacionId(), calidad.fechaEvaluacion(),
                preciosClase, porMuestra, f.getGastoLlenado(), f.getPrecioPromedio(), f.getPrecioTecnico(),
                f.getPrecioPactado(), ajuste, f.getFechaPacto(), f.getObservacion(), f.getUpdatedAt());
    }

    // ================================================================ cargas

    @Transactional
    public Creacion<CargaResponse> guardarCarga(UUID loteId, UUID id, CargaRequest request) {
        Lote lote = loteEditable(loteId);
        UUID empresaId = tenantProvider.currentEmpresaId();
        var existente = cargaRepository.findByIdAndEmpresaId(id, empresaId);
        Carga carga = existente.map(c -> delLote(c, c.getLoteId(), lote, "La carga"))
                .orElseGet(() -> nueva(new Carga(empresaId, lote.getId()), id));
        TipoEmpaque empaque = request.tipoEmpaqueId() == null ? null : tipoEmpaqueService.referenciaActiva(request.tipoEmpaqueId());

        carga.setFecha(request.fecha());
        carga.setPlaca(textoMayus(request.placa()));
        carga.setKg(request.kg().setScale(2, RoundingMode.HALF_UP));
        carga.setCantidadEmpaques(request.cantidadEmpaques() == null ? 0 : request.cantidadEmpaques());
        carga.setTipoEmpaqueId(empaque == null ? null : empaque.getId());
        carga.setPrecioKg(precio(request.precioKg()));
        carga.setDestarePct((request.destarePct() == null ? DESTARE_POR_DEFECTO : request.destarePct()).setScale(2, RoundingMode.HALF_UP));
        carga.setObservacion(request.observacion());
        Carga guardada = cargaRepository.saveAndFlush(carga);
        Map<UUID, TipoEmpaque> empaques = empaque == null ? Map.of() : Map.of(empaque.getId(), empaque);
        return new Creacion<>(toResponse(guardada, empaques), existente.isEmpty());
    }

    /** 409 si la carga tiene gastos vinculados; elimina tambien sus comprobantes. */
    @Transactional
    public void eliminarCarga(UUID loteId, UUID id) {
        Lote lote = loteEditable(loteId);
        Carga carga = cargaRepository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .filter(c -> c.getLoteId().equals(lote.getId()))
                .orElseThrow(() -> new NotFoundException("Carga", id));
        if (gastoRepository.existsByCargaId(id)) {
            throw new ConflictException("La carga tiene gastos vinculados; quitelos o paselos a generales primero");
        }
        comprobanteService.eliminarDeEntidad(id);
        cargaRepository.delete(carga);
        logger.info("Carga {} eliminada del lote {}", id, lote.getCodigo());
    }

    private static CargaResponse toResponse(Carga c, Map<UUID, TipoEmpaque> empaques) {
        CalculoCompra.LineaCarga l = c.calcular();
        TipoEmpaque empaque = c.getTipoEmpaqueId() == null ? null : empaques.get(c.getTipoEmpaqueId());
        return new CargaResponse(c.getId(), c.getLoteId(), c.getFecha(), c.getPlaca(), c.getKg(), c.getCantidadEmpaques(),
                c.getTipoEmpaqueId(), empaque == null ? null : empaque.getNombre(), c.getPrecioKg(), c.getDestarePct(),
                l.destareKg(), l.kgNeto(), l.importe(), l.descuentoDestare(), l.total(), c.getObservacion(), c.getUpdatedAt());
    }

    // ================================================================ gastos vinculados

    @Transactional
    public Creacion<GastoResponse> guardarGasto(UUID loteId, UUID id, GastoRequest request) {
        Lote lote = loteEditable(loteId);
        UUID empresaId = tenantProvider.currentEmpresaId();
        var existente = gastoRepository.findByIdAndEmpresaId(id, empresaId);
        GastoVinculado gasto = existente.map(g -> delLote(g, g.getLoteId(), lote, "El gasto"))
                .orElseGet(() -> nueva(new GastoVinculado(empresaId, lote.getId()), id));
        TipoGasto tipo = tipoGastoService.referenciaActiva(request.tipoGastoId());
        if (request.cargaId() != null) {
            cargaRepository.findByIdAndEmpresaId(request.cargaId(), empresaId)
                    .filter(c -> c.getLoteId().equals(lote.getId()))
                    .orElseThrow(() -> new BusinessException("La carga " + request.cargaId() + " no existe en el lote"));
        }
        if (tipo.isRequiereDescripcion() && !StringUtils.hasText(request.descripcion())) {
            throw new BusinessException("Describa el gasto (" + tipo.getNombre() + ")");
        }

        gasto.setTipoGastoId(tipo.getId());
        gasto.setCargaId(request.cargaId());
        gasto.setFecha(request.fecha());
        gasto.setMonto(monto(request.monto()));
        gasto.setDescripcion(StringUtils.hasText(request.descripcion()) ? request.descripcion().trim() : null);
        GastoVinculado guardado = gastoRepository.saveAndFlush(gasto);
        return new Creacion<>(toResponse(guardado, Map.of(tipo.getId(), tipo)), existente.isEmpty());
    }

    @Transactional
    public void eliminarGasto(UUID loteId, UUID id) {
        Lote lote = loteEditable(loteId);
        GastoVinculado gasto = gastoRepository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .filter(g -> g.getLoteId().equals(lote.getId()))
                .orElseThrow(() -> new NotFoundException("Gasto", id));
        comprobanteService.eliminarDeEntidad(id);
        gastoRepository.delete(gasto);
    }

    private static GastoResponse toResponse(GastoVinculado g, Map<UUID, TipoGasto> tipos) {
        TipoGasto tipo = tipos.get(g.getTipoGastoId());
        return new GastoResponse(g.getId(), g.getLoteId(), g.getCargaId(), g.getTipoGastoId(),
                tipo == null ? null : tipo.getNombre(), g.getFecha(), g.getMonto(), g.getDescripcion(), g.getUpdatedAt());
    }

    // ================================================================ pagos

    @Transactional
    public Creacion<PagoResponse> guardarPago(UUID loteId, UUID id, PagoRequest request) {
        Lote lote = loteEditable(loteId);
        UUID empresaId = tenantProvider.currentEmpresaId();
        var existente = pagoRepository.findByIdAndEmpresaId(id, empresaId);
        Pago pago = existente.map(p -> delLote(p, p.getLoteId(), lote, "El pago"))
                .orElseGet(() -> nueva(new Pago(empresaId, lote.getId()), id));
        CondicionPago condicion = condicionPagoService.referenciaActiva(request.condicionPagoId());
        var beneficiario = request.beneficiarioId() == null ? null : personaService.referencia(request.beneficiarioId());

        pago.setFecha(request.fecha());
        pago.setCondicionPagoId(condicion.getId());
        pago.setMonto(monto(request.monto()));
        pago.setBeneficiarioId(beneficiario == null ? null : beneficiario.getId());
        pago.setReferencia(StringUtils.hasText(request.referencia()) ? request.referencia().trim() : null);
        pago.setObservacion(request.observacion());
        Pago guardado = pagoRepository.saveAndFlush(pago);
        Map<UUID, String> nombres = beneficiario == null ? Map.of() : Map.of(beneficiario.getId(), beneficiario.getNombres());
        return new Creacion<>(toResponse(guardado, Map.of(condicion.getId(), condicion), nombres), existente.isEmpty());
    }

    @Transactional
    public void eliminarPago(UUID loteId, UUID id) {
        Lote lote = loteEditable(loteId);
        Pago pago = pagoRepository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .filter(p -> p.getLoteId().equals(lote.getId()))
                .orElseThrow(() -> new NotFoundException("Pago", id));
        comprobanteService.eliminarDeEntidad(id);
        pagoRepository.delete(pago);
        logger.info("Pago {} eliminado del lote {}", id, lote.getCodigo());
    }

    private static PagoResponse toResponse(Pago p, Map<UUID, CondicionPago> condiciones, Map<UUID, String> beneficiarios) {
        CondicionPago condicion = condiciones.get(p.getCondicionPagoId());
        return new PagoResponse(p.getId(), p.getLoteId(), p.getFecha(), p.getCondicionPagoId(),
                condicion == null ? null : condicion.getNombre(), p.getMonto(), p.getBeneficiarioId(),
                p.getBeneficiarioId() == null ? null : beneficiarios.get(p.getBeneficiarioId()),
                p.getReferencia(), p.getObservacion(), p.getUpdatedAt());
    }

    // ================================================================ util

    /** Lote de la empresa (404) que acepta cambios: un lote anulado no se modifica (409). */
    private Lote loteEditable(UUID loteId) {
        Lote lote = loteService.referencia(loteId);
        if (!lote.isActivo()) {
            throw new ConflictException("El lote " + lote.getCodigo() + " esta anulado");
        }
        return lote;
    }

    /** Un id del cliente que ya existe en otro lote es un conflicto (no se mueve de lote). */
    private static <E> E delLote(E entidad, UUID loteEntidad, Lote lote, String nombre) {
        if (!loteEntidad.equals(lote.getId())) {
            throw new ConflictException(nombre + " ya existe en otro lote");
        }
        return entidad;
    }

    private static <E extends TenantEntity> E nueva(E entidad, UUID id) {
        entidad.asignarId(id);
        return entidad;
    }

    private static List<Map<UUID, BigDecimal>> calidadMuestras(CalidadPorMuestra calidad) {
        return calidad.muestras().stream().map(CalidadPorMuestra.MuestraCalidad::calidad).toList();
    }

    private static <T> List<UUID> ids(Collection<T> items, Function<T, UUID> id) {
        return items.stream().map(id).filter(Objects::nonNull).distinct().toList();
    }

    private static int orden(ClaseCalidad c) {
        return c == null || c.getOrden() == null ? Integer.MAX_VALUE : c.getOrden();
    }

    private static BigDecimal precio(BigDecimal v) {
        return v.setScale(4, RoundingMode.HALF_UP);
    }

    private static BigDecimal monto(BigDecimal v) {
        return v.setScale(2, RoundingMode.HALF_UP);
    }

    private static String textoMayus(String v) {
        return StringUtils.hasText(v) ? v.trim().toUpperCase(Locale.ROOT) : null;
    }
}

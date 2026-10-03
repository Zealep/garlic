package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.compra.dto.CargaRequest;
import com.zealep.garlicbackend.compra.dto.CargaResponse;
import com.zealep.garlicbackend.compra.dto.ComprobanteResponse;
import com.zealep.garlicbackend.compra.dto.CompraLoteResponse;
import com.zealep.garlicbackend.compra.dto.FijacionRequest;
import com.zealep.garlicbackend.compra.dto.FijacionResponse;
import com.zealep.garlicbackend.compra.dto.GastoRequest;
import com.zealep.garlicbackend.compra.dto.GastoResponse;
import com.zealep.garlicbackend.compra.dto.PagoRequest;
import com.zealep.garlicbackend.compra.dto.PagoResponse;
import com.zealep.garlicbackend.shared.web.Creacion;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.Instant;
import java.util.UUID;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

/**
 * Punto 3 del protocolo. Los PUT de cargas, gastos y pagos crean o reemplazan con el UUID del cliente
 * (201 al crear, 200 al actualizar), asi la app offline nunca recibe 404 al sincronizar.
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Compra del lote (precio, cargas, gastos, pagos)")
public class CompraController {

    private final CompraService service;
    private final ComprobanteService comprobanteService;

    public CompraController(CompraService service, ComprobanteService comprobanteService) {
        this.service = service;
        this.comprobanteService = comprobanteService;
    }

    @GetMapping("/lotes/{loteId}/compra")
    @Operation(summary = "Fijacion de precio, cargas, gastos, pagos, comprobantes y balance del lote")
    public CompraLoteResponse obtener(@PathVariable UUID loteId) {
        return service.obtener(loteId);
    }

    @PutMapping("/lotes/{loteId}/fijacion-precio")
    @Operation(summary = "Crear o reemplazar la fijacion de precio (requiere una evaluacion cerrada del lote)")
    public ResponseEntity<FijacionResponse> guardarFijacion(@PathVariable UUID loteId,
            @Valid @RequestBody FijacionRequest request) {
        return responder(service.guardarFijacion(loteId, request));
    }

    @PutMapping("/lotes/{loteId}/cargas/{id}")
    @Operation(summary = "Crear o actualizar una carga (camion)")
    public ResponseEntity<CargaResponse> guardarCarga(@PathVariable UUID loteId, @PathVariable UUID id,
            @Valid @RequestBody CargaRequest request) {
        return responder(service.guardarCarga(loteId, id, request));
    }

    @DeleteMapping("/lotes/{loteId}/cargas/{id}")
    @Operation(summary = "Eliminar una carga (409 si tiene gastos vinculados)")
    public ResponseEntity<Void> eliminarCarga(@PathVariable UUID loteId, @PathVariable UUID id) {
        service.eliminarCarga(loteId, id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/lotes/{loteId}/gastos/{id}")
    @Operation(summary = "Crear o actualizar un gasto vinculado a la materia prima")
    public ResponseEntity<GastoResponse> guardarGasto(@PathVariable UUID loteId, @PathVariable UUID id,
            @Valid @RequestBody GastoRequest request) {
        return responder(service.guardarGasto(loteId, id, request));
    }

    @DeleteMapping("/lotes/{loteId}/gastos/{id}")
    public ResponseEntity<Void> eliminarGasto(@PathVariable UUID loteId, @PathVariable UUID id) {
        service.eliminarGasto(loteId, id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/lotes/{loteId}/pagos/{id}")
    @Operation(summary = "Crear o actualizar un pago (abono / adelanto) por la materia prima")
    public ResponseEntity<PagoResponse> guardarPago(@PathVariable UUID loteId, @PathVariable UUID id,
            @Valid @RequestBody PagoRequest request) {
        return responder(service.guardarPago(loteId, id, request));
    }

    @DeleteMapping("/lotes/{loteId}/pagos/{id}")
    public ResponseEntity<Void> eliminarPago(@PathVariable UUID loteId, @PathVariable UUID id) {
        service.eliminarPago(loteId, id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(path = "/lotes/{loteId}/comprobantes", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Subir foto de respaldo de una carga, gasto o pago (id opcional del cliente: 200 si ya existe)")
    public ResponseEntity<ComprobanteResponse> subirComprobante(
            @PathVariable UUID loteId,
            @RequestParam("archivo") MultipartFile archivo,
            @RequestParam EntidadComprobante entidad,
            @RequestParam UUID entidadId,
            @RequestParam(required = false) UUID id,
            @RequestParam(required = false) Instant fechaCaptura) {
        Creacion<ComprobanteResponse> resultado =
                comprobanteService.subir(id, loteId, entidad, entidadId, archivo, fechaCaptura);
        return resultado.respuesta(URI.create(resultado.valor().url()));
    }

    @GetMapping("/comprobantes/{id}/archivo")
    @Operation(summary = "Descargar la foto del comprobante")
    public ResponseEntity<Resource> archivoComprobante(@PathVariable UUID id) {
        ComprobanteService.Archivo archivo = comprobanteService.archivo(id);
        return ResponseEntity.ok()
                .contentType(archivo.tipo())
                .cacheControl(CacheControl.noCache().cachePrivate())
                .body(archivo.contenido());
    }

    @DeleteMapping("/comprobantes/{id}")
    public ResponseEntity<Void> eliminarComprobante(@PathVariable UUID id) {
        comprobanteService.eliminar(id);
        return ResponseEntity.noContent().build();
    }

    private static <T> ResponseEntity<T> responder(Creacion<T> resultado) {
        return resultado.respuesta(ServletUriComponentsBuilder.fromCurrentRequest().build().toUri());
    }
}

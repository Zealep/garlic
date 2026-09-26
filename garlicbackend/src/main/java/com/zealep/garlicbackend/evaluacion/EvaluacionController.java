package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResponse;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResumen;
import com.zealep.garlicbackend.evaluacion.dto.FormularioEvaluacion;
import com.zealep.garlicbackend.shared.web.Creacion;
import com.zealep.garlicbackend.shared.web.PageResponse;
import java.time.LocalDate;
import org.springframework.data.domain.Pageable;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
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

@RestController
@RequestMapping("/api/v1")
@Tag(name = "Evaluacion de lotes")
public class EvaluacionController {

    private final EvaluacionService service;

    public EvaluacionController(EvaluacionService service) {
        this.service = service;
    }

    @GetMapping("/evaluaciones/formulario")
    @Operation(summary = "Opciones activas de cada factor para dibujar el formulario del cultivo")
    public FormularioEvaluacion formulario(@RequestParam UUID cultivoId) {
        return service.formulario(cultivoId);
    }

    @GetMapping("/evaluaciones")
    @Operation(summary = "Bandeja de evaluaciones (filtra por estado, lote y fechas)")
    public PageResponse<EvaluacionResumen> listar(
            @RequestParam(required = false) EstadoEvaluacion estado,
            @RequestParam(required = false) UUID loteId,
            @RequestParam(required = false) LocalDate desde,
            @RequestParam(required = false) LocalDate hasta,
            Pageable pageable) {
        return service.listar(new EvaluacionFiltro(estado, loteId, desde, hasta), pageable);
    }

    @GetMapping("/lotes/{loteId}/evaluaciones")
    @Operation(summary = "Historial de evaluaciones del lote")
    public List<EvaluacionResumen> listarPorLote(@PathVariable UUID loteId) {
        return service.listarPorLote(loteId);
    }

    @PostMapping("/lotes/{loteId}/evaluaciones")
    @Operation(summary = "Crear evaluacion en BORRADOR (200 si el id del cliente ya existe)")
    public ResponseEntity<EvaluacionResponse> crear(@PathVariable UUID loteId, @Valid @RequestBody EvaluacionRequest request) {
        Creacion<EvaluacionResponse> resultado = service.crear(loteId, request);
        return resultado.respuesta(URI.create("/api/v1/evaluaciones/" + resultado.valor().id()));
    }

    @GetMapping("/evaluaciones/{id}")
    @Operation(summary = "Detalle con muestras, promedios y factores")
    public EvaluacionResponse obtener(@PathVariable UUID id) {
        return service.obtener(id);
    }

    @PutMapping("/evaluaciones/{id}")
    @Operation(summary = "Guardar (reemplaza el contenido; solo BORRADOR)")
    public EvaluacionResponse actualizar(@PathVariable UUID id, @Valid @RequestBody EvaluacionRequest request) {
        return service.actualizar(id, request);
    }

    @PostMapping("/evaluaciones/{id}/cerrar")
    @Operation(summary = "Cerrar (valida que este completa; idempotente si ya estaba cerrada)")
    public EvaluacionResponse cerrar(@PathVariable UUID id) {
        return service.cerrar(id);
    }

    @DeleteMapping("/evaluaciones/{id}")
    @Operation(summary = "Eliminar borrador (y sus evidencias)")
    public ResponseEntity<Void> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

package com.zealep.garlicbackend.evaluacion.evidencia;

import com.zealep.garlicbackend.shared.web.Creacion;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1")
@Tag(name = "Evidencias fotograficas")
public class EvidenciaController {

    private final EvidenciaService service;

    public EvidenciaController(EvidenciaService service) {
        this.service = service;
    }

    @PostMapping(path = "/evaluaciones/{evaluacionId}/evidencias", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Subir foto (JPG/PNG/WEBP/HEIC, max 10MB); muestraNumero vacio = evidencia general; "
            + "id opcional del cliente (200 si ya existe)")
    public ResponseEntity<EvidenciaResponse> subir(
            @PathVariable UUID evaluacionId,
            @RequestParam("archivo") MultipartFile archivo,
            @RequestParam(required = false) UUID id,
            @RequestParam(required = false) @Positive Short muestraNumero,
            @RequestParam(required = false) FactorEvidencia factor,
            @RequestParam(required = false) @Size(max = 250) String descripcion,
            @RequestParam(required = false) Instant fechaCaptura) {
        Creacion<EvidenciaResponse> resultado =
                service.subir(id, evaluacionId, archivo, muestraNumero, factor, descripcion, fechaCaptura);
        return resultado.respuesta(URI.create(resultado.valor().url()));
    }

    @GetMapping("/evaluaciones/{evaluacionId}/evidencias")
    public List<EvidenciaResponse> listar(@PathVariable UUID evaluacionId) {
        return service.listar(evaluacionId);
    }

    @GetMapping("/evidencias/{id}/archivo")
    @Operation(summary = "Descargar la foto")
    public ResponseEntity<Resource> archivo(@PathVariable UUID id) {
        EvidenciaService.ArchivoEvidencia archivo = service.archivo(id);
        return ResponseEntity.ok()
                .contentType(archivo.tipo())
                .cacheControl(CacheControl.noCache().cachePrivate())
                .body(archivo.contenido());
    }

    @DeleteMapping("/evidencias/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

package com.zealep.garlicbackend.acceso;

import com.zealep.garlicbackend.acceso.AccesoDtos.CambioClaveRequest;
import com.zealep.garlicbackend.acceso.AccesoDtos.LoginRequest;
import com.zealep.garlicbackend.acceso.AccesoDtos.PerfilResponse;
import com.zealep.garlicbackend.acceso.AccesoDtos.RefreshRequest;
import com.zealep.garlicbackend.acceso.AccesoDtos.SesionResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Acceso")
public class AccesoController {

    private final AccesoService service;

    public AccesoController(AccesoService service) {
        this.service = service;
    }

    @PostMapping("/login")
    @Operation(summary = "Iniciar sesion con DNI y contraseña")
    public SesionResponse login(@Valid @RequestBody LoginRequest request) {
        return service.login(request.dni(), request.clave(), request.dispositivo());
    }

    @PostMapping("/refresh")
    @Operation(summary = "Renovar el access token (rota el refresh token)")
    public SesionResponse refrescar(@Valid @RequestBody RefreshRequest request) {
        return service.refrescar(request.refreshToken());
    }

    @PostMapping("/logout")
    @Operation(summary = "Cerrar la sesion de este dispositivo")
    public ResponseEntity<Void> logout(@Valid @RequestBody RefreshRequest request) {
        service.logout(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/yo")
    @Operation(summary = "Usuario de la sesion")
    public PerfilResponse perfil() {
        return service.perfil();
    }

    @PutMapping("/clave")
    @Operation(summary = "Cambiar la propia contraseña")
    public PerfilResponse cambiarClave(@Valid @RequestBody CambioClaveRequest request) {
        return service.cambiarClave(request.actual(), request.nueva());
    }
}

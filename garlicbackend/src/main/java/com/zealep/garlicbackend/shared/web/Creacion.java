package com.zealep.garlicbackend.shared.web;

import java.net.URI;
import org.springframework.http.ResponseEntity;

/**
 * Resultado de una creacion idempotente: si el id enviado por el cliente ya existia se devuelve
 * el recurso existente (200) en vez de crear uno nuevo (201).
 */
public record Creacion<T>(T valor, boolean creado) {

    public static <T> Creacion<T> nuevo(T valor) {
        return new Creacion<>(valor, true);
    }

    public static <T> Creacion<T> existente(T valor) {
        return new Creacion<>(valor, false);
    }

    public ResponseEntity<T> respuesta(URI location) {
        return creado ? ResponseEntity.created(location).body(valor) : ResponseEntity.ok(valor);
    }
}

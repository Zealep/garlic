package com.zealep.garlicbackend.shared.storage;

import com.zealep.garlicbackend.shared.exception.BusinessException;
import java.util.Locale;
import java.util.Map;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

/**
 * Utilidades comunes para fotos subidas (evidencias de evaluacion y comprobantes de compra).
 */
public final class ArchivosSubidos {

    /** Tipos de imagen aceptados y la extension con la que se guardan. */
    private static final Map<String, String> TIPOS_PERMITIDOS = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp",
            "image/heic", "heic",
            "image/heif", "heif");

    private ArchivosSubidos() {
    }

    /** Extension del archivo si es una imagen permitida; 422 si esta vacio o es de otro tipo. */
    public static String extensionImagen(MultipartFile archivo) {
        if (archivo == null || archivo.isEmpty()) {
            throw new BusinessException("El archivo esta vacio");
        }
        String tipo = archivo.getContentType() == null ? "" : archivo.getContentType().toLowerCase(Locale.ROOT);
        String extension = TIPOS_PERMITIDOS.get(tipo);
        if (extension == null) {
            throw new BusinessException("Tipo de archivo no permitido (" + tipo + "). Use JPG, PNG, WEBP o HEIC");
        }
        return extension;
    }

    /**
     * Ejecuta la accion al terminar la transaccion actual con el estado indicado
     * (ej. borrar el archivo guardado si la transaccion se revierte).
     */
    public static void alTerminar(int estadoEsperado, Runnable accion) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCompletion(int status) {
                if (status == estadoEsperado) {
                    accion.run();
                }
            }
        });
    }
}

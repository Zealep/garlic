package com.zealep.garlicbackend.shared.storage;

import java.io.InputStream;
import org.springframework.core.io.Resource;

/**
 * Almacenamiento de archivos (evidencias). Hoy disco local; en produccion se reemplaza por S3 o similar
 * implementando esta interfaz.
 */
public interface StorageService {

    /**
     * Guarda el contenido y devuelve la clave con la que se recupera.
     *
     * @param carpeta   ruta logica (ej. empresa/evaluacion)
     * @param extension extension sin punto (jpg, png, ...)
     */
    String guardar(String carpeta, String extension, InputStream contenido);

    Resource cargar(String clave);

    void eliminar(String clave);
}

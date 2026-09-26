package com.zealep.garlicbackend.shared.storage;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

/**
 * Guarda archivos en disco bajo {@code garlic.storage.directorio}. La clave es la ruta relativa.
 */
@Service
@EnableConfigurationProperties(StorageProperties.class)
public class LocalStorageService implements StorageService {

    private static final Logger logger = LoggerFactory.getLogger(LocalStorageService.class);

    private final Path base;

    public LocalStorageService(StorageProperties properties) {
        this.base = properties.directorio().toAbsolutePath().normalize();
    }

    @Override
    public String guardar(String carpeta, String extension, InputStream contenido) {
        String clave = carpeta + "/" + UUID.randomUUID() + "." + extension;
        Path destino = resolver(clave);
        try {
            Files.createDirectories(destino.getParent());
            Files.copy(contenido, destino);
        } catch (IOException e) {
            throw new UncheckedIOException("No se pudo guardar el archivo " + clave, e);
        }
        logger.debug("Archivo guardado: {}", clave);
        return clave;
    }

    @Override
    public Resource cargar(String clave) {
        Path archivo = resolver(clave);
        if (!Files.isRegularFile(archivo)) {
            throw new UncheckedIOException(new IOException("Archivo no encontrado: " + clave));
        }
        return new PathResource(archivo);
    }

    @Override
    public void eliminar(String clave) {
        try {
            Files.deleteIfExists(resolver(clave));
        } catch (IOException e) {
            // No debe impedir borrar el registro; queda un archivo huerfano que se puede limpiar luego
            logger.warn("No se pudo eliminar el archivo {}", clave, e);
        }
    }

    /** Evita salir de la carpeta base (path traversal). */
    private Path resolver(String clave) {
        Path ruta = base.resolve(clave).normalize();
        if (!ruta.startsWith(base)) {
            throw new IllegalArgumentException("Clave de archivo invalida: " + clave);
        }
        return ruta;
    }
}

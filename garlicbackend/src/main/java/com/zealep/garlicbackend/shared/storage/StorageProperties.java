package com.zealep.garlicbackend.shared.storage;

import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param directorio carpeta base donde se guardan los archivos (almacenamiento local)
 */
@ConfigurationProperties("garlic.storage")
public record StorageProperties(Path directorio) {
}

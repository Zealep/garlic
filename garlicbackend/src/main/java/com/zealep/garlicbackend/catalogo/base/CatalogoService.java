package com.zealep.garlicbackend.catalogo.base;

import com.zealep.garlicbackend.shared.web.PageResponse;
import java.util.UUID;
import org.springframework.data.domain.Pageable;

/**
 * Operaciones CRUD de un catalogo, siempre dentro de la empresa actual.
 */
public interface CatalogoService<REQ, RES> {

    PageResponse<RES> listar(CatalogoFiltro filtro, Pageable pageable);

    RES obtener(UUID id);

    RES crear(REQ request);

    RES actualizar(UUID id, REQ request);

    /** Baja logica (activo = false). */
    void desactivar(UUID id);

    RES activar(UUID id);
}

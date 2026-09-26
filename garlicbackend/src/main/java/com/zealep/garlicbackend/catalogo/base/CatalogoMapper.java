package com.zealep.garlicbackend.catalogo.base;

import org.mapstruct.MappingTarget;

/**
 * Contrato de mapeo DTO &lt;-&gt; entidad. Cada catalogo lo extiende con un {@code @Mapper} de MapStruct.
 */
public interface CatalogoMapper<E extends CatalogoEntity, REQ, RES> {

    RES toResponse(E entity);

    E toEntity(REQ request);

    void actualizar(REQ request, @MappingTarget E entity);
}

package com.zealep.garlicbackend.catalogo.tipoempaque;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface TipoEmpaqueMapper extends CatalogoMapper<TipoEmpaque, TipoEmpaqueRequest, TipoEmpaqueResponse> {
}

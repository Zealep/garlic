package com.zealep.garlicbackend.catalogo.tipoempaste;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface TipoEmpasteMapper extends CatalogoMapper<TipoEmpaste, TipoEmpasteRequest, TipoEmpasteResponse> {
}

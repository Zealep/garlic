package com.zealep.garlicbackend.catalogo.tipogasto;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface TipoGastoMapper extends CatalogoMapper<TipoGasto, TipoGastoRequest, TipoGastoResponse> {
}

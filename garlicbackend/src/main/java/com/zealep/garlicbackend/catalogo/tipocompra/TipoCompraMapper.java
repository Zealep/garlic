package com.zealep.garlicbackend.catalogo.tipocompra;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface TipoCompraMapper extends CatalogoMapper<TipoCompra, TipoCompraRequest, TipoCompraResponse> {
}

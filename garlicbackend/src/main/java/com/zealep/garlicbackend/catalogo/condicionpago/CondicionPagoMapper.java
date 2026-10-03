package com.zealep.garlicbackend.catalogo.condicionpago;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface CondicionPagoMapper extends CatalogoMapper<CondicionPago, CondicionPagoRequest, CondicionPagoResponse> {
}

package com.zealep.garlicbackend.catalogo.tipohumedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface TipoHumedadMapper extends CatalogoMapper<TipoHumedad, TipoHumedadRequest, TipoHumedadResponse> {
}

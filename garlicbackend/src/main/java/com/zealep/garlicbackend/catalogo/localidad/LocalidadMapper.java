package com.zealep.garlicbackend.catalogo.localidad;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface LocalidadMapper extends CatalogoMapper<Localidad, LocalidadRequest, LocalidadResponse> {
}

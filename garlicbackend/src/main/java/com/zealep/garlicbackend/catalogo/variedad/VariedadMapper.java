package com.zealep.garlicbackend.catalogo.variedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface VariedadMapper extends CatalogoMapper<Variedad, VariedadRequest, VariedadResponse> {
}

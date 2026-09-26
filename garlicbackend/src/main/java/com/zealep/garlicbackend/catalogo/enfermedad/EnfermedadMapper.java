package com.zealep.garlicbackend.catalogo.enfermedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface EnfermedadMapper extends CatalogoMapper<Enfermedad, EnfermedadRequest, EnfermedadResponse> {
}

package com.zealep.garlicbackend.catalogo.campania;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface CampaniaMapper extends CatalogoMapper<Campania, CampaniaRequest, CampaniaResponse> {
}

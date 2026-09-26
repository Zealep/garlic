package com.zealep.garlicbackend.catalogo.calibre;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface CalibreMapper extends CatalogoMapper<Calibre, CalibreRequest, CalibreResponse> {
}

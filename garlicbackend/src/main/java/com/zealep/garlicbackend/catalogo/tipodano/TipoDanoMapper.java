package com.zealep.garlicbackend.catalogo.tipodano;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface TipoDanoMapper extends CatalogoMapper<TipoDano, TipoDanoRequest, TipoDanoResponse> {
}

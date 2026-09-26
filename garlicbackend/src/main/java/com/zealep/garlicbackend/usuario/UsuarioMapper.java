package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.CatalogoMapper;
import org.mapstruct.Mapper;

@Mapper
public interface UsuarioMapper extends CatalogoMapper<Usuario, UsuarioRequest, UsuarioResponse> {
}

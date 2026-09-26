package com.zealep.garlicbackend.tercero.persona;

import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper
public interface PersonaMapper {

    PersonaResponse toResponse(Persona persona);

    Persona toEntity(PersonaRequest request);

    void actualizar(PersonaRequest request, @MappingTarget Persona persona);
}

package com.zealep.garlicbackend.tercero.persona;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface PersonaRepository extends JpaRepository<Persona, UUID>, JpaSpecificationExecutor<Persona> {

    Optional<Persona> findByIdAndEmpresaId(UUID id, UUID empresaId);

    Optional<Persona> findByEmpresaIdAndTipoDocumentoAndNumeroDocumento(
            UUID empresaId, TipoDocumento tipoDocumento, String numeroDocumento);
}

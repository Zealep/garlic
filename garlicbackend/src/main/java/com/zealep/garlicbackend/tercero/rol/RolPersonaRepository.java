package com.zealep.garlicbackend.tercero.rol;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.repository.NoRepositoryBean;

/**
 * Siempre trae la persona en la misma consulta (evita N+1 al listar).
 */
@NoRepositoryBean
public interface RolPersonaRepository<E extends RolPersonaEntity>
        extends JpaRepository<E, UUID>, JpaSpecificationExecutor<E> {

    @EntityGraph(attributePaths = "persona")
    Optional<E> findByIdAndEmpresaId(UUID id, UUID empresaId);

    @Override
    @EntityGraph(attributePaths = "persona")
    Page<E> findAll(Specification<E> spec, Pageable pageable);

    boolean existsByPersonaId(UUID personaId);
}

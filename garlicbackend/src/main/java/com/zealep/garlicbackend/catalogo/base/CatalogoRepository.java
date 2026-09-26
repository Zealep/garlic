package com.zealep.garlicbackend.catalogo.base;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface CatalogoRepository<E extends CatalogoEntity>
        extends JpaRepository<E, UUID>, JpaSpecificationExecutor<E> {

    Optional<E> findByIdAndEmpresaId(UUID id, UUID empresaId);
}

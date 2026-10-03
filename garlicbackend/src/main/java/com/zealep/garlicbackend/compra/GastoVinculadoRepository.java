package com.zealep.garlicbackend.compra;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GastoVinculadoRepository extends JpaRepository<GastoVinculado, UUID> {

    Optional<GastoVinculado> findByIdAndEmpresaId(UUID id, UUID empresaId);

    boolean existsByCargaId(UUID cargaId);

    List<GastoVinculado> findByLoteIdAndEmpresaIdOrderByCreatedAt(UUID loteId, UUID empresaId);
}

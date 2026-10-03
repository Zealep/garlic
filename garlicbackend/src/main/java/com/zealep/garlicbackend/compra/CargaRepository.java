package com.zealep.garlicbackend.compra;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CargaRepository extends JpaRepository<Carga, UUID> {

    Optional<Carga> findByIdAndEmpresaId(UUID id, UUID empresaId);

    List<Carga> findByLoteIdAndEmpresaIdOrderByCreatedAt(UUID loteId, UUID empresaId);
}

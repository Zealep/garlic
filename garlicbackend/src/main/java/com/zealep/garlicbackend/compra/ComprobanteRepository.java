package com.zealep.garlicbackend.compra;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ComprobanteRepository extends JpaRepository<Comprobante, UUID> {

    Optional<Comprobante> findByIdAndEmpresaId(UUID id, UUID empresaId);

    List<Comprobante> findByEntidadIdAndEmpresaId(UUID entidadId, UUID empresaId);

    List<Comprobante> findByLoteIdAndEmpresaIdOrderByCreatedAt(UUID loteId, UUID empresaId);
}

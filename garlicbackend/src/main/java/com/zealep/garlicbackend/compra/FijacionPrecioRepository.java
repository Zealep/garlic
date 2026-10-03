package com.zealep.garlicbackend.compra;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FijacionPrecioRepository extends JpaRepository<FijacionPrecio, UUID> {

    Optional<FijacionPrecio> findByLoteIdAndEmpresaId(UUID loteId, UUID empresaId);
}

package com.zealep.garlicbackend.evaluacion.evidencia;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EvidenciaRepository extends JpaRepository<Evidencia, UUID> {

    @EntityGraph(attributePaths = {"evaluacion", "muestra"})
    Optional<Evidencia> findByIdAndEmpresaId(UUID id, UUID empresaId);

    @EntityGraph(attributePaths = "muestra")
    List<Evidencia> findByEvaluacionIdAndEmpresaIdOrderByCreatedAt(UUID evaluacionId, UUID empresaId);

    List<Evidencia> findByMuestraIdIn(Collection<UUID> muestraIds);

    List<Evidencia> findByEvaluacionId(UUID evaluacionId);
}

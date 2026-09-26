package com.zealep.garlicbackend.evaluacion;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface EvaluacionLoteRepository extends JpaRepository<EvaluacionLote, UUID>, JpaSpecificationExecutor<EvaluacionLote> {

    /** Solo relaciones a-uno en el grafo (paginacion en base); las muestras se cargan por lotes (@BatchSize). */
    @Override
    @EntityGraph(attributePaths = {"lote", "evaluador"})
    Page<EvaluacionLote> findAll(Specification<EvaluacionLote> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"lote", "evaluador", "muestras"})
    Optional<EvaluacionLote> findByIdAndEmpresaId(UUID id, UUID empresaId);

    @EntityGraph(attributePaths = {"evaluador", "muestras"})
    List<EvaluacionLote> findByLoteIdAndEmpresaIdOrderByFechaEvaluacionDescCreatedAtDesc(UUID loteId, UUID empresaId);
}

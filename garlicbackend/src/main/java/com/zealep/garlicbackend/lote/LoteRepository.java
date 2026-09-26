package com.zealep.garlicbackend.lote;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LoteRepository extends JpaRepository<Lote, UUID>, JpaSpecificationExecutor<Lote> {

    @EntityGraph(attributePaths = {"campania", "variedad", "agricultor.persona", "proveedor.persona",
            "titularLiquidacion", "localidad", "tipoCompra"})
    Optional<Lote> findByIdAndEmpresaId(UUID id, UUID empresaId);

    @Override
    @EntityGraph(attributePaths = {"campania", "variedad", "agricultor.persona", "proveedor.persona",
            "titularLiquidacion", "localidad", "tipoCompra"})
    Page<Lote> findAll(Specification<Lote> spec, Pageable pageable);

    /** Lote activo que ya ocupa la zona en la campania (excluyendo el propio al actualizar). */
    @Query("""
            select l from Lote l
            where l.empresaId = :empresaId and l.campania.id = :campaniaId
              and l.zonaNormalizada = :zona and l.estado = com.zealep.garlicbackend.lote.EstadoLote.ACTIVO
              and (:excluirId is null or l.id <> :excluirId)
            """)
    Optional<Lote> buscarActivoEnZona(@Param("empresaId") UUID empresaId, @Param("campaniaId") UUID campaniaId,
            @Param("zona") String zonaNormalizada, @Param("excluirId") UUID excluirId);

    @Query("""
            select count(l) > 0 from Lote l
            where l.empresaId = :empresaId and l.campania.id = :campaniaId and l.codigo = :codigo
              and (:excluirId is null or l.id <> :excluirId)
            """)
    boolean existeCodigo(@Param("empresaId") UUID empresaId, @Param("campaniaId") UUID campaniaId,
            @Param("codigo") String codigo, @Param("excluirId") UUID excluirId);
}

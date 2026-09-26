package com.zealep.garlicbackend.shared.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Transient;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/**
 * Base de toda entidad que pertenece a una empresa (tenant).
 * El id puede venir del cliente (app offline); {@link Persistable} indica a Spring Data que una
 * entidad nueva con id asignado se inserta (persist) y no se intenta actualizar (merge).
 */
@MappedSuperclass
public abstract class TenantEntity extends AuditableEntity implements Persistable<UUID> {

    @Id
    @AssignableUuid
    private UUID id;

    @Column(name = "empresa_id", nullable = false, updatable = false)
    private UUID empresaId;

    @Transient
    private boolean nuevo = true;

    @Override
    public UUID getId() {
        return id;
    }

    /** Id generado por el cliente; solo para entidades nuevas. */
    public void asignarId(UUID id) {
        if (!nuevo) {
            throw new IllegalStateException("No se puede cambiar el id de una entidad existente");
        }
        this.id = id;
    }

    @Override
    public boolean isNew() {
        return nuevo;
    }

    @PostLoad
    @PostPersist
    void marcarPersistido() {
        this.nuevo = false;
    }

    public UUID getEmpresaId() {
        return empresaId;
    }

    public void setEmpresaId(UUID empresaId) {
        this.empresaId = empresaId;
    }
}

package com.zealep.garlicbackend.catalogo.base;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;

/**
 * Base de todo catalogo por empresa: agrega la baja logica (activo).
 */
@MappedSuperclass
public abstract class CatalogoEntity extends TenantEntity {

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

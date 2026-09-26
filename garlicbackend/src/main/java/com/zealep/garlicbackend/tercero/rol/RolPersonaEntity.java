package com.zealep.garlicbackend.tercero.rol;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import com.zealep.garlicbackend.tercero.persona.Persona;
import jakarta.persistence.Column;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.OneToOne;

/**
 * Rol que cumple una persona para la empresa (agricultor, proveedor, ...). Relacion 1 a 1 con persona.
 */
@MappedSuperclass
public abstract class RolPersonaEntity extends TenantEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "persona_id", nullable = false, updatable = false)
    private Persona persona;

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    public Persona getPersona() {
        return persona;
    }

    public void setPersona(Persona persona) {
        this.persona = persona;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

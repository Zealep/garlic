package com.zealep.garlicbackend.catalogo.cultivo;

import com.zealep.garlicbackend.shared.domain.AuditableEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/**
 * Catalogo global (no depende de la empresa). Se administra por migraciones.
 */
@Entity
@Table(name = "cultivo")
public class Cultivo extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "codigo", nullable = false, length = 20)
    private String codigo;

    @Column(name = "nombre", nullable = false, length = 80)
    private String nombre;

    public UUID getId() {
        return id;
    }

    public String getCodigo() {
        return codigo;
    }

    public String getNombre() {
        return nombre;
    }
}

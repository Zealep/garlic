package com.zealep.garlicbackend.tercero.proveedor;

import com.zealep.garlicbackend.tercero.rol.RolPersonaEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Intermediario / acopiador que trae el lote.
 */
@Entity
@Table(name = "proveedor")
public class Proveedor extends RolPersonaEntity {
}

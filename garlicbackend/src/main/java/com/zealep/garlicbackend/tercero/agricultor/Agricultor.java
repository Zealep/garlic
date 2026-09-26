package com.zealep.garlicbackend.tercero.agricultor;

import com.zealep.garlicbackend.tercero.rol.RolPersonaEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Agricultor que cultiva y vende el lote.
 */
@Entity
@Table(name = "agricultor")
public class Agricultor extends RolPersonaEntity {
}

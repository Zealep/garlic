package com.zealep.garlicbackend.catalogo.variedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "variedad")
public class Variedad extends CatalogoCultivoEntity {
}

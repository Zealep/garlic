package com.zealep.garlicbackend.catalogo.tipohumedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "tipo_humedad")
public class TipoHumedad extends CatalogoCultivoEntity {
}

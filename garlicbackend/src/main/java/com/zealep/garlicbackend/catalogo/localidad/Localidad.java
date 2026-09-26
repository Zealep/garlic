package com.zealep.garlicbackend.catalogo.localidad;

import com.zealep.garlicbackend.catalogo.base.CatalogoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.util.Locale;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "localidad")
public class Localidad extends CatalogoEntity {

    @Column(name = "nombre", nullable = false, length = 120)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false, length = 10)
    private TipoLocalidad tipo;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "ubigeo", length = 6)
    private String ubigeo;

    public String getNombre() {
        return nombre;
    }

    /** El nombre se guarda en mayusculas para evitar duplicados por escritura. */
    public void setNombre(String nombre) {
        this.nombre = nombre == null ? null : nombre.trim().toUpperCase(Locale.ROOT);
    }

    public TipoLocalidad getTipo() {
        return tipo;
    }

    public void setTipo(TipoLocalidad tipo) {
        this.tipo = tipo;
    }

    public String getUbigeo() {
        return ubigeo;
    }

    public void setUbigeo(String ubigeo) {
        this.ubigeo = ubigeo;
    }
}

package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.CatalogoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.util.Locale;

/**
 * Usuario de la empresa. El evaluador de campo es un usuario.
 * (Cuando se agregue autenticacion se sumaran credenciales / proveedor de identidad.)
 */
@Entity
@Table(name = "usuario")
public class Usuario extends CatalogoEntity {

    @Column(name = "nombres", nullable = false, length = 150)
    private String nombres;

    @Column(name = "dni", length = 15)
    private String dni;

    @Column(name = "email", nullable = false, length = 150)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "rol", nullable = false, length = 30)
    private RolUsuario rol = RolUsuario.EVALUADOR;

    public String getNombres() {
        return nombres;
    }

    public void setNombres(String nombres) {
        this.nombres = nombres == null ? null : nombres.trim().replaceAll("\\s+", " ");
    }

    public String getDni() {
        return dni;
    }

    public void setDni(String dni) {
        this.dni = dni == null || dni.isBlank() ? null : dni.trim();
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }

    public RolUsuario getRol() {
        return rol;
    }

    public void setRol(RolUsuario rol) {
        this.rol = rol;
    }
}

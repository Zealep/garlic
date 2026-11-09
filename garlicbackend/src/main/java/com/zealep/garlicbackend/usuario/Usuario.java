package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.CatalogoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Locale;

/**
 * Usuario de la empresa. El evaluador de campo es un usuario. Entra con su DNI y su contraseña:
 * la clave y las sesiones se manejan en el modulo {@code acceso} (aqui solo se leen para mostrarlas).
 */
@Entity
@Table(name = "usuario")
public class Usuario extends CatalogoEntity {

    @Column(name = "nombres", nullable = false, length = 150)
    private String nombres;

    @Column(name = "dni", length = 15)
    private String dni;

    @Column(name = "email", length = 150)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "rol", nullable = false, length = 30)
    private RolUsuario rol = RolUsuario.EVALUADOR;

    @Column(name = "clave_hash", insertable = false, updatable = false)
    private String claveHash;

    @Column(name = "ultimo_acceso", insertable = false, updatable = false)
    private Instant ultimoAcceso;

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
        this.email = email == null || email.isBlank() ? null : email.trim().toLowerCase(Locale.ROOT);
    }

    /** Ya tiene contraseña (puede entrar). */
    public boolean isTieneClave() {
        return claveHash != null;
    }

    public Instant getUltimoAcceso() {
        return ultimoAcceso;
    }

    public RolUsuario getRol() {
        return rol;
    }

    public void setRol(RolUsuario rol) {
        this.rol = rol;
    }
}

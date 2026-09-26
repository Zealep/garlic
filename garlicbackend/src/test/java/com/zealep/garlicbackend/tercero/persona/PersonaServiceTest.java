package com.zealep.garlicbackend.tercero.persona;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mapstruct.factory.Mappers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PersonaServiceTest {

    private static final UUID EMPRESA = UUID.randomUUID();

    @Mock
    private PersonaRepository repository;

    @Mock
    private TenantProvider tenantProvider;

    private PersonaService service;

    @BeforeEach
    void setUp() {
        service = new PersonaService(repository, Mappers.getMapper(PersonaMapper.class), tenantProvider);
        when(tenantProvider.currentEmpresaId()).thenReturn(EMPRESA);
    }

    @Test
    void crear_conDocumentoExistente_lanzaConflict() {
        when(repository.findByEmpresaIdAndTipoDocumentoAndNumeroDocumento(EMPRESA, TipoDocumento.DNI, "72790829"))
                .thenReturn(Optional.of(persona("72790829", "KEVIN")));

        assertThatThrownBy(() -> service.crear(new PersonaRequest(TipoDocumento.DNI, " 7279 0829", "Kevin", null)))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("DNI 72790829");
        verify(repository, never()).saveAndFlush(any());
    }

    @Test
    void obtenerOCrear_existente_reutilizaYActualizaNombres_sinBorrarTelefono() {
        Persona existente = persona("72790829", "KEVIN");
        existente.setTelefono("999888777");
        when(repository.findByEmpresaIdAndTipoDocumentoAndNumeroDocumento(EMPRESA, TipoDocumento.DNI, "72790829"))
                .thenReturn(Optional.of(existente));

        Persona res = service.obtenerOCrear(new PersonaRequest(TipoDocumento.DNI, "72790829", "Kevin  Quispe", null));

        assertThat(res).isSameAs(existente);
        assertThat(res.getNombres()).isEqualTo("Kevin Quispe");
        assertThat(res.getTelefono()).isEqualTo("999888777");
        verify(repository, never()).save(any());
    }

    @Test
    void obtenerOCrear_nuevo_creaEnLaEmpresaActual() {
        when(repository.findByEmpresaIdAndTipoDocumentoAndNumeroDocumento(any(), any(), any())).thenReturn(Optional.empty());
        when(repository.save(any(Persona.class))).thenAnswer(inv -> inv.getArgument(0));

        Persona res = service.obtenerOCrear(new PersonaRequest(TipoDocumento.DNI, "72790829", "Kevin", "999"));

        assertThat(res.getEmpresaId()).isEqualTo(EMPRESA);
        assertThat(res.getNumeroDocumento()).isEqualTo("72790829");
    }

    private static Persona persona(String dni, String nombres) {
        Persona p = new Persona();
        p.setEmpresaId(EMPRESA);
        p.setTipoDocumento(TipoDocumento.DNI);
        p.setNumeroDocumento(dni);
        p.setNombres(nombres);
        return p;
    }
}

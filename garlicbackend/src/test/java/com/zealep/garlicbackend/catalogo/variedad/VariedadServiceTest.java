package com.zealep.garlicbackend.catalogo.variedad;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mapstruct.factory.Mappers;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Cubre el comportamiento generico de AbstractCatalogoService a traves de Variedad.
 */
@ExtendWith(MockitoExtension.class)
class VariedadServiceTest {

    private static final UUID EMPRESA = UUID.randomUUID();
    private static final UUID CULTIVO = UUID.randomUUID();

    @Mock
    private VariedadRepository repository;

    @Mock
    private TenantProvider tenantProvider;

    private VariedadService service;

    @BeforeEach
    void setUp() {
        service = new VariedadService(repository, Mappers.getMapper(VariedadMapper.class), tenantProvider);
        when(tenantProvider.currentEmpresaId()).thenReturn(EMPRESA);
    }

    @Test
    void crear_asignaEmpresaDelTenant_normalizaCodigo_yQuedaActivo() {
        when(repository.saveAndFlush(any(Variedad.class))).thenAnswer(inv -> inv.getArgument(0));

        VariedadResponse res = service.crear(new VariedadRequest(CULTIVO, "  napuri ", " Napuri ", null));

        ArgumentCaptor<Variedad> captor = ArgumentCaptor.forClass(Variedad.class);
        verify(repository).saveAndFlush(captor.capture());
        Variedad guardada = captor.getValue();
        assertThat(guardada.getEmpresaId()).isEqualTo(EMPRESA);
        assertThat(guardada.getCodigo()).isEqualTo("NAPURI");
        assertThat(guardada.getNombre()).isEqualTo("Napuri");
        assertThat(guardada.getOrden()).isZero();
        assertThat(res.activo()).isTrue();
    }

    @Test
    void obtener_deOtraEmpresaONoExistente_lanzaNotFound() {
        UUID id = UUID.randomUUID();
        when(repository.findByIdAndEmpresaId(id, EMPRESA)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.obtener(id))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining(id.toString());
    }

    @Test
    void actualizar_noExistente_noGuarda() {
        UUID id = UUID.randomUUID();
        when(repository.findByIdAndEmpresaId(id, EMPRESA)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.actualizar(id, new VariedadRequest(CULTIVO, "X", "X", (short) 1)))
                .isInstanceOf(NotFoundException.class);
        verify(repository, never()).saveAndFlush(any());
    }

    @Test
    void actualizar_modificaCampos_sinCambiarEmpresa() {
        Variedad existente = variedad("CHINO", "Chino");
        UUID id = UUID.randomUUID();
        when(repository.findByIdAndEmpresaId(id, EMPRESA)).thenReturn(Optional.of(existente));
        when(repository.saveAndFlush(existente)).thenReturn(existente);

        VariedadResponse res = service.actualizar(id, new VariedadRequest(CULTIVO, "chino_blanco", "Chino Blanco", (short) 2));

        assertThat(res.codigo()).isEqualTo("CHINO_BLANCO");
        assertThat(res.nombre()).isEqualTo("Chino Blanco");
        assertThat(res.orden()).isEqualTo((short) 2);
        assertThat(existente.getEmpresaId()).isEqualTo(EMPRESA);
    }

    @Test
    void desactivar_y_activar_cambianSoloElFlag() {
        Variedad existente = variedad("NAPURI", "Napuri");
        UUID id = UUID.randomUUID();
        when(repository.findByIdAndEmpresaId(id, EMPRESA)).thenReturn(Optional.of(existente));
        when(repository.saveAndFlush(existente)).thenReturn(existente);

        service.desactivar(id);
        assertThat(existente.isActivo()).isFalse();

        VariedadResponse res = service.activar(id);
        assertThat(res.activo()).isTrue();
    }

    private static Variedad variedad(String codigo, String nombre) {
        Variedad v = new Variedad();
        v.setEmpresaId(EMPRESA);
        v.setCultivoId(CULTIVO);
        v.setCodigo(codigo);
        v.setNombre(nombre);
        return v;
    }
}

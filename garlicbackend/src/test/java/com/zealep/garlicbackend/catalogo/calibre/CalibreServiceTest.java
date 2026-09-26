package com.zealep.garlicbackend.catalogo.calibre;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mapstruct.factory.Mappers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CalibreServiceTest {

    private static final UUID CULTIVO = UUID.randomUUID();

    @Mock
    private CalibreRepository repository;

    @Mock
    private TenantProvider tenantProvider;

    private CalibreService service;

    @BeforeEach
    void setUp() {
        service = new CalibreService(repository, Mappers.getMapper(CalibreMapper.class), tenantProvider);
    }

    @Test
    void crear_conMaximoMenorOIgualAlMinimo_lanzaBusinessException() {
        CalibreRequest req = new CalibreRequest(CULTIVO, "50/45", "50/45", null, new BigDecimal("50"), new BigDecimal("45"));

        assertThatThrownBy(() -> service.crear(req))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("diametro maximo");
        verify(repository, never()).saveAndFlush(any());
    }

    @Test
    void crear_sinMaximo_esValido_rangoAbierto() {
        when(tenantProvider.currentEmpresaId()).thenReturn(UUID.randomUUID());
        when(repository.saveAndFlush(any(Calibre.class))).thenAnswer(inv -> inv.getArgument(0));

        CalibreResponse res = service.crear(new CalibreRequest(CULTIVO, ">70", ">70", (short) 6, new BigDecimal("70"), null));

        assertThat(res.diametroMaxMm()).isNull();
        assertThat(res.diametroMinMm()).isEqualByComparingTo("70");
    }
}

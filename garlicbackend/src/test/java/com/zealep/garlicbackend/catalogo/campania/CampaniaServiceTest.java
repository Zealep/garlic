package com.zealep.garlicbackend.catalogo.campania;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mapstruct.factory.Mappers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CampaniaServiceTest {

    @Mock
    private CampaniaRepository repository;

    @Mock
    private TenantProvider tenantProvider;

    private CampaniaService service;

    @BeforeEach
    void setUp() {
        service = new CampaniaService(repository, Mappers.getMapper(CampaniaMapper.class), tenantProvider);
    }

    @Test
    void crear_conFechaFinAnteriorAInicio_lanzaBusinessException() {
        CampaniaRequest req = new CampaniaRequest(
                UUID.randomUUID(), "2026", LocalDate.of(2026, 12, 31), LocalDate.of(2026, 1, 1));

        assertThatThrownBy(() -> service.crear(req))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("fecha fin");
        verify(repository, never()).saveAndFlush(any());
    }
}

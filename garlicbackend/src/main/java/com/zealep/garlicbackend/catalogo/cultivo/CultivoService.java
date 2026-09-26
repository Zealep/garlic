package com.zealep.garlicbackend.catalogo.cultivo;

import com.zealep.garlicbackend.shared.exception.NotFoundException;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CultivoService {

    private final CultivoRepository repository;

    public CultivoService(CultivoRepository repository) {
        this.repository = repository;
    }

    public List<CultivoResponse> listar() {
        return repository.findAll(Sort.by("nombre")).stream().map(CultivoResponse::from).toList();
    }

    public CultivoResponse obtener(UUID id) {
        return repository.findById(id)
                .map(CultivoResponse::from)
                .orElseThrow(() -> new NotFoundException("Cultivo", id));
    }
}

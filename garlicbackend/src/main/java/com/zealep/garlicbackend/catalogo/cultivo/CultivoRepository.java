package com.zealep.garlicbackend.catalogo.cultivo;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CultivoRepository extends JpaRepository<Cultivo, UUID> {
}

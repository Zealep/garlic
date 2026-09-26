package com.zealep.garlicbackend.catalogo.base;

import java.util.UUID;

/**
 * Filtros opcionales del listado de catalogos.
 *
 * @param q         texto a buscar (contiene, sin distinguir mayusculas) en los campos de busqueda
 * @param activo    solo activos / inactivos; null = todos
 * @param cultivoId solo del cultivo indicado (si el catalogo tiene cultivo)
 */
public record CatalogoFiltro(String q, Boolean activo, UUID cultivoId) {
}

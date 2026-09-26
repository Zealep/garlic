-- =====================================================================
-- Datos semilla (catalogos tomados del Excel "N°1 EVALUACION CAMPO AJO 2025")
-- Solo perfil dev (spring.flyway.locations). Migracion repetible e idempotente:
-- se re-ejecuta si cambia su contenido. La empresa es un placeholder.
-- =====================================================================



INSERT INTO empresa (ruc, razon_social, nombre_comercial)
VALUES ('00000000000', 'AGROEXPORTADORA DEMO S.A.C.', 'Agroexportadora Demo')
ON CONFLICT (ruc) DO NOTHING;

-- Catalogos de la empresa demo para el cultivo AJO
DO $$
DECLARE
    v_emp uuid := (SELECT id FROM empresa WHERE ruc = '00000000000');
    v_cul uuid := (SELECT id FROM cultivo WHERE codigo = 'AJO');
BEGIN
    INSERT INTO campania (empresa_id, cultivo_id, codigo, fecha_inicio, fecha_fin)
    VALUES (v_emp, v_cul, '2025', DATE '2025-01-01', DATE '2025-12-31')
    ON CONFLICT DO NOTHING;

    INSERT INTO localidad (empresa_id, nombre, tipo)
    VALUES (v_emp, 'EL PEDREGAL', 'CCPP')
    ON CONFLICT DO NOTHING;

    INSERT INTO variedad (empresa_id, cultivo_id, codigo, nombre, orden) VALUES
        (v_emp, v_cul, 'CHINO_BLANCO', 'CHINO BLANCO', 1),
        (v_emp, v_cul, 'CHINO_MORADO', 'CHINO MORADO', 2),
        (v_emp, v_cul, 'NAPURI',       'NAPURI',       3),
        (v_emp, v_cul, 'BARRANQUINO',  'BARRANQUINO',  4)
    ON CONFLICT DO NOTHING;

    INSERT INTO tipo_compra (empresa_id, cultivo_id, codigo, nombre, orden) VALUES
        (v_emp, v_cul, 'PRIMERA_5_ARRIBA', 'PRIMERA 5 ARRIBA',    1),
        (v_emp, v_cul, 'PRIMERA_45_55',    'PRIMERA 45/50 50/55', 2),
        (v_emp, v_cul, 'SEGUNDA_ESCOGIDO', 'SEGUNDA ESCOGIDO',    3),
        (v_emp, v_cul, 'ABIERTOS',         'ABIERTOS',            4)
    ON CONFLICT DO NOTHING;

    INSERT INTO clase_calidad (empresa_id, cultivo_id, codigo, nombre, orden) VALUES
        (v_emp, v_cul, 'PRIMERA',  'PRIMERA',  1),
        (v_emp, v_cul, 'ABIERTOS', 'ABIERTOS', 2)
    ON CONFLICT DO NOTHING;

    INSERT INTO calibre (empresa_id, cultivo_id, codigo, nombre, diametro_min_mm, diametro_max_mm, orden) VALUES
        (v_emp, v_cul, '45/50', '45/50', 45, 50,   1),
        (v_emp, v_cul, '50/55', '50/55', 50, 55,   2),
        (v_emp, v_cul, '55/60', '55/60', 55, 60,   3),
        (v_emp, v_cul, '60/65', '60/65', 60, 65,   4),
        (v_emp, v_cul, '65/70', '65/70', 65, 70,   5),
        (v_emp, v_cul, '>70',   '>70',   70, NULL, 6)
    ON CONFLICT DO NOTHING;

    INSERT INTO tipo_humedad (empresa_id, cultivo_id, codigo, nombre, orden) VALUES
        (v_emp, v_cul, 'GOTAS_DENTRO',        'GOTAS DENTRO',            1),
        (v_emp, v_cul, 'DIENTE_MORADO',       'COLOR DIENTE MORADO',     2),
        (v_emp, v_cul, 'AGUA_APLASTADO_RAIZ', 'AGUA APLASTADO DE RAIZ',  3),
        (v_emp, v_cul, 'DIENTE_ROSA_BEIGE',   'COLOR DIENTE ROSA BEIGE', 4)
    ON CONFLICT DO NOTHING;

    INSERT INTO tipo_empaste (empresa_id, cultivo_id, codigo, nombre, orden) VALUES
        (v_emp, v_cul, 'BAJO',      'BAJO',      1),
        (v_emp, v_cul, 'MEDIO',     'MEDIO',     2),
        (v_emp, v_cul, 'BUENO',     'BUENO',     3),
        (v_emp, v_cul, 'MANDARINA', 'MANDARINA', 4)
    ON CONFLICT DO NOTHING;

    INSERT INTO tipo_dano (empresa_id, cultivo_id, codigo, nombre, es_excluyente, orden) VALUES
        (v_emp, v_cul, 'PARALISIS_CEROSA', 'PARALISIS CEROSA (Caramelo)',     false, 1),
        (v_emp, v_cul, 'PARALISIS_ACUOSA', 'PARALISIS ACUOSA (Dano Diente)',  false, 2),
        (v_emp, v_cul, 'NO_CONTIENE',      'NO CONTIENE',                     true,  3)
    ON CONFLICT DO NOTHING;

    INSERT INTO enfermedad (empresa_id, cultivo_id, codigo, nombre, nombre_cientifico, se_transmite_por_semilla, evaluar_en_campo, orden) VALUES
        (v_emp, v_cul, 'RAIZ_ROSADA',       'RAIZ ROSADA',                     NULL,                                 false, true,  1),
        (v_emp, v_cul, 'FUSARIUM',          'FUSARIUM',                        'Fusarium spp.',                      true,  true,  2),
        (v_emp, v_cul, 'PUDRICION_BLANCA',  'PUDRICION BLANCA',                'Sclerotium cepivorum',               true,  false, 3),
        (v_emp, v_cul, 'MILDIU_VELLOSO',    'MILDIU VELLOSO',                  NULL,                                 false, false, 4),
        (v_emp, v_cul, 'BOTRYTIS',          'PUDRICION DEL CUELLO',            'Botrytis spp.',                      false, false, 5),
        (v_emp, v_cul, 'PODREDUMBRE',       'PODREDUMBRE VEGETAL',             'Penicillium / Mucor / Rhizopus spp.', false, false, 6),
        (v_emp, v_cul, 'EMBELLISIA',        'MANCHA POR EMBELLISIA',           'Embellisia allii',                   false, false, 7),
        (v_emp, v_cul, 'OXIDO',             'OXIDO',                           'Puccinia allii',                     false, false, 8),
        (v_emp, v_cul, 'NEMATODO',          'NEMATODO DEL TALLO Y BULBO',      'Ditylenchus dipsaci',                false, false, 9),
        (v_emp, v_cul, 'GUSANO_ALAMBRE',    'GUSANOS DE ALAMBRE',              NULL,                                 false, false, 10),
        (v_emp, v_cul, 'ACARO_BULBO',       'ACAROS DEL BULBO',                NULL,                                 false, false, 11),
        (v_emp, v_cul, 'PENICILLIUM',       'PENICILLIUM',                     'Penicillium spp.',                   false, false, 12)
    ON CONFLICT DO NOTHING;

    -- ------------------------------------------------------------ datos de la prueba de concepto
    INSERT INTO usuario (empresa_id, nombres, dni, email, rol)
    VALUES (v_emp, 'Evaluador Demo', '40000001', 'evaluador@demo.pe', 'EVALUADOR')
    ON CONFLICT DO NOTHING;

    INSERT INTO persona (empresa_id, tipo_documento, numero_documento, nombres, telefono) VALUES
        (v_emp, 'DNI', '72790829', 'KEVIN ARELY',     '987654321'),
        (v_emp, 'DNI', '41234567', 'NEIVER LAZARTE',  '912345678'),
        (v_emp, 'DNI', '29345678', 'WERNER CASCADA',  NULL),
        (v_emp, 'DNI', '30456789', 'SONIA BONAFRUTA', NULL)
    ON CONFLICT DO NOTHING;

    INSERT INTO agricultor (empresa_id, persona_id)
    SELECT v_emp, p.id FROM persona p
    WHERE p.empresa_id = v_emp AND p.numero_documento IN ('72790829', '29345678', '30456789')
    ON CONFLICT DO NOTHING;

    INSERT INTO proveedor (empresa_id, persona_id)
    SELECT v_emp, p.id FROM persona p
    WHERE p.empresa_id = v_emp AND p.numero_documento = '41234567'
    ON CONFLICT DO NOTHING;

    -- Lote modelo del Excel (LOTE #XXX MODELO): El Pedregal, zona B3 P52, Napuri
    INSERT INTO lote (empresa_id, campania_id, cultivo_id, codigo, variedad_id, agricultor_id, proveedor_id,
                      localidad_id, zona, latitud, longitud, tipo_compra_id, fecha_arrancado, fecha_corte)
    SELECT v_emp,
           (SELECT id FROM campania WHERE empresa_id = v_emp AND codigo = '2025'),
           v_cul,
           'LOTE 004',
           (SELECT id FROM variedad WHERE empresa_id = v_emp AND codigo = 'NAPURI'),
           (SELECT a.id FROM agricultor a JOIN persona p ON p.id = a.persona_id
             WHERE a.empresa_id = v_emp AND p.numero_documento = '72790829'),
           (SELECT pr.id FROM proveedor pr JOIN persona p ON p.id = pr.persona_id
             WHERE pr.empresa_id = v_emp AND p.numero_documento = '41234567'),
           (SELECT id FROM localidad WHERE empresa_id = v_emp AND nombre = 'EL PEDREGAL'),
           'B3 P52', -16.357500, -72.201900,
           (SELECT id FROM tipo_compra WHERE empresa_id = v_emp AND codigo = 'PRIMERA_5_ARRIBA'),
           DATE '2025-10-08', DATE '2025-10-10'
    ON CONFLICT DO NOTHING;
END;
$$;


-- =====================================================================
-- Prueba: carga el lote modelo del Excel y valida vistas y restricciones.
-- Se ejecuta dentro de una transaccion con ROLLBACK (no deja datos).
--   docker compose exec -T db psql -U garlic -d garlic -v ON_ERROR_STOP=1 < database/test/demo_lote_kevin.sql
-- =====================================================================

BEGIN;

DO $$
DECLARE
    v_emp  uuid := (SELECT id FROM empresa WHERE ruc = '00000000000');
    v_cul  uuid := (SELECT id FROM cultivo WHERE codigo = 'AJO');
    v_cam  uuid := (SELECT id FROM campania WHERE codigo = '2025');
    v_usr  uuid;
    v_per_agr uuid; v_per_prov uuid;
    v_agr  uuid; v_prov uuid;
    v_lote uuid; v_eval uuid; v_m uuid;
    i int;
    pct_primera numeric[] := ARRAY[80, 85, 75];
    pct_cal numeric[][] := ARRAY[
        [13, 18.2, 28.6, 14.3, 3.9, 1.3],
        [10, 15, 15, 15, 15, 15],
        [20, 20, 20, 20, 20, 20]];
    cal_codes text[] := ARRAY['45/50','50/55','55/60','60/65','65/70','>70'];
    j int;
BEGIN
    INSERT INTO usuario (empresa_id, nombres, email) VALUES (v_emp, 'EVALUADOR DEMO', 'evaluador@demo.pe') RETURNING id INTO v_usr;

    INSERT INTO persona (empresa_id, numero_documento, nombres) VALUES (v_emp, '72790829', 'KEVIN') RETURNING id INTO v_per_agr;
    INSERT INTO persona (empresa_id, numero_documento, nombres) VALUES (v_emp, '00000001', 'NEIVER LAZARTE') RETURNING id INTO v_per_prov;
    INSERT INTO agricultor (empresa_id, persona_id) VALUES (v_emp, v_per_agr) RETURNING id INTO v_agr;
    INSERT INTO proveedor (empresa_id, persona_id) VALUES (v_emp, v_per_prov) RETURNING id INTO v_prov;

    INSERT INTO lote (empresa_id, campania_id, cultivo_id, codigo, variedad_id, agricultor_id, proveedor_id,
                      titular_liquidacion_id, localidad_id, zona, tipo_compra_id)
    VALUES (v_emp, v_cam, v_cul, 'LOTE 004',
            (SELECT id FROM variedad WHERE codigo = 'NAPURI'), v_agr, v_prov, v_per_agr,
            (SELECT id FROM localidad WHERE nombre = 'EL PEDREGAL'), 'b3  p52',
            (SELECT id FROM tipo_compra WHERE codigo = 'PRIMERA_5_ARRIBA'))
    RETURNING id INTO v_lote;

    INSERT INTO evaluacion_lote (empresa_id, lote_id, evaluador_id, observacion)
    VALUES (v_emp, v_lote, v_usr, 'SE RECOMIENDA CARGAR EN 3 DIAS PARA BAJAR LA HUMEDAD')
    RETURNING id INTO v_eval;

    FOR i IN 1..3 LOOP
        INSERT INTO muestra (evaluacion_id, numero) VALUES (v_eval, i) RETURNING id INTO v_m;
        INSERT INTO muestra_calidad (muestra_id, clase_calidad_id, porcentaje) VALUES
            (v_m, (SELECT id FROM clase_calidad WHERE codigo = 'PRIMERA'),  pct_primera[i]),
            (v_m, (SELECT id FROM clase_calidad WHERE codigo = 'ABIERTOS'), 100 - pct_primera[i]);
        FOR j IN 1..6 LOOP
            INSERT INTO muestra_calibre (muestra_id, calibre_id, porcentaje)
            VALUES (v_m, (SELECT id FROM calibre WHERE codigo = cal_codes[j]), pct_cal[i][j]);
        END LOOP;
    END LOOP;

    INSERT INTO evaluacion_humedad (evaluacion_id, tipo_humedad_id, nivel)
    SELECT v_eval, id, CASE codigo WHEN 'DIENTE_ROSA_BEIGE' THEN 'MEDIA' ELSE 'ALTA' END::nivel_enum FROM tipo_humedad;

    INSERT INTO evaluacion_empaste VALUES (v_eval, (SELECT id FROM tipo_empaste WHERE codigo = 'BUENO'));
    INSERT INTO evaluacion_dano VALUES (v_eval, (SELECT id FROM tipo_dano WHERE codigo = 'NO_CONTIENE'));
    INSERT INTO evaluacion_sanidad (evaluacion_id, enfermedad_id, presente, porcentaje) VALUES
        (v_eval, (SELECT id FROM enfermedad WHERE codigo = 'RAIZ_ROSADA'), false, NULL),
        (v_eval, (SELECT id FROM enfermedad WHERE codigo = 'FUSARIUM'),    true,  5);

    INSERT INTO evidencia (empresa_id, evaluacion_id, muestra_id, factor, url_archivo)
    VALUES (v_emp, v_eval, v_m, 'CALIDAD', 's3://demo/foto1.jpg');

    -- ---- Validaciones ----
    ASSERT (SELECT zona_normalizada FROM lote WHERE id = v_lote) = 'B3 P52', 'zona no normalizada';
    ASSERT (SELECT porcentaje_promedio FROM v_evaluacion_calidad_prom
            WHERE evaluacion_id = v_eval AND clase_calidad_codigo = 'PRIMERA') = 80.00, 'PROM PRIMERA <> 80';
    ASSERT (SELECT porcentaje_promedio FROM v_evaluacion_calidad_prom
            WHERE evaluacion_id = v_eval AND clase_calidad_codigo = 'ABIERTOS') = 20.00, 'PROM ABIERTOS <> 20';
    ASSERT (SELECT porcentaje_promedio FROM v_evaluacion_calibre_prom
            WHERE evaluacion_id = v_eval AND calibre_codigo = '45/50') = 14.33, 'PROM 45/50 <> 14.33';

    -- Antiduplicados por zona
    BEGIN
        INSERT INTO lote (empresa_id, campania_id, cultivo_id, codigo, variedad_id, agricultor_id, localidad_id, zona, tipo_compra_id)
        VALUES (v_emp, v_cam, v_cul, 'LOTE 999', (SELECT id FROM variedad WHERE codigo = 'NAPURI'), v_agr,
                (SELECT id FROM localidad WHERE nombre = 'EL PEDREGAL'), 'B3 P52',
                (SELECT id FROM tipo_compra WHERE codigo = 'ABIERTOS'));
        RAISE EXCEPTION 'FALLO: se permitio lote duplicado por zona';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'OK: lote duplicado por zona rechazado';
    END;

    -- Porcentaje de sanidad sin estar presente
    BEGIN
        UPDATE evaluacion_sanidad SET porcentaje = 10
        WHERE evaluacion_id = v_eval AND enfermedad_id = (SELECT id FROM enfermedad WHERE codigo = 'RAIZ_ROSADA');
        RAISE EXCEPTION 'FALLO: se permitio porcentaje con presente = NO';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: porcentaje de sanidad con presente = NO rechazado';
    END;

    RAISE NOTICE 'OK: lote modelo cargado y promedios coinciden con el Excel';
END;
$$;

SELECT clase_calidad_codigo, porcentaje_promedio FROM v_evaluacion_calidad_prom ORDER BY orden;
SELECT calibre_codigo, porcentaje_promedio FROM v_evaluacion_calibre_prom ORDER BY orden;

ROLLBACK;

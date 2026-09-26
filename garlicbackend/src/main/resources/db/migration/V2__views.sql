-- =====================================================================
-- Vistas: promedios (columna PROM del protocolo)
-- =====================================================================


-- 2.1 Promedio por clase de calidad en cada evaluacion
CREATE VIEW v_evaluacion_calidad_prom AS
SELECT m.evaluacion_id,
       cc.id                         AS clase_calidad_id,
       cc.codigo                     AS clase_calidad_codigo,
       cc.orden,
       count(*)                      AS nro_muestras,
       round(avg(mc.porcentaje), 2)  AS porcentaje_promedio
FROM muestra m
JOIN muestra_calidad mc ON mc.muestra_id = m.id
JOIN clase_calidad cc   ON cc.id = mc.clase_calidad_id
GROUP BY m.evaluacion_id, cc.id, cc.codigo, cc.orden;

-- 2.2 Promedio por calibre en cada evaluacion
CREATE VIEW v_evaluacion_calibre_prom AS
SELECT m.evaluacion_id,
       c.id                          AS calibre_id,
       c.codigo                      AS calibre_codigo,
       c.orden,
       count(*)                      AS nro_muestras,
       round(avg(mc.porcentaje), 2)  AS porcentaje_promedio
FROM muestra m
JOIN muestra_calibre mc ON mc.muestra_id = m.id
JOIN calibre c          ON c.id = mc.calibre_id
GROUP BY m.evaluacion_id, c.id, c.codigo, c.orden;


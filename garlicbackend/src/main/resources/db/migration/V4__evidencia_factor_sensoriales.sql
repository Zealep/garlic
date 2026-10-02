-- =====================================================================
-- Evidencias: las fotos se toman dentro de cada seccion del wizard.
-- La seccion "Sensoriales" tiene un solo bloque de fotos (factor SENSORIALES).
-- =====================================================================
ALTER TABLE evidencia DROP CONSTRAINT ck_evidencia_factor;

ALTER TABLE evidencia ADD CONSTRAINT ck_evidencia_factor
    CHECK (factor IS NULL OR factor IN ('CALIDAD', 'CALIBRE', 'HUMEDAD', 'EMPASTE', 'DANO', 'SANIDAD', 'SENSORIALES'));

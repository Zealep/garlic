-- =====================================================================
-- Resultado (dictamen) de la evaluacion, definido despues de cerrarla:
--   ACEPTADA     el lote cumple y se compra
--   RECHAZADA    el lote no cumple
--   SIN_ACUERDO  no se cerro con el agricultor (no hubo acuerdo de precio)
-- NULL = pendiente. Es independiente de la compra: un lote rechazado puede comprarse igual.
-- =====================================================================
ALTER TABLE evaluacion_lote
    ADD COLUMN resultado         varchar(15),
    ADD COLUMN motivo_resultado  varchar(500),
    ADD COLUMN fecha_resultado   timestamptz,
    ADD CONSTRAINT ck_evaluacion_resultado
        CHECK (resultado IS NULL OR resultado IN ('ACEPTADA', 'RECHAZADA', 'SIN_ACUERDO')),
    ADD CONSTRAINT ck_evaluacion_resultado_cerrada
        CHECK (resultado IS NULL OR estado = 'CERRADA');

COMMENT ON COLUMN evaluacion_lote.resultado IS 'Dictamen tras cerrar: ACEPTADA, RECHAZADA o SIN_ACUERDO (sin acuerdo de precio). NULL = pendiente.';

-- El codigo del lote ahora lo asigna el servidor: correlativo por campania (LOTE 001, LOTE 002, ...)
COMMENT ON COLUMN lote.codigo IS 'Correlativo por campania asignado por el servidor (LOTE 001...). Unico en la campania.';

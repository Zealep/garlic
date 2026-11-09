-- =====================================================================
-- Observaciones del cliente (2026-11-02)
--  * Sensoriales (humedad, empaste, danos) y sanidad se registran POR MUESTRA (antes por evaluacion).
--  * Humedad: SI/NO por indicador (antes BAJA/MEDIA/ALTA).
--  * Danos con cantidades (paralisis): frutos total y frutos afectados -> % de dano.
--  * La muestra conserva su id al renumerarse (id asignado por la app).
--  * Lote: cuenta o CCI de la liquidacion; la ciudad/CCPP es opcional si hay coordenadas GPS.
--  * Carga: destare en kg (antes %).
-- Las evaluaciones de prueba se eliminan (decision del usuario): cambia su estructura.
-- =====================================================================

-- ---------------------------------------------------------------- limpieza de evaluaciones de prueba
DELETE FROM fijacion_precio;
DELETE FROM evaluacion_lote;   -- cascade: muestras, factores y evidencias

-- ---------------------------------------------------------------- factores por evaluacion -> por muestra
DROP TABLE evaluacion_humedad;
DROP TABLE evaluacion_empaste;
DROP TABLE evaluacion_dano;
DROP TABLE evaluacion_sanidad;
DROP TYPE nivel_enum;

ALTER TABLE tipo_dano ADD COLUMN pide_cantidades boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN tipo_dano.pide_cantidades IS 'Al marcarlo se registran frutos total y afectados (% de dano). Ej. paralisis.';
UPDATE tipo_dano SET pide_cantidades = true WHERE codigo LIKE 'PARALISIS%';

CREATE TABLE muestra_humedad (
    muestra_id       uuid        NOT NULL REFERENCES muestra(id) ON DELETE CASCADE,
    tipo_humedad_id  uuid        NOT NULL REFERENCES tipo_humedad(id),
    presente         boolean     NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    created_by       uuid,
    updated_at       timestamptz NOT NULL DEFAULT now(),
    updated_by       uuid,
    PRIMARY KEY (muestra_id, tipo_humedad_id)
);
COMMENT ON TABLE muestra_humedad IS '2.2.1 Humedad por muestra: SI/NO por indicador.';

CREATE TABLE muestra_empaste (
    muestra_id       uuid        NOT NULL REFERENCES muestra(id) ON DELETE CASCADE,
    tipo_empaste_id  uuid        NOT NULL REFERENCES tipo_empaste(id),
    created_at       timestamptz NOT NULL DEFAULT now(),
    created_by       uuid,
    PRIMARY KEY (muestra_id, tipo_empaste_id)
);
COMMENT ON TABLE muestra_empaste IS '2.2.2 Empaste por muestra (multi check).';

CREATE TABLE muestra_dano (
    muestra_id        uuid        NOT NULL REFERENCES muestra(id) ON DELETE CASCADE,
    tipo_dano_id      uuid        NOT NULL REFERENCES tipo_dano(id),
    frutos_total      integer,
    frutos_afectados  integer,
    created_at        timestamptz NOT NULL DEFAULT now(),
    created_by        uuid,
    PRIMARY KEY (muestra_id, tipo_dano_id),
    CONSTRAINT ck_muestra_dano_total CHECK (frutos_total IS NULL OR frutos_total > 0),
    CONSTRAINT ck_muestra_dano_afectados CHECK (frutos_afectados IS NULL OR frutos_afectados >= 0),
    CONSTRAINT ck_muestra_dano_rango CHECK (frutos_afectados IS NULL OR frutos_total IS NULL OR frutos_afectados <= frutos_total)
);
COMMENT ON TABLE muestra_dano IS 'Danos no visibles por muestra; % de dano = frutos_afectados / frutos_total.';

CREATE TABLE muestra_sanidad (
    muestra_id     uuid         NOT NULL REFERENCES muestra(id) ON DELETE CASCADE,
    enfermedad_id  uuid         NOT NULL REFERENCES enfermedad(id),
    presente       boolean      NOT NULL,
    porcentaje     numeric(5,2),
    created_at     timestamptz  NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz  NOT NULL DEFAULT now(),
    updated_by     uuid,
    PRIMARY KEY (muestra_id, enfermedad_id),
    CONSTRAINT ck_muestra_sanidad_pct CHECK (porcentaje IS NULL OR porcentaje BETWEEN 0 AND 100),
    CONSTRAINT ck_muestra_sanidad_pct_si_presente CHECK (presente OR porcentaje IS NULL)
);
COMMENT ON TABLE muestra_sanidad IS '2.2.4 / 2.2.5 Sanidad por muestra: SI/NO + % si es SI.';

CREATE INDEX ix_muestra_humedad_tipo   ON muestra_humedad (tipo_humedad_id);
CREATE INDEX ix_muestra_empaste_tipo   ON muestra_empaste (tipo_empaste_id);
CREATE INDEX ix_muestra_dano_tipo      ON muestra_dano (tipo_dano_id);
CREATE INDEX ix_muestra_sanidad_enf    ON muestra_sanidad (enfermedad_id);

-- renumerar muestras (1..n) en un mismo guardado sin chocar con la unicidad
ALTER TABLE muestra DROP CONSTRAINT uq_muestra;
ALTER TABLE muestra ADD CONSTRAINT uq_muestra UNIQUE (evaluacion_id, numero) DEFERRABLE INITIALLY DEFERRED;

-- ---------------------------------------------------------------- lote
ALTER TABLE lote ADD COLUMN cuenta_liquidacion varchar(30);
COMMENT ON COLUMN lote.cuenta_liquidacion IS 'Numero de cuenta o CCI de quien cobra la liquidacion.';
ALTER TABLE lote ALTER COLUMN localidad_id DROP NOT NULL;
ALTER TABLE lote ADD CONSTRAINT ck_lote_ubicacion CHECK (localidad_id IS NOT NULL OR latitud IS NOT NULL);

-- ---------------------------------------------------------------- carga: destare en kg
ALTER TABLE carga ADD COLUMN destare_kg numeric(12,2) NOT NULL DEFAULT 0;
UPDATE carga SET destare_kg = round(kg * destare_pct / 100, 2);
ALTER TABLE carga DROP CONSTRAINT ck_carga_destare;
ALTER TABLE carga DROP COLUMN destare_pct;
ALTER TABLE carga ADD CONSTRAINT ck_carga_destare CHECK (destare_kg >= 0 AND destare_kg <= kg);
COMMENT ON TABLE carga IS '3.2 Compra de materia prima: una fila por camion. total = (kg - destare_kg) * precio_kg.';

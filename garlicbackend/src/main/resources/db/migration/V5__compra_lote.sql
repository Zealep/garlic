-- =====================================================================
-- Punto 3 del protocolo: compra del lote
--   fijacion de precio, cargas (camiones), gastos vinculados, pagos y comprobantes.
-- Formulas en docs/modelo-datos/02-compra-lote.md
-- =====================================================================

-- ---------------------------------------------------------------- catalogos

CREATE TABLE tipo_empaque (
    id                   uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id           uuid          NOT NULL REFERENCES empresa(id),
    cultivo_id           uuid          NOT NULL REFERENCES cultivo(id),
    codigo               varchar(30)   NOT NULL,
    nombre               varchar(120)  NOT NULL,
    peso_referencial_kg  numeric(8,2),
    orden                smallint      NOT NULL DEFAULT 0,
    activo               boolean       NOT NULL DEFAULT true,
    created_at           timestamptz   NOT NULL DEFAULT now(),
    created_by           uuid,
    updated_at           timestamptz   NOT NULL DEFAULT now(),
    updated_by           uuid,
    CONSTRAINT uq_tipo_empaque UNIQUE (empresa_id, cultivo_id, codigo),
    CONSTRAINT ck_tipo_empaque_peso CHECK (peso_referencial_kg IS NULL OR peso_referencial_kg > 0)
);
COMMENT ON TABLE tipo_empaque IS 'Empaques de la carga (mallas, javas, sacos). peso_referencial_kg sugiere la cantidad.';

CREATE TABLE tipo_gasto (
    id                    uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id            uuid          NOT NULL REFERENCES empresa(id),
    cultivo_id            uuid          NOT NULL REFERENCES cultivo(id),
    codigo                varchar(30)   NOT NULL,
    nombre                varchar(120)  NOT NULL,
    por_carga             boolean       NOT NULL DEFAULT false,
    requiere_descripcion  boolean       NOT NULL DEFAULT false,
    orden                 smallint      NOT NULL DEFAULT 0,
    activo                boolean       NOT NULL DEFAULT true,
    created_at            timestamptz   NOT NULL DEFAULT now(),
    created_by            uuid,
    updated_at            timestamptz   NOT NULL DEFAULT now(),
    updated_by            uuid,
    CONSTRAINT uq_tipo_gasto UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE tipo_gasto IS 'Gastos vinculados a la materia prima (llevarla al packing). por_carga = se registra por camion.';

CREATE TABLE condicion_pago (
    id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid          NOT NULL REFERENCES empresa(id),
    cultivo_id  uuid          NOT NULL REFERENCES cultivo(id),
    codigo      varchar(30)   NOT NULL,
    nombre      varchar(120)  NOT NULL,
    orden       smallint      NOT NULL DEFAULT 0,
    activo      boolean       NOT NULL DEFAULT true,
    created_at  timestamptz   NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz   NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT uq_condicion_pago UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE condicion_pago IS 'Condicion del pago al agricultor/proveedor (CTA BANCO, EFECTIVO, CREDITO).';

-- ---------------------------------------------------------------- fijacion de precio

CREATE TABLE fijacion_precio (
    id               uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id       uuid           NOT NULL REFERENCES empresa(id),
    lote_id          uuid           NOT NULL REFERENCES lote(id),
    evaluacion_id    uuid           NOT NULL REFERENCES evaluacion_lote(id),
    gasto_llenado    numeric(10,4)  NOT NULL DEFAULT 0,
    precio_promedio  numeric(10,4)  NOT NULL,
    precio_tecnico   numeric(10,4)  NOT NULL,
    precio_pactado   numeric(10,4),
    fecha_pacto      date,
    observacion      text,
    created_at       timestamptz    NOT NULL DEFAULT now(),
    created_by       uuid,
    updated_at       timestamptz    NOT NULL DEFAULT now(),
    updated_by       uuid,
    CONSTRAINT uq_fijacion_precio_lote UNIQUE (lote_id),
    CONSTRAINT ck_fijacion_llenado CHECK (gasto_llenado >= 0),
    CONSTRAINT ck_fijacion_pactado CHECK (precio_pactado IS NULL OR precio_pactado > 0)
);
COMMENT ON TABLE fijacion_precio IS 'Modulo de fijacion de precio (S/ por kg). precio_tecnico = promedio muestras - gasto llenado.';
COMMENT ON COLUMN fijacion_precio.precio_promedio IS 'Promedio de las muestras: sum(precio_base * %calidad). Calculado por el servidor.';

CREATE TABLE fijacion_precio_clase (
    fijacion_id       uuid           NOT NULL REFERENCES fijacion_precio(id) ON DELETE CASCADE,
    clase_calidad_id  uuid           NOT NULL REFERENCES clase_calidad(id),
    precio_base       numeric(10,4)  NOT NULL,
    PRIMARY KEY (fijacion_id, clase_calidad_id),
    CONSTRAINT ck_fijacion_precio_base CHECK (precio_base >= 0)
);
COMMENT ON TABLE fijacion_precio_clase IS 'Precio base (S/ por kg) de cada clase de calidad.';

-- ---------------------------------------------------------------- cargas, gastos y pagos

CREATE TABLE carga (
    id                 uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id         uuid           NOT NULL REFERENCES empresa(id),
    lote_id            uuid           NOT NULL REFERENCES lote(id),
    fecha              date           NOT NULL,
    placa              varchar(15),
    kg                 numeric(12,2)  NOT NULL,
    cantidad_empaques  integer        NOT NULL DEFAULT 0,
    tipo_empaque_id    uuid           REFERENCES tipo_empaque(id),
    precio_kg          numeric(10,4)  NOT NULL,
    destare_pct        numeric(5,2)   NOT NULL DEFAULT 1,
    observacion        text,
    created_at         timestamptz    NOT NULL DEFAULT now(),
    created_by         uuid,
    updated_at         timestamptz    NOT NULL DEFAULT now(),
    updated_by         uuid,
    CONSTRAINT ck_carga_kg CHECK (kg > 0),
    CONSTRAINT ck_carga_empaques CHECK (cantidad_empaques >= 0),
    CONSTRAINT ck_carga_precio CHECK (precio_kg > 0),
    CONSTRAINT ck_carga_destare CHECK (destare_pct BETWEEN 0 AND 100)
);
COMMENT ON TABLE carga IS '3.2 Compra de materia prima: una fila por camion. total = (kg - kg*destare_pct/100) * precio_kg.';

CREATE TABLE gasto_vinculado (
    id             uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id     uuid           NOT NULL REFERENCES empresa(id),
    lote_id        uuid           NOT NULL REFERENCES lote(id),
    carga_id       uuid           REFERENCES carga(id),
    tipo_gasto_id  uuid           NOT NULL REFERENCES tipo_gasto(id),
    fecha          date           NOT NULL,
    monto          numeric(12,2)  NOT NULL,
    descripcion    varchar(250),
    created_at     timestamptz    NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz    NOT NULL DEFAULT now(),
    updated_by     uuid,
    CONSTRAINT ck_gasto_monto CHECK (monto > 0)
);
COMMENT ON TABLE gasto_vinculado IS 'Gastos vinculados a la materia prima (estiba, pesaje, flete...). carga_id NULL = gasto general.';

CREATE TABLE pago (
    id                 uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id         uuid           NOT NULL REFERENCES empresa(id),
    lote_id            uuid           NOT NULL REFERENCES lote(id),
    fecha              date           NOT NULL,
    condicion_pago_id  uuid           NOT NULL REFERENCES condicion_pago(id),
    monto              numeric(12,2)  NOT NULL,
    beneficiario_id    uuid           REFERENCES persona(id),
    referencia         varchar(60),
    observacion        text,
    created_at         timestamptz    NOT NULL DEFAULT now(),
    created_by         uuid,
    updated_at         timestamptz    NOT NULL DEFAULT now(),
    updated_by         uuid,
    CONSTRAINT ck_pago_monto CHECK (monto > 0)
);
COMMENT ON TABLE pago IS '3.1 Abonos / adelantos al agricultor o proveedor, solo por la materia prima.';

CREATE TABLE comprobante (
    id             uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id     uuid          NOT NULL REFERENCES empresa(id),
    lote_id        uuid          NOT NULL REFERENCES lote(id),
    entidad        varchar(10)   NOT NULL,
    entidad_id     uuid          NOT NULL,
    url_archivo    text          NOT NULL,
    fecha_captura  timestamptz,
    created_at     timestamptz   NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz   NOT NULL DEFAULT now(),
    updated_by     uuid,
    CONSTRAINT ck_comprobante_entidad CHECK (entidad IN ('CARGA', 'GASTO', 'PAGO'))
);
COMMENT ON TABLE comprobante IS 'Fotos de respaldo: ticket de balanza (carga), voucher (pago), recibo (gasto).';

CREATE INDEX ix_tipo_empaque_empresa    ON tipo_empaque (empresa_id);
CREATE INDEX ix_tipo_gasto_empresa      ON tipo_gasto (empresa_id);
CREATE INDEX ix_condicion_pago_empresa  ON condicion_pago (empresa_id);
CREATE INDEX ix_fijacion_evaluacion     ON fijacion_precio (evaluacion_id);
CREATE INDEX ix_carga_lote              ON carga (lote_id);
CREATE INDEX ix_carga_tipo_empaque      ON carga (tipo_empaque_id);
CREATE INDEX ix_gasto_lote              ON gasto_vinculado (lote_id);
CREATE INDEX ix_gasto_carga             ON gasto_vinculado (carga_id);
CREATE INDEX ix_gasto_tipo              ON gasto_vinculado (tipo_gasto_id);
CREATE INDEX ix_pago_lote               ON pago (lote_id);
CREATE INDEX ix_pago_condicion          ON pago (condicion_pago_id);
CREATE INDEX ix_pago_beneficiario       ON pago (beneficiario_id);
CREATE INDEX ix_comprobante_entidad     ON comprobante (entidad_id);
CREATE INDEX ix_comprobante_lote        ON comprobante (lote_id);

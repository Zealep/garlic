-- =====================================================================
-- App Garlic - Modelo de datos v1
-- Modulo: 01. Identificacion y Calidad del Lote
-- Motor : PostgreSQL >= 13 (gen_random_uuid nativo). Gestionado por Flyway.
-- Doc   : docs/modelo-datos/01-identificacion-calidad-lote.md
-- =====================================================================


-- ---------------------------------------------------------------------
-- Tipos
-- ---------------------------------------------------------------------
CREATE TYPE nivel_enum AS ENUM ('BAJA', 'MEDIA', 'ALTA');

-- ---------------------------------------------------------------------
-- Funcion de auditoria: mantiene updated_at
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- =====================================================================
-- A. BASE / SAAS
-- =====================================================================

CREATE TABLE empresa (
    id                uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    ruc               varchar(11)  NOT NULL UNIQUE,
    razon_social      varchar(200) NOT NULL,
    nombre_comercial  varchar(200),
    activo            boolean      NOT NULL DEFAULT true,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    created_by        uuid,
    updated_at        timestamptz  NOT NULL DEFAULT now(),
    updated_by        uuid
);
COMMENT ON TABLE empresa IS 'Tenant del SaaS (agroexportadora cliente).';

CREATE TABLE usuario (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    nombres     varchar(150) NOT NULL,
    dni         varchar(15),
    email       varchar(150) NOT NULL UNIQUE,
    rol         varchar(30)  NOT NULL DEFAULT 'EVALUADOR',
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('ADMIN', 'EVALUADOR', 'SUPERVISOR'))
);
COMMENT ON TABLE usuario IS 'Usuarios del sistema; el evaluador de campo es un usuario.';

CREATE TABLE cultivo (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo      varchar(20) NOT NULL UNIQUE,
    nombre      varchar(80) NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    updated_by  uuid
);
COMMENT ON TABLE cultivo IS 'Catalogo global de cultivos (AJO, ...).';

-- =====================================================================
-- B. MAESTROS (Punto 1)
-- =====================================================================

CREATE TABLE persona (
    id                uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id        uuid         NOT NULL REFERENCES empresa(id),
    tipo_documento    varchar(10)  NOT NULL DEFAULT 'DNI',
    numero_documento  varchar(20)  NOT NULL,
    nombres           varchar(200) NOT NULL,
    telefono          varchar(20),
    created_at        timestamptz  NOT NULL DEFAULT now(),
    created_by        uuid,
    updated_at        timestamptz  NOT NULL DEFAULT now(),
    updated_by        uuid,
    CONSTRAINT ck_persona_tipo_doc CHECK (tipo_documento IN ('DNI', 'RUC', 'CE', 'PASAPORTE')),
    CONSTRAINT uq_persona_documento UNIQUE (empresa_id, tipo_documento, numero_documento)
);
COMMENT ON TABLE persona IS 'Identidad compartida por agricultores, proveedores y titulares de liquidacion.';

CREATE TABLE agricultor (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid        NOT NULL REFERENCES empresa(id),
    persona_id  uuid        NOT NULL UNIQUE REFERENCES persona(id),
    activo      boolean     NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    updated_by  uuid
);

CREATE TABLE proveedor (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid        NOT NULL REFERENCES empresa(id),
    persona_id  uuid        NOT NULL UNIQUE REFERENCES persona(id),
    activo      boolean     NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    updated_by  uuid
);
COMMENT ON TABLE proveedor IS 'Intermediario / acopiador que trae el lote.';

CREATE TABLE localidad (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    nombre      varchar(120) NOT NULL,
    tipo        varchar(10)  NOT NULL DEFAULT 'CCPP',
    ubigeo      char(6),
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT ck_localidad_tipo CHECK (tipo IN ('CIUDAD', 'CCPP')),
    CONSTRAINT uq_localidad UNIQUE (empresa_id, nombre)
);
COMMENT ON TABLE localidad IS 'Ciudad o Centro Poblado (CCPP).';

CREATE TABLE campania (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id    uuid        NOT NULL REFERENCES empresa(id),
    cultivo_id    uuid        NOT NULL REFERENCES cultivo(id),
    codigo        varchar(20) NOT NULL,
    fecha_inicio  date,
    fecha_fin     date,
    activa        boolean     NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    created_by    uuid,
    updated_at    timestamptz NOT NULL DEFAULT now(),
    updated_by    uuid,
    CONSTRAINT uq_campania UNIQUE (empresa_id, cultivo_id, codigo),
    CONSTRAINT ck_campania_fechas CHECK (fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio)
);

-- ---------------------------------------------------------------------
-- Catalogos con estructura comun:
--   id, empresa_id, cultivo_id, codigo, nombre, orden, activo + auditoria
-- ---------------------------------------------------------------------

CREATE TABLE variedad (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id  uuid         NOT NULL REFERENCES cultivo(id),
    codigo      varchar(30)  NOT NULL,
    nombre      varchar(120) NOT NULL,
    orden       smallint     NOT NULL DEFAULT 0,
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT uq_variedad UNIQUE (empresa_id, cultivo_id, codigo)
);

CREATE TABLE tipo_compra (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id  uuid         NOT NULL REFERENCES cultivo(id),
    codigo      varchar(30)  NOT NULL,
    nombre      varchar(120) NOT NULL,
    orden       smallint     NOT NULL DEFAULT 0,
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT uq_tipo_compra UNIQUE (empresa_id, cultivo_id, codigo)
);

-- =====================================================================
-- C. CATALOGOS DE CALIDAD (Punto 2)
-- =====================================================================

CREATE TABLE clase_calidad (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id  uuid         NOT NULL REFERENCES cultivo(id),
    codigo      varchar(30)  NOT NULL,
    nombre      varchar(120) NOT NULL,
    orden       smallint     NOT NULL DEFAULT 0,
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT uq_clase_calidad UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE clase_calidad IS '2.1 Factor calidad global (PRIMERA, ABIERTOS, ...).';

CREATE TABLE calibre (
    id               uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id       uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id       uuid         NOT NULL REFERENCES cultivo(id),
    codigo           varchar(30)  NOT NULL,
    nombre           varchar(120) NOT NULL,
    diametro_min_mm  numeric(5,1),
    diametro_max_mm  numeric(5,1),
    orden            smallint     NOT NULL DEFAULT 0,
    activo           boolean      NOT NULL DEFAULT true,
    created_at       timestamptz  NOT NULL DEFAULT now(),
    created_by       uuid,
    updated_at       timestamptz  NOT NULL DEFAULT now(),
    updated_by       uuid,
    CONSTRAINT uq_calibre UNIQUE (empresa_id, cultivo_id, codigo),
    CONSTRAINT ck_calibre_rango CHECK (diametro_max_mm IS NULL OR diametro_min_mm IS NULL OR diametro_max_mm > diametro_min_mm)
);
COMMENT ON TABLE calibre IS '2.2 Factor tamano. diametro_max_mm NULL = sin tope (>70).';

CREATE TABLE tipo_humedad (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id  uuid         NOT NULL REFERENCES cultivo(id),
    codigo      varchar(30)  NOT NULL,
    nombre      varchar(120) NOT NULL,
    orden       smallint     NOT NULL DEFAULT 0,
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT uq_tipo_humedad UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE tipo_humedad IS '2.2.1 Indicadores de humedad.';

CREATE TABLE tipo_empaste (
    id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id  uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id  uuid         NOT NULL REFERENCES cultivo(id),
    codigo      varchar(30)  NOT NULL,
    nombre      varchar(120) NOT NULL,
    orden       smallint     NOT NULL DEFAULT 0,
    activo      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    created_by  uuid,
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid,
    CONSTRAINT uq_tipo_empaste UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE tipo_empaste IS '2.2.2 Empaste (multi check).';

CREATE TABLE tipo_dano (
    id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id     uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id     uuid         NOT NULL REFERENCES cultivo(id),
    codigo         varchar(30)  NOT NULL,
    nombre         varchar(120) NOT NULL,
    es_excluyente  boolean      NOT NULL DEFAULT false,
    orden          smallint     NOT NULL DEFAULT 0,
    activo         boolean      NOT NULL DEFAULT true,
    created_at     timestamptz  NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz  NOT NULL DEFAULT now(),
    updated_by     uuid,
    CONSTRAINT uq_tipo_dano UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE tipo_dano IS 'Danos no visibles (multi check). es_excluyente = NO CONTIENE.';

CREATE TABLE enfermedad (
    id                        uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id                uuid         NOT NULL REFERENCES empresa(id),
    cultivo_id                uuid         NOT NULL REFERENCES cultivo(id),
    codigo                    varchar(30)  NOT NULL,
    nombre                    varchar(120) NOT NULL,
    nombre_cientifico         varchar(150),
    se_transmite_por_semilla  boolean      NOT NULL DEFAULT false,
    evaluar_en_campo          boolean      NOT NULL DEFAULT false,
    orden                     smallint     NOT NULL DEFAULT 0,
    activo                    boolean      NOT NULL DEFAULT true,
    created_at                timestamptz  NOT NULL DEFAULT now(),
    created_by                uuid,
    updated_at                timestamptz  NOT NULL DEFAULT now(),
    updated_by                uuid,
    CONSTRAINT uq_enfermedad UNIQUE (empresa_id, cultivo_id, codigo)
);
COMMENT ON TABLE enfermedad IS 'Enfermedades/plagas. evaluar_en_campo = aparece en el formulario (Raiz rosada, Fusarium).';

-- =====================================================================
-- D. TRANSACCIONALES
-- =====================================================================

CREATE TABLE lote (
    id                      uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id              uuid         NOT NULL REFERENCES empresa(id),
    campania_id             uuid         NOT NULL REFERENCES campania(id),
    cultivo_id              uuid         NOT NULL REFERENCES cultivo(id),
    codigo                  varchar(30)  NOT NULL,
    variedad_id             uuid         NOT NULL REFERENCES variedad(id),
    agricultor_id           uuid         NOT NULL REFERENCES agricultor(id),
    proveedor_id            uuid         REFERENCES proveedor(id),
    titular_liquidacion_id  uuid         REFERENCES persona(id),
    localidad_id            uuid         NOT NULL REFERENCES localidad(id),
    zona                    varchar(50)  NOT NULL,
    zona_normalizada        varchar(50)  GENERATED ALWAYS AS (upper(regexp_replace(btrim(zona), '\s+', ' ', 'g'))) STORED,
    latitud                 numeric(9,6),
    longitud                numeric(9,6),
    maps_url                text,
    tipo_compra_id          uuid         NOT NULL REFERENCES tipo_compra(id),
    fecha_arrancado         date,
    fecha_corte             date,
    fecha_carga             date,
    estado                  varchar(15)  NOT NULL DEFAULT 'ACTIVO',
    created_at              timestamptz  NOT NULL DEFAULT now(),
    created_by              uuid,
    updated_at              timestamptz  NOT NULL DEFAULT now(),
    updated_by              uuid,
    CONSTRAINT uq_lote_codigo UNIQUE (empresa_id, campania_id, codigo),
    CONSTRAINT ck_lote_estado CHECK (estado IN ('ACTIVO', 'ANULADO')),
    CONSTRAINT ck_lote_latitud CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
    CONSTRAINT ck_lote_longitud CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180)
);
COMMENT ON TABLE lote IS 'Punto 1: Identificacion del lote.';
COMMENT ON COLUMN lote.titular_liquidacion_id IS 'DNI LC: persona a cuyo nombre se emite la liquidacion de compra.';
COMMENT ON COLUMN lote.zona IS 'Zona tal como se ingresa (ej. B3 P52). Clave antiduplicados.';
COMMENT ON COLUMN lote.tipo_compra_id IS 'Tipo de compra decidido por el evaluador.';

-- Antiduplicados: no puede haber dos lotes activos con la misma zona en la misma campania
CREATE UNIQUE INDEX ux_lote_zona_campania
    ON lote (empresa_id, campania_id, zona_normalizada)
    WHERE estado <> 'ANULADO';

CREATE TABLE evaluacion_lote (
    id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id        uuid        NOT NULL REFERENCES empresa(id),
    lote_id           uuid        NOT NULL REFERENCES lote(id),
    evaluador_id      uuid        NOT NULL REFERENCES usuario(id),
    fecha_evaluacion  date        NOT NULL DEFAULT current_date,
    observacion       text,
    estado            varchar(15) NOT NULL DEFAULT 'BORRADOR',
    created_at        timestamptz NOT NULL DEFAULT now(),
    created_by        uuid,
    updated_at        timestamptz NOT NULL DEFAULT now(),
    updated_by        uuid,
    CONSTRAINT ck_evaluacion_estado CHECK (estado IN ('BORRADOR', 'CERRADA'))
);
COMMENT ON TABLE evaluacion_lote IS 'Punto 2: Evaluacion de calidad del lote (permite re-evaluaciones).';

CREATE TABLE muestra (
    id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluacion_id  uuid        NOT NULL REFERENCES evaluacion_lote(id) ON DELETE CASCADE,
    numero         smallint    NOT NULL,
    observacion    text,
    created_at     timestamptz NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz NOT NULL DEFAULT now(),
    updated_by     uuid,
    CONSTRAINT uq_muestra UNIQUE (evaluacion_id, numero),
    CONSTRAINT ck_muestra_numero CHECK (numero > 0)
);
COMMENT ON TABLE muestra IS 'Muestra representativa del lote (1..N).';

CREATE TABLE muestra_calidad (
    muestra_id        uuid         NOT NULL REFERENCES muestra(id) ON DELETE CASCADE,
    clase_calidad_id  uuid         NOT NULL REFERENCES clase_calidad(id),
    porcentaje        numeric(5,2) NOT NULL,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    created_by        uuid,
    updated_at        timestamptz  NOT NULL DEFAULT now(),
    updated_by        uuid,
    PRIMARY KEY (muestra_id, clase_calidad_id),
    CONSTRAINT ck_muestra_calidad_pct CHECK (porcentaje BETWEEN 0 AND 100)
);
COMMENT ON TABLE muestra_calidad IS '2.1 % por clase de calidad y muestra.';

CREATE TABLE muestra_calibre (
    muestra_id   uuid         NOT NULL REFERENCES muestra(id) ON DELETE CASCADE,
    calibre_id   uuid         NOT NULL REFERENCES calibre(id),
    porcentaje   numeric(5,2) NOT NULL,
    created_at   timestamptz  NOT NULL DEFAULT now(),
    created_by   uuid,
    updated_at   timestamptz  NOT NULL DEFAULT now(),
    updated_by   uuid,
    PRIMARY KEY (muestra_id, calibre_id),
    CONSTRAINT ck_muestra_calibre_pct CHECK (porcentaje BETWEEN 0 AND 100)
);
COMMENT ON TABLE muestra_calibre IS '2.2 % por calibre y muestra (no se exige suma 100).';

CREATE TABLE evaluacion_humedad (
    evaluacion_id    uuid        NOT NULL REFERENCES evaluacion_lote(id) ON DELETE CASCADE,
    tipo_humedad_id  uuid        NOT NULL REFERENCES tipo_humedad(id),
    nivel            nivel_enum  NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    created_by       uuid,
    updated_at       timestamptz NOT NULL DEFAULT now(),
    updated_by       uuid,
    PRIMARY KEY (evaluacion_id, tipo_humedad_id)
);
COMMENT ON TABLE evaluacion_humedad IS '2.2.1 Humedad por evaluacion (BAJA/MEDIA/ALTA).';

CREATE TABLE evaluacion_empaste (
    evaluacion_id    uuid        NOT NULL REFERENCES evaluacion_lote(id) ON DELETE CASCADE,
    tipo_empaste_id  uuid        NOT NULL REFERENCES tipo_empaste(id),
    created_at       timestamptz NOT NULL DEFAULT now(),
    created_by       uuid,
    PRIMARY KEY (evaluacion_id, tipo_empaste_id)
);
COMMENT ON TABLE evaluacion_empaste IS '2.2.2 Empaste (multi check).';

CREATE TABLE evaluacion_dano (
    evaluacion_id  uuid        NOT NULL REFERENCES evaluacion_lote(id) ON DELETE CASCADE,
    tipo_dano_id   uuid        NOT NULL REFERENCES tipo_dano(id),
    created_at     timestamptz NOT NULL DEFAULT now(),
    created_by     uuid,
    PRIMARY KEY (evaluacion_id, tipo_dano_id)
);
COMMENT ON TABLE evaluacion_dano IS 'Danos no visibles (multi check).';

CREATE TABLE evaluacion_sanidad (
    evaluacion_id  uuid         NOT NULL REFERENCES evaluacion_lote(id) ON DELETE CASCADE,
    enfermedad_id  uuid         NOT NULL REFERENCES enfermedad(id),
    presente       boolean      NOT NULL,
    porcentaje     numeric(5,2),
    created_at     timestamptz  NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz  NOT NULL DEFAULT now(),
    updated_by     uuid,
    PRIMARY KEY (evaluacion_id, enfermedad_id),
    CONSTRAINT ck_sanidad_pct CHECK (porcentaje IS NULL OR porcentaje BETWEEN 0 AND 100),
    CONSTRAINT ck_sanidad_pct_si_presente CHECK (presente OR porcentaje IS NULL)
);
COMMENT ON TABLE evaluacion_sanidad IS '2.2.4 Raiz rosada / 2.2.5 Fusarium: SI/NO + % si es SI.';

CREATE TABLE evidencia (
    id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id     uuid         NOT NULL REFERENCES empresa(id),
    evaluacion_id  uuid         NOT NULL REFERENCES evaluacion_lote(id) ON DELETE CASCADE,
    muestra_id     uuid         REFERENCES muestra(id) ON DELETE CASCADE,
    factor         varchar(20),
    url_archivo    text         NOT NULL,
    descripcion    varchar(250),
    fecha_captura  timestamptz,
    created_at     timestamptz  NOT NULL DEFAULT now(),
    created_by     uuid,
    updated_at     timestamptz  NOT NULL DEFAULT now(),
    updated_by     uuid,
    CONSTRAINT ck_evidencia_factor CHECK (factor IS NULL OR factor IN ('CALIDAD', 'CALIBRE', 'HUMEDAD', 'EMPASTE', 'DANO', 'SANIDAD'))
);
COMMENT ON TABLE evidencia IS 'Evidencias fotograficas. muestra_id NULL = evidencia general.';

-- =====================================================================
-- Indices sobre FKs (PostgreSQL no los crea automaticamente)
-- =====================================================================
CREATE INDEX ix_usuario_empresa        ON usuario (empresa_id);
CREATE INDEX ix_persona_empresa        ON persona (empresa_id);
CREATE INDEX ix_agricultor_empresa     ON agricultor (empresa_id);
CREATE INDEX ix_proveedor_empresa      ON proveedor (empresa_id);
CREATE INDEX ix_lote_variedad          ON lote (variedad_id);
CREATE INDEX ix_lote_agricultor        ON lote (agricultor_id);
CREATE INDEX ix_lote_proveedor         ON lote (proveedor_id);
CREATE INDEX ix_lote_titular_liq       ON lote (titular_liquidacion_id);
CREATE INDEX ix_lote_localidad         ON lote (localidad_id);
CREATE INDEX ix_lote_tipo_compra       ON lote (tipo_compra_id);
CREATE INDEX ix_evaluacion_lote        ON evaluacion_lote (lote_id);
CREATE INDEX ix_evaluacion_evaluador   ON evaluacion_lote (evaluador_id);
CREATE INDEX ix_evaluacion_empresa_fec ON evaluacion_lote (empresa_id, fecha_evaluacion);
CREATE INDEX ix_muestra_calidad_clase  ON muestra_calidad (clase_calidad_id);
CREATE INDEX ix_muestra_calibre_cal    ON muestra_calibre (calibre_id);
CREATE INDEX ix_evidencia_evaluacion   ON evidencia (evaluacion_id);
CREATE INDEX ix_evidencia_muestra      ON evidencia (muestra_id);

-- =====================================================================
-- Triggers updated_at en todas las tablas que tienen la columna
-- =====================================================================
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN
        SELECT c.table_name
        FROM information_schema.columns c
        JOIN information_schema.tables tb
          ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name
        WHERE c.table_schema = 'public'
          AND c.column_name = 'updated_at'
          AND tb.table_type = 'BASE TABLE'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%1$s_updated_at BEFORE UPDATE ON %1$I
             FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at()', t);
    END LOOP;
END;
$$;


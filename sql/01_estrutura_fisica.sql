-- 01 - Estrutura fisica do DW Airbnb (PostgreSQL 12+)
-- Schemas: stg = area de staging (espelho dos CSVs); dw = tabelas finais (modelo com fato).
-- Pode rodar de novo sem problema (usa IF NOT EXISTS).

CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dw;

-- ===================== STAGING (mesma ordem de colunas dos CSVs) =====================

CREATE TABLE IF NOT EXISTS stg.neighbourhoods (
    neighbourhood_group  VARCHAR(100),
    neighbourhood        VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS stg.listings (
    id                              BIGINT,
    name                            TEXT,
    host_id                         BIGINT,
    host_profile_id                 BIGINT,
    host_name                       VARCHAR(200),
    neighbourhood_group             VARCHAR(100),
    neighbourhood                   VARCHAR(100),
    latitude                        DOUBLE PRECISION,
    longitude                       DOUBLE PRECISION,
    room_type                       VARCHAR(50),
    price                           NUMERIC,
    minimum_nights                  INTEGER,
    number_of_reviews               INTEGER,
    last_review                     DATE,
    reviews_per_month               NUMERIC,
    calculated_host_listings_count  INTEGER,
    availability_365                INTEGER,
    number_of_reviews_ltm           INTEGER,
    license                         VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS stg.reviews (
    listing_id  BIGINT,
    date        DATE
);

-- ===================== DW: DIMENSOES =====================

CREATE TABLE IF NOT EXISTS dw.neighbourhoods (
    neighbourhood        VARCHAR(100)  PRIMARY KEY,
    neighbourhood_group  VARCHAR(100)                      -- vem 100% vazia nos arquivos
);

CREATE TABLE IF NOT EXISTS dw.listings (
    id                              BIGINT         PRIMARY KEY,
    name                            TEXT,
    host_id                         BIGINT,
    host_profile_id                 BIGINT,
    host_name                       VARCHAR(200),
    neighbourhood                   VARCHAR(100)   NOT NULL REFERENCES dw.neighbourhoods (neighbourhood),
    neighbourhood_group             VARCHAR(100),          -- vem 100% vazia nos arquivos
    latitude                        NUMERIC(9,6),
    longitude                       NUMERIC(9,6),
    room_type                       VARCHAR(50),
    price                           NUMERIC(12,2),
    minimum_nights                  INTEGER,
    number_of_reviews               INTEGER,
    last_review                     DATE,
    reviews_per_month               NUMERIC(8,2),
    calculated_host_listings_count  INTEGER,
    availability_365                INTEGER,
    number_of_reviews_ltm           INTEGER,
    license                         VARCHAR(100)           -- vem 100% vazia nos arquivos
);

-- ===================== DW: FATO =====================

-- Granularidade: uma linha por avaliacao. Nao tem chave primaria porque existem
-- avaliacoes repetidas (mesmo anuncio, mesma data).
CREATE TABLE IF NOT EXISTS dw.fato_reviews (
    listing_id     BIGINT        NOT NULL REFERENCES dw.listings (id),
    neighbourhood  VARCHAR(100)  NOT NULL REFERENCES dw.neighbourhoods (neighbourhood),
    data           DATE          NOT NULL,
    ano            SMALLINT      NOT NULL,
    trimestre      SMALLINT      NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    mes            SMALLINT      NOT NULL CHECK (mes BETWEEN 1 AND 12),
    dia_semana     SMALLINT      NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),  -- 1 = segunda ... 7 = domingo
    qtd_avaliacao  SMALLINT      NOT NULL DEFAULT 1
);

COMMENT ON TABLE  dw.fato_reviews IS 'Fato: uma linha por avaliacao recebida. Indicador de demanda (a data e posterior a estadia).';
COMMENT ON COLUMN dw.fato_reviews.qtd_avaliacao IS 'Medida aditiva (sempre 1 por linha).';

-- ===================== INDICES =====================

CREATE INDEX IF NOT EXISTS ix_listings_neighbourhood  ON dw.listings (neighbourhood);
CREATE INDEX IF NOT EXISTS ix_fato_reviews_listing    ON dw.fato_reviews (listing_id);
CREATE INDEX IF NOT EXISTS ix_fato_reviews_bairro     ON dw.fato_reviews (neighbourhood);
CREATE INDEX IF NOT EXISTS ix_fato_reviews_ano_mes    ON dw.fato_reviews (ano, mes);
CREATE INDEX IF NOT EXISTS ix_fato_reviews_data       ON dw.fato_reviews (data);

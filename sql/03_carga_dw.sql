-- 03 - Carga das tabelas do DW a partir da staging
-- Carga completa: apaga e recarrega tudo dentro de uma transacao
-- (se algo falhar, nada muda; os CSVs do Inside Airbnb sao cumulativos).

BEGIN;

TRUNCATE dw.fato_reviews, dw.listings, dw.neighbourhoods;

-- Dimensao: bairros
INSERT INTO dw.neighbourhoods (neighbourhood, neighbourhood_group)
SELECT neighbourhood, neighbourhood_group
FROM   stg.neighbourhoods;

-- Dimensao: anuncios
INSERT INTO dw.listings (
    id, name, host_id, host_profile_id, host_name, neighbourhood, neighbourhood_group,
    latitude, longitude, room_type, price, minimum_nights, number_of_reviews, last_review,
    reviews_per_month, calculated_host_listings_count, availability_365,
    number_of_reviews_ltm, license
)
SELECT
    id, name, host_id, host_profile_id, host_name, neighbourhood, neighbourhood_group,
    ROUND(latitude::numeric, 6), ROUND(longitude::numeric, 6), room_type, price,
    minimum_nights, number_of_reviews, last_review, reviews_per_month,
    calculated_host_listings_count, availability_365, number_of_reviews_ltm, license
FROM stg.listings;

-- Fato: uma linha por avaliacao, com o bairro e os atributos de data ja calculados
INSERT INTO dw.fato_reviews (
    listing_id, neighbourhood, data, ano, trimestre, mes, dia_semana, qtd_avaliacao
)
SELECT
    r.listing_id,
    l.neighbourhood,
    r.date,
    EXTRACT(YEAR    FROM r.date)::smallint,
    EXTRACT(QUARTER FROM r.date)::smallint,
    EXTRACT(MONTH   FROM r.date)::smallint,
    EXTRACT(ISODOW  FROM r.date)::smallint,
    1
FROM stg.reviews  r
JOIN stg.listings l ON l.id = r.listing_id;

COMMIT;

ANALYZE dw.neighbourhoods;
ANALYZE dw.listings;
ANALYZE dw.fato_reviews;

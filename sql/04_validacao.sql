-- 04 - Validacao da carga

-- 1) Linhas na staging x DW (as colunas "diferenca" tem que ser 0)
SELECT 'neighbourhoods' AS tabela,
       (SELECT COUNT(*) FROM stg.neighbourhoods) AS staging,
       (SELECT COUNT(*) FROM dw.neighbourhoods)  AS dw,
       (SELECT COUNT(*) FROM stg.neighbourhoods) - (SELECT COUNT(*) FROM dw.neighbourhoods) AS diferenca
UNION ALL
SELECT 'listings',
       (SELECT COUNT(*) FROM stg.listings),
       (SELECT COUNT(*) FROM dw.listings),
       (SELECT COUNT(*) FROM stg.listings) - (SELECT COUNT(*) FROM dw.listings)
UNION ALL
SELECT 'reviews / fato_reviews',
       (SELECT COUNT(*) FROM stg.reviews),
       (SELECT COUNT(*) FROM dw.fato_reviews),
       (SELECT COUNT(*) FROM stg.reviews) - (SELECT COUNT(*) FROM dw.fato_reviews);

-- 2) Avaliacoes sem anuncio correspondente (esperado: 0)
SELECT COUNT(*) AS avaliacoes_sem_anuncio
FROM   stg.reviews r
LEFT   JOIN stg.listings l ON l.id = r.listing_id
WHERE  l.id IS NULL;

-- 3) Anuncios cujo bairro nao existe em neighbourhoods (esperado: 0)
SELECT COUNT(*) AS anuncios_sem_bairro
FROM   stg.listings l
LEFT   JOIN stg.neighbourhoods n ON n.neighbourhood = l.neighbourhood
WHERE  n.neighbourhood IS NULL;

-- 4) Consulta de exemplo: indice sazonal da demanda (1,0 = media mensal do proprio ano)
--    Usa 2022-2025 (anos completos). Compara cada mes com a media do ano.
WITH mensal AS (
    SELECT ano, mes, SUM(qtd_avaliacao) AS qtd
    FROM   dw.fato_reviews
    WHERE  ano BETWEEN 2022 AND 2025
    GROUP  BY ano, mes
),
media_ano AS (
    SELECT ano, AVG(qtd) AS media FROM mensal GROUP BY ano
)
SELECT m.mes,
       ROUND(AVG(m.qtd / a.media), 2) AS indice_sazonal
FROM   mensal m
JOIN   media_ano a USING (ano)
GROUP  BY m.mes
ORDER  BY m.mes;

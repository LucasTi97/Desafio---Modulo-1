-- 02 - Carga dos CSVs na staging (psql)
-- Rode o psql DENTRO da pasta onde estao os 3 CSVs (os caminhos abaixo sao relativos).
-- \copy le o arquivo no computador de quem roda o psql (nao precisa de permissao no servidor).
-- Cada \copy tem que ficar em UMA linha, sem ponto e virgula no final.

TRUNCATE stg.neighbourhoods, stg.listings, stg.reviews;

\copy stg.neighbourhoods FROM 'neighbourhoods.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.listings FROM 'listings.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.reviews FROM 'reviews.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Alternativa sem psql (ex.: DBeaver/pgAdmin com o arquivo no servidor), com caminho absoluto:
--   COPY stg.listings FROM '/caminho/no/servidor/listings.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
-- Em CSV, campo vazio vira NULL automaticamente.

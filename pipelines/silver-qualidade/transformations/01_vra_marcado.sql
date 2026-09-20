-- ========================================================================
-- VRA Marcado: Enriquecimento dos dados de VRA com flags de validação
-- ========================================================================
-- Esta view temporária marca cada voo com indicadores booleanos que
-- identificam se origem, destino e empresa estão cadastrados nos registros
-- de referência (aeródromos e empresas). Também calcula atrasos em minutos.
-- ========================================================================

CREATE TEMPORARY VIEW vra_marcado AS
WITH 
-- CTE 1: Lista de todos os aeródromos válidos cadastrados
aerodromo AS (
  SELECT DISTINCT codigo_oaci as icao FROM voe_bem.bronze.aerodromos
  WHERE codigo_oaci IS NOT NULL AND codigo_oaci <> ''
),

-- CTE 2: Lista de todas as empresas válidas (nacionais + estrangeiras)
empresa AS (
  SELECT DISTINCT icao FROM voe_bem.bronze.empresas_nacionais
  WHERE icao IS NOT NULL AND icao <> ''
  UNION
  SELECT DISTINCT icao FROM voe_bem.bronze.empresas_estrangeiras
  WHERE icao IS NOT NULL AND icao <> ''
)

-- Query principal: Enriquece os dados de VRA com flags de validação e cálculo de atrasos
SELECT
  v.*,
  
  -- Flags booleanas: indicam se os códigos ICAO existem nos cadastros
  (ao.icao IS NOT NULL) AS origem_no_cadastro,
  (ad.icao IS NOT NULL) AS destino_no_cadastro,
  (em.icao IS NOT NULL) AS empresa_no_cadastro,
  
  -- Cálculo de atraso na PARTIDA (em minutos)
  -- Resultado positivo = atraso | Resultado negativo = adiantamento
  CASE
    WHEN v.partida_real IS NOT NULL AND v.partida_prevista IS NOT NULL
    THEN CAST((unix_timestamp(v.partida_real) - unix_timestamp(v.partida_prevista)) / 60 AS INT)
  END AS atraso_partida_min,
  
  -- Cálculo de atraso na CHEGADA (em minutos)
  -- Resultado positivo = atraso | Resultado negativo = adiantamento
  CASE
    WHEN v.chegada_real IS NOT NULL AND v.chegada_prevista IS NOT NULL
    THEN CAST((unix_timestamp(v.chegada_real) - unix_timestamp(v.chegada_prevista)) / 60 AS INT)
  END AS atraso_chegada_min
  
FROM voe_bem.bronze.vra v
-- LEFT JOIN para preservar todos os voos, mesmo aqueles com códigos inválidos
LEFT JOIN aerodromo ao ON v.icao_aerodromo_origem = ao.icao
LEFT JOIN aerodromo ad ON v.icao_aerodromo_destino = ad.icao
LEFT JOIN empresa   em ON v.icao_empresa_aerea = em.icao;
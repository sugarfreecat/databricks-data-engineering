-- ========================================================================
-- VRA Quarentena: Registros Problemáticos para Análise Diagnóstica
-- ========================================================================
-- Esta view materializa APENAS os registros que violaram pelo menos UMA
-- expectation do contrato de qualidade (vra_auditado).
--
-- PROPÓSITO:
--   - Isolar registros problemáticos para investigação
--   - Documentar QUAIS regras cada registro violou
--   - Facilitar análise de causa raiz
--   - Permitir correção/enriquecimento retroativo se necessário
--
-- IMPORTANTE:
--   - Estes registros NÃO sobem para a camada gold
--   - São mantidos para auditoria e diagnóstico
--   - A coluna 'motivos_quarentena' lista todas as violações
-- ========================================================================

CREATE OR REFRESH MATERIALIZED VIEW vra_quarentena
COMMENT 'Silver quarentena - espelho DIAGNOSTICO dos registros de silver.vra que reprovaram em alguma expectation do contrato de dados, com o motivo por registro. NAO e filtro: silver.vra permanece com a contagem original. A decisao de excluir ou nao cada categoria e de negocio e acontece na gold.'
AS
SELECT
  *,
  
  -- ===================================================================
  -- Coluna diagnóstica: Lista de TODAS as violações para este registro
  -- ===================================================================
  -- Concatena os nomes das constraints violadas, separadas por ' | '
  -- Exemplo: "HORARIOS_FALTANTES | EMPRESA_INVALIDA | ATRASO_IMPLAUSIVE"
  
  CONCAT_WS(' | ',
    
    -- GRUPO 1: COMPLETUDE
    CASE 
      WHEN partida_prevista IS NULL OR chegada_prevista IS NULL 
      THEN 'HORARIOS_PREVISTOS_FALTANTES'
    END,
    
    CASE 
      WHEN situacao_voo NOT IN ('REALIZADO', 'CANCELADO') OR situacao_voo IS NULL
      THEN 'SITUACAO_VOO_DESCONHECIDA'
    END,
    
    -- GRUPO 2: COERÊNCIA TEMPORAL
    CASE 
      WHEN partida_prevista IS NOT NULL 
           AND chegada_prevista IS NOT NULL 
           AND chegada_prevista <= partida_prevista
      THEN 'CHEGADA_PREVISTA_ANTES_DA_PARTIDA_PREVISTA'
    END,
    
    CASE 
      WHEN partida_real IS NOT NULL 
           AND chegada_real IS NOT NULL 
           AND chegada_real <= partida_real
      THEN 'CHEGADA_REAL_ANTES_DA_PARTIDA_REAL'
    END,
    
    -- GRUPO 3: PLAUSIBILIDADE
    CASE 
      WHEN atraso_partida_min IS NOT NULL 
           AND (atraso_partida_min < -120 OR atraso_partida_min > 1440)
      THEN 'ATRASO_PARTIDA_IMPLAUSIVEL'
    END,
    
    CASE 
      WHEN atraso_chegada_min IS NOT NULL 
           AND (atraso_chegada_min < -120 OR atraso_chegada_min > 1440)
      THEN 'ATRASO_CHEGADA_IMPLAUSIVEL'
    END,
    
    -- GRUPO 4: INTEGRIDADE REFERENCIAL
    CASE 
      WHEN NOT empresa_no_cadastro
      THEN 'EMPRESA_NAO_CADASTRADA_ANAC'
    END,
    
    CASE 
      WHEN NOT origem_no_cadastro
      THEN 'AEROPORTO_ORIGEM_NAO_CADASTRADO_ANAC'
    END,
    
    CASE 
      WHEN NOT destino_no_cadastro
      THEN 'AEROPORTO_DESTINO_NAO_CADASTRADO_ANAC'
    END
    
  ) AS motivos_quarentena
  
FROM vra_auditado

-- ===================================================================
-- FILTRO: Apenas registros com PELO MENOS UMA violação
-- ===================================================================
WHERE 
  -- COMPLETUDE
  (partida_prevista IS NULL OR chegada_prevista IS NULL)
  OR (situacao_voo NOT IN ('REALIZADO', 'CANCELADO') OR situacao_voo IS NULL)
  
  -- COERÊNCIA TEMPORAL
  OR (partida_prevista IS NOT NULL 
      AND chegada_prevista IS NOT NULL 
      AND chegada_prevista <= partida_prevista)
  OR (partida_real IS NOT NULL 
      AND chegada_real IS NOT NULL 
      AND chegada_real <= partida_real)
  
  -- PLAUSIBILIDADE
  OR (atraso_partida_min IS NOT NULL 
      AND (atraso_partida_min < -120 OR atraso_partida_min > 1440))
  OR (atraso_chegada_min IS NOT NULL 
      AND (atraso_chegada_min < -120 OR atraso_chegada_min > 1440))
  
  -- INTEGRIDADE REFERENCIAL
  OR NOT empresa_no_cadastro
  OR NOT origem_no_cadastro
  OR NOT destino_no_cadastro;
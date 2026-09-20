-- ========================================================================
-- VRA Auditado: Contrato de Qualidade de Dados (Data Quality Contract)
-- ========================================================================
-- Esta materialized view implementa um conjunto de expectations (constraints)
-- que auditam a qualidade dos dados de voo sem DESCARTAR registros.
-- 
-- IMPORTANTE: Todas as constraints estão em modo WARN (padrão), o que significa:
--   - Violações são REGISTRADAS mas NÃO bloqueiam a pipeline
--   - Linhas problemáticas são MANTIDAS na view
--   - Métricas de qualidade ficam disponíveis para monitoramento
-- 
-- Este padrão permite:
--   1. Medir a qualidade dos dados de forma contínua
--   2. Identificar padrões de problemas ao longo do tempo
--   3. Manter o fluxo de dados mesmo com problemas
--   4. Tomar decisões de negócio sobre quais registros usar
-- ========================================================================

CREATE OR REFRESH MATERIALIZED VIEW vra_auditado (
  -- ===================================================================
  -- GRUPO 1: COMPLETUDE (Completeness)
  -- ===================================================================
  -- Verifica se campos essenciais estão preenchidos
  
  -- Horários previstos são obrigatórios para análises de pontualidade
  CONSTRAINT horarios_previstos_presentes
    EXPECT (partida_prevista IS NOT NULL AND chegada_prevista IS NOT NULL),
  
  -- Situação do voo deve estar em um domínio conhecido
  CONSTRAINT situacao_voo_conhecida
    EXPECT (situacao_voo IN ('REALIZADO', 'CANCELADO')),
  
  -- ===================================================================
  -- GRUPO 2: COERÊNCIA TEMPORAL (Temporal Consistency)
  -- ===================================================================
  -- Valida a lógica temporal: chegadas devem ocorrer APÓS partidas
  -- NULL é explicitamente aprovado (voos cancelados podem não ter horários reais)
  
  -- Previsto: chegada prevista deve ser posterior à partida prevista
  CONSTRAINT chegada_prevista_depois_da_partida_prevista
    EXPECT (partida_prevista IS NULL OR chegada_prevista IS NULL
            OR chegada_prevista > partida_prevista),
  
  -- Real: chegada real deve ser posterior à partida real
  CONSTRAINT chegada_real_depois_da_partida_real
    EXPECT (partida_real IS NULL OR chegada_real IS NULL
            OR chegada_real > partida_real),
  
  -- ===================================================================
  -- GRUPO 3: PLAUSIBILIDADE (Plausibility / Range Validation)
  -- ===================================================================
  -- Define limites razoáveis para atrasos/adiantamentos
  -- Faixa: -120 min (-2h de antecipação) até +1440 min (+24h de atraso)
  -- Valores fora desta faixa indicam possíveis erros de dados
  
  -- Atraso na partida deve estar dentro da faixa aceitável
  -- Negativo = adiantamento | Positivo = atraso
  CONSTRAINT atraso_partida_plausivel
    EXPECT (atraso_partida_min IS NULL
            OR atraso_partida_min BETWEEN -120 AND 1440),
  
  -- Atraso na chegada deve estar dentro da faixa aceitável
  -- Negativo = adiantamento | Positivo = atraso
  CONSTRAINT atraso_chegada_plausivel
    EXPECT (atraso_chegada_min IS NULL
            OR atraso_chegada_min BETWEEN -120 AND 1440),
  
  -- ===================================================================
  -- GRUPO 4: INTEGRIDADE REFERENCIAL (Referential Integrity)
  -- ===================================================================
  -- Valida se os códigos ICAO existem nos cadastros da ANAC
  -- As flags booleanas (TRUE/FALSE) foram criadas no passo anterior (vra_marcado)
  -- via LEFT JOIN com as tabelas de referência (aerodromos e empresas)
  
  -- Empresa aérea deve existir no cadastro da ANAC
  CONSTRAINT empresa_no_cadastro_anac
    EXPECT (empresa_no_cadastro),
  
  -- Aeroporto de origem deve existir no cadastro da ANAC
  CONSTRAINT aeroporto_origem_no_cadastro_anac
    EXPECT (origem_no_cadastro),
  
  -- Aeroporto de destino deve existir no cadastro da ANAC
  CONSTRAINT aeroporto_destino_no_cadastro_anac
    EXPECT (destino_no_cadastro)
)
-- Documentação da view
COMMENT 'Contrato de dados de silver.vra. Move expectations, todas em modo warn: medem qualidade sem descartar linha. A view serve como input do gold'
-- Seleciona TODOS os dados de vra_marcado (incluindo as flags e cálculos de atraso)
AS SELECT * FROM vra_marcado;
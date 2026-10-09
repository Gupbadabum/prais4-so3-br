# ============================================================
# PRAIS4 - SO3.3
# VULNERABILIDADE A SECA
# ORQUESTRADOR PRINCIPAL
# ============================================================
#
# Executar a partir da raiz do repositorio:
#
#   prais4-so3-br/
#
# ============================================================


# ============================================================
# 0. PACOTES
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop(
    "O pacote 'data.table' e necessario para o processamento."
  )
}


# ============================================================
# 1. CONFIGURACAO
# ============================================================

source(
  "so3.3/config/config.R"
)

source(
  "so3.3/config/config_local.R"
)


# ============================================================
# 2. FUNCOES DE LEITURA E HARMONIZACAO
# ============================================================

source(
  "so3.3/R/01_leitura/adaptar_censo_2022.R"
)

source(
  "so3.3/R/02_indicadores/social.R"
)

source(
  "so3.3/R/03_diagnostico/diagnostico_indicadores.R"
)

# ============================================================
# 3. PREPARACAO DAS FONTES
# ============================================================

# ------------------------------------------------------------
# Censo Demografico 2022
# ------------------------------------------------------------

censo_2022 <- preparar_censo_2022()

# ============================================================
# 5. DIMENSAO SOCIAL
# CENSO DEMOGRAFICO 2022
# ============================================================

# ------------------------------------------------------------
# Processamento nacional
#
# Cada UF e:
#
#   1. lida;
#   2. adaptada para a estrutura canonica;
#   3. transformada em indicadores municipais;
#   4. reduzida ao resultado agregado.
#
# Os microdados das 27 UFs nao permanecem simultaneamente
# em memoria.
# ------------------------------------------------------------

social_2022 <- data.table::rbindlist(
  lapply(
    censo_2022$arquivos,
    function(arq) {

      message(
        "Processando Social 2022: ",
        basename(arq)
      )

      dados_uf <- adaptar_censo_2022(
        arq
      )

      resultado_uf <- calcular_social_direto(
        dados_uf
      )

      rm(dados_uf)

      return(
        resultado_uf
      )
    }
  ),
  use.names = TRUE,
  fill = TRUE
)


# ------------------------------------------------------------
# Ordenacao
# ------------------------------------------------------------

data.table::setorder(
  social_2022,
  indicador,
  cod_mun,
  grupo
)

# ============================================================
# DIAGNOSTICO - SOCIAL 2022
# ============================================================

diagnostico_social_2022 <- diagnosticar_indicadores(
  social_2022,
  n_extremos = 10L
)


# ------------------------------------------------------------
# Controle especifico dos indicadores percentuais
# ------------------------------------------------------------

problemas_intervalo_social_2022 <-
  verificar_intervalo_indicadores(
    social_2022,
    indicadores = c(
      "SOC01_ALF15",
      "SOC02_RURAL",
      "SOC04_POP1564"
    ),
    minimo = 0,
    maximo = 100
  )


# ------------------------------------------------------------
# Portas de controle
# ------------------------------------------------------------

if (
  nrow(
    diagnostico_social_2022$duplicidades
  ) > 0L
) {

  stop(
    "Foram encontradas duplicidades na base Social 2022."
  )
}


if (
  nrow(
    diagnostico_social_2022$
      problemas_consistencia_sexo
  ) > 0L
) {

  warning(
    "Foram encontradas inconsistencias entre Total, ",
    "Masculino e Feminino na base Social 2022."
  )
}


if (
  nrow(
    problemas_intervalo_social_2022
  ) > 0L
) {

  warning(
    "Foram encontrados valores ausentes ou fora de ",
    "[0,100] nos indicadores sociais percentuais de 2022."
  )
}


# ============================================================
# 6. DIMENSAO ECONOMICA
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 7. DIMENSAO INFRAESTRUTURAL
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 8. CONSOLIDACAO DOS INDICADORES
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 9. DIAGNOSTICO
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 10. TRATAMENTO ESTATISTICO
# ============================================================
#
# Winsorizacao
# Box-Cox
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 11. NORMALIZACAO
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 12. COMPONENTES DAS DIMENSOES
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 13. DVI
# ============================================================
#
# Ainda nao implementado.
# ============================================================


# ============================================================
# 14. EXPORTACAO
# ============================================================
#
# Ainda nao implementado.
# ============================================================

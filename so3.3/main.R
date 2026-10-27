# ============================================================
# PRAIS4 - SO3.3
# VULNERABILIDADE A SECA
# ORQUESTRADOR PRINCIPAL
# ============================================================
#
# Filosofia operacional:
#
#   uma execucao = uma dimensao + um ano
#
# Exemplo, a partir da raiz do repositorio:
#
#   DIMENSAO_ATIVA <- "social"
#   ANO_ATIVO <- 2010L
#   source("so3.3/main.R")
#
# O processamento censitario gera produtos brutos e
# intermediarios com checkpoints em disco. Winsorizacao e
# Box-Cox pertencem a uma etapa posterior, quando os tres
# recortes temporais ja estiverem reduzidos a bases municipais.
#
# ============================================================


# ============================================================
# 0. SELECAO DA EXECUCAO
# ============================================================

if (!exists("DIMENSAO_ATIVA", inherits = TRUE)) {
  stop(
    "Defina DIMENSAO_ATIVA antes de executar o main.R. ",
    "Exemplo: DIMENSAO_ATIVA <- 'social'"
  )
}

if (!exists("ANO_ATIVO", inherits = TRUE)) {
  stop(
    "Defina ANO_ATIVO antes de executar o main.R. ",
    "Exemplo: ANO_ATIVO <- 2010L"
  )
}

DIMENSAO_ATIVA <-
  tolower(
    trimws(
      as.character(
        DIMENSAO_ATIVA
      )
    )
  )

ANO_ATIVO <-
  as.integer(
    ANO_ATIVO
  )

if (!exists("FORCAR_RECALCULO", inherits = TRUE)) {
  FORCAR_RECALCULO <- FALSE
}

FORCAR_RECALCULO <-
  isTRUE(
    FORCAR_RECALCULO
  )


# ============================================================
# 1. DEPENDENCIAS BASICAS
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop(
    "O pacote 'data.table' e necessario para o processamento."
  )
}


# ============================================================
# 2. CONFIGURACAO
# ============================================================

source(
  "so3.3/config/config.R"
)

# config_local.R contem somente caminhos/ajustes da maquina.
# Ele e opcional para execucoes que nao dependam de arquivos
# locais, como a leitura 2010 via censobr.

ARQ_CONFIG_LOCAL <-
  "so3.3/config/config_local.R"

if (file.exists(ARQ_CONFIG_LOCAL)) {
  source(
    ARQ_CONFIG_LOCAL
  )
}


# ============================================================
# 3. VALIDACAO DA CHAMADA
# ============================================================

if (!DIMENSAO_ATIVA %in% DIMENSOES_DVI) {
  stop(
    "Dimensao invalida: ",
    DIMENSAO_ATIVA,
    ". Permitidas: ",
    paste(
      DIMENSOES_DVI,
      collapse = ", "
    )
  )
}

if (!ANO_ATIVO %in% ANOS_DVI) {
  stop(
    "Ano invalido: ",
    ANO_ATIVO,
    ". Permitidos: ",
    paste(
      ANOS_DVI,
      collapse = ", "
    )
  )
}


message(
  "PRAIS4 SO3.3 | dimensao = ",
  DIMENSAO_ATIVA,
  " | ano = ",
  ANO_ATIVO,
  " | forcar_recalculo = ",
  FORCAR_RECALCULO
)


# ============================================================
# 4. DIMENSAO SOCIAL
# ============================================================

if (DIMENSAO_ATIVA == "social") {

  source(
    "so3.3/R/02_indicadores/social.R"
  )

  source(
    "so3.3/R/03_diagnostico/diagnostico_indicadores.R"
  )

  source(
    "so3.3/R/02_indicadores/expectativa_vida_indireta.R"
  )


  # ----------------------------------------------------------
  # Dependencias obrigatorias para o SOC03 completo
  # ----------------------------------------------------------

  ARQ_ESTABILIZACAO_Q5_EB <-
    "so3.3/R/02_indicadores/estabilizacao_q5_eb.R"

  if (!file.exists(ARQ_ESTABILIZACAO_Q5_EB)) {
    stop(
      "SOC03: modulo de estabilizacao EB ausente: ",
      ARQ_ESTABILIZACAO_Q5_EB
    )
  }

  source(ARQ_ESTABILIZACAO_Q5_EB)

  source(
    "so3.3/R/02_indicadores/preparar_referencias_soc03.R"
  )

  source(
    "so3.3/R/02_indicadores/converter_soc03_ev0.R"
  )

  source(
    "so3.3/R/05_exportacao/exportar_resultados_csv.R"
  )


  # ----------------------------------------------------------
  # Adaptador especifico do recorte censitario
  # ----------------------------------------------------------

  if (ANO_ATIVO == 2000L) {

    source(
      "so3.3/R/01_leitura/adaptar_censo_2000.R"
    )
  }


  if (ANO_ATIVO == 2010L) {

    source(
      "so3.3/R/01_leitura/adaptar_censo_2010.R"
    )
  }


  if (ANO_ATIVO == 2022L) {

    source(
      "so3.3/R/01_leitura/adaptar_censo_2022.R"
    )
  }

  source(
    "so3.3/R/04_execucao/processar_social.R"
  )


  # ----------------------------------------------------------
  # 1. Insumos censitarios + SOC01, SOC02, SOC04 + Brass/EB
  # ----------------------------------------------------------

  resultado_execucao <-
    processar_dimensao_social(
      ano = ANO_ATIVO,
      executar_soc03 = TRUE,
      executar_eb = TRUE,
      forcar_recalculo = FORCAR_RECALCULO
    )

  # ----------------------------------------------------------
  # 2. Referencias West/IBGE (reutilizadas quando atualizadas)
  # ----------------------------------------------------------

  message("SOC03 | Preparando referencias West/IBGE...")
  preparar_referencias_soc03(forcar = FALSE)

  # ----------------------------------------------------------
  # 3. Conversao municipal final q(5) EB -> e0 (T/M/F)
  #
  # Sem fallback: uma etapa ausente ou invalida interrompe
  # a execucao, em vez de concluir uma Social incompleta.
  # ----------------------------------------------------------

  message("SOC03 | Produzindo expectativa de vida municipal...")
  produzir_soc03_ev0(
    ano = ANO_ATIVO,
    dir_intermediario = DIR_OUTPUT_INTERMEDIARIO,
    dir_bruto = DIR_OUTPUT_BRUTO,
    forcar = FORCAR_RECALCULO
  )

  # ----------------------------------------------------------
  # 4. CSVs dos quatro indicadores (inclui nomes IBGE 2025)
  # ----------------------------------------------------------

  message("Social | Exportando indicadores municipais em CSV...")
  resultado_exportacao <-
    exportar_social_bruto_csv(
      ano = ANO_ATIVO,
      dir_bruto = DIR_OUTPUT_BRUTO,
      sobrescrever = FORCAR_RECALCULO
    )

  message(
    "Execucao integral concluida: Social ",
    ANO_ATIVO,
    " (SOC01, SOC02, SOC03, SOC04 e CSVs)."
  )
}


# ============================================================
# 5. DIMENSAO ECONOMICA
# ============================================================

if (DIMENSAO_ATIVA == "economica") {

  # Filosofia de execucao: uma dimensao + um ano.
  # ECO01, ECO02 e ECO03 sao processados/validados conjuntamente
  # no ano PRAIS selecionado; indicadores individuais mantem
  # seus processadores proprios para testes e manutencao.
  #
  # INDICADOR_ECONOMICO_ATIVO nao e mais utilizado no main.R.
  # A execucao integrada nao sobrescreve resultados divergentes.

  source(
    "so3.3/R/04_execucao/processar_dimensao_economica.R"
  )

  resultado_execucao <- processar_dimensao_economica(
    ano = ANO_ATIVO,
    forcar_recalculo = FORCAR_RECALCULO
  )

  if (!isTRUE(resultado_execucao$integral)) {
    stop(
      "Economica: execucao nao foi concluida integralmente em ",
      ANO_ATIVO, "."
    )
  }

  resultado_exportacao <- resultado_execucao$exportacao
  resultado_validacao_economica <- resultado_execucao$resumo

  message(
    "Execucao integral concluida: Economica ", ANO_ATIVO,
    " (ECO01, ECO02, ECO03 e tres CSVs municipais validados)."
  )
}


# ============================================================
# 6. DIMENSAO INFRAESTRUTURAL - INF01
# ============================================================

if (DIMENSAO_ATIVA == "infraestrutural") {

  # A integracao atual cobre SOMENTE INF01: acesso a rede geral
  # como fonte principal, com canalizacao interna (Total/Masc/Fem).
  # Outros indicadores infraestruturais nao estao integrados.
  #
  # Os processadores ja validados preservam checkpoints e produtos
  # divergentes; a execucao pelo main.R nao autoriza recalculo
  # destrutivo nem altera os resultados municipais aprovados.

  if (FORCAR_RECALCULO) {
    stop(
      "INF01: FORCAR_RECALCULO=TRUE nao e permitido no main.R. ",
      "Os processadores de producao nao sobrescrevem resultados."
    )
  }

  ARQ_PROCESSADOR_INF01 <- switch(
    as.character(ANO_ATIVO),
    "2000" = "so3.3/R/04_execucao/processar_inf01.R",
    "2010" = "so3.3/R/04_execucao/processar_inf01_2010.R",
    "2022" = "so3.3/R/04_execucao/processar_inf01_2022.R"
  )

  if (is.null(ARQ_PROCESSADOR_INF01) ||
      !file.exists(ARQ_PROCESSADOR_INF01)) {
    stop(
      "INF01/", ANO_ATIVO, ": processador nao encontrado: ",
      ARQ_PROCESSADOR_INF01,
      ". Versione os modulos do indicador antes de executar."
    )
  }

  source(ARQ_PROCESSADOR_INF01)

  resultado_execucao <- switch(
    as.character(ANO_ATIVO),
    "2000" = processar_inf01(
      ano = ANO_ATIVO,
      promover = TRUE,
      forcar_recalculo = FALSE
    ),
    "2010" = processar_inf01_2010(
      promover = TRUE,
      forcar_recalculo = FALSE,
      origem = "teste12"
    ),
    "2022" = processar_inf01_2022(
      promover = TRUE,
      forcar_recalculo = FALSE,
      origem = "teste18"
    )
  )

  STATUS_INF01_VALIDOS <- c(
    "bruto_gravado_validado",
    "bruto_reutilizado_validado"
  )

  if (!is.list(resultado_execucao) ||
      !isTRUE(resultado_execucao$integral) ||
      length(resultado_execucao$status) != 1L ||
      is.na(resultado_execucao$status) ||
      !resultado_execucao$status %in% STATUS_INF01_VALIDOS) {
    stop(
      "INF01/", ANO_ATIVO,
      ": execucao sem promocao integral e validada."
    )
  }

  resultado_exportacao <- resultado_execucao$arquivo_bruto_csv

  message(
    "Execucao concluida: Infraestrutural ", ANO_ATIVO,
    " / INF01 (Total, Masculino e Feminino). ",
    "A dimensao Infraestrutural completa ainda nao foi integrada."
  )
}

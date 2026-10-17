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

  # ECO01 implementado. ECO02 e ECO03 ainda nao integram
  # o dispatcher economico.
  source(
    "so3.3/R/02_indicadores/preparar_referencias_eco01.R"
  )
  source(
    "so3.3/R/02_indicadores/eco01_pobreza.R"
  )
  source(
    "so3.3/R/05_exportacao/exportar_resultados_csv.R"
  )

  # Um adaptador e um processador por recorte censitario.
  if (ANO_ATIVO == 2000L) {
    source("so3.3/R/01_leitura/adaptar_censo_2000_economica.R")
    source("so3.3/R/04_execucao/processar_eco01_2000.R")

    resultado_execucao <- processar_eco01_2000(
      forcar_recalculo = FORCAR_RECALCULO
    )
  }

  if (ANO_ATIVO == 2010L) {
    source("so3.3/R/01_leitura/adaptar_censo_2010_economica.R")
    source("so3.3/R/04_execucao/processar_eco01_2010.R")

    resultado_execucao <- processar_eco01_2010(
      forcar_recalculo = FORCAR_RECALCULO
    )
  }

  if (ANO_ATIVO == 2022L) {
    source("so3.3/R/01_leitura/adaptar_censo_2022_economica.R")
    source("so3.3/R/04_execucao/processar_eco01_2022.R")

    resultado_execucao <- processar_eco01_2022(
      forcar_recalculo = FORCAR_RECALCULO
    )
  }

  if (!isTRUE(resultado_execucao$integral)) {
    stop("ECO01: processamento nacional incompleto; CSV nao sera gerado.")
  }

  # Rele o produto nacional RDS e sua auditoria, valida
  # municipio/grupo, e confere a leitura do CSV produzido.
  # Um CSV existente so e reutilizado se for identico ao RDS.
  resultado_exportacao <- exportar_eco01_bruto_csv(
    ano = ANO_ATIVO,
    dir_bruto = DIR_OUTPUT_BRUTO,
    dir_intermediario = DIR_OUTPUT_INTERMEDIARIO
  )

  resultado_validacao_eco01 <- NULL
  arquivos_csv_eco01 <- file.path(
    DIR_OUTPUT_BRUTO,
    "economica",
    as.character(ANOS_DVI),
    paste0("ECO01_POV3_PPC21_", ANOS_DVI, ".csv")
  )

  if (all(file.exists(arquivos_csv_eco01))) {
    message("ECO01 | Conferindo conjuntamente 2000, 2010 e 2022...")
    resultado_validacao_eco01 <- validar_eco01_tres_recortes_csv(
      dir_bruto = DIR_OUTPUT_BRUTO,
      dir_intermediario = DIR_OUTPUT_INTERMEDIARIO
    )
    message("ECO01 | Integracao dos tres recortes validada.")
  } else {
    message(
      "ECO01 | Validacao conjunta pendente. CSVs ainda ausentes: ",
      paste(basename(arquivos_csv_eco01[
        !file.exists(arquivos_csv_eco01)
      ]), collapse = ", ")
    )
  }

  message(
    "Execucao concluida: Economica ", ANO_ATIVO,
    " (somente ECO01_POV3_PPC21 e CSV bruto)."
  )
}


# ============================================================
# 6. DIMENSAO INFRAESTRUTURAL
# ============================================================

if (DIMENSAO_ATIVA == "infraestrutural") {

  stop(
    "A dimensao Infraestrutural ainda nao foi migrada para o ",
    "dispatcher por dimensao + ano."
  )
}

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
    "so3.3/R/02_indicadores/expectativa_vida_indireta.R"
  )


  # ----------------------------------------------------------
  # Estabilizacao q(5) EB
  #
  # O arquivo pode existir apenas na arvore local durante a
  # transicao. Quando presente, ele e carregado e o executor
  # produz automaticamente os checkpoints do EB.
  # ----------------------------------------------------------

  ARQ_ESTABILIZACAO_Q5_EB <-
    "so3.3/R/02_indicadores/estabilizacao_q5_eb.R"

  if (file.exists(ARQ_ESTABILIZACAO_Q5_EB)) {

    source(
      ARQ_ESTABILIZACAO_Q5_EB
    )

  } else {

    warning(
      "Arquivo de estabilizacao q(5) EB nao encontrado. ",
      "A execucao seguira ate Brass-Trussell e preservara ",
      "os checkpoints disponiveis."
    )
  }


  # ----------------------------------------------------------
  # Adaptador especifico do recorte censitario
  # ----------------------------------------------------------

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


  # 2000 sera habilitado somente quando seu adaptador for
  # migrado e validado na nova arquitetura.


  source(
    "so3.3/R/04_execucao/processar_social.R"
  )


  resultado_execucao <-
    processar_dimensao_social(
      ano = ANO_ATIVO,
      executar_soc03 = TRUE,
      executar_eb = TRUE,
      forcar_recalculo = FORCAR_RECALCULO
    )


  message(
    "Execucao concluida: Social ",
    ANO_ATIVO,
    "."
  )
}


# ============================================================
# 5. DIMENSAO ECONOMICA
# ============================================================

if (DIMENSAO_ATIVA == "economica") {

  stop(
    "A dimensao Economica ainda nao foi migrada para o ",
    "dispatcher por dimensao + ano."
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

#!/usr/bin/env Rscript

# ============================================================
# PRAIS4 / SO3.3 / INF02 - ETAPA 03
# EXECUTOR
# ============================================================
#
# Executar a partir da raiz do repositorio:
#
# RSCRIPT so3.3/executar_inf02_etapa03.R completo
#
# Promocao opcional aos produtos brutos:
#
# RSCRIPT so3.3/executar_inf02_etapa03.R completo promover
#
# ============================================================


args <- commandArgs(
  trailingOnly = TRUE
)

modo <- if (length(args)) {
  tolower(args[[1L]])
} else {
  "completo"
}

if (!modo %in% c(
  "2000",
  "2010",
  "2022",
  "completo"
)) {
  stop(
    "INF02/E03: use 2000, 2010, 2022 ou completo."
  )
}


# ------------------------------------------------------------
# Controle da promocao
# ------------------------------------------------------------

promover <-
  length(args) >= 2L &&
  identical(
    tolower(args[[2L]]),
    "promover"
  )

if (
  length(args) > 2L ||
  (
    length(args) == 2L &&
      !promover
  )
) {
  stop(
    "INF02/E03: segundo argumento opcional ",
    "deve ser 'promover'."
  )
}


# ------------------------------------------------------------
# Configuracao
# ------------------------------------------------------------

source(
  "so3.3/config/config.R"
)

if (
  file.exists(
    "so3.3/config/config_local.R"
  )
) {
  source(
    "so3.3/config/config_local.R"
  )
}


# ------------------------------------------------------------
# Processador
# ------------------------------------------------------------

source(
  "so3.3/R/04_execucao/processar_inf02_etapa03.R"
)


# ------------------------------------------------------------
# Selecionar anos
# ------------------------------------------------------------

anos <- if (modo == "completo") {
  c(2000L, 2010L, 2022L)
} else {
  as.integer(modo)
}


# ------------------------------------------------------------
# Execucao
# ------------------------------------------------------------

qa <- processar_inf02_etapa03(
  anos = anos,
  promover = promover
)

print(qa)

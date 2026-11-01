#!/usr/bin/env Rscript
# PRAIS4/SO3.3 | Entrada operacional da Etapa 01 INF02.
# Execute da raiz do repositorio prais4-so3-br.
#
# RSCRIPT so3.3/executar_inf02_etapa01.R [INFO2] [shp_municipios] [DF|completo]
# Os argumentos 1 e 2 tambem podem ser declarados em config_local.R:
#   DIR_INF02_PREPARACAO
#   ARQ_INF02_MUNICIPIOS_2025_SHP

args <- commandArgs(trailingOnly = TRUE)
source("so3.3/config/config.R")
if (file.exists("so3.3/config/config_local.R")) {
  source("so3.3/config/config_local.R")
}

definir_insumos <- function() {
  if (length(args) >= 1L && nzchar(args[[1L]])) return(args[[1L]])
  if (exists("DIR_INF02_PREPARACAO", inherits = TRUE)) {
    return(get("DIR_INF02_PREPARACAO", inherits = TRUE))
  }
  if (dir.exists("INFO2")) return("INFO2")
  stop("Defina DIR_INF02_PREPARACAO em config_local.R ou passe INFO2 no argumento 1.")
}

definir_municipios <- function() {
  if (length(args) >= 2L && nzchar(args[[2L]])) return(args[[2L]])
  if (exists("ARQ_INF02_MUNICIPIOS_2025_SHP", inherits = TRUE)) {
    return(get("ARQ_INF02_MUNICIPIOS_2025_SHP", inherits = TRUE))
  }
  stop("Defina ARQ_INF02_MUNICIPIOS_2025_SHP ou passe shapefile no argumento 2.")
}

escopo <- if (length(args) >= 3L) toupper(args[[3L]]) else "DF"
if (identical(escopo, "COMPLETO")) {
  modo <- "completo"
  uf <- "DF"
} else {
  modo <- "uf"
  uf <- escopo
}

source("so3.3/R/04_execucao/processar_inf02_municipalizacao.R")
resultado_inf02_e01 <- processar_inf02_municipalizacao(
  dir_insumos = definir_insumos(),
  arquivo_municipios = definir_municipios(),
  dir_saida = file.path(DIR_OUTPUT_INTERMEDIARIO,
                        "infraestrutural", "inf02", "etapa01"),
  modo = modo,
  uf_alvo = uf
)
print(resultado_inf02_e01)

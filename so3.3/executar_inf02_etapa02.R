#!/usr/bin/env Rscript
# PRAIS4/SO3.3 | INF02 | Etapa 02 - Populacao total censitaria.
# Execute desde a raiz do repositorio prais4-so3-br:
#   RSCRIPT so3.3/executar_inf02_etapa02.R 2022
#   RSCRIPT so3.3/executar_inf02_etapa02.R completo

args <- commandArgs(trailingOnly = TRUE)
modo <- if (length(args)) tolower(args[[1L]]) else "2022"
if (!modo %in% c("2000", "2010", "2022", "completo")) {
  stop("Use 2000, 2010, 2022 ou completo.")
}
source("so3.3/config/config.R")
if (file.exists("so3.3/config/config_local.R")) {
  source("so3.3/config/config_local.R")
}
source("so3.3/R/04_execucao/processar_inf02_etapa02.R")
anos <- if (modo == "completo") c(2000L, 2010L, 2022L) else as.integer(modo)
resultado_inf02_e02 <- processar_inf02_etapa02(
  anos = anos,
  arquivo_hidrologico = file.path(
    DIR_OUTPUT_INTERMEDIARIO, "infraestrutural", "inf02", "etapa01",
    "INF02_E01_contribuicao_incremental_municipal_IBGE2025.rds"),
  dir_saida = file.path(DIR_OUTPUT_INTERMEDIARIO, "infraestrutural",
                        "inf02", "etapa02"))
print(resultado_inf02_e02)

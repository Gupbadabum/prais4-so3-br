# ============================================================
# PRAIS4 - SO3.3
# CONFIGURACAO DO PROJETO
# ============================================================
#
# Arquivos:
#   config/config.R
#       Configuracoes versionaveis e independentes da maquina.
#
# ============================================================

# ============================================================
# ARQUIVO: config/config.R
# ============================================================

# ------------------------------------------------------------
# Recortes temporais do DVI
# ------------------------------------------------------------

ANOS_DVI <- c(
  2000L,
  2010L,
  2022L
)


# ------------------------------------------------------------
# Grupos populacionais
# ------------------------------------------------------------

GRUPOS_DVI <- c(
  "Total",
  "Masculino",
  "Feminino"
)


# ------------------------------------------------------------
# Diretorios internos ao modulo SO3.3
#
# O main.R deve ser executado a partir da raiz:
#
#   prais4-so3-br/
#
# ------------------------------------------------------------

DIR_SO33 <- "so3.3"

DIR_R <- file.path(
  DIR_SO33,
  "R"
)

DIR_METADATA <- file.path(
  DIR_SO33,
  "metadata"
)

DIR_OUTPUTS <- file.path(
  DIR_SO33,
  "outputs"
)

DIR_DOCS <- file.path(
  DIR_SO33,
  "docs"
)


# ------------------------------------------------------------
# Subdiretorios de resultados
# ------------------------------------------------------------

DIR_OUTPUT_BRUTO <- file.path(
  DIR_OUTPUTS,
  "bruto"
)

DIR_OUTPUT_TRATADO <- file.path(
  DIR_OUTPUTS,
  "tratado"
)

DIR_OUTPUT_NORMALIZADO <- file.path(
  DIR_OUTPUTS,
  "normalizado"
)

DIR_OUTPUT_COMPONENTES <- file.path(
  DIR_OUTPUTS,
  "componentes"
)

DIR_OUTPUT_DVI <- file.path(
  DIR_OUTPUTS,
  "dvi"
)


# ------------------------------------------------------------
# Cria os diretorios de saida quando necessario
# ------------------------------------------------------------

dirs_saida <- c(
  DIR_OUTPUTS,
  DIR_OUTPUT_BRUTO,
  DIR_OUTPUT_TRATADO,
  DIR_OUTPUT_NORMALIZADO,
  DIR_OUTPUT_COMPONENTES,
  DIR_OUTPUT_DVI
)

invisible(
  lapply(
    dirs_saida,
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )
)

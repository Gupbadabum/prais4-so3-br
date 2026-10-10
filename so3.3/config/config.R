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
# Insumos versionados
#
# Diferentemente de so3.3/data/, estes arquivos fazem parte
# do repositorio por serem fontes de referencia necessarias
# para a reproducao metodologica.
# ------------------------------------------------------------

DIR_INPUTS <- file.path(
  DIR_SO33,
  "inputs"
)

DIR_REFERENCIAS <- file.path(
  DIR_INPUTS,
  "referencias"
)

DIR_REFERENCIAS_IBGE <- file.path(
  DIR_REFERENCIAS,
  "ibge"
)

# ------------------------------------------------------------
# Tabelas de mortalidade - IBGE
# Projecoes da Populacao, Revisao 2024
# Brasil, Grandes Regioes e UFs - 2000/2070
# ------------------------------------------------------------

ARQ_TABUAS_MORTALIDADE_IBGE <- file.path(
  DIR_REFERENCIAS_IBGE,
  "projecoes_2024_tab5_tabuas_mortalidade.xlsx"
)

# ------------------------------------------------------------
# Tabuas-modelo Coale-Demeny - familia West
#
# Referencia utilizada para harmonizar q2, q3 e q5
# estimados pelo metodo Brass-Trussell.
# ------------------------------------------------------------

ARQ_COALE_DEMENY_WEST <- file.path(
  DIR_REFERENCIAS_COALE_DEMENY,
  "coale_demeny_west_qx.csv"
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

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
# Dimensoes operacionais
# ------------------------------------------------------------

DIMENSOES_DVI <- c(
  "social",
  "economica",
  "infraestrutural"
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

DIR_REFERENCIAS_COALE_DEMENY <- file.path(
  DIR_REFERENCIAS,
  "coale_demeny"
)

# Tabuas-modelo de vida estendidas, UN DESA (modelo UN 2011).
# Os caminhos sao relativos a raiz do repositorio, para nao
# depender do ponto de montagem ou do usuario da maquina.
DIR_REFERENCIAS_UNDESA <- file.path(
  DIR_REFERENCIAS,
  "undesa"
)

DIR_TABUAS_VIDA_UNDESA_2011 <- file.path(
  DIR_REFERENCIAS_UNDESA,
  "model_life_tables_2011"
)

ARQ_UNDESA_WEST_COMPLETA <- file.path(
  DIR_TABUAS_VIDA_UNDESA_2011,
  "undesa_pd_2026_mlt_un2011_130_1y_complete.xlsx"
)

ARQ_UNDESA_WEST_ABREVIADA <- file.path(
  DIR_TABUAS_VIDA_UNDESA_2011,
  "unpd_2011_mlt_130_1y_abridged.xlsx"
)


# ------------------------------------------------------------
# Tabelas de mortalidade - IBGE
# Projecoes da Populacao, Revisao 2024
# ------------------------------------------------------------

ARQ_TABUAS_MORTALIDADE_IBGE <- file.path(
  DIR_REFERENCIAS_IBGE,
  "projecoes_2024_tab5_tabuas_mortalidade.xlsx"
)

# IPCA - SIDRA 1737; serie original utilizada pelo ECO01.
# Arquivo fonte versionado separadamente dos derivados economicos.
ARQ_IPCA_1737 <- file.path(
  DIR_REFERENCIAS_IBGE,
  "tabela_1737_IPCA_para_uso.xlsx"
)


# ------------------------------------------------------------
# Tabuas-modelo Coale-Demeny - familia West
# ------------------------------------------------------------

ARQ_COALE_DEMENY_WEST <- file.path(
  DIR_REFERENCIAS_COALE_DEMENY,
  "coale_demeny_west_qx.csv"
)


# ------------------------------------------------------------
# Subdiretorios de resultados
#
# bruto:
#   indicadores municipais antes do tratamento estatistico.
#
# intermediario:
#   objetos necessarios para auditoria/reproducao de etapas
#   metodologicas, mas que nao constituem o indicador final.
#
# tratado:
#   resultados apos winsorizacao / Box-Cox.
#
# normalizado:
#   indicadores apos normalizacao PRAIS.
# ------------------------------------------------------------

DIR_OUTPUT_BRUTO <- file.path(
  DIR_OUTPUTS,
  "bruto"
)

DIR_OUTPUT_INTERMEDIARIO <- file.path(
  DIR_OUTPUTS,
  "intermediario"
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
  DIR_OUTPUT_INTERMEDIARIO,
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

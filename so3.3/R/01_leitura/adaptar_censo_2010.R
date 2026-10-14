# ============================================================
# PRAIS4 - SO3.3
# ADAPTADOR DO CENSO DEMOGRAFICO 2010
# ============================================================
#
# Objetivo:
#
#   Ler o Censo 2010 por meio do pacote censobr sem
#   materializar o conjunto nacional em memoria e converter
#   uma UF por vez para a estrutura canonica do SO3.3.
#
# A leitura nacional permanece como Arrow Dataset.
# Somente uma UF e coletada para RAM de cada vez.
#
# ============================================================


# ============================================================
# 1. DEPENDENCIAS
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("O pacote 'data.table' e necessario.")
}

if (!requireNamespace("dplyr", quietly = TRUE)) {
  stop("O pacote 'dplyr' e necessario.")
}

if (!requireNamespace("censobr", quietly = TRUE)) {
  stop("O pacote 'censobr' e necessario.")
}


# ============================================================
# 2. VARIAVEIS NECESSARIAS - DIMENSAO SOCIAL
# ============================================================

VARIAVEIS_SOCIAL_CENSO_2010 <- c(
  "code_muni",  # codigo municipal harmonizado pelo censobr
  "V0001",  # UF
  "V0002",  # municipio (5 posicoes dentro da UF)
  "V0010",  # peso amostral
  "V1006",  # situacao do domicilio
  "V0601",  # sexo
  "V6036",  # idade
  "V0627",  # alfabetizacao
  "V0663",  # teve filhos nascidos vivos
  "V6631",  # filhos nascidos vivos - masculino
  "V6632",  # filhos nascidos vivos - feminino
  "V6633",  # filhos nascidos vivos - total
  "V0664",  # informacao sobre sobrevivencia
  "V6641",  # filhos sobreviventes - masculino
  "V6642",  # filhos sobreviventes - feminino
  "V6643"   # filhos sobreviventes - total
)


# ============================================================
# 3. ABERTURA DO CENSO 2010
# ============================================================

abrir_censo_2010_social <- function(
  showProgress = TRUE
) {

  censobr::read_population(
    year = 2010,
    columns = VARIAVEIS_SOCIAL_CENSO_2010,
    as_data_frame = FALSE,
    merge_households = FALSE,
    showProgress = showProgress
  )
}


# ============================================================
# 4. LISTAGEM DAS UFs
# ============================================================

listar_ufs_censo_2010 <- function(
  censo_arrow
) {

  ufs <- censo_arrow |>
    dplyr::distinct(V0001) |>
    dplyr::collect()

  ufs <- sort(
    as.integer(
      ufs$V0001
    )
  )

  if (length(ufs) != 27L) {
    stop(
      "Esperadas 27 UFs no Censo 2010. Encontradas: ",
      length(ufs)
    )
  }

  ufs
}


# ============================================================
# 5. LEITURA DE UMA UF
# ============================================================

coletar_uf_censo_2010 <- function(
  censo_arrow,
  uf
) {

  censo_arrow |>
    dplyr::filter(
      V0001 == uf
    ) |>
    dplyr::collect()
}


# ============================================================
# 6. ADAPTACAO DE UMA UF PARA A ESTRUTURA CANONICA
# ============================================================

adaptar_censo_2010_uf <- function(
  dados_uf
) {

  d <- data.table::as.data.table(
    dados_uf
  )

  variaveis_numericas <- VARIAVEIS_SOCIAL_CENSO_2010

  for (v in variaveis_numericas) {

    data.table::set(
      d,
      j = v,
      value = suppressWarnings(
        as.numeric(
          d[[v]]
        )
      )
    )
  }


  # ----------------------------------------------------------
  # Harmonizacao estrutural da fecundidade
  #
  # V0663 = 2 e V6633 = 0:
  #   mulher declarou nao ter filhos nascidos vivos.
  #
  # Nesses casos as variaveis desagregadas por sexo e de
  # sobrevivencia aparecem estruturalmente em branco.
  # Esses brancos representam zero, nao ausencia de informacao.
  #
  # Nenhum NA associado a V6633 > 0 e modificado.
  # ----------------------------------------------------------

  sem_filhos <-
    !is.na(d$V0601) &
    d$V0601 == 2 &
    !is.na(d$V0663) &
    d$V0663 == 2 &
    !is.na(d$V6633) &
    d$V6633 == 0

  colunas_zero_estrutural <- c(
    "V6631",
    "V6632",
    "V6641",
    "V6642",
    "V6643"
  )

  for (v in colunas_zero_estrutural) {

    x <- d[[v]]

    idx <-
      sem_filhos &
      is.na(x)

    x[idx] <- 0

    data.table::set(
      d,
      j = v,
      value = x
    )
  }


  # ----------------------------------------------------------
  # Estrutura canonica
  # ----------------------------------------------------------

  canonico <- d[
    ,
    .(
      ano = 2010L,

      uf = sprintf(
        "%02d",
        as.integer(V0001)
      ),

      cod_mun = sprintf("%07d", as.integer(code_muni)),

      peso = as.numeric(
        V0010
      ),

      sexo = data.table::fcase(
        V0601 == 1,
        "Masculino",

        V0601 == 2,
        "Feminino",

        default = NA_character_
      ),

      idade = as.numeric(
        V6036
      ),

      rural = data.table::fcase(
        V1006 == 2,
        TRUE,

        V1006 == 1,
        FALSE,

        default = NA
      ),

      alfabetizado = data.table::fcase(
        V0627 == 1,
        TRUE,

        V0627 == 2,
        FALSE,

        default = NA
      ),

      filhos_nv_masc = as.numeric(
        V6631
      ),

      filhos_nv_fem = as.numeric(
        V6632
      ),

      filhos_nv_total = as.numeric(
        V6633
      ),

      filhos_vivos_masc = as.numeric(
        V6641
      ),

      filhos_vivos_fem = as.numeric(
        V6642
      ),

      filhos_vivos_total = as.numeric(
        V6643
      )
    )
  ]


  # ----------------------------------------------------------
  # Identificacao e peso sao requisitos estruturais.
  # NAs nas demais variaveis sao preservados para que cada
  # indicador defina seu proprio universo.
  # ----------------------------------------------------------

  canonico <- canonico[
    !is.na(cod_mun) &
      !is.na(peso) &
      is.finite(peso) &
      peso > 0
  ]

  canonico[]
}

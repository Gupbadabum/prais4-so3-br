# ============================================================
# PRAIS4 - SO3.3
# ADAPTADOR DO CENSO DEMOGRAFICO 2000
# ============================================================
#
# Objetivo:
#
#   Ler o Censo 2000 por meio do pacote censobr sem
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

VARIAVEIS_SOCIAL_CENSO_2000 <- c(
  "code_muni",  # codigo municipal harmonizado pelo censobr
  "V0102",  # UF
  "V0103",  # municipio - codigo completo de 7 digitos
  "P001",   # peso
  "V1006",  # situacao do domicilio
  "V0401",  # sexo
  "V4752",  # idade
  "V0428",  # alfabetizacao
  "V4620",  # filhos nascidos vivos - total
  "V0463",  # filhos sobreviventes - total
  "V4621",  # filhos nascidos vivos - masculino
  "V4622",  # filhos nascidos vivos - feminino
  "V4631",  # filhos sobreviventes - masculino
  "V4632"   # filhos sobreviventes - feminino
)


# ============================================================
# 3. ABERTURA DO CENSO 2000
# ============================================================

abrir_censo_2000_social <- function(
  showProgress = TRUE
) {

  censobr::read_population(
    year = 2000,
    columns = VARIAVEIS_SOCIAL_CENSO_2000,
    as_data_frame = FALSE,
    showProgress = showProgress
  )
}


# ============================================================
# 4. LISTAGEM DAS UFs
# ============================================================

listar_ufs_censo_2000 <- function(
  censo_arrow
) {

  ufs <- censo_arrow |>
    dplyr::distinct(V0102) |>
    dplyr::collect()

  ufs <- sort(
    as.integer(
      ufs$V0102
    )
  )

  if (length(ufs) != 27L) {
    stop(
      "Esperadas 27 UFs no Censo 2000. Encontradas: ",
      length(ufs)
    )
  }

  ufs
}


# ============================================================
# 5. LEITURA DE UMA UF
# ============================================================

coletar_uf_censo_2000 <- function(
  censo_arrow,
  uf
) {

  censo_arrow |>
    dplyr::filter(
      V0102 == uf
    ) |>
    dplyr::collect()
}


# ============================================================
# 6. ADAPTACAO DE UMA UF PARA A ESTRUTURA CANONICA
# ============================================================

adaptar_censo_2000_uf <- function(
  dados_uf
) {

  d <- data.table::as.data.table(
    dados_uf
  )


  for (v in VARIAVEIS_SOCIAL_CENSO_2000) {

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
  # Diagnostico previamente validado:
  #   - sobreviventes ausentes ocorrem quando nascidos = 0;
  #   - nao foram observados sobreviventes ausentes com
  #     nascidos > 0;
  #   - nenhum valor positivo e imputado ou corrigido.
  #
  # A regra e aplicada separadamente ao Total, Masculino e
  # Feminino para preservar exatamente a desagregacao por sexo.
  # ----------------------------------------------------------

  pares_fecundidade <- list(
    c("V4620", "V0463"),
    c("V4621", "V4631"),
    c("V4622", "V4632")
  )


  for (par in pares_fecundidade) {

    var_nascidos <- par[1]
    var_vivos <- par[2]

    nascidos <- d[[var_nascidos]]
    vivos <- d[[var_vivos]]

    idx_zero_estrutural <-
      !is.na(nascidos) &
      nascidos == 0 &
      is.na(vivos)

    vivos[idx_zero_estrutural] <- 0

    data.table::set(
      d,
      j = var_vivos,
      value = vivos
    )
  }


  # ----------------------------------------------------------
  # Geografia: identificador municipal harmonizado do censobr.
  # ----------------------------------------------------------

  # ----------------------------------------------------------
  # Estrutura canonica
  # ----------------------------------------------------------

  canonico <- d[
    ,
    .(
      ano = 2000L,

      uf = sprintf(
        "%02d",
        as.integer(V0102)
      ),

      cod_mun = sprintf("%07d", as.integer(code_muni)),

      peso = as.numeric(
        P001
      ),

      sexo = data.table::fcase(
        V0401 == 1,
        "Masculino",

        V0401 == 2,
        "Feminino",

        default = NA_character_
      ),

      idade = as.numeric(
        V4752
      ),

      rural = data.table::fcase(
        V1006 == 2,
        TRUE,

        V1006 == 1,
        FALSE,

        default = NA
      ),

      alfabetizado = data.table::fcase(
        V0428 == 1,
        TRUE,

        V0428 == 2,
        FALSE,

        default = NA
      ),

      filhos_nv_masc = as.numeric(
        V4621
      ),

      filhos_nv_fem = as.numeric(
        V4622
      ),

      filhos_nv_total = as.numeric(
        V4620
      ),

      filhos_vivos_masc = as.numeric(
        V4631
      ),

      filhos_vivos_fem = as.numeric(
        V4632
      ),

      filhos_vivos_total = as.numeric(
        V0463
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

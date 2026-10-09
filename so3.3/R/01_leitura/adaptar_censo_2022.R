# ============================================================
# PRAIS4 - SO3.3
# ADAPTADOR DO CENSO DEMOGRAFICO 2022
# ============================================================
#
# Objetivo:
#
#   Converter as variaveis originais dos microdados controlados
#   do Censo 2022 para a estrutura canonica utilizada pelo
#   SO3.3.
#
# O adaptador conhece os codigos originais do Censo.
# As funcoes de indicadores NAO devem conhecer variaveis Pxxxx.
#
# ============================================================


# ============================================================
# 1. DEPENDENCIAS
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop(
    "O pacote 'data.table' e necessario para o processamento."
  )
}


# ============================================================
# 2. VARIAVEIS NECESSARIAS
# ============================================================

VARIAVEIS_CENSO_2022 <- c(
  # Identificacao e ponderacao
  "P0080",   # Municipio
  "P0111",   # Peso da amostra controlada

  # Caracteristicas individuais
  "P0140",   # Situacao urbano/rural
  "P0160",   # Sexo
  "P0181",   # Idade calculada
  "P0640",   # Alfabetizacao

  # Fecundidade e sobrevivencia dos filhos
  "P0320",   # Filhos homens nascidos vivos
  "P0330",   # Filhas mulheres nascidas vivas
  "P0340",   # Total de filhos nascidos vivos

  "P0350",   # Filhos homens sobreviventes
  "P0360",   # Filhas mulheres sobreviventes
  "P0370"    # Total de filhos sobreviventes
)


# ============================================================
# 3. LOCALIZACAO DOS ARQUIVOS
# ============================================================

listar_arquivos_pessoas_2022 <- function(
    dir_censo = DIR_CENSO_2022
) {

  arquivos <- list.files(
    path = dir_censo,
    pattern = "^Pessoas_[0-9]{2}_controlado\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )

  arquivos <- sort(
    arquivos
  )

  if (length(arquivos) != 27L) {

    stop(
      paste0(
        "Esperados 27 arquivos de Pessoas para o Censo 2022. ",
        "Foram encontrados: ",
        length(arquivos)
      )
    )
  }

  return(
    arquivos
  )
}


# ============================================================
# 4. VALIDACAO DO LAYOUT
# ============================================================

validar_layout_censo_2022 <- function(
    arquivos,
    variaveis = VARIAVEIS_CENSO_2022
) {

  resultado <- data.table::rbindlist(
    lapply(
      arquivos,
      function(arq) {

        cabecalho <- names(
          data.table::fread(
            arq,
            sep = ";",
            nrows = 0L,
            showProgress = FALSE
          )
        )

        faltantes <- setdiff(
          variaveis,
          cabecalho
        )

        data.table::data.table(
          arquivo = arq,
          valido = length(faltantes) == 0L,
          variaveis_faltantes = paste(
            faltantes,
            collapse = ", "
          )
        )
      }
    )
  )

  if (any(!resultado$valido)) {

    problemas <- resultado[
      valido == FALSE
    ]

    stop(
      paste0(
        "Foram encontrados arquivos do Censo 2022 ",
        "sem todas as variaveis necessarias.\n",
        paste(
          problemas$arquivo,
          problemas$variaveis_faltantes,
          sep = ": ",
          collapse = "\n"
        )
      )
    )
  }

  return(
    resultado[]
  )
}


# ============================================================
# 5. EXTRACAO DO CODIGO DA UF
# ============================================================

extrair_uf_2022 <- function(arq) {

  nome <- basename(
    arq
  )

  uf <- sub(
    "^Pessoas_([0-9]{2})_controlado\\.csv$",
    "\\1",
    nome
  )

  return(
    uf
  )
}


# ============================================================
# 6. ADAPTACAO PARA A ESTRUTURA CANONICA
# ============================================================

adaptar_censo_2022 <- function(arq) {

  uf_arquivo <- extrair_uf_2022(
    arq
  )


  d <- data.table::fread(
    arq,
    sep = ";",
    select = VARIAVEIS_CENSO_2022,
    showProgress = FALSE,
    na.strings = c(
      "",
      "NA"
    )
  )


  # ----------------------------------------------------------
  # Estrutura canonica
  # ----------------------------------------------------------

  d[
    ,
    `:=`(
      ano = 2022L,

      uf = uf_arquivo,

      cod_mun = as.character(
        P0080
      ),

      peso = as.numeric(
        P0111
      ),

      sexo = data.table::fcase(
        P0160 == 1,
        "Masculino",

        P0160 == 2,
        "Feminino",

        default = NA_character_
      ),

      idade = as.numeric(
        P0181
      ),

      rural = data.table::fcase(
        P0140 == 1,
        FALSE,

        P0140 == 2,
        TRUE,

        default = NA
      ),

      alfabetizado = data.table::fcase(
        P0640 == 1,
        TRUE,

        P0640 == 2,
        FALSE,

        default = NA
      ),

      
      # ------------------------------------------------------
      # Fecundidade / sobrevivencia
      #
      # Masculino/Feminino refere-se ao sexo DOS FILHOS.
      #
      # Para sobreviventes:
      #
      #   nascidos vivos = 0 + sobreviventes = NA
      #       -> sobreviventes = 0
      #
      # O NA estrutural ocorre quando nao houve nascimento
      # vivo daquele grupo.
      #
      # Quando nascidos vivos > 0, qualquer NA observado em
      # sobreviventes e preservado como NA.
      # ------------------------------------------------------

      filhos_nv_masc = as.numeric(
        P0320
      ),

      filhos_nv_fem = as.numeric(
        P0330
      ),

      filhos_nv_total = as.numeric(
        P0340
      ),

      filhos_vivos_masc = data.table::fcase(
        P0320 == 0 & is.na(P0350),
        0,
      
        default = as.numeric(P0350)
      ),

      filhos_vivos_fem = data.table::fcase(
        P0330 == 0 & is.na(P0360),
        0,

        default = as.numeric(P0360)
      ),

      filhos_vivos_total = data.table::fcase(
        P0340 == 0 & is.na(P0370),
        0,

        default = as.numeric(P0370)
      )
    )
  ]


  # ----------------------------------------------------------
  # Mantem apenas registros com identificacao municipal e
  # peso amostral validos.
  #
  # NAs nas demais variaveis NAO sao removidos aqui.
  # O universo de cada indicador e definido posteriormente.
  # ----------------------------------------------------------

  d <- d[
    !is.na(cod_mun) &
      !is.na(peso) &
      peso > 0
  ]


  # ----------------------------------------------------------
  # Retorno canonico
  # ----------------------------------------------------------

  return(
    d[
      ,
      .(
        ano,
        uf,
        cod_mun,
        peso,
        sexo,
        idade,
        rural,
        alfabetizado,

        filhos_nv_masc,
        filhos_nv_fem,
        filhos_nv_total,

        filhos_vivos_masc,
        filhos_vivos_fem,
        filhos_vivos_total
      )
    ]
  )
}


# ============================================================
# 7. PREPARACAO DO CENSO 2022
# ============================================================

preparar_censo_2022 <- function(
    dir_censo = DIR_CENSO_2022
) {

  arquivos <- listar_arquivos_pessoas_2022(
    dir_censo
  )

  validacao <- validar_layout_censo_2022(
    arquivos
  )

  message(
    "Censo 2022 preparado: ",
    length(arquivos),
    " arquivos de Pessoas validados."
  )

  return(
    list(
      arquivos = arquivos,
      validacao = validacao
    )
  )
}

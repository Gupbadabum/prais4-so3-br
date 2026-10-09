# ============================================================
# PRAIS4 - SO3.3
# DIMENSAO SOCIAL
# FUNCOES COMUNS AOS RECORTES CENSITARIOS
# ============================================================
#
# Este arquivo trabalha exclusivamente com a estrutura
# canonica produzida pelos adaptadores censitarios.
#
# Estrutura minima esperada:
#
#   ano
#   uf
#   cod_mun
#   peso
#   sexo
#   idade
#   rural
#   alfabetizado
#
# Nenhuma variavel original do IBGE deve aparecer aqui.
#
# Indicadores implementados nesta etapa:
#
#   SOC01_ALF15
#       Taxa de alfabetizacao da populacao de 15 anos ou mais
#
#   SOC02_RURAL
#       Percentual da populacao residente em area rural
#
#   SOC04_POP1564
#       Percentual da populacao entre 15 e 64 anos
#
# SOC03_EV0 - Expectativa de vida ao nascer
# sera implementado posteriormente, pois exige procedimento
# demografico especifico.
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
# 2. VALIDACAO DA ESTRUTURA CANONICA
# ============================================================

validar_estrutura_social <- function(dt) {

  variaveis_necessarias <- c(
    "ano",
    "uf",
    "cod_mun",
    "peso",
    "sexo",
    "idade",
    "rural",
    "alfabetizado"
  )

  faltantes <- setdiff(
    variaveis_necessarias,
    names(dt)
  )

  if (length(faltantes) > 0L) {
    stop(
      paste0(
        "Estrutura canonica incompleta. Variaveis ausentes: ",
        paste(faltantes, collapse = ", ")
      )
    )
  }

  if (any(is.na(dt$cod_mun))) {
    stop(
      "Existem registros sem codigo municipal."
    )
  }

  if (
    any(
      is.na(dt$peso) |
      !is.finite(dt$peso) |
      dt$peso <= 0
    )
  ) {
    stop(
      "Existem pesos ausentes, nao finitos ou nao positivos."
    )
  }

  invisible(TRUE)
}


# ============================================================
# 3. FUNCAO COMUM PARA INDICADORES PROPORCIONAIS
# ============================================================
#
# Para cada municipio e grupo populacional calcula:
#
#   valor
#       percentual ponderado do evento no universo
#
#   numerador
#       soma dos pesos dos registros que atendem ao evento
#
#   denominador
#       soma dos pesos de todo o universo do indicador
#
#   n_amostra
#       numero de observacoes nao ponderadas no universo
#
#   soma_pesos2
#       soma dos pesos ao quadrado
#
#   n_efetivo
#       tamanho amostral efetivo associado aos pesos:
#
#                     (sum w)^2
#       n_efetivo = -------------
#                      sum(w^2)
#
# n_amostra e n_efetivo sao diagnosticos internos.
# Nao implicam exclusao automatica de municipios.
#
# ============================================================

calcular_proporcao_social <- function(
    dt,
    universo,
    evento,
    indicador
) {

  # ----------------------------------------------------------
  # Universo valido do indicador
  # ----------------------------------------------------------

  d <- dt[
    eval(universo)
  ]

  if (nrow(d) == 0L) {
    stop(
      "O universo do indicador ",
      indicador,
      " resultou em zero registros."
    )
  }


  # ----------------------------------------------------------
  # Funcao interna para um grupo populacional
  # ----------------------------------------------------------

  calcular_grupo <- function(x, grupo_nome) {

    if (nrow(x) == 0L) {
      return(
        data.table::data.table()
      )
    }

    resultado <- x[
      ,
      .(
        numerador = sum(
          peso[eval(evento)],
          na.rm = TRUE
        ),

        denominador = sum(
          peso,
          na.rm = TRUE
        ),

        n_amostra = .N,

        soma_pesos2 = sum(
          peso^2,
          na.rm = TRUE
        )
      ),
      by = .(
        ano,
        uf,
        cod_mun
      )
    ]

    resultado[
      ,
      `:=`(
        grupo = grupo_nome,

        n_efetivo = data.table::fifelse(
          soma_pesos2 > 0,
          denominador^2 / soma_pesos2,
          NA_real_
        ),

        valor = data.table::fifelse(
          denominador > 0,
          100 * numerador / denominador,
          NA_real_
        )
      )
    ]

    return(resultado[])
  }


  # ----------------------------------------------------------
  # Total
  # ----------------------------------------------------------

  total <- calcular_grupo(
    d,
    "Total"
  )


  # ----------------------------------------------------------
  # Masculino
  # ----------------------------------------------------------

  masculino <- calcular_grupo(
    d[
      sexo == "Masculino"
    ],
    "Masculino"
  )


  # ----------------------------------------------------------
  # Feminino
  # ----------------------------------------------------------

  feminino <- calcular_grupo(
    d[
      sexo == "Feminino"
    ],
    "Feminino"
  )


  # ----------------------------------------------------------
  # Consolidacao dos grupos
  # ----------------------------------------------------------

  out <- data.table::rbindlist(
    list(
      total,
      masculino,
      feminino
    ),
    use.names = TRUE,
    fill = TRUE
  )

  out[
    ,
    `:=`(
      dimensao = "Social",
      indicador = indicador
    )
  ]


  # ----------------------------------------------------------
  # Ordem das colunas
  # ----------------------------------------------------------

  data.table::setcolorder(
    out,
    c(
      "ano",
      "uf",
      "cod_mun",
      "grupo",
      "dimensao",
      "indicador",
      "valor",
      "numerador",
      "denominador",
      "n_amostra",
      "n_efetivo",
      "soma_pesos2"
    )
  )

  return(out[])
}


# ============================================================
# 4. SOC01 - TAXA DE ALFABETIZACAO DA POPULACAO 15+
# ============================================================
#
# Universo:
#
#   pessoas com 15 anos ou mais e informacao valida de
#   alfabetizacao
#
# Numerador:
#
#   pessoas alfabetizadas dentro desse universo
#
# ============================================================

calcular_soc01_alf15 <- function(dt) {

  calcular_proporcao_social(
    dt = dt,

    universo = quote(
      !is.na(idade) &
      idade >= 15 &
      !is.na(alfabetizado)
    ),

    evento = quote(
      alfabetizado == TRUE
    ),

    indicador = "SOC01_ALF15"
  )
}


# ============================================================
# 5. SOC02 - POPULACAO RURAL
# ============================================================
#
# Universo:
#
#   registros com situacao urbano/rural valida
#
# Numerador:
#
#   residentes classificados como rurais
#
# ============================================================

calcular_soc02_rural <- function(dt) {

  calcular_proporcao_social(
    dt = dt,

    universo = quote(
      !is.na(rural)
    ),

    evento = quote(
      rural == TRUE
    ),

    indicador = "SOC02_RURAL"
  )
}


# ============================================================
# 6. SOC04 - POPULACAO DE 15 A 64 ANOS
# ============================================================
#
# Universo:
#
#   populacao com idade valida
#
# Numerador:
#
#   pessoas entre 15 e 64 anos, inclusive
#
# ============================================================

calcular_soc04_pop1564 <- function(dt) {

  calcular_proporcao_social(
    dt = dt,

    universo = quote(
      !is.na(idade) &
      idade >= 0
    ),

    evento = quote(
      idade >= 15 &
      idade <= 64
    ),

    indicador = "SOC04_POP1564"
  )
}


# ============================================================
# 7. CALCULO CONJUNTO DOS INDICADORES SOCIAIS DIRETOS
# ============================================================
#
# Esta e a funcao que o main.R utilizara.
#
# Ela recebe qualquer recorte censitario que ja tenha passado
# por seu respectivo adaptador e devolve os indicadores no
# mesmo formato.
#
# Portanto:
#
#   adaptar_censo_2000()
#           |
#           v
#   calcular_social_direto()
#
#   adaptar_censo_2010()
#           |
#           v
#   calcular_social_direto()
#
#   adaptar_censo_2022()
#           |
#           v
#   calcular_social_direto()
#
# ============================================================

calcular_social_direto <- function(dt) {

  validar_estrutura_social(dt)

  soc01 <- calcular_soc01_alf15(
    dt
  )

  soc02 <- calcular_soc02_rural(
    dt
  )

  soc04 <- calcular_soc04_pop1564(
    dt
  )

  out <- data.table::rbindlist(
    list(
      soc01,
      soc02,
      soc04
    ),
    use.names = TRUE,
    fill = TRUE
  )

  data.table::setorder(
    out,
    indicador,
    cod_mun,
    grupo
  )

  return(out[])
}

# ============================================================
# SOC03 - EXPECTATIVA DE VIDA AO NASCER
# PREPARACAO DOS INSUMOS DEMOGRAFICOS
# ============================================================
#
# Esta etapa NAO calcula ainda a expectativa de vida.
#
# Ela organiza, por municipio, grupo etario materno e sexo
# dos filhos:
#
#   - mulheres na amostra;
#   - tamanho efetivo da amostra;
#   - filhos nascidos vivos;
#   - filhos sobreviventes;
#   - filhos falecidos;
#   - proporcao de filhos falecidos.
#
# A agregacao e feita ANTES do calculo da proporcao:
#
#             sum(B) - sum(S)
#   D_i = -----------------------
#                  sum(B)
#
# onde:
#
#   B = filhos nascidos vivos
#   S = filhos sobreviventes
#
# ============================================================


validar_estrutura_ev0 <- function(dt) {

  variaveis_obrigatorias <- c(
    "ano",
    "uf",
    "cod_mun",
    "peso",
    "sexo",
    "idade",

    "filhos_nv_masc",
    "filhos_nv_fem",
    "filhos_nv_total",

    "filhos_vivos_masc",
    "filhos_vivos_fem",
    "filhos_vivos_total"
  )

  faltantes <- setdiff(
    variaveis_obrigatorias,
    names(dt)
  )

  if (length(faltantes) > 0L) {

    stop(
      paste0(
        "Estrutura insuficiente para SOC03_EV0. ",
        "Variaveis ausentes: ",
        paste(
          faltantes,
          collapse = ", "
        )
      )
    )
  }

  invisible(TRUE)
}


# ------------------------------------------------------------
# Classificacao da idade materna
# ------------------------------------------------------------

classificar_idade_mae_ev0 <- function(idade) {

  data.table::fcase(
    idade >= 15 & idade <= 19, "15-19",
    idade >= 20 & idade <= 24, "20-24",
    idade >= 25 & idade <= 29, "25-29",
    idade >= 30 & idade <= 34, "30-34",
    idade >= 35 & idade <= 39, "35-39",
    idade >= 40 & idade <= 44, "40-44",
    idade >= 45 & idade <= 49, "45-49",
    default = NA_character_
  )
}


# ------------------------------------------------------------
# Agregacao para um grupo de sexo dos filhos
# ------------------------------------------------------------

agregar_ev0_grupo <- function(
    dt,
    grupo_nome,
    coluna_nv,
    coluna_vivos
) {

  d <- data.table::copy(
    dt
  )

  d[
    ,
    `:=`(
      filhos_nv = get(
        coluna_nv
      ),

      filhos_vivos = get(
        coluna_vivos
      )
    )
  ]


  # Mantem apenas observacoes com informacao suficiente
  # para o calculo demografico.

  d <- d[
    !is.na(filhos_nv) &
      !is.na(filhos_vivos)
  ]


  resultado <- d[
    ,
    .(
      n_mulheres = .N,

      soma_pesos = sum(
        peso,
        na.rm = TRUE
      ),

      soma_pesos2 = sum(
        peso^2,
        na.rm = TRUE
      ),

      filhos_nv = sum(
        peso * filhos_nv,
        na.rm = TRUE
      ),

      filhos_vivos = sum(
        peso * filhos_vivos,
        na.rm = TRUE
      )
    ),
    by = .(
      ano,
      uf,
      cod_mun,
      idade_mae
    )
  ]


  resultado[
    ,
    `:=`(
      grupo = grupo_nome,

      n_efetivo =
        data.table::fifelse(
          soma_pesos2 > 0,

          soma_pesos^2 /
            soma_pesos2,

          NA_real_
        ),

      filhos_falecidos =
        filhos_nv -
        filhos_vivos,

      proporcao_falecidos =
        data.table::fifelse(
          filhos_nv > 0,

          (
            filhos_nv -
            filhos_vivos
          ) /
            filhos_nv,

          NA_real_
        )
    )
  ]


  resultado[
    ,
    .(
      ano,
      uf,
      cod_mun,
      grupo,
      idade_mae,

      n_mulheres,
      n_efetivo,
      soma_pesos,

      filhos_nv,
      filhos_vivos,
      filhos_falecidos,
      proporcao_falecidos
    )
  ]
}


# ------------------------------------------------------------
# Preparacao completa dos insumos
# ------------------------------------------------------------

preparar_insumos_soc03_ev0 <- function(dt) {

  validar_estrutura_ev0(
    dt
  )


  d <- data.table::copy(
    dt
  )


  # ----------------------------------------------------------
  # Universo materno utilizado na preparacao
  #
  # Mantemos 15-49 anos nesta camada intermediaria.
  #
  # A escolha dos grupos efetivamente utilizados no metodo
  # indireto ocorre em etapa posterior.
  # ----------------------------------------------------------

  d <- d[
    sexo == "Feminino" &
      !is.na(idade) &
      idade >= 15 &
      idade <= 49
  ]


  d[
    ,
    idade_mae :=
      classificar_idade_mae_ev0(
        idade
      )
  ]


  d <- d[
    !is.na(idade_mae)
  ]


  total <- agregar_ev0_grupo(
    d,
    grupo_nome = "Total",
    coluna_nv = "filhos_nv_total",
    coluna_vivos = "filhos_vivos_total"
  )


  masculino <- agregar_ev0_grupo(
    d,
    grupo_nome = "Masculino",
    coluna_nv = "filhos_nv_masc",
    coluna_vivos = "filhos_vivos_masc"
  )


  feminino <- agregar_ev0_grupo(
    d,
    grupo_nome = "Feminino",
    coluna_nv = "filhos_nv_fem",
    coluna_vivos = "filhos_vivos_fem"
  )


  resultado <- data.table::rbindlist(
    list(
      total,
      masculino,
      feminino
    ),
    use.names = TRUE
  )


  data.table::setorder(
    resultado,
    ano,
    cod_mun,
    grupo,
    idade_mae
  )


  return(
    resultado[]
  )
}


# ============================================================
# PROCESSAMENTO SOCIAL DE UM CENSO
# ============================================================

processar_social_censo <- function(
    arquivos,
    adaptar_fun
) {

  resultados <- lapply(
    arquivos,
    function(arq) {

      message(
        "Processando Social: ",
        basename(arq)
      )

      dados <- adaptar_fun(
        arq
      )

      direto <- calcular_social_direto(
        dados
      )

      ev0 <- preparar_insumos_soc03_ev0(
        dados
      )

      rm(dados)

      list(
        direto = direto,
        ev0 = ev0
      )
    }
  )


  social_direto <- data.table::rbindlist(
    lapply(
      resultados,
      `[[`,
      "direto"
    ),
    use.names = TRUE,
    fill = TRUE
  )


  insumos_ev0 <- data.table::rbindlist(
    lapply(
      resultados,
      `[[`,
      "ev0"
    ),
    use.names = TRUE,
    fill = TRUE
  )


  data.table::setorder(
    social_direto,
    indicador,
    cod_mun,
    grupo
  )

  data.table::setorder(
    insumos_ev0,
    ano,
    cod_mun,
    grupo,
    idade_mae
  )


  return(
    list(
      direto = social_direto,
      ev0 = insumos_ev0
    )
  )
}

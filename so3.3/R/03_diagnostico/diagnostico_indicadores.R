# ============================================================
# PRAIS4 - SO3.3
# DIAGNOSTICO DOS INDICADORES
# ============================================================
#
# Objetivo:
#
#   Concentrar os procedimentos de controle de qualidade,
#   auditoria e diagnostico das bases municipais produzidas
#   pelas diferentes dimensoes do SO3.3.
#
# Este arquivo NAO altera os valores dos indicadores.
#
# Diagnostico != tratamento.
#
# Winsorizacao, Box-Cox e normalizacao pertencem a etapas
# posteriores do pipeline.
#
# Funcoes implementadas:
#
#   validar_base_indicadores()
#   diagnosticar_duplicidades()
#   resumir_indicadores()
#   diagnosticar_amostra()
#   verificar_consistencia_sexo()
#   verificar_intervalo_indicadores()
#   extrair_extremos_indicadores()
#   diagnosticar_indicadores()
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
# 2. FUNCOES AUXILIARES
# ============================================================

min_seguro <- function(x) {

  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }

  as.numeric(min(
    x,
    na.rm = TRUE
  ))
}


max_seguro <- function(x) {

  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }

  as.numeric(max(
    x,
    na.rm = TRUE
  ))
}


media_segura <- function(x) {

  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }

  mean(
    x,
    na.rm = TRUE
  )
}


mediana_segura <- function(x) {

  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }

  median(
    x,
    na.rm = TRUE
  )
}


quantil_seguro <- function(
    x,
    prob
) {

  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }

  as.numeric(
    stats::quantile(
      x,
      probs = prob,
      na.rm = TRUE,
      names = FALSE
    )
  )
}


# ============================================================
# 3. VALIDACAO DA ESTRUTURA MINIMA
# ============================================================
#
# Esta validacao e intencionalmente generica.
#
# Ela deve funcionar para indicadores sociais, economicos
# e infraestruturais.
#
# ============================================================

validar_base_indicadores <- function(dt) {

  variaveis_obrigatorias <- c(
    "ano",
    "uf",
    "cod_mun",
    "grupo",
    "dimensao",
    "indicador",
    "valor"
  )

  faltantes <- setdiff(
    variaveis_obrigatorias,
    names(dt)
  )

  if (length(faltantes) > 0L) {

    stop(
      paste0(
        "Base de indicadores incompleta. Variaveis ausentes: ",
        paste(
          faltantes,
          collapse = ", "
        )
      )
    )
  }


  if (any(is.na(dt$ano))) {

    stop(
      "Existem registros sem ano."
    )
  }


  if (any(is.na(dt$cod_mun))) {

    stop(
      "Existem registros sem codigo municipal."
    )
  }


  if (any(is.na(dt$grupo))) {

    stop(
      "Existem registros sem grupo populacional."
    )
  }


  if (any(is.na(dt$indicador))) {

    stop(
      "Existem registros sem identificacao do indicador."
    )
  }


  invisible(TRUE)
}


# ============================================================
# 4. DUPLICIDADES
# ============================================================
#
# Uma observacao deve ser unica por:
#
#   ano
#   municipio
#   grupo
#   dimensao
#   indicador
#
# ============================================================

diagnosticar_duplicidades <- function(dt) {

  validar_base_indicadores(dt)

  dt[
    ,
    .N,
    by = .(
      ano,
      uf,
      cod_mun,
      grupo,
      dimensao,
      indicador
    )
  ][
    N > 1L
  ][
    order(
      ano,
      dimensao,
      indicador,
      cod_mun,
      grupo
    )
  ]
}


# ============================================================
# 5. RESUMO DOS INDICADORES
# ============================================================
#
# Produz estatisticas descritivas sem alterar os dados.
#
# A media e a mediana aqui sao MUNICIPAIS:
# cada municipio representa uma observacao.
#
# Elas nao devem ser interpretadas como estatisticas
# nacionais ponderadas pela populacao.
#
# ============================================================

resumir_indicadores <- function(dt) {

  validar_base_indicadores(dt)

  dt[
    ,
    .(
      linhas = .N,

      municipios = data.table::uniqueN(
        cod_mun
      ),

      ausentes = sum(
        is.na(valor)
      ),

      minimo = min_seguro(
        valor
      ),

      q25 = quantil_seguro(
        valor,
        0.25
      ),

      media = media_segura(
        valor
      ),

      mediana = mediana_segura(
        valor
      ),

      q75 = quantil_seguro(
        valor,
        0.75
      ),

      maximo = max_seguro(
        valor
      )
    ),
    by = .(
      ano,
      dimensao,
      indicador,
      grupo
    )
  ][
    order(
      ano,
      dimensao,
      indicador,
      grupo
    )
  ]
}


# ============================================================
# 6. DIAGNOSTICO AMOSTRAL
# ============================================================
#
# Aplicavel aos indicadores derivados de microdados para os
# quais n_amostra e n_efetivo foram preservados.
#
# Caso essas variaveis nao existam na base, a funcao devolve
# uma data.table vazia.
#
# eficiencia_amostral:
#
#                 n_efetivo
#   eficiencia = -----------
#                 n_amostra
#
# Esse valor e apenas diagnostico.
#
# Nenhum municipio e removido ou corrigido automaticamente.
#
# ============================================================

diagnosticar_amostra <- function(dt) {

  variaveis_amostrais <- c(
    "n_amostra",
    "n_efetivo"
  )

  if (
    !all(
      variaveis_amostrais %in% names(dt)
    )
  ) {

    return(
      data.table::data.table()
    )
  }


  d <- data.table::copy(dt)

  d[
    ,
    eficiencia_amostral :=
      data.table::fifelse(
        !is.na(n_amostra) &
          n_amostra > 0 &
          !is.na(n_efetivo),

        n_efetivo / n_amostra,

        NA_real_
      )
  ]


  d[
    ,
    .(
      n_amostra_min = min_seguro(
        n_amostra
      ),

      n_amostra_q25 = quantil_seguro(
        n_amostra,
        0.25
      ),

      n_amostra_mediana = mediana_segura(
        n_amostra
      ),

      n_amostra_q75 = quantil_seguro(
        n_amostra,
        0.75
      ),

      n_amostra_max = max_seguro(
        n_amostra
      ),

      n_efetivo_min = min_seguro(
        n_efetivo
      ),

      n_efetivo_q25 = quantil_seguro(
        n_efetivo,
        0.25
      ),

      n_efetivo_mediana = mediana_segura(
        n_efetivo
      ),

      n_efetivo_q75 = quantil_seguro(
        n_efetivo,
        0.75
      ),

      n_efetivo_max = max_seguro(
        n_efetivo
      ),

      eficiencia_min = min_seguro(
        eficiencia_amostral
      ),

      eficiencia_mediana = mediana_segura(
        eficiencia_amostral
      )
    ),
    by = .(
      ano,
      dimensao,
      indicador,
      grupo
    )
  ][
    order(
      ano,
      dimensao,
      indicador,
      grupo
    )
  ]
}


# ============================================================
# 7. CONSISTENCIA TOTAL = MASCULINO + FEMININO
# ============================================================
#
# Esta verificacao utiliza:
#
#   numerador
#   denominador
#   n_amostra
#
# portanto e aplicavel aos indicadores proporcionais
# derivados dos microdados.
#
# Para cada municipio:
#
#   numerador_Total
#     =
#   numerador_Masculino + numerador_Feminino
#
#   denominador_Total
#     =
#   denominador_Masculino + denominador_Feminino
#
#   n_amostra_Total
#     =
#   n_amostra_Masculino + n_amostra_Feminino
#
# Pequenas diferencas numericas sao aceitas para variaveis
# ponderadas.
#
# ============================================================

verificar_consistencia_sexo <- function(
    dt,
    tolerancia = 1e-6
) {

  variaveis_necessarias <- c(
    "numerador",
    "denominador",
    "n_amostra"
  )

  if (
    !all(
      variaveis_necessarias %in% names(dt)
    )
  ) {

    return(
      data.table::data.table()
    )
  }


  d <- dt[
    grupo %in% c(
      "Total",
      "Masculino",
      "Feminino"
    )
  ]


  wide <- data.table::dcast(
    d,
    ano +
      uf +
      cod_mun +
      dimensao +
      indicador ~ grupo,

    value.var = c(
      "numerador",
      "denominador",
      "n_amostra"
    )
  )


  colunas_esperadas <- c(
    "numerador_Total",
    "numerador_Masculino",
    "numerador_Feminino",
    "denominador_Total",
    "denominador_Masculino",
    "denominador_Feminino",
    "n_amostra_Total",
    "n_amostra_Masculino",
    "n_amostra_Feminino"
  )


  faltantes <- setdiff(
    colunas_esperadas,
    names(wide)
  )


  if (length(faltantes) > 0L) {

    stop(
      paste0(
        "Nao foi possivel verificar consistencia T/M/F. ",
        "Colunas ausentes apos reorganizacao: ",
        paste(
          faltantes,
          collapse = ", "
        )
      )
    )
  }


  wide[
    ,
    `:=`(
      diferenca_numerador =
        numerador_Total -
        (
          numerador_Masculino +
          numerador_Feminino
        ),

      diferenca_denominador =
        denominador_Total -
        (
          denominador_Masculino +
          denominador_Feminino
        ),

      diferenca_n_amostra =
        n_amostra_Total -
        (
          n_amostra_Masculino +
          n_amostra_Feminino
        )
    )
  ]


  wide[
    ,
    consistente :=
      !is.na(diferenca_numerador) &
      !is.na(diferenca_denominador) &
      !is.na(diferenca_n_amostra) &

      abs(
        diferenca_numerador
      ) <= tolerancia &

      abs(
        diferenca_denominador
      ) <= tolerancia &

      diferenca_n_amostra == 0
  ]


  data.table::setorder(
    wide,
    ano,
    dimensao,
    indicador,
    cod_mun
  )


  return(
    wide[]
  )
}


# ============================================================
# 8. VERIFICACAO DE INTERVALO
# ============================================================
#
# Esta funcao NAO e executada automaticamente para todos
# os indicadores.
#
# Exemplo:
#
#   verificar_intervalo_indicadores(
#     social_2022,
#     indicadores = c(
#       "SOC01_ALF15",
#       "SOC02_RURAL",
#       "SOC04_POP1564"
#     ),
#     minimo = 0,
#     maximo = 100
#   )
#
# Isto evita impor [0,100] a indicadores como PIB per capita
# ou recursos hidricos renovaveis per capita.
#
# ============================================================

verificar_intervalo_indicadores <- function(
    dt,
    indicadores = NULL,
    minimo = -Inf,
    maximo = Inf
) {

  validar_base_indicadores(dt)

  d <- dt


  if (!is.null(indicadores)) {

    d <- d[
      indicador %in% indicadores
    ]
  }


  d[
    is.na(valor) |
      valor < minimo |
      valor > maximo
  ][
    order(
      ano,
      indicador,
      grupo,
      cod_mun
    )
  ]
}


# ============================================================
# 9. EXTREMOS OBSERVADOS
# ============================================================
#
# Identifica os N menores ou N maiores valores de cada:
#
#   ano
#   dimensao
#   indicador
#   grupo
#
# NAO classifica automaticamente esses municipios como
# outliers.
#
# Um extremo observado e apenas um municipio a ser
# investigado.
#
# ============================================================

extrair_extremos_indicadores <- function(
    dt,
    n = 10L,
    tipo = c(
      "inferior",
      "superior"
    )
) {

  validar_base_indicadores(dt)

  tipo <- match.arg(
    tipo
  )


  if (
    length(n) != 1L ||
    is.na(n) ||
    n < 1L
  ) {

    stop(
      "'n' deve ser um inteiro positivo."
    )
  }


  n <- as.integer(
    n
  )


  colunas_diagnosticas <- intersect(
    c(
      "numerador",
      "denominador",
      "n_amostra",
      "n_efetivo",
      "soma_pesos2"
    ),
    names(dt)
  )


  colunas_saida <- c(
    "uf",
    "cod_mun",
    "valor",
    colunas_diagnosticas
  )


  d <- dt[
    !is.na(valor)
  ]


  if (tipo == "inferior") {

    data.table::setorderv(
      d,
      cols = c(
        "ano",
        "dimensao",
        "indicador",
        "grupo",
        "valor"
      ),
      order = c(
        1L,
        1L,
        1L,
        1L,
        1L
      )
    )

  } else {

    data.table::setorderv(
      d,
      cols = c(
        "ano",
        "dimensao",
        "indicador",
        "grupo",
        "valor"
      ),
      order = c(
        1L,
        1L,
        1L,
        1L,
        -1L
      )
    )
  }


  d[
    ,
    head(
      .SD,
      n
    ),
    by = .(
      ano,
      dimensao,
      indicador,
      grupo
    ),
    .SDcols = colunas_saida
  ]
}


# ============================================================
# 10. DIAGNOSTICO COMPLETO
# ============================================================
#
# Executa os diagnosticos gerais e devolve uma lista.
#
# Nenhuma informacao da base original e modificada.
#
# Estrutura resultante:
#
#   $resumo
#   $duplicidades
#   $amostra
#   $consistencia_sexo
#   $problemas_consistencia_sexo
#   $extremos_inferiores
#   $extremos_superiores
#
# ============================================================

diagnosticar_indicadores <- function(
    dt,
    n_extremos = 10L,
    tolerancia_sexo = 1e-6
) {

  validar_base_indicadores(
    dt
  )


  duplicidades <- diagnosticar_duplicidades(
    dt
  )


  resumo <- resumir_indicadores(
    dt
  )


  amostra <- diagnosticar_amostra(
    dt
  )


  consistencia_sexo <- verificar_consistencia_sexo(
    dt,
    tolerancia = tolerancia_sexo
  )


  if (nrow(consistencia_sexo) > 0L) {

    problemas_consistencia_sexo <- consistencia_sexo[
      consistente == FALSE |
        is.na(consistente)
    ]

  } else {

    problemas_consistencia_sexo <- data.table::data.table()
  }


  extremos_inferiores <- extrair_extremos_indicadores(
    dt,
    n = n_extremos,
    tipo = "inferior"
  )


  extremos_superiores <- extrair_extremos_indicadores(
    dt,
    n = n_extremos,
    tipo = "superior"
  )


  return(
    list(
      resumo = resumo,

      duplicidades = duplicidades,

      amostra = amostra,

      consistencia_sexo = consistencia_sexo,

      problemas_consistencia_sexo =
        problemas_consistencia_sexo,

      extremos_inferiores =
        extremos_inferiores,

      extremos_superiores =
        extremos_superiores
    )
  )
}

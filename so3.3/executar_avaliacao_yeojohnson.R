#!/usr/bin/env Rscript

# PRAIS4 / SO3.3
# Avaliacao especifica de Yeo-Johnson por indicador territorial.
#
# Executar a partir da raiz do repositorio:
#
# RSCRIPT so3.3/executar_avaliacao_yeojohnson.R \
#   infraestrutural INF02_RECURSOS_HIDRICOS_PC
#
# R base.
# Nao altera os dados brutos nem os produtos tratados oficiais.
# A transformacao e candidata, sujeita a validacao metodologica.

avaliar_yeojohnson <- function(
    args = commandArgs(trailingOnly = TRUE)) {

  modulo <- paste0(
    "so3.3/R/03_diagnostico/",
    "estatistica_brutos_conjuntos.R"
  )

  if (!file.exists(modulo)) {
    stop("Execute a partir da raiz do repositorio.")
  }

  source(modulo, local = TRUE)

  if (length(args) != 2L) {
    stop(
      "Uso: RSCRIPT ",
      "so3.3/executar_avaliacao_yeojohnson.R ",
      "DIMENSAO INDICADOR"
    )
  }

  dimensao <- tolower(args[[1L]])
  id <- args[[2L]]

  catalogo <- estat_so33_catalogo()

  meta <- catalogo[
    catalogo$indicador == id &
      catalogo$dimensao == dimensao,
    ,
    drop = FALSE
  ]

  if (nrow(meta) != 1L) {
    stop("Indicador ou dimensao invalidos: ", dimensao, " / ", id)
  }

  anos <- estat_so33_anos()

  entradas <- lapply(
    anos,
    function(ano) estat_so33_ler_bruto(id, ano)
  )

  base <- do.call(
    rbind,
    lapply(entradas, `[[`, "dados")
  )

  series <- estat_so33_series(
    base,
    meta$natureza
  )

  if (length(series) != 1L) {
    stop(
      "Esta versao avalia apenas indicadores ",
      "territoriais compartilhados."
    )
  }

  d <- series[[1L]]
  x <- d$valor

  # INF02: verificar a disponibilidade dos metadados.
  campos_status <- c(
    "status_calculo",
    "situacao_qualidade",
    "compatibilidade_territorial"
  )

  if (
    id == "INF02_RECURSOS_HIDRICOS_PC" &&
    !all(campos_status %in% names(d))
  ) {
    stop("Campos de status INF02 ausentes.")
  }

  validos <- which(is.finite(x))

  if (
    length(validos) < 4L ||
    stats::sd(x[validos]) == 0
  ) {
    stop("Serie insuficiente ou constante: ", id)
  }

  if (any(!is.na(x) & !is.finite(x))) {
    stop("A serie contem valores infinitos.")
  }

  # ---------------------------------------------------------
  # 1. Transformacao Yeo-Johnson
  # ---------------------------------------------------------

  yeojohnson <- function(v, lambda) {

    z <- v

    positivos <- which(
      !is.na(v) & v >= 0
    )

    negativos <- which(
      !is.na(v) & v < 0
    )

    if (length(positivos)) {

      z[positivos] <- if (abs(lambda) < 1e-8) {

        log1p(v[positivos])

      } else {

        expm1(
          lambda * log1p(v[positivos])
        ) / lambda

      }
    }

    if (length(negativos)) {

      z[negativos] <- if (abs(lambda - 2) < 1e-8) {

        -log1p(-v[negativos])

      } else {

        -expm1(
          (2 - lambda) * log1p(-v[negativos])
        ) / (2 - lambda)

      }
    }

    z
  }

  # ---------------------------------------------------------
  # 2. Estimacao do parametro lambda
  # ---------------------------------------------------------

  objetivo <- function(lambda) {

    z <- yeojohnson(
      x[validos],
      lambda
    )

    if (!all(is.finite(z))) {
      return(Inf)
    }

    variancia <- mean(
      (z - mean(z))^2
    )

    if (
      !is.finite(variancia) ||
      variancia <= 0
    ) {
      return(Inf)
    }

    # Log-verossimilhanca perfilada,
    # incluindo o termo jacobiano.

    -(
      -length(z) / 2 * log(variancia) +
        (lambda - 1) *
        sum(
          sign(x[validos]) *
            log1p(abs(x[validos]))
        )
    )
  }

  ajuste <- stats::optimize(
    objetivo,
    interval = c(-3, 3),
    tol = 1e-6
  )

  lambda <- ajuste$minimum

  y <- yeojohnson(
    x,
    lambda
  )

  # ---------------------------------------------------------
  # 3. Integridade e monotonicidade
  # ---------------------------------------------------------

  ausencias_preservadas <- identical(
    which(is.na(x)),
    which(is.na(y))
  )

  if (
    !ausencias_preservadas ||
    any(!is.finite(y[validos]))
  ) {
    stop("Falha de integridade da transformacao.")
  }

  ux <- sort(
    unique(x[validos])
  )

  uy <- yeojohnson(
    ux,
    lambda
  )

  monotona <- (
    length(uy) <= 1L ||
      all(diff(uy) > 0)
  )

  if (!monotona) {
    stop("Falha de monotonicidade numerica.")
  }

  # ---------------------------------------------------------
  # 4. Diagnostico estatistico conjunto
  # ---------------------------------------------------------

  m0 <- estat_so33_momentos_coinr(x)
  m1 <- estat_so33_momentos_coinr(y)

  normalizar <- function(v) {

    limites <- range(
      v,
      na.rm = TRUE
    )

    if (diff(limites) <= 0) {
      stop("Amplitude nula para normalizacao.")
    }

    (v - limites[1]) / diff(limites)
  }

  nx <- normalizar(x)
  ny <- normalizar(y)

  # Normalizacao somente diagnostica.
  # Nao representa o produto PRAIS4 definitivo.

  dnorm <- abs(ny - nx)

  mediana_segura <- function(v) {

    if (all(is.na(v))) {
      return(NA_real_)
    }

    stats::median(
      v,
      na.rm = TRUE
    )
  }

  q_seguro <- function(v, p) {

    if (all(is.na(v))) {
      return(NA_real_)
    }

    unname(
      stats::quantile(
        v,
        probs = p,
        na.rm = TRUE
      )
    )
  }

  iqr0 <- stats::IQR(
    nx,
    na.rm = TRUE
  )

  iqr1 <- stats::IQR(
    ny,
    na.rm = TRUE
  )

  # ---------------------------------------------------------
  # 5. Diagnosticos anuais
  # ---------------------------------------------------------

  descritivas <- do.call(
    rbind,
    lapply(anos, function(ano) {

      idx <- d$ano == ano

      xa <- x[idx]
      ya <- y[idx]

      mxa <- estat_so33_momentos_coinr(xa)
      mya <- estat_so33_momentos_coinr(ya)

      data.frame(

        ano = ano,

        n_validos = sum(!is.na(xa)),
        n_ausentes = sum(is.na(xa)),

        mediana_original = mediana_segura(xa),
        mediana_yj = mediana_segura(ya),

        mediana_norm_original = mediana_segura(nx[idx]),
        mediana_norm_yj = mediana_segura(ny[idx]),

        p05_norm_original = q_seguro(nx[idx], 0.05),
        p05_norm_yj = q_seguro(ny[idx], 0.05),

        p95_norm_original = q_seguro(nx[idx], 0.95),
        p95_norm_yj = q_seguro(ny[idx], 0.95),

        assimetria_original = mxa$assimetria,
        assimetria_yj = mya$assimetria,

        curtose_original = mxa$curtose_excesso,
        curtose_yj = mya$curtose_excesso,

        stringsAsFactors = FALSE
      )
    })
  )

  # ---------------------------------------------------------
  # 6. Comparacao temporal
  # ---------------------------------------------------------

  comparacoes <- data.frame(

    periodo = c(
      "2000_2010",
      "2010_2022",
      "2000_2022"
    ),

    delta_mediana_norm_original = c(

      diff(
        descritivas$mediana_norm_original
      ),

      descritivas$mediana_norm_original[3] -
        descritivas$mediana_norm_original[1]
    ),

    delta_mediana_norm_yj = c(

      diff(
        descritivas$mediana_norm_yj
      ),

      descritivas$mediana_norm_yj[3] -
        descritivas$mediana_norm_yj[1]
    ),

    stringsAsFactors = FALSE
  )

  comparacoes$sentido_preservado <- with(
    comparacoes,

    sign(delta_mediana_norm_original) ==
      sign(delta_mediana_norm_yj)
  )

  # ---------------------------------------------------------
  # 7. Resumo conjunto
  # ---------------------------------------------------------

  sumario <- data.frame(

    indicador = id,
    grupo = "Compartilhado",

    n_validos = length(validos),

    lambda = lambda,

    assimetria_original = m0$assimetria,
    curtose_original = m0$curtose_excesso,
    triagem_original = m0$status,

    assimetria_yj = m1$assimetria,
    curtose_yj = m1$curtose_excesso,
    triagem_yj = m1$status,

    monotonicidade_preservada = monotona,
    ausencias_preservadas = ausencias_preservadas,

    iqr_norm_original = iqr0,
    iqr_norm_yj = iqr1,

    alteracao_rel_iqr_norm = if (iqr0 > 0) {
      abs(iqr1 / iqr0 - 1)
    } else {
      NA_real_
    },

    mediana_delta_norm = mediana_segura(dnorm),
    p95_delta_norm = q_seguro(dnorm, 0.95),

    decisao = "CANDIDATA_YJ_PENDENTE_VALIDACAO",

    stringsAsFactors = FALSE
  )

  # ---------------------------------------------------------
  # 8. Diretorio de resultados
  # ---------------------------------------------------------

  destino <- file.path(

    "so3.3",
    "outputs",
    "intermediario",
    "estatistica",
    "avaliacao_yj",
    id,

    format(
      Sys.time(),
      "%Y%m%dT%H%M%S"
    )
  )

  if (dir.exists(destino)) {
    stop("Diretorio existente; nao sobrescrever.")
  }

  if (
    !dir.create(
      destino,
      recursive = TRUE,
      showWarnings = FALSE
    )
  ) {
    stop("Nao foi possivel criar a pasta de saida.")
  }

  gravar <- function(v, nome) {

    utils::write.table(

      v,

      file.path(
        destino,
        nome
      ),

      sep = ";",
      dec = ".",

      row.names = FALSE,
      col.names = TRUE,

      quote = TRUE,
      na = "",

      fileEncoding = "UTF-8"
    )
  }

  # ---------------------------------------------------------
  # 9. Produtos consolidados
  # ---------------------------------------------------------

  gravar(
    sumario,
    "01_resumo_yj.csv"
  )

  gravar(
    descritivas,
    "02_diagnosticos_anuais.csv"
  )

  gravar(
    comparacoes,
    "03_comparacao_temporal.csv"
  )

  inventario <- do.call(
    rbind,
    lapply(entradas, `[[`, "inventario")
  )

  gravar(
    inventario,
    "04_fontes_md5.csv"
  )

  # ---------------------------------------------------------
  # 10. Valores municipais candidatos
  # ---------------------------------------------------------

  candidato <- d[
    ,
    c(
      "ano",
      "uf",
      "cod_mun",
      "nm_mun"
    ),
    drop = FALSE
  ]

  candidato$valor_original <- x
  candidato$valor_yj_candidato <- y

  if (id == "INF02_RECURSOS_HIDRICOS_PC") {

    for (campo in campos_status) {
      candidato[[campo]] <- d[[campo]]
    }

    for (campo in campos_status) {

      if (
        !identical(
          candidato[[campo]],
          d[[campo]]
        )
      ) {
        stop("Metadado INF02 alterado.")
      }
    }
  }

  gravar(
    candidato,
    "05_valores_candidatos.csv"
  )

  # ---------------------------------------------------------
  # 11. Diagnostico dos status do INF02
  # ---------------------------------------------------------

  if (id == "INF02_RECURSOS_HIDRICOS_PC") {

    partes <- list()

    for (ano in anos) {

      da <- candidato[
        candidato$ano == ano,
        ,
        drop = FALSE
      ]

      for (campo in campos_status) {

        tab <- table(
          da[[campo]],
          useNA = "ifany"
        )

        partes[[length(partes) + 1L]] <- data.frame(

          ano = ano,

          campo = campo,

          categoria = names(tab),

          frequencia = as.integer(tab),

          stringsAsFactors = FALSE
        )
      }
    }

    gravar(
      do.call(rbind, partes),
      "06_status_INF02.csv"
    )
  }

  # ---------------------------------------------------------
  # 12. Manifesto da execucao
  # ---------------------------------------------------------

  writeLines(

    c(

      paste(
        id,
        ": sem winsorizacao; lambda unico para tres censos."
      ),

      "Yeo-Johnson em avaliacao, NAO aprovada automaticamente.",

      "As mudancas min-max sao documentadas, sem veto automatico.",

      "Um unico valor territorial por municipio/ano.",

      "Nenhuma triplicacao por sexo.",

      "INF02: status de calculo, qualidade e compatibilidade preservados.",

      "Nenhum dado bruto ou tratado oficial foi modificado.",

      paste(
        "R:",
        R.version.string
      ),

      paste(
        "UTC:",
        format(
          Sys.time(),
          tz = "UTC",
          usetz = TRUE
        )
      )
    ),

    file.path(
      destino,
      "LEIA_ME.txt"
    )
  )

  # ---------------------------------------------------------
  # 13. Resumo no terminal
  # ---------------------------------------------------------

  print(
    sumario,
    row.names = FALSE
  )

  print(
    comparacoes,
    row.names = FALSE
  )

  message(
    "Diagnostico Yeo-Johnson concluido: ",
    normalizePath(destino)
  )

  invisible(
    list(
      resumo = sumario,
      anual = descritivas,
      temporal = comparacoes
    )
  )
}

if (sys.nframe() == 0L) {
  avaliar_yeojohnson()
}

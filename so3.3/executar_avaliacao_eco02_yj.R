#!/usr/bin/env Rscript
# PRAIS4/SO3.3 - ECO02: avaliacao isolada de Yeo-Johnson.
# Executar da raiz: RSCRIPT so3.3/executar_avaliacao_eco02_yj.R
# Somente R base. Nao altera brutos nem produtos tratados oficiais.
# O candidato nao e aprovado para producao automaticamente.

avaliar_eco02_yj <- function() {
  modulo <- 'so3.3/R/03_diagnostico/estatistica_brutos_conjuntos.R'
  if (!file.exists(modulo)) stop('Execute na raiz do repositorio.')
  source(modulo, local = TRUE)
  id <- 'ECO02_PIBPC'
  anos <- estat_so33_anos()
  entradas <- lapply(anos, function(ano) estat_so33_ler_bruto(id, ano))
  base <- do.call(rbind, lapply(entradas, `[[`, 'dados'))
  series <- estat_so33_series(base, 'territorial_compartilhado')
  stopifnot(identical(names(series), 'Compartilhado'))
  d <- series[['Compartilhado']]
  x <- d$valor
  validos <- which(is.finite(x))
  if (length(validos) < 4L || stats::sd(x[validos]) == 0) {
    stop('Serie ECO02 insuficiente ou constante.')
  }
  if (any(!is.na(x) & !is.finite(x))) stop('Valores infinitos na serie.')

  yeojohnson <- function(v, lambda) {
    z <- v
    p <- which(!is.na(v) & v >= 0)
    n <- which(!is.na(v) & v < 0)
    if (length(p)) {
      z[p] <- if (abs(lambda) < 1e-8) log1p(v[p]) else
        expm1(lambda * log1p(v[p])) / lambda
    }
    if (length(n)) {
      z[n] <- if (abs(lambda - 2) < 1e-8) -log1p(-v[n]) else
        -expm1((2 - lambda) * log1p(-v[n])) / (2 - lambda)
    }
    z
  }
  objetivo <- function(lambda) {
    z <- yeojohnson(x[validos], lambda)
    if (!all(is.finite(z))) return(Inf)
    variancia <- mean((z - mean(z))^2)
    if (!is.finite(variancia) || variancia <= 0) return(Inf)
    # Log-verossimilhanca perfilada de Yeo-Johnson, incluindo jacobiano.
    -(-length(z) / 2 * log(variancia) +
        (lambda - 1) * sum(sign(x[validos]) * log1p(abs(x[validos]))))
  }
  ajuste <- stats::optimize(objetivo, interval = c(-3, 3), tol = 1e-6)
  lambda <- ajuste$minimum
  y <- yeojohnson(x, lambda)
  if (!identical(which(is.na(x)), which(is.na(y))) ||
      any(!is.finite(y[validos]))) stop('Falha de integridade em Yeo-Johnson.')

  # Verificacao por valores distintos ordenados, sem comparacoes quadratiques.
  ux <- sort(unique(x[validos]))
  uy <- yeojohnson(ux, lambda)
  monotona <- length(uy) <= 1L || all(diff(uy) > 0)
  if (!monotona) stop('Falha de monotonicidade numerica.')
  m0 <- estat_so33_momentos_coinr(x)
  m1 <- estat_so33_momentos_coinr(y)
  normalizar <- function(v) {
    limites <- range(v, na.rm = TRUE)
    if (diff(limites) <= 0) stop('Amplitude nula para normalizacao diagnostica.')
    (v - limites[1]) / diff(limites)
  }
  nx <- normalizar(x)
  ny <- normalizar(y)
  # Mudancas na escala 0-1 sao efeitos diagnosticos, nao veto automatico.
  dnorm <- abs(ny - nx)
  mediana_segura <- function(v) {
    if (all(is.na(v))) return(NA_real_)
    stats::median(v, na.rm = TRUE)
  }
  q_seguro <- function(v, p) {
    if (all(is.na(v))) return(NA_real_)
    unname(stats::quantile(v, p, na.rm = TRUE))
  }
  iqr0 <- stats::IQR(nx, na.rm = TRUE)
  iqr1 <- stats::IQR(ny, na.rm = TRUE)
  descritivas <- do.call(rbind, lapply(anos, function(ano) {
    idx <- d$ano == ano
    xa <- x[idx]; ya <- y[idx]
    mxa <- estat_so33_momentos_coinr(xa)
    mya <- estat_so33_momentos_coinr(ya)
    data.frame(ano = ano, n_validos = sum(!is.na(xa)),
      n_ausentes = sum(is.na(xa)),
      mediana_original = mediana_segura(xa),
      mediana_yj = mediana_segura(ya),
      mediana_norm_original = mediana_segura(nx[idx]),
      mediana_norm_yj = mediana_segura(ny[idx]),
      p05_norm_original = q_seguro(nx[idx], .05),
      p05_norm_yj = q_seguro(ny[idx], .05),
      p95_norm_original = q_seguro(nx[idx], .95),
      p95_norm_yj = q_seguro(ny[idx], .95),
      assimetria_original = mxa$assimetria,
      assimetria_yj = mya$assimetria,
      curtose_original = mxa$curtose_excesso,
      curtose_yj = mya$curtose_excesso)
  }))
  comparacoes <- data.frame(
    periodo = c('2000_2010', '2010_2022', '2000_2022'),
    delta_mediana_norm_original = c(diff(descritivas$mediana_norm_original),
      descritivas$mediana_norm_original[3] - descritivas$mediana_norm_original[1]),
    delta_mediana_norm_yj = c(diff(descritivas$mediana_norm_yj),
      descritivas$mediana_norm_yj[3] - descritivas$mediana_norm_yj[1])
  )
  comparacoes$sentido_preservado <- with(comparacoes,
    sign(delta_mediana_norm_original) == sign(delta_mediana_norm_yj))
  sumario <- data.frame(
    indicador = id, grupo = 'Compartilhado',
    n_validos = length(validos), lambda = lambda,
    assimetria_original = m0$assimetria, curtose_original = m0$curtose_excesso,
    triagem_original = m0$status,
    assimetria_yj = m1$assimetria, curtose_yj = m1$curtose_excesso,
    triagem_yj = m1$status,
    monotonicidade_preservada = monotona,
    ausencias_preservadas = identical(which(is.na(x)), which(is.na(y))),
    iqr_norm_original = iqr0, iqr_norm_yj = iqr1,
    alteracao_rel_iqr_norm = if (iqr0 > 0) abs(iqr1 / iqr0 - 1) else NA_real_,
    mediana_delta_norm = mediana_segura(dnorm),
    p95_delta_norm = q_seguro(dnorm, .95),
    decisao = 'CANDIDATA_YJ_PENDENTE_VALIDACAO',
    stringsAsFactors = FALSE
  )
  destino <- file.path('so3.3', 'outputs', 'intermediario', 'estatistica',
    'avaliacao_yj', id, format(Sys.time(), '%Y%m%dT%H%M%S'))
  if (dir.exists(destino)) stop('Saida existente; nao sobrescrever: ', destino)
  if (!dir.create(destino, recursive = TRUE, showWarnings = FALSE))
    stop('Nao foi possivel criar a pasta de saida.')
  gravar <- function(v, nome) utils::write.table(v, file.path(destino, nome),
    sep = ';', dec = '.', row.names = FALSE, col.names = TRUE,
    quote = TRUE, na = '', fileEncoding = 'UTF-8')
  gravar(sumario, '01_resumo_yj.csv')
  gravar(descritivas, '02_diagnosticos_anuais.csv')
  gravar(comparacoes, '03_comparacao_temporal.csv')
  gravar(do.call(rbind, lapply(entradas, `[[`, 'inventario')),
    '04_fontes_md5.csv')
  # CSV municipal candidato: leitura posterior somente; nao interfere em producao.
  candidato <- d[, c('ano', 'uf', 'cod_mun', 'nm_mun'), drop = FALSE]
  candidato$valor_original <- x
  candidato$valor_yj_candidato <- y
  gravar(candidato, '05_valores_candidatos.csv')
  writeLines(c('ECO02_PIBPC: sem winsorizacao; lambda unico para tres censos.',
    'Yeo-Johnson em avaliacao, NAO aprovada automaticamente.',
    'As mudancas min-max sao documentadas, sem veto por limites arbitrarios.',
    'Um unico valor territorial por municipio/ano; nenhuma triplicacao por sexo.',
    'Nenhum dado bruto ou tratado oficial foi modificado.',
    paste('R:', R.version.string),
    paste('UTC:', format(Sys.time(), tz='UTC', usetz=TRUE))),
    file.path(destino, 'LEIA_ME.txt'))
  print(sumario, row.names = FALSE)
  print(comparacoes, row.names = FALSE)
  message('Diagnostico ECO02 concluido: ', normalizePath(destino))
  invisible(list(resumo=sumario, anual=descritivas, temporal=comparacoes))
}

if (sys.nframe() == 0L) avaliar_eco02_yj()

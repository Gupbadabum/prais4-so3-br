# ============================================================
# PRAIS4 - SO3.3
# ESTABILIZACAO MUNICIPAL DO q(5) TRUSSELL (MAES 30-34 ANOS)
#
# Empirical Bayes para evento raro em pequena area:
#
#   - gama-Poisson  (modelo principal)
#   - beta-binomial (modelo de comparacao)
#
# Depende de expectativa_vida_indireta.R, que deve ser
# carregado antes (usa coeficientes_trussell_west e a saida
# de estimar_mortalidade_trussell()).
#
# Este arquivo contem SOMENTE funcoes.
# Nao deve executar processamento censitario diretamente.
#
# DECISOES DE PROJETO
#
#   1. O modelo e ajustado sobre D (proporcao de filhos
#      falecidos), nao sobre q. O multiplicador k e o tempo
#      t sao aplicados depois, no nivel da UF (k_modo = "uf"),
#      para nao carregar o ruido das razoes P1/P2 e P2/P3
#      municipais.
#
#   2. Pseudocontagens para o modelo:
#
#      Base principal: pesos normalizados ao tamanho da amostra
#
#        fator = n_mulheres / soma_pesos
#        B_ef  = filhos_nv         * fator
#        d_ef  = filhos_falecidos * fator
#
#      Essa normalizacao preserva exatamente D ponderado e
#      coloca a exposicao em escala proxima a quantidade
#      efetivamente observada na amostra.
#
#      Sensibilidade: normalizacao pelo n_efetivo de Kish:
#
#        fator = n_efetivo / soma_pesos
#
#      Kish NAO e a variancia de desenho: nao captura
#      conglomeracao por setor nem correlacao entre filhos da
#      mesma mae. Os zeros observados sao definidos pelas
#      contagens raw, nunca por arredondamento das pseudocontagens.
#
#   3. Ancora: proporcao D da UF (soma ponderada dos obitos /
#      soma ponderada dos nascidos, municipios validos).
#      theta = risco relativo municipal em relacao a ancora.
#
#   4. Hiperparametro estimado por estrato (ano x grupo x
#      regiao) por maxima verossimilhanca marginal. Estrato
#      pequeno ou sem convergencia usa o ajuste nacional
#      (ano x grupo), com flag.
#
#   5. Covariaveis (opcionais) restritas as derivadas dos
#      proprios insumos do calculo do q(x).
#
#   6. Nenhum valor e truncado. Flags registram a situacao.
# ============================================================


if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("O pacote 'data.table' e necessario para o processamento.")
}


# ============================================================
# 7. UTILITARIOS
# ============================================================

# Regiao a partir do codigo IBGE de 2 digitos da UF
# (1 Norte, 2 Nordeste, 3 Sudeste, 4 Sul, 5 Centro-Oeste).

mapear_regiao_uf <- function(uf) {

  primeiro <- substr(trimws(as.character(uf)), 1L, 1L)

  regioes <- c(
    "1" = "Norte",
    "2" = "Nordeste",
    "3" = "Sudeste",
    "4" = "Sul",
    "5" = "Centro-Oeste"
  )

  regiao <- unname(regioes[primeiro])

  if (anyNA(regiao)) {
    stop(
      "Codigo de UF nao reconhecido em mapear_regiao_uf(). ",
      "Esperado codigo IBGE de 2 digitos."
    )
  }

  regiao
}


# Covariaveis permitidas (todas derivadas dos insumos do q(x)).

COVARIAVEIS_Q5_EB <- c(
  "log_nascidos_ef",
  "paridade_alvo",
  "razao_P1_P2",
  "razao_P2_P3",
  "log_rr_adjacentes"
)


# ============================================================
# 8. PREPARACAO DOS INSUMOS (pseudocontagens e ancoras UF)
# ============================================================
#
# Entrada: saida de estimar_mortalidade_trussell().
# Saida: uma linha por ano x uf x municipio x grupo, para o
# grupo etario materno alvo (padrao 30-34, q(5)).

preparar_insumos_q5_eb <- function(
  trussell,
  idade_mae_alvo = "30-34",
  idades_adjacentes = c("25-29", "35-39"),
  base_contagem = c("normalizada_amostra", "kish")
) {

  base_contagem <- match.arg(base_contagem)

  if (!exists("coeficientes_trussell_west", inherits = TRUE)) {
    stop(
      "Objeto 'coeficientes_trussell_west' nao encontrado. ",
      "Carregue expectativa_vida_indireta.R antes."
    )
  }

  colunas_necessarias <- c(
    "ano", "uf", "cod_mun", "grupo", "idade_mae",
    "n_mulheres", "n_efetivo", "soma_pesos",
    "filhos_nv_raw", "filhos_vivos_raw", "filhos_falecidos_raw",
    "filhos_nv", "proporcao_falecidos",
    "paridade", "razao_P1_P2", "razao_P2_P3",
    "k_trussell", "tempo_referencia", "ano_decimal_censo"
  )

  faltantes <- setdiff(colunas_necessarias, names(trussell))

  if (length(faltantes) > 0L) {
    stop(
      "Colunas ausentes na saida Trussell: ",
      paste(faltantes, collapse = ", ")
    )
  }

  d <- data.table::as.data.table(data.table::copy(trussell))

  # ----------------------------------------------------------
  # Obitos ponderados e fator de contagem efetiva
  # ----------------------------------------------------------

  d[
    ,
    obitos_pond := data.table::fifelse(
      !is.na(filhos_nv) & filhos_nv > 0 & !is.na(proporcao_falecidos),
      filhos_nv * proporcao_falecidos,
      data.table::fifelse(
        !is.na(filhos_nv) & filhos_nv == 0,
        0,
        NA_real_
      )
    )
  ]

  # base_contagem = "normalizada_amostra": n_mulheres / soma_pesos
  #   Base principal: preserva D ponderado e normaliza a soma
  #   dos pesos ao tamanho observado da amostra no dominio.
  #
  # base_contagem = "kish": n_efetivo / soma_pesos
  #   Sensibilidade conservadora associada a heterogeneidade
  #   dos pesos. Nao representa variancia oficial de desenho.

  d[
    ,
    fator_efetivo := data.table::fifelse(
      !is.na(soma_pesos) & soma_pesos > 0,
      (if (base_contagem == "normalizada_amostra") n_mulheres else n_efetivo) /
        soma_pesos,
      NA_real_
    )
  ]

  d[
    ,
    `:=`(
      B_ef = filhos_nv * fator_efetivo,
      d_ef = obitos_pond * fator_efetivo
    )
  ]

  d[
    ,
    dado_valido := (
      is.finite(B_ef) & is.finite(d_ef) &
        B_ef >= 0 & d_ef >= 0 &
        d_ef <= B_ef * (1 + 1e-9)
    ) %in% TRUE
  ]

  d[dado_valido == FALSE, `:=`(B_ef = NA_real_, d_ef = NA_real_)]
  d[dado_valido == TRUE & d_ef > B_ef, d_ef := B_ef]

  # ----------------------------------------------------------
  # Ancora UF do grupo alvo: D_uf
  # ----------------------------------------------------------

  ancora <- d[
    idade_mae == idade_mae_alvo & dado_valido == TRUE,
    .(
      B_pond_uf = sum(filhos_nv),
      O_pond_uf = sum(obitos_pond)
    ),
    by = .(ano, uf, grupo)
  ]

  ancora[
    ,
    D_uf := data.table::fifelse(
      B_pond_uf > 0,
      O_pond_uf / B_pond_uf,
      NA_real_
    )
  ]

  # ----------------------------------------------------------
  # k e t no nivel da UF (razoes de paridade agregadas)
  # ----------------------------------------------------------

  faixas_p <- c("15-19", "20-24", "25-29")

  par_uf <- d[
    idade_mae %in% faixas_p & !is.na(filhos_nv) & !is.na(soma_pesos),
    .(B = sum(filhos_nv), W = sum(soma_pesos)),
    by = .(ano, uf, grupo, idade_mae)
  ]

  par_uf[, P := data.table::fifelse(W > 0, B / W, NA_real_)]

  p_uf <- data.table::dcast(
    par_uf,
    ano + uf + grupo ~ idade_mae,
    value.var = "P"
  )

  for (faixa in faixas_p) {
    if (!faixa %in% names(p_uf)) p_uf[, (faixa) := NA_real_]
  }

  data.table::setnames(
    p_uf,
    old = faixas_p,
    new = c("P1_uf", "P2_uf", "P3_uf")
  )

  p_uf[
    ,
    `:=`(
      razao_P1_P2_uf = data.table::fifelse(
        !is.na(P1_uf) & !is.na(P2_uf) & P2_uf > 0, P1_uf / P2_uf, NA_real_
      ),
      razao_P2_P3_uf = data.table::fifelse(
        !is.na(P2_uf) & !is.na(P3_uf) & P3_uf > 0, P2_uf / P3_uf, NA_real_
      )
    )
  ]

  cf <- coeficientes_trussell_west[idade_mae == idade_mae_alvo]

  if (nrow(cf) != 1L) {
    stop("Coeficientes Trussell nao encontrados para ", idade_mae_alvo)
  }

  p_uf[
    ,
    `:=`(
      k_uf = cf$a_k + cf$b_k * razao_P1_P2_uf + cf$c_k * razao_P2_P3_uf,
      t_uf = cf$a_t + cf$b_t * razao_P1_P2_uf + cf$c_t * razao_P2_P3_uf
    )
  ]

  ancora <- merge(
    ancora,
    p_uf[, .(ano, uf, grupo, razao_P1_P2_uf, razao_P2_P3_uf, k_uf, t_uf)],
    by = c("ano", "uf", "grupo"),
    all.x = TRUE,
    sort = FALSE
  )

  # ----------------------------------------------------------
  # Covariavel interna: risco relativo dos grupos adjacentes
  #
  # (obitos efetivos + 0,5) / (esperados pela UF + 0,5),
  # agrupando as idades maternas adjacentes ao grupo alvo.
  # Sao outras maes, no mesmo municipio e censo.
  # ----------------------------------------------------------

  adj <- d[idade_mae %in% idades_adjacentes & dado_valido == TRUE]

  uf_adj <- adj[
    ,
    .(D_uf_g = sum(obitos_pond) / sum(filhos_nv)),
    by = .(ano, uf, grupo, idade_mae)
  ]

  adj <- merge(
    adj,
    uf_adj,
    by = c("ano", "uf", "grupo", "idade_mae"),
    all.x = TRUE,
    sort = FALSE
  )

  adj[, E_ef := B_ef * D_uf_g]

  cov_adj <- adj[
    ,
    .(
      d_adj = sum(d_ef, na.rm = TRUE),
      E_adj = sum(E_ef, na.rm = TRUE)
    ),
    by = .(ano, uf, cod_mun, grupo)
  ]

  cov_adj[, log_rr_adjacentes := log((d_adj + 0.5) / (E_adj + 0.5))]

  # ----------------------------------------------------------
  # Base municipal do grupo alvo
  # ----------------------------------------------------------

  alvo <- d[idade_mae == idade_mae_alvo]

  alvo[
    ,
    `:=`(
      regiao = mapear_regiao_uf(uf),
      D_bruto = data.table::fifelse(
        is.finite(B_ef) & B_ef > 0,
        d_ef / B_ef,
        NA_real_
      ),
      k_municipal = k_trussell,
      t_municipal = tempo_referencia,
      paridade_alvo = paridade,
      log_nascidos_ef = data.table::fifelse(
        is.finite(B_ef) & B_ef > 0,
        log(B_ef),
        NA_real_
      ),
      filhos_nv_pond = filhos_nv,
      filhos_falecidos_pond = obitos_pond,
      zero_observado_raw = (
        is.finite(filhos_nv_raw) & filhos_nv_raw > 0 &
          is.finite(filhos_falecidos_raw) & filhos_falecidos_raw == 0
      ) %in% TRUE
    )
  ]

  alvo <- merge(
    alvo,
    ancora[, .(ano, uf, grupo, D_uf, k_uf, t_uf)],
    by = c("ano", "uf", "grupo"),
    all.x = TRUE,
    sort = FALSE
  )

  alvo <- merge(
    alvo,
    cov_adj[, .(ano, uf, cod_mun, grupo, log_rr_adjacentes)],
    by = c("ano", "uf", "cod_mun", "grupo"),
    all.x = TRUE,
    sort = FALSE
  )

  alvo[
    ,
    `:=`(
      q5_uf_trussell = k_uf * D_uf,
      ano_referencia_uf = ano_decimal_censo - t_uf
    )
  ]

  colunas_saida <- c(
    "ano", "uf", "regiao", "cod_mun", "grupo",
    "n_mulheres", "soma_pesos", "n_efetivo",
    "filhos_nv_raw", "filhos_vivos_raw", "filhos_falecidos_raw",
    "filhos_nv_pond", "filhos_falecidos_pond",
    "zero_observado_raw",
    "fator_efetivo", "B_ef", "d_ef", "dado_valido", "D_bruto",
    "D_uf", "k_uf", "t_uf", "q5_uf_trussell",
    "k_municipal", "t_municipal",
    "ano_decimal_censo", "ano_referencia_uf",
    COVARIAVEIS_Q5_EB
  )

  resultado <- alvo[, ..colunas_saida]
  resultado[, base_contagem := base_contagem]

  data.table::setcolorder(
    resultado,
    c("ano", "uf", "regiao", "cod_mun", "grupo", "base_contagem",
      setdiff(names(resultado), c("ano", "uf", "regiao", "cod_mun", "grupo", "base_contagem")))
  )

  data.table::setorder(resultado, ano, grupo, uf, cod_mun)

  resultado[]
}


# ============================================================
# 9. NUCLEO ESTATISTICO
# ============================================================

# log-pmf marginal gama-Poisson (binomial negativa):
#   d | theta ~ Poisson(E * theta),  theta ~ Gama(media = exp(eta), forma = a)

.q5eb_logpmf_gp <- function(d, E, eta, a) {

  mu <- E * exp(eta)

  lgamma(d + a) - lgamma(a) - lgamma(d + 1) +
    a * log(a / (a + mu)) +
    d * log(mu / (a + mu))
}


# log-pmf marginal beta-binomial, media p0 e precisao phi.
# Com contagens nao inteiras (efetivas) e uma quase-verossimilhanca.

.q5eb_logpmf_bb <- function(d, n, p0, phi) {

  alfa <- p0 * phi
  beta <- (1 - p0) * phi

  lgamma(n + 1) - lgamma(d + 1) - lgamma(n - d + 1) +
    lbeta(d + alfa, n - d + beta) - lbeta(alfa, beta)
}


# Matriz de covariaveis padronizada (media 0, dp 1).
# Faltantes viram 0 (media) e sao marcados como imputados.

.q5eb_montar_X <- function(dat, covariaveis, centro = NULL, escala = NULL) {

  if (length(covariaveis) == 0L) {
    return(list(
      X = NULL, centro = NULL, escala = NULL,
      imputado = rep(FALSE, nrow(dat))
    ))
  }

  M <- do.call(
    cbind,
    lapply(covariaveis, function(v) as.numeric(dat[[v]]))
  )

  M[!is.finite(M)] <- NA_real_

  imputado <- rowSums(is.na(M)) > 0

  if (is.null(centro)) {
    centro <- colMeans(M, na.rm = TRUE)
    escala <- apply(M, 2L, stats::sd, na.rm = TRUE)
    centro[!is.finite(centro)] <- 0
    escala[!is.finite(escala) | escala == 0] <- 1
  }

  Z <- sweep(sweep(M, 2L, centro, "-"), 2L, escala, "/")
  Z[is.na(Z)] <- 0

  list(X = Z, centro = centro, escala = escala, imputado = imputado)
}


# Maxima verossimilhanca marginal.
# Parametros: (b0, b1..bk) se houver covariaveis, e log do
# hiperparametro (a no gama-Poisson, phi no beta-binomial).

.q5eb_ajustar <- function(d, n, E, p_uf, Z, modelo) {

  nb <- if (is.null(Z)) 0L else ncol(Z) + 1L

  eta_de <- function(par) {
    if (nb == 0L) {
      rep(0, length(d))
    } else {
      as.numeric(par[1L] + Z %*% par[2L:nb])
    }
  }

  ll <- function(par) {

    eta <- eta_de(par)
    h <- exp(par[nb + 1L])

    v <- if (modelo == "gama_poisson") {
      .q5eb_logpmf_gp(d, E, eta, h)
    } else {
      .q5eb_logpmf_bb(d, n, stats::plogis(stats::qlogis(p_uf) + eta), h)
    }

    s <- sum(v)

    if (is.finite(s)) s else -1e10
  }

  h0 <- if (modelo == "gama_poisson") {
    log(10)
  } else {
    log(10 / mean(p_uf))
  }

  lim_h <- c(-3, 16)

  ajuste <- tryCatch(
    stats::optim(
      par = c(rep(0, nb), h0),
      fn = ll,
      method = "L-BFGS-B",
      lower = c(rep(-5, nb), lim_h[1L]),
      upper = c(rep(5, nb), lim_h[2L]),
      control = list(fnscale = -1, maxit = 500L)
    ),
    error = function(e) NULL
  )

  if (is.null(ajuste)) return(NULL)

  lh <- ajuste$par[nb + 1L]

  list(
    par = ajuste$par,
    nb = nb,
    n_par = nb + 1L,
    loglik = ajuste$value,
    convergencia = ajuste$convergence == 0L,
    h = exp(lh),
    no_limite = lh >= lim_h[2L] - 1e-6 || lh <= lim_h[1L] + 1e-6
  )
}


# Eta (log do risco relativo a priori) para novas linhas.

.q5eb_eta <- function(ajuste, Z) {

  if (ajuste$nb == 0L || is.null(Z)) {
    return(rep(0, if (is.null(Z)) 0L else nrow(Z)))
  }

  as.numeric(ajuste$par[1L] + Z %*% ajuste$par[2L:ajuste$nb])
}


# Posteriori de theta (risco relativo a ancora UF).

.q5eb_posterior <- function(d, n, E, p_uf, eta, h, modelo, nivel) {

  alfa <- (1 - nivel) / 2

  if (modelo == "gama_poisson") {

    m0 <- exp(eta)
    forma <- h + d
    taxa <- h / m0 + E

    return(list(
      theta = forma / taxa,
      theta_prior = m0,
      peso_dados = E / (E + h / m0),
      ic_inf = stats::qgamma(alfa, forma, taxa),
      ic_sup = stats::qgamma(1 - alfa, forma, taxa)
    ))
  }

  p0 <- stats::plogis(stats::qlogis(p_uf) + eta)
  a1 <- d + p0 * h
  b1 <- n - d + (1 - p0) * h

  list(
    theta = (a1 / (a1 + b1)) / p_uf,
    theta_prior = p0 / p_uf,
    peso_dados = n / (n + h),
    ic_inf = stats::qbeta(alfa, a1, b1) / p_uf,
    ic_sup = stats::qbeta(1 - alfa, a1, b1) / p_uf
  )
}


# ============================================================
# 10. ESTABILIZACAO MUNICIPAL
# ============================================================
#
# estrato: "nacional" (padrao), "regiao" ou "uf".
# Cada grupo (Total, Masculino, Feminino) e tratado separadamente.

estabilizar_q5_eb <- function(
  insumos_q5,
  modelo = c("gama_poisson", "beta_binomial"),
  covariaveis = NULL,
  estrato = c("nacional", "regiao", "uf"),
  nivel_ic = 0.90,
  k_modo = c("uf", "municipal"),
  n_min_estrato = 50L,
  limiar_peso_alto = 0.50,
  limiar_peso_baixo = 0.20
) {

  modelo <- match.arg(modelo)
  estrato <- match.arg(estrato)
  k_modo <- match.arg(k_modo)

  if (!is.null(covariaveis)) {
    invalidas <- setdiff(covariaveis, COVARIAVEIS_Q5_EB)
    if (length(invalidas) > 0L) {
      stop(
        "Covariaveis fora do conjunto permitido: ",
        paste(invalidas, collapse = ", "),
        ". Permitidas: ",
        paste(COVARIAVEIS_Q5_EB, collapse = ", ")
      )
    }
  }

  colunas_necessarias <- c(
    "ano", "uf", "regiao", "cod_mun", "grupo",
    "filhos_nv_raw", "filhos_falecidos_raw", "zero_observado_raw",
    "B_ef", "d_ef", "dado_valido", "D_bruto",
    "D_uf", "k_uf", "t_uf", "k_municipal", "t_municipal",
    "ano_decimal_censo", COVARIAVEIS_Q5_EB
  )

  faltantes <- setdiff(colunas_necessarias, names(insumos_q5))

  if (length(faltantes) > 0L) {
    stop("Colunas ausentes em insumos_q5: ", paste(faltantes, collapse = ", "))
  }

  if (!(limiar_peso_baixo < limiar_peso_alto)) {
    stop("limiar_peso_baixo deve ser menor que limiar_peso_alto.")
  }

  d <- data.table::copy(data.table::as.data.table(insumos_q5))
  d[, .idx := .I]

  chave_estrato <- switch(
    estrato,
    regiao = "regiao",
    uf = "uf",
    nacional = NULL
  )

  # Linhas com ancora utilizavel
  d[
    ,
    ancora_ok := (
      dado_valido & is.finite(D_uf) & D_uf > 0 & D_uf < 1
    ) %in% TRUE
  ]

  d[, com_info := ancora_ok & (B_ef > 0) %in% TRUE]

  resultados <- list()

  blocos <- unique(d[, .(ano, grupo)])

  for (b in seq_len(nrow(blocos))) {

    bloco <- d[ano == blocos$ano[b] & grupo == blocos$grupo[b]]

    # ---- ajuste nacional (fallback) ----
    nac <- bloco[com_info == TRUE]

    if (nrow(nac) < 10L) next

    X_nac <- .q5eb_montar_X(nac, covariaveis)

    fit_nac <- .q5eb_ajustar(
      d = nac$d_ef, n = nac$B_ef, E = nac$B_ef * nac$D_uf,
      p_uf = nac$D_uf, Z = X_nac$X, modelo = modelo
    )

    subgrupos <- if (is.null(chave_estrato)) {
      list(bloco)
    } else {
      split(bloco, by = chave_estrato, keep.by = TRUE)
    }

    for (sub in subgrupos) {

      info <- sub[com_info == TRUE]

      usa_nacional <- FALSE
      fit <- NULL
      X_use <- NULL

      if (nrow(info) >= n_min_estrato) {

        X_s <- .q5eb_montar_X(info, covariaveis)

        fit <- .q5eb_ajustar(
          d = info$d_ef, n = info$B_ef, E = info$B_ef * info$D_uf,
          p_uf = info$D_uf, Z = X_s$X, modelo = modelo
        )

        if (!is.null(fit) && isTRUE(fit$convergencia)) {
          X_use <- X_s
        } else {
          fit <- NULL
        }
      }

      if (is.null(fit)) {
        fit <- fit_nac
        X_use <- X_nac
        usa_nacional <- TRUE
      }

      if (is.null(fit)) next

      # ---- predicao para todas as linhas com ancora ----
      pred <- sub[ancora_ok == TRUE]

      if (nrow(pred) == 0L) next

      X_pred <- .q5eb_montar_X(
        pred, covariaveis,
        centro = X_use$centro, escala = X_use$escala
      )

      eta <- .q5eb_eta(fit, X_pred$X)
      if (length(eta) == 0L) eta <- rep(0, nrow(pred))

      d_ef <- data.table::fifelse(is.finite(pred$d_ef), pred$d_ef, 0)
      n_ef <- data.table::fifelse(is.finite(pred$B_ef), pred$B_ef, 0)

      post <- .q5eb_posterior(
        d = d_ef, n = n_ef, E = n_ef * pred$D_uf, p_uf = pred$D_uf,
        eta = eta, h = fit$h, modelo = modelo, nivel = nivel_ic
      )

      res <- data.table::data.table(
        .idx = pred$.idx,
        hiper_param = fit$h,
        theta_prior = post$theta_prior,
        theta = post$theta,
        theta_ic_inf = post$ic_inf,
        theta_ic_sup = post$ic_sup,
        peso_dados = post$peso_dados,
        flag_covariavel_imputada = X_pred$imputado,
        flag_hiper_limite = fit$no_limite,
        flag_ajuste_nacional = usa_nacional
      )

      resultados[[length(resultados) + 1L]] <- res
    }
  }

  if (length(resultados) == 0L) {
    stop("Nenhum estrato foi estimado. Verifique os insumos.")
  }

  res <- data.table::rbindlist(resultados)

  out <- merge(d, res, by = ".idx", all.x = TRUE, sort = FALSE)

  # ----------------------------------------------------------
  # Escala de q5
  # ----------------------------------------------------------

  out[
    ,
    `:=`(
      k_usado = if (k_modo == "uf") k_uf else k_municipal,
      t_usado = if (k_modo == "uf") t_uf else t_municipal
    )
  ]

  out[
    ,
    `:=`(
      modelo = modelo,
      covariaveis = if (is.null(covariaveis)) "nenhuma" else paste(covariaveis, collapse = "+"),
      hiper_nome = if (modelo == "gama_poisson") "a" else "phi",
      E_esperado = B_ef * D_uf,
      smr_bruto = data.table::fifelse(
        is.finite(B_ef) & B_ef > 0, d_ef / (B_ef * D_uf), NA_real_
      ),
      peso_retracao = 1 - peso_dados,
      D_estabilizado = theta * D_uf,
      q5_trussell_bruto = k_municipal * D_bruto,
      q5_estabilizado = k_usado * theta * D_uf,
      q5_ic_inf = k_usado * theta_ic_inf * D_uf,
      q5_ic_sup = k_usado * theta_ic_sup * D_uf,
      ano_referencia_q5 = ano_decimal_censo - t_usado,
      amplitude_relativa_ic = (theta_ic_sup - theta_ic_inf) / theta
    )
  ]

  out[
    ,
    `:=`(
      flag_zero_observado_raw = zero_observado_raw,
      flag_sem_nascimentos = (B_ef == 0) %in% TRUE,
      flag_dados_invalidos = !dado_valido,
      flag_sem_ancora = !ancora_ok,
      flag_D_estabilizado_acima_1 = (D_estabilizado > 1) %in% TRUE
    )
  ]

  out[
    ,
    flag_confiabilidade := data.table::fcase(
      is.na(theta) | flag_sem_nascimentos, "sem_informacao",
      peso_dados >= limiar_peso_alto, "alta",
      peso_dados < limiar_peso_baixo, "baixa",
      default = "media"
    )
  ]

  out[, c(".idx", "ancora_ok", "com_info") := NULL]

  data.table::setorder(out, ano, grupo, uf, cod_mun)

  out[]
}


# ============================================================
# 11. COMPARACAO DE MODELOS E ESPECIFICACOES
# ============================================================
#
# Para cada ano x grupo x estrato x especificacao:
#
#   - log-verossimilhanca marginal e AIC
#   - validacao cruzada por municipios (K dobras): log-score
#     preditivo medio de municipios nao usados no ajuste
#   - zeros observados vs. zeros previstos pelo modelo
#
# Para comparar gama-Poisson e beta-binomial em pe de igualdade,
# as contagens sao arredondadas para inteiros (padrao); com
# contagens efetivas nao inteiras as duas sao quase-verossimilhancas
# com constantes de normalizacao diferentes.

ESPECIFICACOES_Q5_EB_PADRAO <- list(
  gp_base = list(modelo = "gama_poisson", covariaveis = NULL),
  bb_base = list(modelo = "beta_binomial", covariaveis = NULL),
  gp_tamanho_paridade = list(
    modelo = "gama_poisson",
    covariaveis = c("log_nascidos_ef", "paridade_alvo")
  ),
  gp_rr_adjacentes = list(
    modelo = "gama_poisson",
    covariaveis = "log_rr_adjacentes"
  )
)


.q5eb_ancora_cv_treino <- function(treino) {

  a <- treino[
    is.finite(filhos_nv_pond) & filhos_nv_pond >= 0 &
      is.finite(filhos_falecidos_pond) & filhos_falecidos_pond >= 0,
    .(
      B_pond_uf_cv = sum(filhos_nv_pond),
      O_pond_uf_cv = sum(filhos_falecidos_pond)
    ),
    by = .(ano, uf, grupo)
  ]

  a[
    ,
    D_uf_cv := data.table::fifelse(
      B_pond_uf_cv > 0,
      O_pond_uf_cv / B_pond_uf_cv,
      NA_real_
    )
  ]

  a[]
}


.q5eb_zeros_previstos <- function(fit, d, n, E, p_uf, eta, modelo) {

  if (modelo == "gama_poisson") {
    mu <- E * exp(eta)
    return(mean((fit$h / (fit$h + mu))^fit$h))
  }

  p0 <- stats::plogis(stats::qlogis(p_uf) + eta)
  alfa <- p0 * fit$h
  beta <- (1 - p0) * fit$h

  mean(exp(lbeta(alfa, n + beta) - lbeta(alfa, beta)))
}


comparar_modelos_q5_eb <- function(
  insumos_q5,
  especificacoes = ESPECIFICACOES_Q5_EB_PADRAO,
  estrato = c("nacional", "regiao", "uf"),
  k_dobras = 5L,
  arredondar = TRUE,
  semente = 20260101L
) {

  estrato <- match.arg(estrato)

  d <- data.table::copy(data.table::as.data.table(insumos_q5))

  colunas_necessarias <- c(
    "ano", "uf", "regiao", "cod_mun", "grupo",
    "filhos_nv_raw", "filhos_falecidos_raw", "zero_observado_raw",
    "filhos_nv_pond", "filhos_falecidos_pond",
    "B_ef", "d_ef", "dado_valido", "D_uf"
  )

  faltantes <- setdiff(colunas_necessarias, names(d))

  if (length(faltantes) > 0L) {
    stop(
      "Colunas ausentes em insumos_q5 para comparacao: ",
      paste(faltantes, collapse = ", ")
    )
  }

  d[
    ,
    com_info := (
      dado_valido & is.finite(D_uf) & D_uf > 0 & D_uf < 1 & B_ef > 0
    ) %in% TRUE
  ]

  d <- d[com_info == TRUE]

  if (arredondar) {
    d[, d_use := round(d_ef)]
    d[, n_use := pmax(round(B_ef), d_use)]
  } else {
    d[, d_use := d_ef]
    d[, n_use := B_ef]
  }

  d[, zero_apos_arredondamento := (d_use == 0 & n_use > 0) %in% TRUE]
  d[, E_use := n_use * D_uf]

  chave <- switch(
    estrato,
    regiao = c("ano", "grupo", "regiao"),
    uf = c("ano", "grupo", "uf"),
    nacional = c("ano", "grupo")
  )

  detalhe <- list()

  usa_rr_adjacentes <- any(vapply(
    especificacoes,
    function(x) "log_rr_adjacentes" %in% x$covariaveis,
    logical(1L)
  ))

  if (usa_rr_adjacentes) {
    warning(
      "A validacao cruzada recalcula D_uf do grupo-alvo somente com as ",
      "municipalidades de treino. A covariavel 'log_rr_adjacentes', se usada, ",
      "continua precomputada com ancoras UF das idades adjacentes obtidas da ",
      "base completa; trate o log-score dessas especificacoes como exploratorio."
    )
  }

  set.seed(semente)

  for (sub in split(d, by = chave, keep.by = TRUE)) {

    if (nrow(sub) < 2L * k_dobras) next

    dobras <- sample(rep_len(seq_len(k_dobras), nrow(sub)))
    sub[, .cv_idx := .I]

    for (nome in names(especificacoes)) {

      esp <- especificacoes[[nome]]
      mod <- esp$modelo
      cov <- esp$covariaveis

      X <- .q5eb_montar_X(sub, cov)

      fit <- .q5eb_ajustar(
        d = sub$d_use, n = sub$n_use, E = sub$E_use,
        p_uf = sub$D_uf, Z = X$X, modelo = mod
      )

      if (is.null(fit)) next

      eta <- .q5eb_eta(fit, X$X)
      if (length(eta) == 0L) eta <- rep(0, nrow(sub))

      zeros_prev <- .q5eb_zeros_previstos(
        fit, sub$d_use, sub$n_use, sub$E_use, sub$D_uf, eta, mod
      )

      # ---- validacao cruzada ----
      #
      # A ancora D_uf e recalculada em cada dobra exclusivamente
      # com os municipios de treino. Assim, o municipio de teste
      # nao contribui para a propria referencia UF usada no log-score.
      logscore <- rep(NA_real_, nrow(sub))

      for (f in seq_len(k_dobras)) {

        treino <- data.table::copy(sub[dobras != f])
        teste <- data.table::copy(sub[dobras == f])

        ancora_cv <- .q5eb_ancora_cv_treino(treino)

        treino <- merge(
          treino,
          ancora_cv[, .(ano, uf, grupo, D_uf_cv)],
          by = c("ano", "uf", "grupo"),
          all.x = TRUE,
          sort = FALSE
        )

        teste <- merge(
          teste,
          ancora_cv[, .(ano, uf, grupo, D_uf_cv)],
          by = c("ano", "uf", "grupo"),
          all.x = TRUE,
          sort = FALSE
        )

        treino[
          ,
          E_use_cv := n_use * D_uf_cv
        ]

        teste[
          ,
          E_use_cv := n_use * D_uf_cv
        ]

        treino_cv <- treino[
          is.finite(D_uf_cv) & D_uf_cv > 0 & D_uf_cv < 1 &
            is.finite(E_use_cv) & E_use_cv > 0
        ]

        teste_cv <- teste[
          is.finite(D_uf_cv) & D_uf_cv > 0 & D_uf_cv < 1 &
            is.finite(E_use_cv) & E_use_cv > 0
        ]

        if (nrow(treino_cv) < 2L || nrow(teste_cv) == 0L) next

        Xtr <- .q5eb_montar_X(treino_cv, cov)

        fit_tr <- .q5eb_ajustar(
          d = treino_cv$d_use,
          n = treino_cv$n_use,
          E = treino_cv$E_use_cv,
          p_uf = treino_cv$D_uf_cv,
          Z = Xtr$X,
          modelo = mod
        )

        if (is.null(fit_tr) || !isTRUE(fit_tr$convergencia)) next

        Xte <- .q5eb_montar_X(
          teste_cv, cov, centro = Xtr$centro, escala = Xtr$escala
        )

        eta_te <- .q5eb_eta(fit_tr, Xte$X)
        if (length(eta_te) == 0L) eta_te <- rep(0, nrow(teste_cv))

        score_f <- if (mod == "gama_poisson") {
          .q5eb_logpmf_gp(
            teste_cv$d_use,
            teste_cv$E_use_cv,
            eta_te,
            fit_tr$h
          )
        } else {
          .q5eb_logpmf_bb(
            teste_cv$d_use,
            teste_cv$n_use,
            stats::plogis(stats::qlogis(teste_cv$D_uf_cv) + eta_te),
            fit_tr$h
          )
        }

        logscore[teste_cv$.cv_idx] <- score_f
      }

      detalhe[[length(detalhe) + 1L]] <- data.table::data.table(
        ano = sub$ano[1L],
        grupo = sub$grupo[1L],
        estrato = if (estrato == "nacional") "Brasil" else as.character(sub[[chave[3L]]][1L]),
        especificacao = nome,
        modelo = mod,
        covariaveis = if (is.null(cov)) "nenhuma" else paste(cov, collapse = "+"),
        n_municipios = nrow(sub),
        n_par = fit$n_par,
        hiper_param = fit$h,
        loglik = fit$loglik,
        aic = -2 * fit$loglik + 2 * fit$n_par,
        zeros_obs = mean(sub$zero_observado_raw, na.rm = TRUE),
        zeros_base_exata = mean((sub$d_ef == 0 & sub$B_ef > 0) %in% TRUE),
        zeros_arredondados = mean(sub$zero_apos_arredondamento, na.rm = TRUE),
        zeros_prev = zeros_prev,
        cv_logscore = if (any(is.finite(logscore))) {
          mean(logscore[is.finite(logscore)])
        } else {
          NA_real_
        },
        cv_n = sum(is.finite(logscore)),
        cv_cobertura = mean(is.finite(logscore)),
        convergencia = fit$convergencia
      )
    }
  }

  if (length(detalhe) == 0L) {
    stop("Nenhum estrato com municipios suficientes para comparar.")
  }

  detalhe <- data.table::rbindlist(detalhe)

  resumo <- detalhe[
    ,
    .(
      n_municipios = sum(n_municipios),
      aic_total = sum(aic),
      cv_n = sum(cv_n),
      cv_cobertura = sum(cv_n) / sum(n_municipios),
      cv_logscore = data.table::fifelse(
        sum(cv_n) > 0,
        sum(cv_logscore * cv_n, na.rm = TRUE) / sum(cv_n),
        NA_real_
      ),
      zeros_obs = stats::weighted.mean(zeros_obs, n_municipios),
      zeros_base_exata = stats::weighted.mean(zeros_base_exata, n_municipios),
      zeros_arredondados = stats::weighted.mean(zeros_arredondados, n_municipios),
      zeros_prev = stats::weighted.mean(zeros_prev, n_municipios),
      todos_convergiram = all(convergencia)
    ),
    by = .(ano, grupo, especificacao, modelo, covariaveis)
  ]

  # Diferenca em relacao a primeira especificacao (referencia)
  ref <- names(especificacoes)[1L]

  resumo[
    ,
    `:=`(
      delta_cv_logscore = cv_logscore - cv_logscore[especificacao == ref],
      delta_aic = aic_total - aic_total[especificacao == ref]
    ),
    by = .(ano, grupo)
  ]

  data.table::setorder(resumo, ano, grupo, -cv_logscore)

  list(detalhe = detalhe[], resumo = resumo[])
}


# ============================================================
# 12. SEXOS A PARTIR DO THETA DO TOTAL (opcional)
# ============================================================
#
# O theta do grupo Total usa o dobro da informacao dos grupos
# por sexo. Esta funcao aplica o theta do Total a ancora de cada
# sexo (D_uf, k_uf, t_uf do proprio sexo).
#
# Pressuposto: o risco relativo municipal e comum aos sexos.
# Diferencas municipais especificas por sexo nao sao
# identificaveis com este tamanho amostral.

aplicar_theta_total_aos_sexos <- function(resultado_eb, insumos_q5) {

  if (!"Total" %in% resultado_eb$grupo) {
    stop("resultado_eb nao contem o grupo 'Total'.")
  }

  total <- resultado_eb[
    grupo == "Total",
    .(ano, uf, cod_mun, theta_total = theta,
      theta_total_ic_inf = theta_ic_inf, theta_total_ic_sup = theta_ic_sup,
      flag_confiabilidade_total = flag_confiabilidade)
  ]

  sexos <- data.table::as.data.table(insumos_q5)[
    grupo != "Total",
    .(ano, uf, regiao, cod_mun, grupo,
      filhos_nv_raw, filhos_falecidos_raw, zero_observado_raw,
      B_ef, d_ef, D_uf, k_uf, t_uf, ano_decimal_censo)
  ]

  out <- merge(
    sexos,
    total,
    by = c("ano", "uf", "cod_mun"),
    all.x = TRUE,
    sort = FALSE
  )

  out[
    ,
    `:=`(
      q5_via_total = k_uf * theta_total * D_uf,
      q5_via_total_ic_inf = k_uf * theta_total_ic_inf * D_uf,
      q5_via_total_ic_sup = k_uf * theta_total_ic_sup * D_uf,
      ano_referencia_q5 = ano_decimal_censo - t_uf,
      fonte_theta = "total"
    )
  ]

  data.table::setorder(out, ano, grupo, uf, cod_mun)

  out[]
}
